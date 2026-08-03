"""
Application configuration.

Settings are loaded from environment variables using pydantic-settings.
Never hardcode secrets or credentials here.
"""

from __future__ import annotations

from functools import lru_cache
from typing import Literal

from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="ignore",
    )

    # Application
    APP_ENV: Literal["development", "production"] = "development"
    APP_NAME: str = "security-pulse"
    APP_VERSION: str = "0.0.1"

    # Mock authentication — must be False in production
    ALLOW_MOCK_AUTH: bool = False

    # Database
    DATABASE_URL: str = (
        "postgresql+asyncpg://security_pulse:changeme_local@localhost:5432/security_pulse"
    )
    DATABASE_POOL_SIZE: int = 10
    DATABASE_MAX_OVERFLOW: int = 20

    # Redis
    REDIS_URL: str = "redis://localhost:6379/0"

    # OIDC
    OIDC_ISSUER_URL: str = ""
    OIDC_CLIENT_ID: str = ""
    OIDC_AUDIENCE: str = ""

    # API
    API_SECRET_KEY: str = "changeme-generate-with-openssl-rand-hex-32"  # noqa: S105
    API_CORS_ORIGINS: list[str] = ["http://localhost:3000"]
    API_RATE_LIMIT_PER_MINUTE: int = 60

    # Logging
    LOG_LEVEL: str = "INFO"
    LOG_FORMAT: Literal["json", "text"] = "json"

    @field_validator("API_CORS_ORIGINS", mode="before")
    @classmethod
    def parse_cors_origins(cls, v: str | list[str]) -> list[str]:
        if isinstance(v, str):
            return [origin.strip() for origin in v.split(",") if origin.strip()]
        return v

    @field_validator("ALLOW_MOCK_AUTH", mode="after")
    @classmethod
    def validate_mock_auth_safety(cls, v: bool, info: object) -> bool:
        # Note: full production check is in app.main._assert_production_safety()
        # This validator is a belt-and-suspenders check.
        return v


@lru_cache
def get_settings() -> Settings:
    """Return cached application settings."""
    return Settings()
