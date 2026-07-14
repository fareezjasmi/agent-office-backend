"""HTTP API for milestone 1 — drive the office with curl/httpie."""

import asyncio
import base64
import re
from pathlib import Path
from typing import Literal

from claude_agent_sdk import (
    AssistantMessage,
    ClaudeAgentOptions,
    ResultMessage,
    TextBlock,
    query,
)
from fastapi import APIRouter, HTTPException, WebSocket, WebSocketDisconnect
from pydantic import BaseModel, Field

from app.agents.orchestrator import (
    AGENT_STATUS,
    RUNS,
    SDK_MAX_BUFFER,
    WORKSPACE_ROOT,
    run_goal,
    set_agent_status,
)
from app.agents.roster import ROSTER
from app.agents.sandbox import DEFAULT_STACK, STACKS
from app.config import sdk_env, settings
from app.events import bus
from app.models import Agent, AgentStatus, Run, RunStatus

router = APIRouter()

# Keep strong references so background run tasks aren't garbage-collected.
_background_tasks: set[asyncio.Task] = set()


class ImageAttachment(BaseModel):
    name: str
    data: str  # base64, no data: URI prefix


_IMAGE_TYPES = {
    "png": "image/png",
    "jpg": "image/jpeg",
    "jpeg": "image/jpeg",
    "gif": "image/gif",
    "webp": "image/webp",
}
_MAX_IMAGE_BYTES = 8 * 1024 * 1024
_MAX_IMAGES = 8


def _check_image_count(images: list[ImageAttachment]) -> None:
    if len(images) > _MAX_IMAGES:
        raise HTTPException(
            status_code=422, detail=f"too many images; max {_MAX_IMAGES} per request"
        )


def _decode_image(img: ImageAttachment) -> tuple[str, bytes, str]:
    """Validate an upload and return (safe filename, raw bytes, media type)."""
    ext = Path(img.name).suffix.lower().lstrip(".")
    media_type = _IMAGE_TYPES.get(ext)
    if media_type is None:
        raise HTTPException(
            status_code=422,
            detail=f"unsupported image type '.{ext}'; valid: {sorted(_IMAGE_TYPES)}",
        )
    try:
        raw = base64.b64decode(img.data, validate=True)
    except Exception as exc:
        raise HTTPException(status_code=422, detail="image data is not valid base64") from exc
    if len(raw) > _MAX_IMAGE_BYTES:
        raise HTTPException(status_code=413, detail="image larger than 8 MB")
    safe = re.sub(r"[^A-Za-z0-9._-]", "_", Path(img.name).name) or f"image.{ext}"
    return safe, raw, media_type


class GoalRequest(BaseModel):
    goal: str
    stack: str = DEFAULT_STACK
    # Optional absolute path to an existing project to fix/update in place.
    # Omit for a fresh per-run workspace (greenfield goal).
    workspace: str | None = None
    # Optional reference images (mockups, screenshots, diagrams). Saved under
    # the run's refs/ dir; the PM and coder view them with the Read tool.
    images: list[ImageAttachment] = []


def _resolve_workspace(raw: str) -> Path:
    """Validate an existing-project workspace path or raise an HTTPException.

    Guardrails: the path must be an existing directory inside either
    backend/workspace/ (follow-ups on past runs) or one of the configured
    WORKSPACE_ALLOWLIST roots, and no other run may be active in it — two
    coders editing the same files would trample each other.
    """
    path = Path(raw).expanduser()
    if not path.is_absolute():
        raise HTTPException(status_code=422, detail="workspace must be an absolute path")
    path = path.resolve()
    if not path.is_dir():
        raise HTTPException(status_code=422, detail=f"workspace is not a directory: {path}")

    workspace_root = WORKSPACE_ROOT.resolve()
    if path == workspace_root:
        raise HTTPException(
            status_code=403,
            detail="workspace may not be the run-storage root itself; target one run's directory",
        )
    allowed = path.is_relative_to(workspace_root) or any(
        path == root or path.is_relative_to(root)
        for root in (r.resolve() for r in settings.workspace_allowlist_paths)
    )
    if not allowed:
        raise HTTPException(
            status_code=403,
            detail=(
                f"workspace '{path}' is outside the allowed roots; add its "
                "parent directory to WORKSPACE_ALLOWLIST in backend/.env"
            ),
        )

    for run in RUNS.values():
        if (
            run.workspace
            and run.status in (RunStatus.PENDING, RunStatus.RUNNING)
            and Path(run.workspace) == path
        ):
            raise HTTPException(
                status_code=409,
                detail=f"run {run.id} is already working in this workspace",
            )
    return path


