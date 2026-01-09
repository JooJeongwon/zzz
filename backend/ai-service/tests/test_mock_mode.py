from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_health_check():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok", "service": "ai-service"}

def test_chat_generation_mock_mode():
    payload = {
        "user_id": "user1",
        "partner_id": "partner1",
        "partner_name": "MyLove",
        "message": "보고싶어"
    }
    response = client.post("/api/v1/chat/generate", json=payload)
    assert response.status_code == 200
    data = response.json()
    # Mock response logic: f"[AI Mock] '{user_message}'에 대해 공감합니다. (API Key 미설정)"
    assert "[AI Mock]" in data["response"]
    assert "보고싶어" in data["response"]

def test_recap_mock_mode():
    payload = {
        "user_id": "user1",
        "partner_id": "partner1",
        "partner_name": "MyLove",
        "message": "User: 안녕\nPartner: 잘자"
    }
    response = client.post("/api/v1/chat/recap", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert "(Mock Recap)" in data["response"]
