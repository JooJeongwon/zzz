📝 Task List: ZZZ Project (Updated)
현재 프로젝트의 안정성을 확보하고 유지보수성을 높이기 위한 작업 목록입니다. 우선순위는 긴급 버그 수정 > 기능 보완 > 구조적 리팩토링 > 아키텍처 개선 순으로 배치되었습니다.

1. 🔥 긴급 수정 및 안정성 확보 (Critical Fixes & Stability)
서비스의 정확성과 안정성을 위해 즉시 해결해야 하는 이슈들입니다.

A. 데이터 불일치 해결 (Redis-DB Sync)

문제점: UserService.updateStatus 메서드에서 DB만 업데이트하고, 주석 처리된 상태로 Redis 캐시를 갱신하지 않고 있습니다. 이로 인해 Heartbeat 주기(10분) 동안 상대방에게는 변경 전 상태가 표시됩니다.

작업:

[x] UserService.updateStatus 내에 Redis 캐시(UserStatus)를 즉시 갱신하는 로직 추가.

[x] 상태 변경 시 lastActiveAt 시간도 Redis에 함께 동기화.

B. Android 백그라운드 서비스 안정성 강화

문제점: HeartbeatService.kt에서 앱 초기 실행 직후나 예외 상황에서 userId가 -1로 조회될 경우, stopSelf()를 호출하여 서비스가 영구 종료되는 위험이 있습니다. 또한 네트워크 오류 시 재시도 전략이 부족합니다.

작업:

[x] userId가 유효하지 않을 경우 서비스 종료 대신 일정 시간 후 재시도(Backoff) 하도록 로직 변경.

[x] START_STICKY 외에 START_REDELIVER_INTENT 등을 검토하여 프로세스 재시작 시 안정성 확보.

C. Core-AI 동기 호출 문제 해결 (성능 이슈)

문제점: UserService.processHeartbeat 내부에서 chatService.createRecap을 동기적으로 호출합니다. AI 응답이 지연되면 Heartbeat 처리 스레드 전체가 블로킹될 위험이 있습니다.

작업:

[x] createRecap 호출을 @Async를 사용하여 비동기로 전환하거나, 내부적으로 별도 스레드에서 실행되도록 수정.

2. 🚀 기능 고도화 (Functional Enhancements)
사용자 경험(UX)을 향상시키기 위한 미구현 기능들입니다.

A. 오프라인 모드 및 큐(Queue) 처리 (Native)

문제점: 엘리베이터 등 네트워크 음영 지역에서 Heartbeat 전송 실패 시 데이터가 유실됩니다.

작업:

[x] Android: 전송 실패한 Heartbeat/상태 데이터를 로컬 DB(Room)에 저장.

[x] iOS: 전송 실패한 Heartbeat/상태 데이터를 로컬 DB(CoreData)에 저장.

[x] 네트워크 연결 복구 시 저장된 데이터를 일괄 전송(Batch Upload)하는 로직 구현 (Backend, Android & iOS 완료).

B. 복합 상태 판별 로직 구현 (Scheduler)

문제점: 현재는 단순히 Heartbeat 수신 여부만 확인합니다. 명세서에 있는 '수면', '방전' 등의 구체적 판단 로직이 필요합니다.

작업:

[x] UserStatusScheduler 로직 고도화:

수면: (심야 시간대) AND (Heartbeat 끊김 OR 장시간 움직임 없음) AND (배터리 충전 중).

방전: (Heartbeat 끊김) AND (마지막 배터리 잔량 < 5%).

[x] Timezone을 고려하여 사용자별 현지 시간 기준으로 로직 적용.

C. 푸시 알림 딥링크 (Deep Linking)

현황: FCM 발송 로직은 구현되었으나, 알림 클릭 시 특정 화면 이동은 미구현.

작업:

[x] Flutter: firebase_messaging의 onMessageOpenedApp 콜백 구현.

[x] 알림 타입(채팅, 상태 변화)에 따라 채팅방(ChatScreen) 또는 메인 화면으로 라우팅 처리.

D. 배터리 소모 최적화 (Android)

문제점: 고정된 Heartbeat 주기(10분)는 화면이 꺼져 있는 동안 불필요한 배터리 소모를 유발할 수 있으며, Doze 모드 진입을 방해할 수 있습니다.

작업:

[x] HeartbeatService에 BroadcastReceiver(Screen On/Off) 추가.

[x] 화면 꺼짐 시 전송 주기를 20분으로 늘리고, 켜짐 시 10분으로 복구하며 즉시 Heartbeat 전송.

3. 🛠️ 구조적 리팩토링 (Structural Refactoring)
코드 품질(SOLID 원칙)과 유지보수성을 위한 개선 사항입니다.