@router.get("/agents", response_model=list[Agent])
def list_agents() -> list[Agent]:
    return [a.model_copy(update={"status": AGENT_STATUS[a.id]}) for a in ROSTER]


class ChatMessage(BaseModel):
    sender: Literal["boss", "agent"] = Field(alias="from")
    text: str


class ChatRequest(BaseModel):
    message: str
    history: list[ChatMessage] = []
    # Optional images sent inline with this message (e.g. mockups for the PM).
    images: list[ImageAttachment] = []


class ChatReply(BaseModel):
    reply: str


_DM_NOTE = """

You are currently in a direct-message chat with your boss (the human running
Agent Office). This is a conversation, not a task run. You have READ-ONLY
tools (Read, Grep, Glob) — use them to inspect a run's workspace or attached
reference images when the boss asks what was done or what a file contains.
Never attempt to write, edit, or execute anything from a DM. Reply in plain
text, stay in character, and keep it short and helpful.

Below is the live state of the office (refreshed on every message). Answer
questions about current or past work from it — it is the ground truth for
what you and the team are doing right now; check the actual workspace files
when the boss wants specifics. You cannot start, change, or cancel runs from
this chat: if the boss gives you a new goal or project here, acknowledge it
and ask them to submit it via the "+ New Goal" button so the office picks it
up as a run."""


def _office_context(agent: Agent) -> str:
    """Live office snapshot injected into the DM system prompt."""
    lines = [f"Your current status: {AGENT_STATUS[agent.id].value}"]

    lines.append(f"Run workspaces live under {WORKSPACE_ROOT}/<run_id>.")

    runs = list(RUNS.values())[-5:]
    if not runs:
        lines.append("No goals have been submitted yet this session.")
    for run in runs:
        workspace = run.workspace or str(WORKSPACE_ROOT / run.id)
        lines.append(
            f"Run {run.id} [{run.status.value}] stack={run.stack} workspace={workspace}"
        )
        lines.append(f"  goal: {run.goal[:500]}")
        for task in run.tasks:
            assignee = task.assigned_agent_id or "unassigned"
            lines.append(f"  - task [{task.status.value}] ({assignee}) {task.title[:120]}")
        if run.result:
            lines.append(f"  result: {run.result[:300]}")

    recent = [
        event
        for run in runs
        for event in run.events
        if event["agent"] == agent.id
    ][-8:]
    if recent:
        lines.append("Your recent activity:")
        lines.extend(
            f"  - {e['ts'][11:19]} [{e['type']}] {e['detail'][:200]}" for e in recent
        )

    return "\n\n== LIVE OFFICE STATE ==\n" + "\n".join(lines)


@router.post("/agents/{agent_id}/chat", response_model=ChatReply)
async def dm_agent(agent_id: str, body: ChatRequest) -> ChatReply:
    """1:1 DM with a roster agent — one-shot query with its persona, no tools."""
    agent = next((a for a in ROSTER if a.id == agent_id), None)
    if agent is None:
        raise HTTPException(status_code=404, detail="unknown agent")

    lines = [
        f"{'Boss' if m.sender == 'boss' else agent.name}: {m.text}"
        for m in body.history
    ]
    lines.append(f"Boss: {body.message}")
    prompt = "\n\n".join(lines)
    if body.history:
        prompt += "\n\nReply to the boss's last message."

    options = ClaudeAgentOptions(
        system_prompt=agent.persona_prompt + _DM_NOTE + _office_context(agent),
        model=agent.model,
        # Read-only tools so agents can answer "what did we change?" from the
        # actual workspace files. Auto-allowed (no permission prompts); write
        # and exec tools simply don't exist in a DM.
        tools=["Read", "Grep", "Glob"],
        allowed_tools=["Read", "Grep", "Glob"],
        strict_mcp_config=True,
        max_turns=12,
        max_buffer_size=SDK_MAX_BUFFER,
        env=sdk_env(),
    )

    # A plain string prompt for text; content blocks (streaming input mode)
    # when images ride along.
    if body.images:
        _check_image_count(body.images)
        content: list[dict] = []
        for image in body.images:
            _, raw, media_type = _decode_image(image)
            content.append(
                {
                    "type": "image",
                    "source": {
                        "type": "base64",
                        "media_type": media_type,
                        "data": base64.b64encode(raw).decode(),
                    },
                }
            )
        content.append({"type": "text", "text": prompt})

        async def _message_stream():
            yield {"type": "user", "message": {"role": "user", "content": content}}

        prompt_arg: object = _message_stream()
    else:
        prompt_arg = prompt

    # Show the chat on the office floor, without clobbering a live run's status.
    was_idle = AGENT_STATUS[agent_id] == AgentStatus.IDLE
    if was_idle:
        set_agent_status(agent_id, AgentStatus.THINKING)
    parts: list[str] = []
    result_text: str | None = None
    try:
        async for message in query(prompt=prompt_arg, options=options):
            if isinstance(message, AssistantMessage):
                for block in message.content:
                    if isinstance(block, TextBlock) and block.text.strip():
                        parts.append(block.text.strip())
            elif isinstance(message, ResultMessage) and not message.is_error:
                # The final answer; assistant text collected along the way is
                # tool-use narration we only fall back to.
                result_text = message.result
    except Exception as exc:  # noqa: BLE001 — surface any SDK failure to the client
        raise HTTPException(status_code=502, detail=f"agent chat failed: {exc}") from exc
    finally:
        if was_idle and AGENT_STATUS[agent_id] == AgentStatus.THINKING:
            set_agent_status(agent_id, AgentStatus.IDLE)

    reply = (result_text or "\n\n".join(parts)).strip()
    if not reply:
        raise HTTPException(status_code=502, detail="agent returned no reply")
    return ChatReply(reply=reply)


