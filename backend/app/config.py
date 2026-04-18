from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    valhalla_url: str = "http://valhalla:8002"
    log_level: str = "info"
    assets_dir: str = "/app/assets"
    allowed_origins: str = "http://localhost:8001"
    database_url: str = (
        "postgresql+asyncpg://bike:bike@postgis:5432/bike_routing"
    )
    # Seconds to cache avoid-polygons in memory before re-reading from DB.
    avoid_polygons_cache_ttl: int = 60

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")

    @property
    def cors_origins(self) -> list[str]:
        return [o.strip() for o in self.allowed_origins.split(",") if o.strip()]


settings = Settings()
