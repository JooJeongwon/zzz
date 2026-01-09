# ZZZ Project Architecture Design Document (v2.0)

## 1. 시스템 아키텍처 개요 (System Architecture Overview)

본 프로젝트는 서비스의 확장성, 플랫폼 유연성(Android/iOS), 그리고 각 도메인(Core, AI, Noti)의 독립성을 보장하기 위해 **Event-Driven MSA (Microservices Architecture)** 패턴을 채택합니다.

### High-Level Architecture
```mermaid
graph TD
    UserClient_A[Android Client] --> |REST/Socket| APIGateway[API Gateway]
    UserClient_I[iOS Client] --> |REST/Socket| APIGateway
    
    subgraph "Backend Infrastructure (Private Subnet)"
        APIGateway --> CoreServer[Core Service (Spring Boot)]
        APIGateway --> AIServer[AI Service (Python FastAPI)]
        
        CoreServer --> |Publish Events| MessageQueue[Kafka / RabbitMQ]
        
        MessageQueue --> |Subscribe| AIServer
        MessageQueue --> |Subscribe| NotiServer[Notification Service]
        MessageQueue --> |Subscribe| Analytics[Data Analytics]
        
        CoreServer --> Redis[(Redis - Cache/Session)]
        CoreServer --> RDB[(MySQL - User/Couple)]
        AIServer --> MongoDB[(MongoDB - Chat Logs)]
        AIServer --> VectorDB[(Pinecone - Embeddings)]
    end
    
    NotiServer --> FCM[Firebase Cloud Messaging]
    NotiServer --> APNs[Apple Push Notification]
```

---

## 2. 기술 스택 상세 (Tech Stack Details)

| Layer | Component | Technology | Description |
|---|---|---|---|
| **Client (Mobile)** | **Android** | **Kotlin / Jetpack Compose** | Foreground Service, WorkManager |
| | **iOS** | **Swift / SwiftUI** | ActivityKit (Live Activities), Background Tasks, APNs |
| **Gateway** | **API Gateway** | **Spring Cloud Gateway** or **Nginx** | 라우팅, SSL 인증, Rate Limiting, JWT 검증 |
| **Backend (Core)** | **Core Service** | **Spring Boot (Java/Kotlin)** | 비즈니스 로직, 상태 관리, 웹소켓 서버 |
| **Backend (AI)** | **AI Service** | **Python (FastAPI + LangChain)** | RAG 파이프라인, LLM Serving (OpenAI/Llama3) |
| **Backend (Event)** | **Message Broker** | **Kafka** or **RabbitMQ** | 서비스 간 결합도 감소, 비동기 이벤트 처리 |
| **Databases** | **RDB** | **MySQL (v8.0)** | 사용자, 커플, 결제 정보 (ACID) |
| | **NoSQL** | **MongoDB** | 대화 로그, 알림 히스토리 |
| | **Cache** | **Redis** | 실시간 상태, 세션, Pub/Sub |
| | **Vector DB** | **Pinecone** / **Milvus** | 임베딩 벡터 저장소 (말투 학습용) |
| **Ops** | **Observability** | **Prometheus + Grafana** | 서버 상태 및 비즈니스 매트릭 모니터링 |

---

## 3. 플랫폼별 클라이언트 전략 (Client Strategy)

Android와 iOS의 백그라운드 정책 차이를 극복하기 위한 이원화 전략을 사용합니다.

### A. Android (적극적 감지)
*   **Foreground Service:** 알림바에 상주하며 OS에 의해 프로세스가 죽는 것을 방지.
*   **Heartbeat:** 10분마다 HTTP 요청으로 상태 전송.
*   **Sensor:** 화면 On/Off(`Intent.ACTION_SCREEN_OFF`), 배터리 변화 리스너 등록.

