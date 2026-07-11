"""Docker-per-task command execution for the Coder Agent.

The coder has no Bash tool. Instead it gets one in-process MCP tool,
`mcp__sandbox__run_command`, which execs inside a node:20-slim container with
the run's working directory mounted at /workspace. The container starts
lazily on the first command of a task and is torn down when the task's
dispatch completes (see orchestrator._on_dispatch_result), so each task gets
a fresh container.
"""

import asyncio
import uuid
from pathlib import Path

from claude_agent_sdk import create_sdk_mcp_server, tool

from app.models import Run

IMAGE = "node:20-slim"
START_TIMEOUT = 300  # first start may pull the image
EXEC_TIMEOUT = 180
MAX_OUTPUT_CHARS = 10_000


class SandboxError(Exception):
    pass


class ContainerManager:
    """Lifecycle of the current task's container for one run."""

    def __init__(self, run_id: str, workdir: Path):
        self.run_id = run_id
        self.workdir = workdir
        self._name: str | None = None
        self._lock = asyncio.Lock()

    async def _docker(self, *args: str, timeout: float) -> tuple[int, str]:
        proc = await asyncio.create_subprocess_exec(
            "docker",
            *args,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.STDOUT,
        )
        try:
            out, _ = await asyncio.wait_for(proc.communicate(), timeout)
        except asyncio.TimeoutError:
            proc.kill()
            await proc.wait()
            raise SandboxError(f"docker {args[0]} timed out after {timeout}s")
        return proc.returncode or 0, out.decode(errors="replace")

    async def ensure_started(self) -> str:
        async with self._lock:
            if self._name:
                return self._name
            name = f"agent-office-{self.run_id}-{uuid.uuid4().hex[:6]}"
            code, out = await self._docker(
                "run",
                "-d",
                "--rm",
                "--name",
                name,
                "--memory=1g",
                "--cpus=2",
                "-v",
                f"{self.workdir}:/workspace",
                "-w",
                "/workspace",
                IMAGE,
                "sleep",
                "infinity",
                timeout=START_TIMEOUT,
            )
            if code != 0:
                raise SandboxError(f"container failed to start: {out.strip()}")
            self._name = name
            return name

    async def exec(self, command: str) -> str:
        name = await self.ensure_started()
        code, out = await self._docker(
            "exec", name, "bash", "-lc", command, timeout=EXEC_TIMEOUT
        )
        if len(out) > MAX_OUTPUT_CHARS:
            out = out[:MAX_OUTPUT_CHARS] + "\n... (output truncated)"
        return f"exit code: {code}\n{out}"

    async def stop(self) -> None:
        async with self._lock:
            if not self._name:
                return
            name, self._name = self._name, None
        try:
            await self._docker("stop", "-t", "1", name, timeout=30)
        except SandboxError:
            pass  # --rm cleans up eventually; don't fail the run on teardown


def build_sandbox(run: Run, workdir: Path, on_event=None):
    """Create the per-run container manager and its MCP server.

    `on_event(kind, detail)` lets the orchestrator log sandbox activity into
    the run's event stream without a circular import.
    """
    manager = ContainerManager(run.id, workdir)

    @tool(
        "run_command",
        "Run a shell command inside this task's sandboxed Linux container "
        f"({IMAGE}). The task directory is mounted at /workspace, which is "
        "the working directory — use relative paths. Node and npm are "
        "available; Python is NOT installed.",
        {"command": str},
    )
    async def run_command(args: dict):
        command = str(args.get("command", ""))
        if on_event:
            on_event("sandbox_exec", command)
        try:
            output = await manager.exec(command)
        except SandboxError as exc:
            if on_event:
                on_event("sandbox_error", str(exc))
            return {
                "content": [{"type": "text", "text": f"sandbox error: {exc}"}],
                "is_error": True,
            }
        return {"content": [{"type": "text", "text": output}]}

    server = create_sdk_mcp_server(name="sandbox", version="0.1.0", tools=[run_command])
    return manager, server
