"""Milestone-1 orchestration.

Runs a goal through the PM agent (the SDK main thread) and translates the
message stream into Run/Task/Agent state. The PM dispatches to subagents via
the Agent tool; we watch those tool calls and their results to move tasks
across the board.
"""

import re
from datetime import datetime, timezone
from pathlib import Path

from claude_agent_sdk import (
    AssistantMessage,
    ClaudeAgentOptions,
    PermissionResultAllow,
    PermissionResultDeny,
    ResultMessage,
    TextBlock,
    ToolResultBlock,
    ToolUseBlock,
    UserMessage,
    query,
)

from app.agents.roster import ROSTER, build_subagents, pm_system_prompt
from app.agents.sandbox import DEFAULT_STACK, STACKS, ContainerManager, build_sandbox
from app.config import sdk_env, settings
from app.events import bus
from app.models import AgentStatus, Run, RunStatus, Task, TaskStatus

# In-memory state for the POC. RUNS holds every run this process has seen;
# AGENT_STATUS is the live status chip for each roster agent.
RUNS: dict[str, Run] = {}
AGENT_STATUS: dict[str, AgentStatus] = {a.id: AgentStatus.IDLE for a in ROSTER}

# Each run gets its own working directory; milestone 2 mounts this into a
# per-task container instead of letting Bash run here directly.
WORKSPACE_ROOT = Path(__file__).resolve().parents[2] / "workspace"

MAX_EVENTS = 500

# Reading an attached reference image returns the whole file as base64 inside
# one JSON message on the CLI's stdout; the SDK's default 1 MiB buffer kills
# the stream ("JSON message exceeded maximum buffer size"). 32 MiB covers the
# largest allowed upload (8 MB -> ~11 MB base64) with room to spare.
SDK_MAX_BUFFER = 32 * 1024 * 1024

# Subagents whose dispatches are tracked as board tasks (write access, own a
# per-task sandbox container). The reviewer is handled separately: it gates
# the most recent in-progress worker task instead of creating one.
_WORKER_SUBAGENTS = {"coder", "devops"}
_VERDICT_FAIL = re.compile(r"\bFAIL\b")
_VERDICT_PASS = re.compile(r"\bPASS\b")

# Harness bookkeeping tools the PM may use freely (no side effects outside
# the conversation). Everything else not in allowed_tools gets denied.
_HARMLESS_TOOLS = {
    "TodoWrite",
    "TaskCreate",
    "TaskUpdate",
    "TaskList",
    "TaskGet",
    "TaskOutput",
}


async def _gate_tool(tool_name: str, input_data: dict, _context) -> object:
    """Permission callback for tools not auto-allowed by allowed_tools.

    Two jobs:
    - Force every subagent dispatch into the foreground. Claude honors the
      persona instruction to do this, but other models (via gateways) ignore
      it; a background dispatch returns launch metadata instead of the
      subagent's result, which breaks task/status tracking.
    - Deny everything else (notably local Bash on the main thread) so
      "commands only run inside task containers" holds for every model.
    """
    if tool_name in ("Agent", "Task"):
        return PermissionResultAllow(
            updated_input={**input_data, "run_in_background": False}
        )
    if tool_name in _HARMLESS_TOOLS:
        return PermissionResultAllow()
    return PermissionResultDeny(
        message=(
            f"{tool_name} is not available. Delegate coding work to the coder "
            "agent; commands run only inside its sandboxed container."
        )
    )


def set_agent_status(agent_id: str, status: AgentStatus) -> None:
    if AGENT_STATUS.get(agent_id) == status:
        return
    AGENT_STATUS[agent_id] = status
    bus.publish(
        {"type": "agent_status", "agent_id": agent_id, "status": status.value}
    )


def _publish_task(run: Run, task: Task) -> None:
    bus.publish({"type": "task_update", "run_id": run.id, "task": task.model_dump()})


def _publish_run(run: Run) -> None:
    bus.publish(
        {
            "type": "run_update",
            "run_id": run.id,
            "status": run.status.value,
            "result": run.result,
        }
    )