@router.post("/goals", status_code=202, response_model=Run)
async def create_goal(body: GoalRequest) -> Run:
    if body.stack not in STACKS:
        raise HTTPException(
            status_code=422,
            detail=f"unknown stack '{body.stack}'; valid: {sorted(STACKS)}",
        )
    workspace = _resolve_workspace(body.workspace) if body.workspace else None
    run = Run(goal=body.goal, stack=body.stack, workspace=str(workspace) if workspace else None)
    if body.images:
        # Refs live under the run's own storage dir (even for external
        # workspaces) so we never pollute a user's repo with uploads.
        _check_image_count(body.images)
        refs = WORKSPACE_ROOT / run.id / "refs"
        refs.mkdir(parents=True, exist_ok=True)
        ref_paths: list[Path] = []
        for image in body.images:
            name, raw, _ = _decode_image(image)
            ref_path = refs / name
            n = 1
            while ref_path in ref_paths:  # same filename attached twice
                ref_path = refs / f"{Path(name).stem}-{n}{Path(name).suffix}"
                n += 1
            ref_path.write_bytes(raw)
            ref_paths.append(ref_path)
        listing = "\n".join(f"- {p}" for p in ref_paths)
        plural = "s are" if len(ref_paths) > 1 else " is"
        run.goal += (
            f"\n\n[Reference image{plural} attached:\n{listing}\nView them "
            "with the Read tool before planning. HARD RULE: every task spec "
            "that involves UI or visual work must list these exact file paths "
            "and instruct the coder to view them with the Read tool before "
            "writing code — never substitute your own prose description for "
            "the images. When dispatching the reviewer for such a task, "
            "include the paths and ask it to check the result against them.]"
        )
    RUNS[run.id] = run
    task = asyncio.create_task(run_goal(run))
    _background_tasks.add(task)
    task.add_done_callback(_background_tasks.discard)
    return run


@router.get("/goals", response_model=list[Run])
def list_goals() -> list[Run]:
    return list(RUNS.values())


class Project(BaseModel):
    name: str
    path: str
    kind: Literal["run", "external"]
    runs: int = 0
    last_goal: str | None = None
    last_status: str | None = None
    stack: str | None = None
    active: bool = False  # a run is pending/running here right now


_PROJECT_MARKERS = ("package.json", "pyproject.toml", "pubspec.yaml", "go.mod", ".git")


def _looks_like_project(path: Path) -> bool:
    return any((path / marker).exists() for marker in _PROJECT_MARKERS)


