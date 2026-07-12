"""Core data models for Agent Office."""

import uuid
from enum import Enum

from pydantic import BaseModel, Field


class AgentStatus(str, Enum):
    IDLE = "idle"
    THINKING = "thinking"
    WORKING = "working"
    BLOCKED = "blocked"


class TaskStatus(str, Enum):
    TODO = "todo"
    IN_PROGRESS = "in_progress"
    REVIEW = "review"
    DONE = "done"


class Agent(BaseModel):
    id: str
    name: str
    role: str
    persona_prompt: str
    model: str
    tools: list[str]
    status: AgentStatus = AgentStatus.IDLE


class Task(BaseModel):
    id: str = Field(default_factory=lambda: uuid.uuid4().hex[:8])
    title: str
    assigned_agent_id: str | None = None
    status: TaskStatus = TaskStatus.TODO
    input: str = ""
    output: str | None = None
    created_by: str


class RunStatus(str, Enum):
    PENDING = "pending"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"


class Run(BaseModel):
    """One goal submitted to the office, and everything that happened to it."""

    id: str = Field(default_factory=lambda: uuid.uuid4().hex[:8])
    goal: str
    stack: str = "node"  # key into app.agents.sandbox.STACKS
    status: RunStatus = RunStatus.PENDING
    tasks: list[Task] = Field(default_factory=list)
    result: str | None = None
    events: list[dict] = Field(default_factory=list)