def _event(run: Run, agent: str, kind: str, detail: str) -> None:
    entry = {
        "ts": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "agent": agent,
        "type": kind,
        "detail": detail[:500],
    }
    if len(run.events) < MAX_EVENTS:
        run.events.append(entry)
    bus.publish({"type": "activity", "run_id": run.id, "event": entry})


def _result_text(block: ToolResultBlock) -> str:
    if isinstance(block.content, str):
        return block.content
    if isinstance(block.content, list):
        return "\n".join(
            part.get("text", "") for part in block.content if isinstance(part, dict)
        )
    return ""


def _on_dispatch(
    run: Run, block: ToolUseBlock, dispatches: dict, active_worker: dict
) -> None:
    """PM invoked the Agent tool — a task is being handed to a subagent."""
    subagent = block.input.get("subagent_type", "")
    title = block.input.get("description") or block.input.get("prompt", "")[:80]
    task: Task | None = None

    if subagent in _WORKER_SUBAGENTS:
        active_worker["id"] = subagent  # sandbox events attribute to this agent
        task = Task(
            title=title,
            assigned_agent_id=subagent,
            status=TaskStatus.IN_PROGRESS,
            input=block.input.get("prompt", ""),
            created_by="pm",
        )
        run.tasks.append(task)
        set_agent_status(subagent, AgentStatus.WORKING)
        _publish_task(run, task)
    elif subagent == "reviewer":
        # Heuristic: the reviewer is checking the most recent in-progress
        # worker task. Good enough while dispatch is strictly sequential.
        task = next(
            (
                t
                for t in reversed(run.tasks)
                if t.assigned_agent_id in _WORKER_SUBAGENTS
                and t.status == TaskStatus.IN_PROGRESS
            ),
            None,
        )
        if task:
            task.status = TaskStatus.REVIEW
            _publish_task(run, task)
        set_agent_status("reviewer", AgentStatus.WORKING)

    dispatches[block.id] = (subagent, task)
    _event(run, "pm", "dispatch", f"{subagent}: {title}")


async def _on_dispatch_result(
    run: Run, block: ToolResultBlock, dispatches: dict, sandbox: ContainerManager
) -> None:
    """A subagent finished — its final message came back as the tool result."""
    entry = dispatches.get(block.tool_use_id)
    if entry is None:
        return
    subagent, task = entry
    text = _result_text(block)

    if "Async agent launched" in text[:100]:
        # A background dispatch slipped past _gate_tool: this is launch
        # metadata, not the subagent's result. Leave the dispatch pending so
        # we don't mark agents idle / tear down the sandbox prematurely.
        _event(run, subagent or "subagent", "background_dispatch",
               "subagent launched in background; result tracking degraded")
        return
    dispatches.pop(block.tool_use_id, None)

    if subagent in _WORKER_SUBAGENTS:
        set_agent_status(subagent, AgentStatus.IDLE)
        if task:
            task.output = text
            _publish_task(run, task)
        # Docker-per-task: the task's container dies with the task. The next
        # dispatch gets a fresh one (started lazily on first run_command).
        await sandbox.stop()
        _event(run, "sandbox", "stopped", f"container for task '{task.title if task else '?'}' torn down")
    elif subagent == "reviewer":
        set_agent_status("reviewer", AgentStatus.IDLE)
        if task and task.status == TaskStatus.REVIEW:
            if _VERDICT_FAIL.search(text):
                task.status = TaskStatus.IN_PROGRESS  # bounced back to coder
            elif _VERDICT_PASS.search(text):
                task.status = TaskStatus.DONE
            _publish_task(run, task)

    _event(run, subagent or "subagent", "finished", text)


