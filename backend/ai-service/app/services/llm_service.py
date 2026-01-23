import logging
from typing import List, Optional
from app.core.config import settings
from app.services.llm_providers import LLMProvider, MockLLMProvider, GeminiLLMProvider

logger = logging.getLogger(__name__)

class LLMService:
    def __init__(self):
        self.api_key = settings.GEMINI_API_KEY
        self.provider: LLMProvider = None
        
        if self.api_key and self.api_key != "changeme":
            try:
                self.provider = GeminiLLMProvider(self.api_key)
            except Exception:
                logger.warning("Failed to initialize GeminiLLMProvider. Fallback to Mock.")
                self.provider = MockLLMProvider()
        else:
            logger.warning("Gemini API Key is missing. Switching to Mock Mode.")
            self.provider = MockLLMProvider()

    def get_embedding(self, text: str) -> Optional[List[float]]:
        """Generate embedding for a given text."""
        return self.provider.get_embedding(text)

    def generate_response(self, system_prompt: str, user_message: str) -> str:
        """Generate a chat response."""
        return self.provider.generate_response(system_prompt, user_message)

    def generate_recap(self, conversation_history: str, user_name: str = "당신") -> str:
        """
        Generate a recap of the missed conversation.
        """
        return self.provider.generate_recap(conversation_history, user_name)

    def generate_dream_log(self, conversation_history: str, couple_names: str = "두 사람") -> str:
        """
        Generate a dream log story based on conversation history.
        """
        return self.provider.generate_dream_log(conversation_history, couple_names)


_instance: Optional[LLMService] = None

def get_llm_service() -> LLMService:
    global _instance
    if _instance is None:
        _instance = LLMService()
    return _instance
