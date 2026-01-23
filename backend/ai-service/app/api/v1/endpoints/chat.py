from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from app.services.rag_service import RAGService, get_rag_service
from app.services.llm_service import LLMService, get_llm_service

router = APIRouter()

class ChatRequest(BaseModel):
    user_id: str
    partner_id: str
    partner_name: str
    message: str

class ChatResponse(BaseModel):
    response: str

@router.post("/generate", response_model=ChatResponse)
async def generate_chat_response(
    request: ChatRequest,
    rag_service: RAGService = Depends(get_rag_service)
):
    """
    Generate a response from the AI Persona.
    """
    if not request.message.strip():
        raise HTTPException(status_code=400, detail="Message cannot be empty")

    # Use partner_id as the namespace to search for the partner's persona data
    # In a real scenario, authentication middleware would verify user identity
    response_text = rag_service.get_persona_response(
        target_persona_id=request.partner_id, # Search in partner's vector space
        message=request.message,
        partner_name=request.partner_name
    )
    
    return ChatResponse(response=response_text)

@router.post("/recap", response_model=ChatResponse)
async def generate_recap(
    request: ChatRequest,
    llm_service: LLMService = Depends(get_llm_service)
):
    """
    Generate a recap summary of the conversation that happened while user was away.
    'message' field in request contains the formatted conversation history.
    """
    if not request.message.strip():
         return ChatResponse(response="나눈 대화가 없어서 요약할 내용이 없어요.")

    response_text = llm_service.generate_recap(
        conversation_history=request.message,
        user_name="User" # This could be passed in request if needed
    )
    
    return ChatResponse(response=response_text)