async def _handle_message(
    run: Run, message, dispatches: dict, sandbox: ContainerManager, active_worker: dict
) -> None:
    parent_id = getattr(message, "parent_tool_use_id", None)

    if isinstance(message, AssistantMessage):
        if parent_id:
            # Activity inside a subagent's own context — log its tool use.
            subagent = dispatches.get(parent_id, ("subagent", None))[0]
            for block in message.content:
                if isinstance(block, ToolUseBlock):
                    _event(run, subagent, "tool_use", block.name)
            return
        set_agent_status("pm", AgentStatus.WORKING)
        for block in message.content:
            if isinstance(block, TextBlock) and block.text.strip():
                _event(run, "pm", "message", block.text.strip())
            elif isinstance(block, ToolUseBlock):
                # "Task" is the pre-v2.1.63 name for the Agent tool.
                if block.name in ("Agent", "Task"):
                    _on_dispatch(run, block, dispatches, active_worker)
                else:
                    _event(run, "pm", "tool_use", block.name)

    elif isinstance(message, UserMessage):
        if parent_id or not isinstance(message.content, list):
            return
        for block in message.content:
            if isinstance(block, ToolResultBlock):
                await _on_dispatch_result(run, block, dispatches, sandbox)

    elif isinstance(message, ResultMessage):
        run.result = message.result or ""
        run.status = RunStatus.FAILED if message.is_error else RunStatus.COMPLETED
        if run.status == RunStatus.COMPLETED:
            # The PM signed off on the whole goal, which supersedes per-task
            # verdict tracking (e.g. a PM that verified fixes itself instead
            # of re-dispatching the reviewer). Sweep stragglers to done.
            for task in run.tasks:
                if task.status != TaskStatus.DONE:
                    task.status = TaskStatus.DONE
                    _publish_task(run, task)
                    _event(run, "pm", "task_closed", f"closed with run: {task.title}")
        _event(run, "pm", "run_finished", run.status.value)
        _publish_run(run)


async def run_goal(run: Run) -> None:
    # An existing-project run works directly in that project (validated by
    # the API); a greenfield run gets a fresh per-run directory.
    if run.workspace:
        workdir = Path(run.workspace)
    else:
        workdir = WORKSPACE_ROOT / run.id
        workdir.mkdir(parents=True, exist_ok=True)
    existing_project = run.workspace is not None

    stack = STACKS.get(run.stack, STACKS[DEFAULT_STACK])
    # Which worker subagent currently owns the sandbox — its commands show
    # under that agent in the live feed (coder until the first dispatch).
    active_worker = {"id": "coder"}
    sandbox, sandbox_server = build_sandbox(
        run,
        workdir,
        on_event=lambda kind, detail: _event(run, active_worker["id"], kind, detail),
    )
    options = ClaudeAgentOptions(
        system_prompt=pm_system_prompt(stack, existing_project=existing_project),
        agents=build_subagents(run.stack, existing_project=existing_project),
        # Auto-approve the roster's tools so subagents never hang on a
        # permission prompt. No "Bash" here: commands only run inside the
        # per-task container via the sandbox MCP tool. "Agent" is deliberately
        # NOT listed — auto-allowed tools skip can_use_tool, and _gate_tool
        # must see every dispatch to force it into the foreground.
        allowed_tools=[
            "Read",
            "Write",
            "Edit",
            "Grep",
            "Glob",
            "mcp__sandbox__run_command",
        ],
        can_use_tool=_gate_tool,
        mcp_servers={"sandbox": sandbox_server},
        cwd=str(workdir),
        model=settings.pm_model,
        max_buffer_size=SDK_MAX_BUFFER,
        env=sdk_env(),
    )

    dispatches: dict = {}
    run.status = RunStatus.RUNNING
    _publish_run(run)
    set_agent_status("pm", AgentStatus.THINKING)
    where = f" in {run.workspace}" if run.workspace else ""
    _event(run, "pm", "run_started", f"[{stack.label}]{where} {run.goal}")

    async def _goal_stream():
        # can_use_tool requires streaming input mode, so the goal is wrapped
        # in an async generator instead of passed as a plain string.
        yield {"type": "user", "message": {"role": "user", "content": run.goal}}

    try:
        async for message in query(prompt=_goal_stream(), options=options):
            await _handle_message(run, message, dispatches, sandbox, active_worker)
    except Exception as exc:  # noqa: BLE001 — surface any SDK failure on the run
        run.status = RunStatus.FAILED
        run.result = f"error: {exc}"
        _event(run, "system", "error", str(exc))
        _publish_run(run)
    finally:
        await sandbox.stop()  # safety net if the run died mid-task
        if run.status == RunStatus.RUNNING:
            # Stream ended without a ResultMessage.
            run.status = RunStatus.FAILED
            _publish_run(run)
        for agent_id in AGENT_STATUS:
            set_agent_status(agent_id, AgentStatus.IDLE)
