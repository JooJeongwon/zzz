from typing import List
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    PROJECT_NAME: str = "ZZZ AI Service"
    API_V1_STR: str = "/api/v1"
    
    # OpenAI
    OPENAI_API_KEY: str = "changeme"
    
    # Vector DB (Pinecone)
    PINECONE_API_KEY: str = "changeme"
    PINECONE_ENV: str = "gcp-starter"
    
    class Config:
        case_sensitive = True
        env_file = ".env"

settings = Settings()
