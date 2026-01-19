1. 🚀 기능적 보완 (Functional Improvements)

사용자 경험(UX)과 서비스 안정성을 위해 추가되어야 할 기능들입니다.

A. 토큰 갱신 로직 (Refresh Token Strategy) [Completed]

문제점: HeartbeatService.kt(Android)는 TokenManager에 저장된 Access Token을 사용하여 하트비트를 전송합니다. 보통 Access Token은 수명이 짧은데(예: 30분), 앱이 백그라운드에 오래 떠 있는 경우 토큰이 만료되면 하트비트 전송이 401 Unauthorized로 실패하고, 사용자는 'Offline'으로 오해받게 됩니다.

보완: * [x] 백그라운드 서비스 내에서 401 응답 수신 시, Refresh Token을 사용해 토큰을 갱신하고 재시도하는 로직(Silent Refresh)을 네이티브 레벨(Kotlin)과 플러터 레벨(Dart) 양쪽에 구현해야 합니다.

B. 푸시 알림 연동 (FCM/APNs) [Partially Completed]

문제점: ARCHITECTURE.md에는 NotiServer와 FCM이 명시되어 있으나, 코드상으로는 아직 푸시 발송 로직이 보이지 않습니다. 상대방이 "일어났어요" 상태로 변하거나 AI가 대신 답장을 했을 때, 앱이 꺼져 있다면 사용자는 이를 알 수 없습니다.

보완: 
* [x] **Client:** Flutter에서 `firebase_messaging`을 연동하여 권한 요청, 토큰 획득 및 서버 전송 로직(FcmService) 구현.
* [x] **Backend:** User 엔티티에 FCM Token 필드 추가 및 업데이트 API(`POST /fcm-token`) 구현.
* [x] **Backend:** 특정 이벤트(상태 변경, 채팅 수신) 발생 시 FCM으로 데이터 메시지를 쏘는 로직 추가 (Firebase Admin SDK 연동).
* [ ] **Client:** 알림 클릭 시 해당 화면(채팅방 등)으로 이동하는 딥링크 처리.

C. 오프라인 모드 및 큐(Queue) 처리

문제점: 네트워크가 불안정하거나 끊긴 상황(엘리베이터 등)에서 하트비트나 채팅 전송을 시도하면 즉시 에러가 발생하고 데이터가 유실됩니다.

보완: * Native: HeartbeatService에서 전송 실패 시, 데이터를 로컬 DB(Room)나 큐에 쌓아두고 네트워크 연결 시 일괄 전송(Batch Upload)하는 로직이 필요합니다.

D. 구체적인 상태 판별 로직 적용

문제점: 문서상에는 *"밤 10시~아침 8시 사이에 하트비트가 끊기면 수면(SLEEP)"*이라는 구체적인 로직이 있으나, 현재 코드는 하트비트 수신 여부 정도만 확인하는 기초 단계일 가능성이 높습니다.

보완: * UserStatusScheduler(Java) 내에 단순 타임아웃 체크뿐만 아니라, **현재 시간(Timezone 고려)**과 배터리 상태 패턴을 결합한 복합 판단 로직을 구현해야 합니다. (예: 배터리가 충전 중이면서 움직임이 없으면 '수면' 확률 가중치 부여)

2. 🛠️ 구조적 보완 및 리팩토링 (Structural Refactoring)

코드의 품질, 유지보수성, 그리고 아키텍처 원칙을 준수하기 위한 개선 사항입니다.

A. 진정한 이벤트 기반(Event-Driven) 통신 구현

현황: ARCHITECTURE.md에는 Core -> MessageQueue -> AI 흐름이 그려져 있지만, 코드 파일 목록(AIServiceClient.java)을 보면 Core가 AI 서비스를 **REST API(HTTP)**로 직접 동기 호출하는 구조로 보입니다.

리팩토링: * 사용자가 채팅을 보낼 때, AI 응답을 기다리느라 채팅 API 응답이 느려지는 것을 방지해야 합니다.

RabbitMQ/Kafka 도입: Core 서버는 "메시지 수신됨" 이벤트만 큐에 던지고 즉시 리턴(Ack)합니다. AI 서비스는 큐를 구독(Subscribe)하다가 비동기로 메시지를 처리하고, 답변 생성 후 다시 큐를 통해 Core나 채팅 서버로 알리는 구조로 변경해야 아키텍처 문서와 일치하게 됩니다.

B. 하드코딩 제거 및 환경 분리 [Completed]

현황: ApiService.dart에 http://10.0.2.2:8080과 같은 IP가 하드코딩되어 있습니다. LLMService.py에도 모델명 등이 박혀 있습니다.

리팩토링: * [x] Flutter: flutter_dotenv 패키지나 Flavors를 사용하여 DEV, PROD 환경에 따라 Base URL이 자동으로 변경되도록 수정해야 합니다.

* [x] Backend: application.yml이나 .env 파일로 중요 설정 값(모델 파라미터, 임계값 등)을 외부로 뺍니다.

C. AI 서비스의 Mocking 패턴 개선 (Strategy Pattern)

현황: LLMService.py 내부에 if self.mock_mode: 분기문이 비즈니스 로직과 섞여 있습니다. 코드가 커질수록 유지보수가 어려워집니다.

리팩토링: * 인터페이스(Abstract Base Class)를 정의하고, RealLLMService와 MockLLMService 클래스를 분리하여 구현합니다.

초기화 시 설정(config)에 따라 적절한 구현체를 주입(Dependency Injection)받도록 수정하면, 비즈니스 로직 내에서 if 문을 제거할 수 있어 코드가 훨씬 깔끔해집니다.

D. 도메인 로직과 인프라 코드의 분리

현황: CoupleService.java에서 RedisTemplate을 직접 사용하여 로우 레벨의 opsForValue().get(...) 등을 호출하고 있습니다.

리팩토링: * Repository 패턴 적용: Redis 관련 코드를 UserStatusRepository (Interface) -> RedisUserStatusRepository (Impl) 로 분리합니다.

Service 계층에서는 userStatusRepository.getBatteryLevel(userId)와 같이 도메인 언어로 된 메서드만 호출하도록 하여, 향후 Redis가 다른 저장소로 바뀌더라도 비즈니스 로직을 보호해야 합니다.