A. UserService 책임 분리 (SRP 적용)

문제점: UserService가 인증, 상태 관리, Heartbeat, 채팅 트리거 등 너무 많은 역할을 수행합니다.

작업:

[x] AuthService: 회원가입, 로그인, 토큰 재발급 로직 분리.

[x] UserStatusService: 상태 변경, Heartbeat 처리, Redis 동기화 로직 전담. (Implemented via UserLifecycleFacade & separate UserStatusService logic)

[x] UserLifecycleFacade: 여러 서비스(User, Chat, Couple)를 조율하는 상위 레이어 생성.

B. AI Service 전략 패턴 도입 (OCP 적용)

문제점: LLMService.py 내부에 if self.mock_mode: 분기문이 혼재되어 확장이 어렵습니다.

작업:

[x] LLMProvider 추상 클래스(Interface) 정의.

[x] GeminiLLMProvider와 MockLLMProvider 구현체 분리.

[x] config.py 설정에 따라 의존성 주입(Dependency Injection) 방식으로 변경.

[x] 생성자에서의 외부 API 호출(블로킹 위험)을 Lazy Loading 방식으로 변경.

C. 인프라 코드와 도메인 로직 분리 (DIP 적용)

문제점: CoupleService 등에서 RedisTemplate을 직접 사용하여 구체적인 구현에 의존하고 있습니다.

작업:

[x] UserStatusRepository 인터페이스 정의.

[x] RedisUserStatusRepository 구현체 작성 및 RedisTemplate 로직 이동.

[x] Service 계층에서는 Repository 인터페이스만 의존하도록 리팩토링.

4. 🏗️ 아키텍처 개선 (Architecture Evolution)
장기적인 확장성을 위한 아키텍처 변경 과제입니다.

A. 이벤트 기반(Event-Driven) 통신 도입

현황: Core -> AI 서비스 간 HTTP 동기 호출 사용 중. Notification은 RabbitMQ로 분리됨.

작업:

[x] RabbitMQ 도입 (Infrastructure & Configuration).

[x] Core: NotificationEvent 발행(Publish) 및 구독(Subscribe) 구조 구현.

[x] Core: AIRequestEvent (Chat/Recap) 발행(Publish) 및 AIResponseEvent 구독(Subscribe) 구현.

[x] AI: 메시지 큐를 구독(Subscribe)하여 비동기로 작업 처리 후 결과 발행(Publish).

✅ 완료된 작업 (Completed)
[x] Token Refresh Strategy: Android Native 및 Flutter 레벨에서 401 발생 시 토큰 갱신 로직 구현 (Silent Refresh). [Task 1-A]

[x] Environment Configuration: Flutter(.env) 및 Backend(yml)에서 하드코딩 제거 및 환경 변수 분리. [Task 2-B]

[x] FCM Basic Setup: Flutter 클라이언트 연동 및 Backend 토큰 저장 API 구현. [Task 1-B Partial]

[x] Android Foreground Service: 백그라운드 Heartbeat 전송을 위한 기본 서비스 구현.

[x] Event-Driven Architecture (AI): RabbitMQ를 통한 Core-AI 비동기 통신 (Publish/Subscribe) 구현 완료. [Task 4-A]

코드 품질 및 잠재적 리스크 점검

A. RabbitMQ 메시지 신뢰성 (Data Durability)

[x] RabbitMqConfig.java에 DLQ (Dead Letter Queue) 및 DLX (Dead Letter Exchange) 설정 추가 완료.

B. 오프라인 배치 업로드의 Timestamp 처리

상황: 안드로이드 HeartbeatEntity는 timestamp를 저장합니다.

리스크: 오프라인 상태가 길어져서 5시간 전의 데이터가 지금 업로드될 경우, 서버의 UserStatusService가 이 오래된 데이터를 기준으로 사용자를 "현재 온라인"으로 표시하면 안 됩니다.

[x] 확인 완료: UserStatusService.updateHeartbeat에서 timestamp가 15분 이상 지난 경우 Redis(실시간 상태)를 갱신하지 않고 DB(히스토리)만 저장하는 로직 검증됨 (Unit Test 포함).

C. iOS 백그라운드 제약 (CoreDataStack)

코드: HeartbeatRepository.swift에서 CoreData 저장은 잘 구현되어 있습니다.

현실적 제약: iOS는 앱이 완전히 종료(Kill)되면 백그라운드 작업도 멈춥니다. Android의 Foreground Service처럼 지속적으로 돌기 어렵습니다. 따라서 iOS 사용자는 앱을 켜는 순간(Foreground 진입 시)에 쌓여있던 데이터가 한 번에 전송될 텐데, 이때 "상대방이 갑자기 5시간치 활동 기록을 한 번에 보게 되는" UX가 발생할 수 있습니다. 이는 기술적 버그라기보다 iOS 플랫폼의 특성이므로 기획적인 타협(예: "방금 접속함"으로 퉁치기 등)이 필요할 수 있습니다.

