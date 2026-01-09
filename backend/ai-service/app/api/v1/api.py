from fastapi import APIRouter
from app.api.v1.endpoints import chat, vector_test

api_router = APIRouter()
api_router.include_router(chat.router, prefix="/chat", tags=["chat"])
api_router.include_router(vector_test.router, prefix="/vector", tags=["vector-db"])
