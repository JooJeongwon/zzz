import logging
import random
from typing import List, Optional
from langchain_google_genai import ChatGoogleGenerativeAI, GoogleGenerativeAIEmbeddings
from langchain_core.messages import HumanMessage, SystemMessage
from app.core.config import settings

logger = logging.getLogger(__name__)

class LLMService:
    def __init__(self):
        self.api_key = settings.GEMINI_API_KEY
        self.is_active = False
        self.mock_mode = False
        
        self.chat_model = None
        self.embeddings = None
        
        if self.api_key and self.api_key != "changeme":
            try:
                self.chat_model = ChatGoogleGenerativeAI(
                    google_api_key=self.api_key,
                    model=settings.GEMINI_MODEL_NAME,
                    temperature=0.7
                )
                self.embeddings = GoogleGenerativeAIEmbeddings(
                    google_api_key=self.api_key,
                    model=settings.GEMINI_EMBEDDING_MODEL
                )
                self.is_active = True
                logger.info("LLMService initialized successfully with Gemini.")
            except Exception as e:
                logger.error(f"Failed to initialize LLMService: {e}")
                self.mock_mode = True
        else:
            logger.warning("Gemini API Key is missing. Switching to Mock Mode.")
            self.mock_mode = True

    def get_embedding(self, text: str) -> Optional[List[float]]:
        """Generate embedding for a given text."""
        if self.mock_mode:
            # Return dummy embedding vector of size 768 (Gemini embedding-001 size)
            return [0.1] * 768

        if not self.is_active or not self.embeddings:
            logger.warning("Embeddings model not active.")
            return None
        
        try:
            return self.embeddings.embed_query(text)
        except Exception as e:
            logger.error(f"Error generating embedding: {e}")
            return None

    def generate_response(self, system_prompt: str, user_message: str) -> str:
        """Generate a chat response."""
        if self.mock_mode:
            return f"[AI Mock] '{user_message}'에 대해 공감합니다. (API Key 미설정)"

        if not self.is_active or not self.chat_model:
            return "AI 서비스가 현재 비활성화 상태입니다. (API Key 설정 필요)"
            
        messages = [
            SystemMessage(content=system_prompt),
            HumanMessage(content=user_message)
        ]
        
        try:
            response = self.chat_model.invoke(messages)
            return response.content
        except Exception as e:
            logger.error(f"Error generating response: {e}")
            return "죄송합니다. 답변을 생성하는 중 오류가 발생했습니다."

    def generate_recap(self, conversation_history: str, user_name: str = "당신") -> str:
        """
        Generate a recap of the missed conversation.
        """
        if self.mock_mode:
            return "부재중 동안 3개의 메시지가 왔었어요. 주로 안부를 묻는 내용이었습니다. (Mock Recap)"

        if not self.is_active or not self.chat_model:
            return "AI 서비스가 비활성화되어 요약을 생성할 수 없습니다."
            
        prompt = f"""
        당신은 사용자가 자는 동안이나 공부하는 동안 대신 연락을 받아준 AI 에이전트입니다.
        아래는 부재중일 때 오고 간 대화 내용입니다.
        사용자가 돌아왔을 때 상황을 파악할 수 있도록, 어떤 이야기들이 있었는지 친근한 말투로 3줄 이내로 요약해주세요.
        상대방이 특별히 감정을 표현했거나 중요한 용건이 있었다면 꼭 언급해주세요.
        
        대화 내용:
        {conversation_history}
        
        요약 리포트:
        """
        
        messages = [
            SystemMessage(content="당신은 부재중 대화 요약 비서입니다. 친절하고 명확하게 한국어로 요약합니다."),
            HumanMessage(content=prompt)
        ]
        
        try:
            response = self.chat_model.invoke(messages)
            return response.content
        except Exception as e:
            logger.error(f"Error generating recap: {e}")
            return "대화 내용을 요약하는 중 오류가 발생했습니다."


# Singleton
llm_service = LLMService()
