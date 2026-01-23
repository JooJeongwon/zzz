🛠️ ZZZ 프로젝트 코드 리뷰 및 리팩토링 정의서
작성일: 2026년 01월 23일 대상 모듈: Flutter App, Spring Boot Core, Python AI Service

1. 종합 요약 (Executive Summary)
백엔드 (Spring Boot): 계층형 아키텍처와 Facade 패턴이 잘 적용되어 구조적으로 안정적입니다. 일부 서비스의 역할 분리와 동시성 제어만 보완하면 상용 수준으로 손색이 없습니다.

AI 서비스 (Python): 기능 단위로 간결하게 작성되었으나, 테스트 용이성을 위해 의존성 주입(DI) 방식으로의 전환이 권장됩니다.

모바일 앱 (Flutter): 가장 시급한 개선이 필요합니다. 안티 패턴(Static 남발)과 아키텍처 부재(UI-로직 결합)로 인해 확장성과 테스트가 매우 어려운 상태입니다.

2. 주요 수정 사항 (Critical Refactoring) - Priority: High
📱 Flutter App (Client)

2.1. ApiService 구조 개선 (Anti-Pattern 제거)

문제점: 모든 메서드가 static으로 선언되어 있어 상태 관리가 불가능하고, 테스트 시 Mocking이 어렵습니다. 또한 _getAuthHeaders에서 매번 디스크(SharedPreferences) I/O가 발생합니다.

해결 방안:

ApiService를 일반 클래스로 변경하고 인스턴스화하여 사용합니다.

Dependency Injection(DI): Provider 또는 Riverpod을 사용하여 앱 전역에서 하나의 인스턴스(Singleton)를 주입받아 사용하도록 변경합니다.

Dio 라이브러리 도입: http 패키지 대신 Dio를 사용하여 Interceptor를 통해 토큰 주입 및 공통 에러 처리를 자동화합니다.

2.2. UI와 비즈니스 로직 분리 (MVVM 적용)

문제점: HomeScreen 내부에 데이터 페칭(_fetchPartnerStatus), 폴링(Timer), 위젯 업데이트 로직이 혼재되어 있습니다. (SRP 위반)

해결 방안:

화면(View)과 로직(ViewModel)을 분리합니다.

ViewModel: 상태 관리 라이브러리(Riverpod/Bloc)를 도입하여 비즈니스 로직을 전담합니다.

View: HomeScreen은 ViewModel의 상태(State)를 구독하여 화면을 그리는 역할만 수행합니다.

2.3. 에러 핸들링 체계화

문제점: try-catch 후 단순 return false 또는 null 처리로 인해, 호출부에서 구체적인 에러 원인(네트워크 단절, 인증 실패, 서버 오류 등)을 알 수 없습니다.

해결 방안:

Result<T> 패턴(Success/Failure Sealed Class)을 도입하여 에러를 명시적으로 반환합니다.

UI 레벨에서 에러 타입에 따라 스낵바, 다이얼로그, 재시도 버튼 등 적절한 피드백을 제공합니다.

2.4. 환경 설정 분리

문제점: ApiService.baseUrl 내에 로컬 주소와 플랫폼 분기 처리가 하드코딩되어 있습니다.

해결 방안:

flutter_dotenv 또는 --dart-define을 활용하여 개발(Dev)과 배포(Prod) 환경 변수를 분리합니다.

3. 보완 사항 (Improvements) - Priority: Medium
☕ Spring Boot (Backend)

3.1. ChatService 역할 축소 (Event Driven)

문제점: sendMessage 메서드에서 메시지 저장뿐만 아니라 AIEventPublisher, UserStatus 체크, 알림 발송까지 수행하여 책임이 과중합니다.

해결 방안:

메시지 저장 후 MessageSentEvent를 발행합니다.

@EventListener를 구현한 별도 컴포넌트에서 비동기로 AI 트리거 및 알림 발송을 처리하여 ChatService의 의존성을 줄입니다.

3.2. 동시성 제어 (Concurrency Control)

문제점: processHeartbeat 등에서 데이터를 읽고 쓰는 사이에 상태가 변경될 경우 데이터 정합성 문제가 발생할 수 있습니다.

해결 방안:

JPA의 @Version을 활용한 낙관적 락(Optimistic Lock)을 도입하여 충돌을 감지하거나, Redis 분산 락을 고려합니다.

🐍 Python (AI Service)

3.3. 의존성 주입 (Dependency Injection) 적용

문제점: llm_service.py 마지막 줄에서 전역 인스턴스를 직접 생성(llm_service = LLMService())하고 있어 테스트 시 의존성을 교체하기 어렵습니다.

해결 방안:

FastAPI의 Depends 기능을 활용하여 Request Scope 또는 App Scope에서 인스턴스를 주입받도록 구조를 변경합니다.