from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List, Dict, Any
from app.services.vector_store import vector_store
import random

router = APIRouter()

class VectorTestRequest(BaseModel):
    id: str
    text: str
    namespace: str = "test-namespace"

@router.post("/test-upsert")
async def test_upsert(request: VectorTestRequest):
    """
    Test endpoint to insert a dummy vector.
    Generates a random vector of dimension 1536.
    """
    if not vector_store.index:
         raise HTTPException(status_code=503, detail="Vector DB not initialized. Check API Key.")

    # Generate dummy vector
    dummy_values = [random.random() for _ in range(1536)]
    
    vector_data = [{
        "id": request.id,
        "values": dummy_values,
        "metadata": {"text": request.text}
    }]
    
    success = vector_store.upsert_vectors(vector_data, namespace=request.namespace)
    
    if success:
        return {"status": "success", "message": f"Vector {request.id} upserted."}
    else:
        raise HTTPException(status_code=500, detail="Failed to upsert vector.")

@router.get("/test-query/{query_id}")
async def test_query(query_id: str, namespace: str = "test-namespace"):
    """
    Test endpoint to query with a random vector.
    """
    if not vector_store.index:
         raise HTTPException(status_code=503, detail="Vector DB not initialized. Check API Key.")

    dummy_vector = [random.random() for _ in range(1536)]
    
    matches = vector_store.query_similar(dummy_vector, top_k=3, namespace=namespace)
    
    return {"status": "success", "matches": matches}