다음 단계 추천 (Priority):

테스트 보강 (Test Coverage):

[x] AuthService Unit Test 구현 완료.
[x] UserStatusService Unit Test 구현 완료.
RabbitMQ 연동 부분은 통합 테스트(Integration Test)로 검증해야 합니다.

푸시 알림 딥링크 (Deep Linking) [Task 2.C]:

현재 인프라는 튼튼하므로, 이제 사용자 눈에 보이는 편의 기능을 추가할 차례입니다. 알림을 눌렀을 때 채팅방이나 상태 화면으로 바로 이동하게 해주세요. (채팅방 이동 구현 확인됨).

배포 파이프라인 (CI/CD):

프로젝트 규모가 커졌으므로, Docker Compose를 활용하여 AWS EC2 등에 실제로 띄워보는 경험을 해보시는 것을 추천합니다. RabbitMQ와 Redis가 포함된 인프라 배포는 로컬과 다를 수 있습니다.

## 5. 🚢 배포 및 운영 준비 (Deployment & Ops)
서비스의 실제 배포와 운영을 위한 마무리 작업입니다.

A. 통합 테스트 환경 구축
- [ ] Testcontainers를 도입하여 Redis, MySQL, RabbitMQ 연동 테스트 작성.
- [ ] Core-AI 간의 메시지 큐 송수신 통합 테스트 작성.

B. API 문서화
- [ ] SpringDoc OpenAPI (Swagger) 적용.
- [ ] 주요 API에 대한 설명 및 예제 값(@Schema) 추가.

C. 배포 스크립트 작성
- [ ] GitHub Actions (CI) 설정: 코드 푸시 시 자동 테스트 및 빌드.
- [ ] Docker Compose Prod 설정: 로컬 개발용이 아닌 배포용 설정 파일(재시작 정책, 볼륨 백업 등) 분리.

6. 🎨 Design Implementation (UI/UX)
Design.md 기반의 앱 디자인 구현 작업입니다.

A. Design System Foundation
- [x] Color Palette (Matte Pastels) & Typography (Pretendard) 정의.
- [x] AppTheme (Material3) 적용.

B. Core UI Components
- [x] CleanCard: Border 기반의 심플한 카드 컴포넌트.
- [x] PixelPet: 16x16 Dot Art 캐릭터 CustomPainter.
- [x] StatusChangeDialog: Squircle Shape 및 직관적인 UI.

C. Screen Layout Implementation
- [x] Home Screen: Partner Top Card (55%) & My Floating Control (45%).
- [x] Chat Screen: Paper Cut 스타일 (No Shadow) & Styled Bubbles.

D. Polish & Assets
- [x] Font Assets: Google Fonts (M PLUS Rounded 1c) 적용 완료.
- [ ] Splash Screen 디자인.
- [x] Animations: PixelPet Breathing/Blink, ScaleTap, LoadingDots 구현 완료.

⚙️ 2. 앱 개발 및 로직 관련 사항 (Engineering & Logic)

"코드의 품질, 안정성, 기능적 작동을 위한 작업"

채팅 로직 리팩토링 (Code Quality)

내용: 채팅 화면 코드에서 '일반 메시지'와 '요약(Recap)'을 처리하는 코드가 섞여 있어 복잡합니다.

작업: chat_screen.dart에서 _buildMessageRow 함수 내 분기 처리를 명확하게 분리하여 코드 정리.

언어 통일 (Localization)

내용: 코드 내에 한글('방금 전')과 영어('Connect with Partner')가 섞여 있어 사용자 경험을 해칩니다.

작업: 앱 내 모든 텍스트를 한국어로 통일하고, 날짜 포맷도 intl 패키지를 활용해 한국식으로 변경.

네트워크 에러 처리 (Stability)

내용: 인터넷이 끊기거나 서버 오류 시 앱이 멈춘 것처럼 보이지 않게 처리해야 합니다.

작업: API 호출 실패 시 "재시도" 버튼을 띄우거나, 상단에 "오프라인 상태" 알림 바 표시.

다크 모드 자동화 (Logic)

내용: 디자인 시스템에 있는 Night Mode 색상이 언제 적용될지 로직을 정해야 합니다.

작업: 파트너가 SLEEP 상태가 되면 앱 전체 테마를 자동으로 어두운 색상(AppColors.backgroundNight)으로 전환하는 로직 구현.