@router.get("/projects", response_model=list[Project])
def list_projects() -> list[Project]:
    """Directories the office can work on.

    - "run" projects: per-run workspaces under backend/workspace/.
    - "external" projects: repos under the WORKSPACE_ALLOWLIST roots (the root
      itself if it looks like a project, otherwise its immediate subdirs).
    Enriched with this process's run history where we have it.
    """
    projects: dict[str, Project] = {}

    if WORKSPACE_ROOT.is_dir():
        for entry in WORKSPACE_ROOT.iterdir():
            if not entry.is_dir() or entry.name.startswith("."):
                continue
            contents = [p.name for p in entry.iterdir() if not p.name.startswith(".")]
            if contents in ([], ["refs"]):
                continue  # empty or a refs-only holder for an external run
            projects[str(entry)] = Project(name=entry.name, path=str(entry), kind="run")

    for root in settings.workspace_allowlist_paths:
        root = root.resolve()
        if not root.is_dir():
            continue
        candidates = [root] if _looks_like_project(root) else [
            d for d in root.iterdir() if d.is_dir() and not d.name.startswith(".")
        ]
        for path in candidates:
            projects.setdefault(
                str(path), Project(name=path.name, path=str(path), kind="external")
            )

    for run in RUNS.values():
        path = run.workspace or str(WORKSPACE_ROOT / run.id)
        project = projects.get(path)
        if project is None:
            continue
        project.runs += 1
        project.last_goal = run.goal.split("\n")[0][:160]
        project.last_status = run.status.value
        project.stack = run.stack
        if run.status in (RunStatus.PENDING, RunStatus.RUNNING):
            project.active = True
        if project.kind == "run" and project.name == Path(path).name:
            project.name = project.last_goal or project.name

    # Active work first, then external repos, then past runs.
    return sorted(
        projects.values(), key=lambda p: (not p.active, p.kind == "run", p.name.lower())
    )


@router.get("/goals/{run_id}", response_model=Run)
def get_goal(run_id: str) -> Run:
    run = RUNS.get(run_id)
    if run is None:
        raise HTTPException(status_code=404, detail="run not found")
    return run


@router.post("/debug/simulate", status_code=202)
async def simulate_run() -> dict[str, str]:
    """Replay a canned run through the event bus (no agents, no cost).

    Lets you develop/demo the dashboard without dispatching real work.
    """
    from app.agents.orchestrator import _event, _publish_run, _publish_task, set_agent_status
    from app.models import AgentStatus, Run, RunStatus, Task, TaskStatus

    async def script() -> None:
        run = Run(goal="(simulated) build a demo feature", status=RunStatus.RUNNING)
        RUNS[run.id] = run
        _publish_run(run)
        set_agent_status("pm", AgentStatus.THINKING)
        _event(run, "pm", "run_started", run.goal)
        await asyncio.sleep(1)
        task = Task(
            title="(simulated) implement demo.js",
            assigned_agent_id="coder",
            status=TaskStatus.IN_PROGRESS,
            created_by="pm",
        )
        run.tasks.append(task)
        set_agent_status("pm", AgentStatus.WORKING)
        set_agent_status("coder", AgentStatus.WORKING)
        _publish_task(run, task)
        _event(run, "pm", "dispatch", "coder: implement demo.js")
        await asyncio.sleep(2)
        set_agent_status("coder", AgentStatus.IDLE)
        set_agent_status("reviewer", AgentStatus.WORKING)
        task.status = TaskStatus.REVIEW
        _publish_task(run, task)
        _event(run, "coder", "finished", "demo.js written and verified")
        await asyncio.sleep(2)
        set_agent_status("reviewer", AgentStatus.IDLE)
        task.status = TaskStatus.DONE
        _publish_task(run, task)
        _event(run, "reviewer", "finished", "PASS")
        run.status = RunStatus.COMPLETED
        run.result = "(simulated) goal completed"
        _event(run, "pm", "run_finished", "completed")
        _publish_run(run)
        set_agent_status("pm", AgentStatus.IDLE)

    task = asyncio.create_task(script())
    _background_tasks.add(task)
    task.add_done_callback(_background_tasks.discard)
    return {"status": "simulating"}


@router.websocket("/ws")
async def status_stream(ws: WebSocket) -> None:
    """Live office feed: snapshot on connect, then every bus event.

    Event types: agent_status, task_update, run_update, activity.
    """
    await ws.accept()
    queue = bus.subscribe()
    try:
        await ws.send_json(
            {
                "type": "snapshot",
                "agents": [
                    a.model_copy(update={"status": AGENT_STATUS[a.id]}).model_dump()
                    for a in ROSTER
                ],
                "runs": [r.model_dump() for r in RUNS.values()],
            }
        )
        while True:
            await ws.send_json(await queue.get())
    except WebSocketDisconnect:
        pass
    finally:
        bus.unsubscribe(queue)
