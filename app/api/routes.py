"""HTTP API for milestone 1 — drive the office with curl/httpie."""

import asyncio

from fastapi import APIRouter, HTTPException, WebSocket, WebSocketDisconnect
from pydantic import BaseModel

from app.agents.orchestrator import AGENT_STATUS, RUNS, run_goal
from app.agents.roster import ROSTER
from app.agents.sandbox import DEFAULT_STACK, STACKS
from app.events import bus
from app.models import Agent, Run

router = APIRouter()

# Keep strong references so background run tasks aren't garbage-collected.
_background_tasks: set[asyncio.Task] = set()


class GoalRequest(BaseModel):
    goal: str
    stack: str = DEFAULT_STACK


@router.get("/agents", response_model=list[Agent])
def list_agents() -> list[Agent]:
    return [a.model_copy(update={"status": AGENT_STATUS[a.id]}) for a in ROSTER]


@router.post("/goals", status_code=202, response_model=Run)
async def create_goal(body: GoalRequest) -> Run:
    if body.stack not in STACKS:
        raise HTTPException(
            status_code=422,
            detail=f"unknown stack '{body.stack}'; valid: {sorted(STACKS)}",
        )
    run = Run(goal=body.goal, stack=body.stack)
    RUNS[run.id] = run
    task = asyncio.create_task(run_goal(run))
    _background_tasks.add(task)
    task.add_done_callback(_background_tasks.discard)
    return run


@router.get("/goals", response_model=list[Run])
def list_goals() -> list[Run]:
    return list(RUNS.values())


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
