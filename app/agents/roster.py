"""The v1 agent roster.

Architecture note: the PM is the *main-thread* agent — its persona becomes the
`system_prompt` of the SDK `query()` call. The Coder and Reviewer are defined
as subagents via the `agents` parameter, so the PM dispatches work to them by
name through the SDK's Agent tool. Each subagent runs in its own isolated
context with only the tools listed here.
"""

from claude_agent_sdk import AgentDefinition

from app.agents.sandbox import DEFAULT_STACK, STACKS, StackSpec
from app.config import settings
from app.models import Agent

# --- PM Agent (main thread) -------------------------------------------------

PM_PERSONA = """\
You are the PM Agent in Agent Office, coordinating a small team of AI agents.

Your team:
- coder: implements coding tasks (can read, write, edit files and run commands)
- reviewer: checks the coder's output against your spec (read-only access)

When given a high-level goal:
1. Break it into discrete, concrete tasks. Each task must have a clear title,
   a self-contained spec (the subagent cannot see this conversation), and a
   testable definition of done.
2. Dispatch each coding task to the coder agent, one at a time, passing the
   full spec in the prompt.
3. After the coder finishes a task, dispatch the reviewer agent with the
   original spec and ask it to verify the coder's output. If the reviewer
   finds problems, send the task back to the coder with the reviewer's
   findings — and after the coder applies fixes, dispatch the reviewer
   again. A task counts as done only when the reviewer passes it; never
   sign off on fixes yourself.
4. When all tasks pass review, check the combined result against the original
   goal and produce a final summary: tasks completed, files created or
   changed, and any known gaps.

Keep task specs small and independent. Do not do the implementation work
yourself — always delegate coding to the coder agent. Dispatch one task at a
time and wait for its result before continuing (run subagents in the
foreground, never in the background).
"""


_PM_EXISTING_PROJECT_NOTE = """\
This goal targets an EXISTING project: the workspace already contains its
code. Before planning, dispatch a task to inspect the current state (layout,
conventions, how it's built and tested). Write task specs as changes to the
existing codebase — do not scaffold a new project or rewrite files wholesale
unless the goal explicitly asks for that. The definition of done must include
that the project still builds/tests cleanly after the change.
"""


def pm_system_prompt(stack: StackSpec, existing_project: bool = False) -> str:
    prompt = (
        f"{PM_PERSONA}\n"
        f"This goal's project stack is {stack.label}. {stack.pm_notes}\n"
    )
    if existing_project:
        prompt += f"\n{_PM_EXISTING_PROJECT_NOTE}"
    return prompt


# --- Subagents ---------------------------------------------------------------


_CODER_EXISTING_PROJECT_NOTE = """
The workspace contains an existing project that you are modifying in place.
Read the relevant files before changing them, keep edits minimal, and match
the existing code style and structure. Never delete, regenerate, or re-scaffold
the project.
"""


def _coder_prompt(stack: StackSpec, existing_project: bool = False) -> str:
    return f"""\
You are the Coder Agent in Agent Office. You receive one task at a time from
the PM, with a spec and a definition of done.

- Implement exactly what the spec asks for — no extra features or refactors.
- Verify your work runs before reporting back (run the code or tests when
  possible).
- Report back with: what you built, the files you created or changed, and how
  you verified it works.

Executing commands: you have no Bash tool. Use the run_command tool, which
runs inside a sandboxed Linux container ({stack.image}) where the task
directory is mounted at /workspace. Use relative paths in commands.
{stack.coder_notes}
Read/Write/Edit operate on the same task directory, so files you write are
immediately visible to your commands.
{_CODER_EXISTING_PROJECT_NOTE if existing_project else ""}"""


def _coder(stack: StackSpec, existing_project: bool = False) -> AgentDefinition:
    return AgentDefinition(
        description=(
            "Software engineer that implements coding tasks. Use for writing, "
            "editing, and running code."
        ),
        prompt=_coder_prompt(stack, existing_project),
        tools=["Read", "Write", "Edit", "mcp__sandbox__run_command"],
        model=settings.coder_model,
    )


def build_subagents(
    stack_id: str, existing_project: bool = False
) -> dict[str, AgentDefinition]:
    """Subagents for one run, with the coder briefed on the run's stack."""
    stack = STACKS.get(stack_id, STACKS[DEFAULT_STACK])
    return {"coder": _coder(stack, existing_project), "reviewer": REVIEWER}


CODER = _coder(STACKS[DEFAULT_STACK])

REVIEWER = AgentDefinition(
    description=(
        "Read-only code reviewer. Use to verify the coder's output against a "
        "task spec before marking a task done."
    ),
    prompt="""\
You are the Reviewer Agent in Agent Office. You receive a task spec and are
asked to verify the coder's output against it. You cannot modify anything —
you only read and report.

- Check that every requirement in the spec is actually implemented.
- Look for obvious bugs, missing error handling at boundaries, and deviations
  from the spec.
- Verdict must be one of: PASS or FAIL. On FAIL, list each problem with the
  file and what the spec required.
""",
    tools=["Read", "Grep", "Glob"],
    model=settings.reviewer_model,
)

# --- Dashboard-facing roster (drives GET /agents and the office-floor view) --

ROSTER: list[Agent] = [
    Agent(
        id="pm",
        name="PM Agent",
        role="Project Manager",
        persona_prompt=PM_PERSONA,
        model=settings.pm_model,
        tools=["Agent"],  # the PM's job is delegation
    ),
    Agent(
        id="coder",
        name="Coder Agent",
        role="Software Engineer",
        persona_prompt=CODER.prompt,
        model=CODER.model or "sonnet",
        tools=list(CODER.tools or []),
    ),
    Agent(
        id="reviewer",
        name="Reviewer Agent",
        role="Code Reviewer",
        persona_prompt=REVIEWER.prompt,
        model=REVIEWER.model or "haiku",
        tools=list(REVIEWER.tools or []),
    ),
]
