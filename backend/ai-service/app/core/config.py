from typing import List
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    PROJECT_NAME: str = "ZZZ AI Service"
    API_V1_STR: str = "/api/v1"
    
    # OpenAI
    OPENAI_API_KEY: str = "changeme"

    # Gemini
    GEMINI_API_KEY: str = "changeme"
    GEMINI_MODEL_NAME: str = "gemini-pro"
    GEMINI_EMBEDDING_MODEL: str = "models/embedding-001"
    
    # Vector DB (Pinecone)
    PINECONE_API_KEY: str = "changeme"
    PINECONE_ENV: str = "gcp-starter"

    # RabbitMQ
    RABBITMQ_URL: str = "amqp://guest:guest@localhost:5672/"
    
    class Config:
        case_sensitive = True
        env_file = ".env"

settings = Settings()
