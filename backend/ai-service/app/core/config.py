import os
from pathlib import Path
from typing import List, Optional
from pydantic_settings import BaseSettings, SettingsConfigDict

# Build paths inside the project like this: BASE_DIR / 'subdir'.
# Current file: backend/ai-service/app/core/config.py
# . -> core
# .. -> app
# ... -> ai-service
# .... -> backend
# ..... -> zzz (Root)
BASE_DIR = Path(__file__).resolve().parent.parent.parent.parent.parent

class Settings(BaseSettings):
    PROJECT_NAME: str = "ZZZ AI Service"
    API_V1_STR: str = "/api/v1"
    
    # OpenAI
    OPENAI_API_KEY: Optional[str] = None

    # Gemini
    GEMINI_API_KEY: str
    GEMINI_MODEL_NAME: str = "gemini-1.5-flash"
    GEMINI_EMBEDDING_MODEL: str = "models/embedding-001"
    
    # Vector DB (Pinecone)
    PINECONE_API_KEY: Optional[str] = None
    PINECONE_ENV: str = "gcp-starter"

    # RabbitMQ
    RABBITMQ_URL: str = "amqp://guest:guest@localhost:5672/"
    
    model_config = SettingsConfigDict(
        case_sensitive=True,
        env_file=str(BASE_DIR / ".env"),
        extra="ignore"
    )

settings = Settings()