### B. iOS (하이브리드 감지)
iOS는 앱이 백그라운드로 가면 네트워크 사용이 엄격히 제한됩니다.
*   **Live Activities (Dynamic Island):** 잠금 화면에 캐릭터와 상태를 실시간으로 표시 (푸시로 업데이트).
*   **Background Fetch:** OS가 허용하는 시점에 간헐적으로 상태 전송 (불규칙적).
*   **Silent Push (Server-Triggered):** 서버가 주기적으로 소리 없는 푸시를 보내 앱을 깨우고(Wake-up), 배터리 상태 등을 보고하게 만듦.
*   **Passive Logic:** Heartbeat 의존도를 낮추고, **"마지막 앱 실행/포그라운드 진입 시간"**을 기준으로 상태를 추정하는 서버 로직 강화.

---

## 4. 핵심 컴포넌트 설계 (Core Components)

### A. Status FSM (Finite State Machine)
서버 내 유저 상태 전이 로직.
*   **States:** `ONLINE`, `OFFLINE` (단순 미접속), `SLEEP` (수면 추정), `FOCUS` (방해금지/공부), `DISCHARGED` (방전)
*   **Transitions:**
    *   `Any` -> `ONLINE`: 소켓 연결 or API 호출 시.
    *   `ONLINE` -> `SLEEP`: (Heartbeat 끊김 > 30분) AND (현재 시간 22:00 ~ 08:00).
    *   `ONLINE` -> `DISCHARGED`: 마지막 배터리 보고 < 2% AND Heartbeat 끊김.

### B. AI Persona Pipeline (RAG)
1.  **Ingestion:** 채팅 로그 -> 전처리(익명화) -> Embedding(OpenAI/KoBERT) -> Vector DB 저장.
2.  **Retrieval:** 질문 수신 -> 유사도 검색(Top-k) -> 과거 발화 3~5개 추출.
3.  **Generation:**
    *   Prompt: `"당신은 {User}의 연인입니다. 아래 과거 대화 스타일을 참고하여 답변하세요."` + `Context`
    *   Guardrail: 민감한 주제(이별, 싸움) 감지 시 AI 답변 거부 및 "직접 답장 필요" 알림 생성.

---

## 5. 데이터 흐름 (Event-Driven Flow)

### Scenario: 사용자 수면 감지 및 AI 활성화

1.  **Detect (Core):** Redis Key Expired Event 발생 (Heartbeat Timeout).
2.  **Publish (Core):** `UserStatusChangedEvent` 발행 (Topic: `user.status`).
3.  **Subscribe (Noti):** 알림 서비스가 이벤트를 수신하여 상대방에게 "OO님이 잠드신 것 같아요 🌙" 푸시 발송. iOS의 경우 Live Activity 업데이트 패킷 전송.
4.  **Subscribe (AI):** AI 서비스가 이벤트를 수신하여 해당 유저의 **AI Persona 모드**를 `ACTIVE`로 전환.
5.  **Action (Chat):** 이후 상대방이 메시지를 보내면, Core 서버는 AI 서비스로 메시지를 라우팅.

---

## 6. 장애 대응 및 안정성 (Resilience)

*   **Circuit Breaker:** LLM API 응답 지연 시, 전체 장애로 번지지 않도록 AI 기능을 일시 차단하고 "지금은 AI가 쉬고 있어요"라는 Fallback 메시지 반환.
*   **Rate Limiting:** API Gateway에서 과도한 트래픽(DDoS 등) 차단.
*   **Secure Storage:** 채팅 로그는 DB 레벨에서 암호화하여 저장, 개인정보 보호.

## 7. 로드맵 (Roadmap)

1.  **Phase 1 (MVP):** Android/iOS 기본 상태 공유, 하트비트 로직, Live Activity 적용.
2.  **Phase 2 (Data):** 채팅 서버 구축 및 데이터 수집 시작 (AI 미적용).
3.  **Phase 3 (AI):** 수집된 데이터 기반 페르소나 모델 학습 및 대리 응답 기능 오픈.