# Project Context: ZZZ

## 1. 프로젝트 개요 (Overview)
- **프로젝트명:** ZZZ (지-지-지)
- **한 줄 소개:** "연락이 끊겨도 마음은 연결되게." 연인 간 상태 공유 및 AI 페르소나 대리 응답 서비스.
- **핵심 문제 해결:** 수면, 공부, 배터리 방전 등으로 연락이 안 될 때 발생하는 연인의 불안감을 해소.
- **타겟 유저:** 2030 커플 (특히 군인, 곰신, 장거리 연애, 수험생).
- 항상 한글로 대답하고, 개발 표준 원칙과 SOLID 원칙을 준수해서 개발.
- MSA 구조로 결합도를 낮춤.
- 작업이 끝나면 session_memory.json에 작업 내용을 저장.

## 2. 기술 스택 (Tech Stack)
- **Client:** Android (Kotlin/Java) - Foreground Service 활용 필수.
- **Backend (Core):** Spring Boot (Java) or Node.js - REST API & Socket.io.
- **Backend (AI):** Python (FastAPI/Flask) - LLM Serving & RAG Pipeline.
- **Database:**
  - **RDB:** MySQL/PostgreSQL (사용자, 커플 정보).
  - **NoSQL:** Redis (실시간 상태, 하트비트 캐싱), MongoDB (채팅 로그).
  - **Vector DB:** Pinecone or Milvus (말투 학습용 임베딩 데이터).
- **Infra:** Docker, AWS (EC2/RDS).

## 3. 핵심 기능 명세 (Core Features)

### A. 하트비트 기반 상태 감지 (Heartbeat Logic)
> **중요:** 앱이 백그라운드에서 죽는(Kill) 상황을 고려하여 '서버 주도' 판단 로직을 사용한다.
1. **Client:** 화면 켜짐/꺼짐, 배터리 상태 등을 담은 `Heartbeat` 패킷을 주기적(예: 10분)으로 서버에 전송.
2. **Server:** 마지막 Heartbeat 수신 후 설정된 임계 시간(예: 30분)이 지나면, 해당 유저의 상태를 `SLEEP` 또는 `UNKNOWN`으로 자동 업데이트.
3. **Android:** Doze 모드 회피를 위해 Foreground Service(상단 알림바 노출)를 사용하여 생존 신호 전송 보장.

### B. AI 페르소나 (AI Persona & RAG)
1. **학습:** 사용자의 과거 카톡 대화 내역을 업로드 -> 벡터화(Embedding) -> Vector DB 저장.
2. **대리 응답:** 사용자가 `SLEEP`/`STUDY` 상태일 때 상대방이 말을 걸면 AI가 개입.
   - **Process:** 상대 질문 + 사용자 현재 상태 + 유사한 과거 대화 검색(RAG) -> LLM이 사용자 말투로 답변 생성.
3. **Recap:** 사용자가 복귀(화면 켬) 시, 부재중 동안 AI와 연인이 나눈 대화를 요약 리포트로 제공.

### C. 위젯 & UI
- **Widget:** 원터치 상태 변경(자러 감, 공부 시작), 상대방 상태 표시 캐릭터.
- **Character:** 상태(Online, Sleep, Study)에 따라 변경되는 2D/3D 캐릭터 애니메이션.

## 4. 데이터베이스 스키마 (ERD Summary)

### [Users]
- `user_id` (PK)
- `current_status` (ENUM: ONLINE, SLEEP, STUDY, BUSY)
- `last_active_at` (DATETIME): 마지막 Heartbeat 시간
- `couple_id` (FK)

### [Couples]
- `couple_id` (PK)
- `user_a_id`, `user_b_id`

### [AI_Personas]
- `persona_id` (PK), `user_id` (FK)
- `base_tone` (String): 말투 스타일
- `vector_store_key` (String): 벡터 DB 식별자

### [Chat_Messages]
- `msg_id` (PK)
- `sender_id`, `receiver_id`
- `is_ai_generated` (Boolean): AI 대리 응답 여부
- `content` (Text)

## 5. API 명세 요약 (API Specs)

- `POST /api/v1/users/heartbeat`: 생존 신호 전송 (Body: battery, isScreenOn)
- `POST /api/v1/users/status`: 수동 상태 변경 (Body: status, duration)
- `POST /api/v1/chat/send`: 메시지 전송 (AI 모드 활성화 시 자동 분기 처리)
- `GET /api/v1/couples/partner-status`: 상대방 상태 및 캐릭터 정보 조회

## 6. 개발 컨벤션 (Conventions)
- **Commit Message:** `[FEat]`, `[Fix]`, `[Docs]`, `[Refactor]` 태그 사용.
- **Code Style:** 각 언어별 표준 스타일 가이드 준수 (Java Google Style, PEP8 등).
- **Security:** 민감한 대화 내용은 암호화 저장, API Key는 환경변수(.env)로 관리.