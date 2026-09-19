"""Application configuration settings for Kognit Backend."""

from functools import lru_cache
from typing import List
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings loaded from environment variables and .env file."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore"
    )

    # Server settings
    environment: str = "development"
    debug: bool = True
    api_prefix: str = "/api"
    port: int = 8000
    host: str = "0.0.0.0"

    # Google Gemini Settings
    gemini_api_key: str = ""
    gemini_model: str = "gemini-1.5-flash"

    # Supabase Settings
    supabase_url: str = ""
    supabase_key: str = ""
    supabase_service_role_key: str = ""

    # CORS
    allowed_origins: str = "*"

    @property
    def cors_origins(self) -> List[str]:
        """Return list of allowed CORS origins."""
        if self.allowed_origins == "*":
            return ["*"]
        return [origin.strip() for origin in self.allowed_origins.split(",") if origin.strip()]


@lru_cache()
def get_settings() -> Settings:
    """Cached settings singleton."""
    return Settings()
