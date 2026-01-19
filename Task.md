📝 Task List: ZZZ Project (Updated)
현재 프로젝트의 안정성을 확보하고 유지보수성을 높이기 위한 작업 목록입니다. 우선순위는 긴급 버그 수정 > 기능 보완 > 구조적 리팩토링 > 아키텍처 개선 순으로 배치되었습니다.

1. 🔥 긴급 수정 및 안정성 확보 (Critical Fixes & Stability)
서비스의 정확성과 안정성을 위해 즉시 해결해야 하는 이슈들입니다.

A. 데이터 불일치 해결 (Redis-DB Sync)

문제점: UserService.updateStatus 메서드에서 DB만 업데이트하고, 주석 처리된 상태로 Redis 캐시를 갱신하지 않고 있습니다. 이로 인해 Heartbeat 주기(10분) 동안 상대방에게는 변경 전 상태가 표시됩니다.

작업:

[ ] UserService.updateStatus 내에 Redis 캐시(UserStatus)를 즉시 갱신하는 로직 추가.

[ ] 상태 변경 시 lastActiveAt 시간도 Redis에 함께 동기화.

B. Android 백그라운드 서비스 안정성 강화

문제점: HeartbeatService.kt에서 앱 초기 실행 직후나 예외 상황에서 userId가 -1로 조회될 경우, stopSelf()를 호출하여 서비스가 영구 종료되는 위험이 있습니다. 또한 네트워크 오류 시 재시도 전략이 부족합니다.

작업:

[ ] userId가 유효하지 않을 경우 서비스 종료 대신 일정 시간 후 재시도(Backoff) 하도록 로직 변경.

[ ] START_STICKY 외에 START_REDELIVER_INTENT 등을 검토하여 프로세스 재시작 시 안정성 확보.

C. Core-AI 동기 호출 문제 해결 (성능 이슈)

문제점: UserService.processHeartbeat 내부에서 chatService.createRecap을 동기적으로 호출합니다. AI 응답이 지연되면 Heartbeat 처리 스레드 전체가 블로킹될 위험이 있습니다.

작업:

[ ] createRecap 호출을 @Async를 사용하여 비동기로 전환하거나, 내부적으로 별도 스레드에서 실행되도록 수정.

2. 🚀 기능 고도화 (Functional Enhancements)
사용자 경험(UX)을 향상시키기 위한 미구현 기능들입니다.

A. 오프라인 모드 및 큐(Queue) 처리 (Native)

문제점: 엘리베이터 등 네트워크 음영 지역에서 Heartbeat 전송 실패 시 데이터가 유실됩니다.

작업:

[ ] Android/iOS: 전송 실패한 Heartbeat/상태 데이터를 로컬 DB(Room/CoreData) 또는 메모리 큐에 저장.

[ ] 네트워크 연결 복구 시 저장된 데이터를 일괄 전송(Batch Upload)하는 로직 구현.

B. 복합 상태 판별 로직 구현 (Scheduler)

문제점: 현재는 단순히 Heartbeat 수신 여부만 확인합니다. 명세서에 있는 '수면', '방전' 등의 구체적 판단 로직이 필요합니다.

작업:

[ ] UserStatusScheduler 로직 고도화:

수면: (심야 시간대) AND (Heartbeat 끊김 OR 장시간 움직임 없음) AND (배터리 충전 중).

방전: (Heartbeat 끊김) AND (마지막 배터리 잔량 < 5%).

[ ] Timezone을 고려하여 사용자별 현지 시간 기준으로 로직 적용.

C. 푸시 알림 딥링크 (Deep Linking)

현황: FCM 발송 로직은 구현되었으나, 알림 클릭 시 특정 화면 이동은 미구현.

작업:

[ ] Flutter: firebase_messaging의 onMessageOpenedApp 콜백 구현.

[ ] 알림 타입(채팅, 상태 변화)에 따라 채팅방(ChatScreen) 또는 메인 화면으로 라우팅 처리.

3. 🛠️ 구조적 리팩토링 (Structural Refactoring)
코드 품질(SOLID 원칙)과 유지보수성을 위한 개선 사항입니다.

A. UserService 책임 분리 (SRP 적용)

문제점: UserService가 인증, 상태 관리, Heartbeat, 채팅 트리거 등 너무 많은 역할을 수행합니다.

작업:

[ ] AuthService: 회원가입, 로그인, 토큰 재발급 로직 분리.

[ ] UserStatusService: 상태 변경, Heartbeat 처리, Redis 동기화 로직 전담.

[ ] UserLifecycleFacade: 여러 서비스(User, Chat, Couple)를 조율하는 상위 레이어 생성.

B. AI Service 전략 패턴 도입 (OCP 적용)

문제점: LLMService.py 내부에 if self.mock_mode: 분기문이 혼재되어 확장이 어렵습니다.

작업:

[ ] LLMProvider 추상 클래스(Interface) 정의.

[ ] GeminiLLMProvider와 MockLLMProvider 구현체 분리.

[ ] config.py 설정에 따라 의존성 주입(Dependency Injection) 방식으로 변경.

[ ] 생성자에서의 외부 API 호출(블로킹 위험)을 Lazy Loading 방식으로 변경.

C. 인프라 코드와 도메인 로직 분리 (DIP 적용)

문제점: CoupleService 등에서 RedisTemplate을 직접 사용하여 구체적인 구현에 의존하고 있습니다.

작업:

[ ] UserStatusRepository 인터페이스 정의.

[ ] RedisUserStatusRepository 구현체 작성 및 RedisTemplate 로직 이동.

[ ] Service 계층에서는 Repository 인터페이스만 의존하도록 리팩토링.

4. 🏗️ 아키텍처 개선 (Architecture Evolution)
장기적인 확장성을 위한 아키텍처 변경 과제입니다.

A. 이벤트 기반(Event-Driven) 통신 도입

현황: Core -> AI 서비스 간 HTTP 동기 호출 사용 중.

작업:

[ ] RabbitMQ/Kafka 도입.

[ ] Core: UserWokeUpEvent, ChatMessageReceivedEvent 발행(Publish) 후 즉시 응답.

[ ] AI/Noti: 메시지 큐를 구독(Subscribe)하여 비동기로 작업 처리 후 결과 콜백.

✅ 완료된 작업 (Completed)
[x] Token Refresh Strategy: Android Native 및 Flutter 레벨에서 401 발생 시 토큰 갱신 로직 구현 (Silent Refresh). [Task 1-A]

[x] Environment Configuration: Flutter(.env) 및 Backend(yml)에서 하드코딩 제거 및 환경 변수 분리. [Task 2-B]

[x] FCM Basic Setup: Flutter 클라이언트 연동 및 Backend 토큰 저장 API 구현. [Task 1-B Partial]

[x] Android Foreground Service: 백그라운드 Heartbeat 전송을 위한 기본 서비스 구현.