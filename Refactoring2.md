1. 📱 Client (Flutter) 개선 제안
1.1. 에러 상태 관리의 구체화 (Typed Error Handling)

현황: HomeState에서 에러를 단순 문자열(String? error)로 관리하고 있습니다. (예: 'SESSION_EXPIRED', 'UPDATE_FAILED')

위험: 오타로 인한 버그 발생 가능성이 있고, UI에서 에러 종류에 따라 다르게 대응(재시도 버튼 노출, 스낵바 표시, 로그아웃 처리 등)하기 위해 문자열 비교를 해야 하므로 유지보수가 어렵습니다.

제안: sealed class 또는 enum을 사용하여 에러를 타입화합니다.

1.2. 로깅 및 모니터링 체계 구축

현황: _updateWidget 등 일부 비동기 로직에서 catch (e) 블록이 비어있거나(// Ignore errors), 단순 print만 수행할 가능성이 있습니다.

제안:

앱 충돌 방지를 위해 예외를 잡는 것은 좋으나, 발생 사실을 개발자가 알 수 있어야 합니다.

Firebase Crashlytics나 Sentry 같은 이슈 트래킹 도구를 연동하여, 배포 후 사용자 기기에서 발생하는 예외를 수집해야 합니다.

1.3. MethodChannel의 추상화

현황: HomeViewModel 내부에 static const platform = MethodChannel(...)이 직접 정의되어 있습니다.

제안:

네이티브 기능(하트비트 서비스 등)은 테스트 코드(Unit Test)에서 실행될 수 없습니다.

NativeService와 같은 인터페이스를 만들고, 구현체에서 MethodChannel을 호출하도록 감싸주면, ViewModel 테스트 시 Mocking이 훨씬 수월해집니다.

2. ☕ Backend (Spring Boot) 개선 제안
2.1. 이벤트 발행의 신뢰성 확보 (Transactional Outbox Pattern)

현황: ChatService에서 @Async 이벤트를 발행합니다. 만약 DB 트랜잭션은 커밋되었으나, 이벤트 리스너 실행 중(또는 메시지 큐 전송 중) 서버가 다운되면 "메시지는 저장됐는데 알림/AI요약이 안 오는" 불일치가 발생할 수 있습니다.

제안 (심화):

중요도가 높은 데이터라면 Transactional Outbox Pattern 도입을 고려합니다. (DB에 '이벤트' 테이블을 만들어서 같이 저장하고, 별도 스케줄러가 이벤트를 발행하는 방식)

현재 규모에서는 오버엔지니어링일 수 있으므로, RabbitMQ의 Publisher Confirms 기능을 활성화하는 정도로 타협할 수 있습니다.

2.2. 외부 API (AI 서비스) 호출의 회복탄력성 (Resilience)

현황: ChatEventListener에서 AI 서비스를 호출할 때 단순 try-catch로 처리하고 있습니다. 네트워크 일시 장애로 실패할 경우 AI 응답이 누락됩니다.

제안:

Retry (재시도): 실패 시 1초, 3초, 5초 뒤 재시도하는 로직 추가 (Spring Retry 또는 Resilience4j 활용).

Circuit Breaker (서킷 브레이커): AI 서비스가 아예 죽었을 때, 계속 요청을 보내지 않고 빠르게 실패 처리하여 시스템 자원을 보호.

3. 🐍 AI Service (Python) 개선 제안
3.1. 비동기 처리 최적화 (Async/Await)

현황: FastAPI는 비동기 프레임워크(async def)이지만, 내부에서 사용하는 LLM 클라이언트 라이브러리(Google Gemini SDK 등)가 동기(Sync) 방식인지 확인이 필요합니다.

제안:

만약 사용하는 SDK가 동기 함수(def)라면, FastAPI의 이벤트 루프를 차단(Block)할 수 있습니다. 이 경우 run_in_executor를 사용하거나, 해당 SDK의 비동기 버전을 사용해야 성능 저하를 막을 수 있습니다.

3.2. 설정 관리 (Configuration)

현황: 환경 변수 관리가 잘 되고 있으나, pydantic의 BaseSettings를 활용하여 환경 변수 타입 검증을 강화하면 좋습니다. (예: API 키가 누락되면 서버 시작 시점에 바로 에러 발생)

4. 🧪 테스트 전략 (QA)
4.1. 통합 테스트 (Integration Test) 확충

제안:

현재 단위 테스트(Unit Test) 위주로 구성되어 있다면, **"Flutter 앱 -> Spring Boot API -> H2 DB(Test DB)"**까지 연결되는 통합 테스트 시나리오를 최소 1~2개(예: 로그인 후 상태 변경 시나리오) 작성하는 것을 추천합니다.

이는 리팩토링 과정에서 기능이 깨지지 않았음을 보장하는 가장 강력한 수단입니다.