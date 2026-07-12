# Agent Office — backend

FastAPI orchestration layer over the Claude Agent SDK. The PM agent runs as
the SDK main thread; the Coder and Reviewer run as subagents it dispatches to
(see `app/agents/roster.py`).

## Setup

```sh
uv sync
uv run uvicorn app.main:app --reload
```

Auth comes from your Claude Code login by default. To use an Anthropic API
key, another provider through an Anthropic-compatible gateway (e.g. LiteLLM),
or Bedrock/Vertex — and to change each agent's model — copy `.env.example`
to `.env` and follow the comments. Restart the server after editing it.

## API (milestone 1)

```sh
# Roster with live status chips
curl localhost:8000/agents

# Submit a goal — returns 202 with a run id; the PM works in the background.
# "stack" picks the coder's sandbox: "node" (default) or "flutter".
curl -X POST localhost:8000/goals \
  -H 'content-type: application/json' \
  -d '{"goal": "Create fizzbuzz.js that prints FizzBuzz for 1 to 20, with a test.", "stack": "node"}'

curl -X POST localhost:8000/goals \
  -H 'content-type: application/json' \
  -d '{"goal": "Create a Flutter counter app with a widget test.", "stack": "flutter"}'

# Poll the run: status, task board state, event log, final PM summary
curl localhost:8000/goals/<run_id>

# All runs
curl localhost:8000/goals

# Simulate a run through the event bus (no agents, no cost) — for UI dev
curl -X POST localhost:8000/debug/simulate
```

## WebSocket stream (milestone 3)

Connect to `ws://localhost:8000/ws`. First message is a `snapshot` (roster
with live statuses + all runs), then a stream of events:

- `agent_status` — `{agent_id, status}` whenever a chip changes
- `task_update` — `{run_id, task}` whenever a task moves on the board
- `run_update` — `{run_id, status, result}` on run start/finish
- `activity` — `{run_id, event: {ts, agent, type, detail}}` log lines
  (dispatches, tool use, subagent results) for the per-agent thread view

Each run gets its own working directory under `backend/workspace/<run_id>` —
that's where the Coder's files land. State is in-memory only (POC).

## Milestones

1. ✅ FastAPI scaffold + 3-agent roster + goal dispatch
2. ✅ Docker-per-task execution (coder has no Bash — only `run_command`,
   which execs in a per-task container chosen by the run's stack:
   `node:20-slim` or a Flutter SDK image — see `app/agents/sandbox.py`)
3. ✅ WebSocket status stream
4. ✅ Next.js dashboard: agent grid (`../frontend`)
5. ✅ Next.js dashboard: task board + per-agent threads + goal form
