from abc import ABC, abstractmethod
from typing import List, Optional
import logging
import time
from langchain_google_genai import ChatGoogleGenerativeAI, GoogleGenerativeAIEmbeddings
from langchain_core.messages import HumanMessage, SystemMessage
from app.core.config import settings

logger = logging.getLogger(__name__)

class LLMProvider(ABC):
    @abstractmethod
    def get_embedding(self, text: str) -> Optional[List[float]]:
        pass

    @abstractmethod
    def generate_response(self, system_prompt: str, user_message: str) -> str:
        pass

    @abstractmethod
    def generate_recap(self, conversation_history: str, user_name: str = "당신") -> str:
        pass

    @abstractmethod
    def generate_dream_log(self, conversation_history: str, couple_names: str = "두 사람") -> str:
        pass

class MockLLMProvider(LLMProvider):
    def get_embedding(self, text: str) -> Optional[List[float]]:
        # Return dummy embedding vector of size 768 (Gemini embedding-001 size)
        return [0.1] * 768

    def generate_response(self, system_prompt: str, user_message: str) -> str:
        return f"[AI Mock] '{user_message}'에 대해 공감합니다. (API Key 미설정)"

    def generate_recap(self, conversation_history: str, user_name: str = "당신") -> str:
        return "부재중 동안 3개의 메시지가 왔었어요. 주로 안부를 묻는 내용이었습니다. (Mock Recap)"

    def generate_dream_log(self, conversation_history: str, couple_names: str = "두 사람") -> str:
        return "[꿈의 기록] 달빛 아래 떡볶이 숲\n\n두 마리의 곰돌이가 맛있는 떡볶이 숲을 지나 행복하게 잠이 들었답니다. (Mock Dream Log)"

class GeminiLLMProvider(LLMProvider):
    def __init__(self, api_key: str):
        self.api_key = api_key
        self._chat_model = None
        self._embeddings = None
        logger.info("GeminiLLMProvider initialized (Lazy Loading).")

    @property
    def chat_model(self):
        if self._chat_model is None:
            try:
                self._chat_model = ChatGoogleGenerativeAI(
                    google_api_key=self.api_key,
                    model=settings.GEMINI_MODEL_NAME,
                    temperature=0.7
                )
                logger.info("Gemini Chat Model initialized.")
            except Exception as e:
                logger.error(f"Failed to initialize Gemini Chat Model: {e}")
                raise e
        return self._chat_model

    @property
    def embeddings(self):
        if self._embeddings is None:
            try:
                self._embeddings = GoogleGenerativeAIEmbeddings(
                    google_api_key=self.api_key,
                    model=settings.GEMINI_EMBEDDING_MODEL
                )
                logger.info("Gemini Embeddings initialized.")
            except Exception as e:
                logger.error(f"Failed to initialize Gemini Embeddings: {e}")
                raise e
        return self._embeddings

    def get_embedding(self, text: str) -> Optional[List[float]]:
        retries = 3
        for i in range(retries):
            try:
                return self.embeddings.embed_query(text)
            except Exception as e:
                error_msg = str(e)
                if i == retries - 1:
                    logger.error(f"Error generating embedding after {retries} attempts: {e}")
                    return None
                
                # Retry on Resource Exhausted, Rate Limit, Server Errors, or Timeouts
                retry_triggers = [
                    "RESOURCE_EXHAUSTED", "429", 
                    "500", "503", "504", 
                    "deadline_exceeded", "timeout", 
                    "InternalServerError", "ServiceUnavailable"
                ]
                
                if any(trigger in error_msg for trigger in retry_triggers):
                    sleep_time = 2 ** i
                    logger.warning(f"Embedding failed ({error_msg}). Retrying in {sleep_time}s...")
                    time.sleep(sleep_time)
                else:
                    logger.error(f"Non-retryable error generating embedding: {e}")
                    return None
        return None

    def generate_response(self, system_prompt: str, user_message: str) -> str:
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

    def generate_dream_log(self, conversation_history: str, couple_names: str = "두 사람") -> str:
        prompt = f"""
        두 연인({couple_names})이 어제 나눈 대화를 바탕으로, 짧고 몽환적인 동화(Dream Log)를 만들어주세요.
        대화 속에 등장한 핵심 키워드(음식, 장소, 감정 등)를 은유적으로 포함시켜주세요.
        
        [대화 내용]
        {conversation_history}
        
        [조건]
        - 주인공들은 귀여운 동물이나 꼬마 요정으로 묘사하세요.
        - 분위기는 따뜻하고 신비롭게 작성하세요.
        - 분량은 300자 내외로 작성하세요.
        - 제목을 맨 윗줄에 대괄호로 묶어서 달아주세요 (예: [달빛 아래 떡볶이 숲]).
        """
        
        messages = [
            SystemMessage(content="당신은 꿈의 동화 작가입니다. 연인들의 대화를 바탕으로 아름다운 이야기를 만듭니다."),
            HumanMessage(content=prompt)
        ]
        
        try:
            response = self.chat_model.invoke(messages)
            return response.content
        except Exception as e:
            logger.error(f"Error generating dream log: {e}")
            return "[꿈의 기록] 생성 실패\n\n죄송합니다. 꿈의 기록을 불러오는 데 실패했어요."
