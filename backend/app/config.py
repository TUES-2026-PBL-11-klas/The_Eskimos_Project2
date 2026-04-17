from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    valhalla_url: str = "http://valhalla:8002"
    log_level: str = "info"
    assets_dir: str = "/app/assets"

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")


settings = Settings()
