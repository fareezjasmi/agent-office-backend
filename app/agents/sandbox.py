"""Docker-per-task command execution for the Coder Agent.

The coder has no Bash tool. Instead it gets one in-process MCP tool,
`mcp__sandbox__run_command`, which execs inside a container with the run's
working directory mounted at /workspace. The container starts lazily on the
first command of a task and is torn down when the task's dispatch completes
(see orchestrator._on_dispatch_result), so each task gets a fresh container.

Which container depends on the run's stack (see STACKS): Node goals get
node:20-slim, Flutter goals get a full Flutter SDK image with more memory and
longer timeouts, plus named cache volumes so pub/gradle downloads survive the
per-task teardown.
"""

import asyncio
import uuid
from dataclasses import dataclass, field
from pathlib import Path

from claude_agent_sdk import create_sdk_mcp_server, tool

from app.config import settings
from app.models import Run

MAX_OUTPUT_CHARS = 10_000


@dataclass(frozen=True)
class StackSpec:
    """Everything that varies between project stacks."""

    id: str
    label: str
    image: str
    memory: str
    cpus: str
    exec_timeout: float
    start_timeout: float  # first start may pull the image
    # What the run_command tool description tells the coder about the container.
    tool_notes: str
    # Stack-specific working instructions appended to the coder's persona.
    coder_notes: str
    # Extra line for the PM so task specs target the right stack.
    pm_notes: str
    # Named Docker volumes mounted into every container (name -> mount path),
    # so package downloads survive the Docker-per-task teardown.
    cache_volumes: dict[str, str] = field(default_factory=dict)
    env: dict[str, str] = field(default_factory=dict)


STACKS: dict[str, StackSpec] = {
    "node": StackSpec(
        id="node",
        label="Node.js",
        image="node:20-slim",
        memory="1g",
        cpus="2",
        exec_timeout=180,
        start_timeout=300,
        tool_notes="Node and npm are available; Python is NOT installed.",
        coder_notes=(
            "Node and npm are available; Python is NOT — write and test code "
            "in JavaScript/Node unless the spec says otherwise."
        ),
        pm_notes=(
            "Task specs should target JavaScript/Node — the coder's container "
            "has Node and npm but no Python."
        ),
    ),
    "flutter": StackSpec(
        id="flutter",
        label="Flutter",
        image=settings.flutter_sandbox_image,
        memory="4g",
        cpus="2",
        exec_timeout=900,
        start_timeout=1800,
        tool_notes=(
            "The Flutter SDK (flutter, dart) is preinstalled. There is no "
            "display, emulator, or attached device."
        ),
        coder_notes=(
            "The Flutter SDK is preinstalled (flutter and dart are on PATH). "
            "Scaffold new apps with `flutter create`. There is no display, "
            "emulator, or attached device — never use `flutter run`; verify "
            "with `flutter analyze` and `flutter test`, and use `flutter "
            "build web` when the spec calls for a runnable build. Flutter "
            "commands can legitimately take several minutes (the pub cache "
            "persists across tasks, but compilation is slow) — wait for a "
            "command to finish rather than re-running it."
        ),
        pm_notes=(
            "Task specs must target a Flutter app written in Dart. Every "
            "definition of done must be checkable headlessly — `flutter "
            "analyze` clean, `flutter test` passing, or `flutter build web` "
            "succeeding — because no emulator or device is available. Flutter "
            "tasks are slow; prefer fewer, larger tasks over many tiny ones."
        ),
        cache_volumes={
            "agent-office-pub-cache": "/cache/pub",
            "agent-office-gradle-cache": "/cache/gradle",
        },
        env={"PUB_CACHE": "/cache/pub", "GRADLE_USER_HOME": "/cache/gradle"},
    ),
}

DEFAULT_STACK = "node"


class SandboxError(Exception):
    pass


class ContainerManager:
    """Lifecycle of the current task's container for one run."""

    def __init__(self, run_id: str, workdir: Path, stack: StackSpec):
        self.run_id = run_id
        self.workdir = workdir
        self.stack = stack
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
            args = [
                "run",
                "-d",
                "--rm",
                "--name",
                name,
                f"--memory={self.stack.memory}",
                f"--cpus={self.stack.cpus}",
                "-v",
                f"{self.workdir}:/workspace",
            ]
            for volume, mount in self.stack.cache_volumes.items():
                args += ["-v", f"{volume}:{mount}"]
            for key, value in self.stack.env.items():
                args += ["-e", f"{key}={value}"]
            args += ["-w", "/workspace", self.stack.image, "sleep", "infinity"]
            code, out = await self._docker(*args, timeout=self.stack.start_timeout)
            if code != 0:
                raise SandboxError(f"container failed to start: {out.strip()}")
            self._name = name
            return name

    async def exec(self, command: str) -> str:
        name = await self.ensure_started()
        code, out = await self._docker(
            "exec", name, "bash", "-lc", command, timeout=self.stack.exec_timeout
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
    stack = STACKS.get(run.stack, STACKS[DEFAULT_STACK])
    manager = ContainerManager(run.id, workdir, stack)

    @tool(
        "run_command",
        "Run a shell command inside this task's sandboxed Linux container "
        f"({stack.image}). The task directory is mounted at /workspace, which "
        f"is the working directory — use relative paths. {stack.tool_notes}",
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
