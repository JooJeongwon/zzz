import logging
from typing import List, Optional
from pinecone import Pinecone, ServerlessSpec
from app.core.config import settings

logger = logging.getLogger(__name__)

class VectorStoreService:
    def __init__(self):
        self.api_key = settings.PINECONE_API_KEY
        self.index_name = "zzz-persona-index"
        self.dimension = 768 # Gemini embedding-001 standard
        self.pc = None
        self.index = None
        
        if self.api_key and self.api_key != "changeme":
            try:
                self.pc = Pinecone(api_key=self.api_key)
                self._initialize_index()
            except Exception as e:
                logger.error(f"Failed to initialize Pinecone: {e}")

    def _initialize_index(self):
        """Check if index exists, create if not (Serverless spec)."""
        if not self.pc:
            return

        existing_indexes = [i.name for i in self.pc.list_indexes()]
        
        if self.index_name not in existing_indexes:
            logger.info(f"Creating Pinecone index: {self.index_name}")
            try:
                self.pc.create_index(
                    name=self.index_name,
                    dimension=self.dimension,
                    metric="cosine",
                    spec=ServerlessSpec(
                        cloud="aws",
                        region="us-east-1"
                    )
                )
            except Exception as e:
                logger.error(f"Error creating index: {e}")
                return

        self.index = self.pc.Index(self.index_name)
        logger.info(f"Connected to Pinecone index: {self.index_name}")

    def upsert_vectors(self, vectors: List[dict], namespace: str = "default"):
        """
        Upsert vectors to Pinecone.
        vectors format: [{'id': 'vec1', 'values': [0.1, ...], 'metadata': {'text': '...'}}]
        """
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
