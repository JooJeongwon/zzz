import logging
from app.services.vector_store import vector_store
from app.services.llm_service import llm_service

logger = logging.getLogger(__name__)

class RAGService:
    def __init__(self):
        pass

    def get_persona_response(self, target_persona_id: str, message: str, partner_name: "연인") -> str:
        """
        RAG Pipeline:
        1. Embed user query.
        2. Retrieve similar past conversations (Persona context) of the target.
        3. Generate response using LLM with context.
        """
        
        # 1. Embedding
        query_vector = llm_service.get_embedding(message)
        if not query_vector:
            return "AI 서비스를 사용할 수 없습니다. (Embedding 실패)"

        # 2. Retrieval (Vector Search)
        # namespace를 target_persona_id로 구분하여 해당 사용자의(혹은 파트너의) 말투 데이터만 검색
        search_results = vector_store.query_similar(
            vector=query_vector,
            top_k=3,
            namespace=target_persona_id
        )
        
        context_texts = []
        if search_results:
            for match in search_results:
                if 'metadata' in match and 'text' in match['metadata']:
                    context_texts.append(match['metadata']['text'])
        
        context_str = "\n".join(context_texts)
        
        # 3. Prompt Engineering
        system_prompt = f"""
        당신은 '{partner_name}'의 AI 페르소나입니다. 
        아래 제공되는 '과거 대화 스타일'을 참고하여, 사용자의 말에 연인처럼 다정하게 답변하세요.
        
        [과거 대화 스타일]
        {context_str}
        
        [지시사항]
        - 말투, 어조, 이모티콘 사용 패턴을 위 데이터를 통해 모방하세요.
        - 사용자의 현재 상황을 고려하여 공감해주세요.
        - 너무 길게 말하지 마세요 (3문장 이내).
        """
        
        # 4. Generation
        logger.info(f"Generating response for target {target_persona_id} with RAG context.")
        response = llm_service.generate_response(system_prompt, message)
        
        return response

rag_service = RAGService()
