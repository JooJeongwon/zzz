import logging
import math
from typing import List, Dict, Optional, Any
from app.core.config import settings

logger = logging.getLogger(__name__)

class InMemoryVectorStore:
    def __init__(self, dimension: int):
        self.dimension = dimension
        # Structure: {namespace: {id: {'values': [float], 'metadata': dict}}}
        self.store: Dict[str, Dict[str, Any]] = {}

    def upsert(self, vectors: List[dict], namespace: str = "default"):
        if namespace not in self.store:
            self.store[namespace] = {}
        
        for vec in vectors:
            vec_id = vec.get('id')
            if vec_id:
                self.store[namespace][vec_id] = vec
        logger.info(f"Upserted {len(vectors)} vectors to in-memory store (namespace: {namespace})")
        return True

    def query(self, vector: List[float], top_k: int = 3, namespace: str = "default"):
        if namespace not in self.store:
            return {'matches': []}

        candidates = self.store[namespace].values()
        results = []

        for candidate in candidates:
            score = self._cosine_similarity(vector, candidate['values'])
            results.append({
                'id': candidate['id'],
                'score': score,
                'metadata': candidate.get('metadata', {})
            })

        # Sort by score descending
        results.sort(key=lambda x: x['score'], reverse=True)
        return {'matches': results[:top_k]}

    def _cosine_similarity(self, v1: List[float], v2: List[float]) -> float:
        if len(v1) != len(v2):
            return 0.0
        
        dot_product = sum(a * b for a, b in zip(v1, v2))
        magnitude1 = math.sqrt(sum(a * a for a in v1))
        magnitude2 = math.sqrt(sum(b * b for b in v2))
        
        if magnitude1 == 0 or magnitude2 == 0:
            return 0.0
            
        return dot_product / (magnitude1 * magnitude2)

class VectorStoreService:
    def __init__(self):
        self.api_key = settings.PINECONE_API_KEY
        self.index_name = "zzz-persona-index"
        self.dimension = 768 # Gemini gemini-embedding-001 standard
        self.pc = None
        self.index = None
        self.use_memory_store = False
        self.memory_store = None

        if self.api_key and self.api_key != "changeme":
            try:
                from pinecone import Pinecone, ServerlessSpec
                self.pc = Pinecone(api_key=self.api_key)
                self._initialize_pinecone_index(ServerlessSpec)
            except Exception as e:
                logger.error(f"Failed to initialize Pinecone: {e}")
                self.use_memory_store = True
        else:
            logger.warning("Pinecone API Key missing. Using In-Memory Vector Store.")
            self.use_memory_store = True

        if self.use_memory_store:
            self.memory_store = InMemoryVectorStore(self.dimension)

    def _initialize_pinecone_index(self, ServerlessSpec):
        """Check if index exists, create if not (Serverless spec)."""
        if not self.pc:
            return

        try:
            existing_indexes = [i.name for i in self.pc.list_indexes()]
            
            if self.index_name not in existing_indexes:
                logger.info(f"Creating Pinecone index: {self.index_name}")
                self.pc.create_index(
                    name=self.index_name,
                    dimension=self.dimension,
                    metric="cosine",
                    spec=ServerlessSpec(
                        cloud="aws",
                        region="us-east-1"
                    )
                )

            self.index = self.pc.Index(self.index_name)
            logger.info(f"Connected to Pinecone index: {self.index_name}")
        except Exception as e:
            logger.error(f"Error initializing Pinecone index: {e}. Switching to memory store.")
            self.use_memory_store = True
            self.memory_store = InMemoryVectorStore(self.dimension)

    def upsert_vectors(self, vectors: List[dict], namespace: str = "default"):
        """
        Upsert vectors to Pinecone or Memory.
        vectors format: [{'id': 'vec1', 'values': [0.1, ...], 'metadata': {'text': '...'}}]
        """
        if self.use_memory_store:
            return self.memory_store.upsert(vectors, namespace)
            
        if not self.index:
            logger.warning("Pinecone index not initialized. Skipping upsert.")
            return False
            
        try:
            self.index.upsert(vectors=vectors, namespace=namespace)
            return True
        except Exception as e:
            logger.error(f"Error upserting vectors: {e}")
            return False

    def query_similar(self, vector: List[float], top_k: int = 3, namespace: str = "default"):
        """Query similar vectors."""
        if self.use_memory_store:
            return self.memory_store.query(vector, top_k, namespace)['matches']

        if not self.index:
            logger.warning("Pinecone index not initialized. Skipping query.")
            return []
            
        try:
            response = self.index.query(
                vector=vector,
                top_k=top_k,
                include_metadata=True,
                namespace=namespace
            )
            return response['matches']
        except Exception as e:
            logger.error(f"Error querying vectors: {e}")
            return []

# Singleton instance
vector_store = VectorStoreService()