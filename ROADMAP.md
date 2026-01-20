# 🗺️ ZZZ Project Roadmap

현재 진행 상황과 향후 개발 마일스톤을 정리한 문서입니다.

## ✅ Phase 1: Foundation (기반 구축) - [Current Status: 100%]
기본적인 프로젝트 구조와 통신 테스트를 완료하는 단계입니다.
- [x] **Infra:** Docker Compose 구성 (MySQL, Redis, Mongo, RabbitMQ).
- [x] **Backend (Core):** Spring Boot 프로젝트 셋업.
- [x] **Backend (Core):** User 도메인 및 회원가입 API 구현.
- [x] **Backend (Core):** Heartbeat 수신 API 구현.
- [x] **Client (Flutter):** Flutter 프로젝트(`app`) 셋업 및 아키텍처 설계.
- [x] **Client (Flutter):** 기본 네이티브 설정(Permission) 및 환경 구축.

## 🚧 Phase 2: Core Logic & Native Bridge (핵심 로직 및 네이티브 연동)
단순한 데이터 저장을 넘어, 플랫폼 별 특화 기능과 연결하는 단계입니다.
- [x] **Backend (Core):** Redis 연동을 통한 실시간 상태 관리.
- [x] **Backend (Core):** `Couples` 도메인 및 인증(JWT) 구현.
- [x] **Backend (Core):** 사용자 상태 판별 스케줄러.
- [x] **Client (Native):** Android Foreground Service 구현 (Kotlin) 및 MethodChannel 연동.
- [x] **Client (Native):** iOS Live Activity prototype (Swift) and MethodChannel integration.
- [x] **Client (Flutter):** Heartbeat 전송 로직 구현 (Dart -> Native 호출).

## 🤖 Phase 3: AI Service Initialization (AI 서비스 구축) - [Current Status: 100%]
AI 페르소나 기능을 위한 별도 서비스를 구축합니다.
- [x] **Backend (AI):** Python FastAPI 프로젝트 이니셜라이징.
- [x] **Backend (AI):** RAG 파이프라인 및 Vector DB 연동.
- [x] **Backend (AI):** LLM (OpenAI) API 연동.
- [x] **Integration:** Core Service <-> AI Service 통신.

## 📱 Phase 4: Flutter UI & Feature Integration (Basic) - [Current Status: 100%]
사용자가 체감할 수 있는 UI와 기능을 Flutter로 완성합니다.
- [x] **Client (Flutter):** 메인 화면 (Status Indicator, Character Animation(현재 정적 아이콘으로 구성)).
- [x] **Client (Flutter):** 로그인/회원가입 UI 및 API 연동.
- [x] **Client (Flutter):** 채팅 UI 구현 (Socket.io/HTTP) 및 AI 응답 처리.
- [x] **Client (Flutter):** 상태 변경 위젯(Overlay/Dialog) 구현.
- [x] **Backend:** 채팅 기록 조회 및 저장 로직 고도화 (Recap 기능 포함).

## 🎨 Phase 5: Advanced UI & Widgets (고도화 및 위젯) - [Current Status: 100%]
기본 기능을 넘어 사용성을 높이고 플랫폼 특화 위젯을 구현합니다.
- [x] **Client (Flutter):** 채팅 UI 고도화 (날짜 구분선, 시간 표시, AI 메시지 스타일링).
- [x] **Client (Flutter):** AI Recap(요약) 메시지 전용 UI 구현.
- [x] **Client (Flutter):** 상태 변경 다이얼로그 고도화 (지속 시간 설정 기능 추가).
- [x] **Client (Native):** Android Home Screen Widget 구현 (Kotlin).
- [x] **Client (Native):** iOS Home Screen Widget 구현 (Swift/SwiftUI).

## ✨ Phase 6: Polish & Beta (안정화 및 배포) - [Current Status: 80%]
- [x] **Test:** 백엔드 테스트 환경 구축 (H2 DB, Test Config) 및 Context Load 검증.
- [x] **Test:** 통합 테스트 및 시나리오 테스트 (User Lifecycle, Couple Connection 검증 완료).
- [x] **Test:** Testcontainers 도입 및 통합 테스트 환경 구축.
- [x] **Test:** AI 서비스 테스트 환경 구축 (Mock Mode 구현으로 API Key 없이 동작 검증).
- [x] **Test:** 클라이언트(Flutter) 위젯 테스트 및 모델 유닛 테스트 완료.
- [x] **Client (Native):** iOS Heartbeat 전송 로직 실제 구현 (Mock 제거).
- [x] **Security:** Refresh Token Strategy 구현 (Backend & Android Native).
- [x] **Refactor:** 하드코딩 제거 및 환경 변수 분리 (Flutter .env / Backend application.yml).
- [x] **Refactor:** Backend Core (UserService 분리) 및 AI Service (LLMProvider 전략 패턴) 구조 개선.
- [x] **Refactor:** Backend Core DIP 적용 (Redis 의존성 분리 및 Repository 패턴 도입).
- [x] **Arch:** Event-Driven Architecture 기반 구축 (RabbitMQ 도입, Notification 및 AI Service 연동).
- [x] **Feature:** Android Offline Mode (Room DB & Batch Upload).
- [x] **Feature:** Push Notification (FCM) - Client 딥링크 처리 예정 (Backend 발송 로직 완료).
- [ ] **Security:** API 보안 감사 및 데이터 암호화 적용.
- [x] **Optimization:** 배터리 소모 최적화 (Android).
- [ ] **Deploy:** AWS 배포 및 CI/CD 파이프라인 구축.
