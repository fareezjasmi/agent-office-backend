"""Provider and model configuration, loaded from environment / backend/.env.

The agents run on Claude Code under the hood, which talks to the Anthropic
API natively. Provider flexibility comes from where you point it:

- nothing set          -> your Claude Code login (subscription billing)
- ANTHROPIC_API_KEY    -> Anthropic Console key
- ANTHROPIC_BASE_URL   -> any Anthropic-compatible gateway (e.g. a LiteLLM
  (+ AUTH_TOKEN)          proxy routing to OpenAI/Gemini/local models)
- CLAUDE_CODE_USE_BEDROCK / CLAUDE_CODE_USE_VERTEX -> Claude on AWS/GCP,
  using your cloud credentials

Model IDs are passed through as-is, so with a gateway you can use its model
names (e.g. "gpt-5.2", "gemini/gemini-3-pro") per agent.
"""

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    # Credentials / endpoint (all optional — default is your Claude login)
    anthropic_api_key: str | None = None
    anthropic_auth_token: str | None = None
    anthropic_base_url: str | None = None
    claude_code_use_bedrock: bool = False
    claude_code_use_vertex: bool = False

    # Per-agent models: alias ("sonnet", "haiku", "opus") or a full model ID
    pm_model: str = "sonnet"
    coder_model: str = "sonnet"
    reviewer_model: str = "haiku"


settings = Settings()


def sdk_env() -> dict[str, str]:
    """Env vars forwarded to the Claude Code process the SDK spawns.

    Only set keys are forwarded, so an empty .env keeps login-based auth.
    """
    env: dict[str, str] = {}
    if settings.anthropic_api_key:
        env["ANTHROPIC_API_KEY"] = settings.anthropic_api_key
    if settings.anthropic_auth_token:
        env["ANTHROPIC_AUTH_TOKEN"] = settings.anthropic_auth_token
    if settings.anthropic_base_url:
        env["ANTHROPIC_BASE_URL"] = settings.anthropic_base_url
    if settings.claude_code_use_bedrock:
        env["CLAUDE_CODE_USE_BEDROCK"] = "1"
    if settings.claude_code_use_vertex:
        env["CLAUDE_CODE_USE_VERTEX"] = "1"
    return env
