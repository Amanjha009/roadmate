"""RoadMate India — app-level settings driven by .env / environment variables."""

from __future__ import annotations

from typing import List

from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Central configuration object.  Every value can be overridden by an
    environment variable of the same (upper-cased) name or via a `.env` file
    located at the project root."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    # ── Database ──────────────────────────────────────────────────────────
    database_url: str = "postgresql+asyncpg://postgres:postgres@localhost:5432/roadmate_india"
    redis_url: str = "redis://localhost:6379/0"

    # ── JWT ───────────────────────────────────────────────────────────────
    jwt_secret_key: str = "change-me"
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 30
    refresh_token_expire_days: int = 30

    # ── CORS ──────────────────────────────────────────────────────────────
    cors_origins: List[str] = ["http://localhost:3000", "http://localhost:8080"]

    @field_validator("cors_origins", mode="before")
    @classmethod
    def _parse_cors(cls, v: object) -> object:  # noqa: N805
        if isinstance(v, str):
            import json

            return json.loads(v)
        return v

    # ── S3-compatible storage ─────────────────────────────────────────────
    s3_endpoint_url: str = "https://s3.amazonaws.com"
    s3_access_key_id: str = ""
    s3_secret_access_key: str = ""
    s3_bucket_name: str = "roadmate-india"
    s3_region: str = "ap-south-1"

    # ── LLM / OpenAI-compatible API ───────────────────────────────────────
    llm_api_base_url: str = "https://api.openai.com/v1"
    llm_api_key: str = ""
    llm_model: str = "gpt-4o"

    # ── OTP ───────────────────────────────────────────────────────────────
    otp_length: int = 6
    otp_expiry_minutes: int = 5


settings = Settings()
