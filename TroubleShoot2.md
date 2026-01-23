[Bugfix] RabbitMQ Infinite Retry Loop & Data Type Mismatch
1. 이슈 개요 (Issue Summary)
증상: core-service 로그에 NumberFormatException이 발생하며 RabbitMQ 리스너가 무한 루프에 빠짐.

원인: ai-service에서 발행한 메시지 페이로드 내 couple_id 필드가 문자열("partner-1")로 전송되었으나, core-service의 엔티티/DTO는 이를 Long 타입으로 매핑하고 있음.

결과: 수신 측에서 파싱 에러 발생 → 예외 던짐 → RabbitMQ가 메시지를 다시 큐에 넣음(Requeue) → 무한 반복 (Poison Message).

2. 조치 사항 (Action Items)
Step 1. 운영 조치: 독성 메시지 제거 (Queue Purge)

서버를 재시작해도 큐에 남아있는 잘못된 메시지 때문에 즉시 에러가 재발합니다. 우선 큐를 비워야 합니다.

RabbitMQ Management Console 접속 (http://localhost:15672)

Queues 탭 이동

ai.response.queue (또는 에러가 발생하는 큐 이름) 클릭

하단 Purge Messages 패널 확장 → Purge Messages 버튼 클릭

주의: 대기 중인 모든 메시지가 삭제됩니다. 개발 환경이므로 진행합니다.

Step 2. 코드 수정: AI Service Mock 데이터 타입 변경

ai-service의 Mock 데이터 생성 로직을 core-service의 스키마에 맞게 수정해야 합니다.

대상 파일: backend/ai-service/app/services/llm_service.py (또는 관련 Mock 파일)

수정 내용: couple_id 값을 String에서 Long(Integer)으로 변경

Step 3. 재발 방지 (권장 사항 - Backlog)

추후 동일 이슈 방지를 위해 core-service의 예외 처리 로직 보강이 필요합니다.

Global Error Handler 적용: 메시지 처리 중 치명적 에러(포맷 에러 등 복구 불가능한 에러) 발생 시 AmqpRejectAndDontRequeueException을 발생시켜 메시지를 버리거나(Discard), **Dead Letter Queue (DLQ)**로 이동시키도록 설정할 것.

3. 검증 절차 (Verification)
RabbitMQ 큐가 비어있는지 확인 (Ready: 0).

core-service 재시작 (./gradlew bootRun).

ai-service 재시작 및 API 요청 트리거.

core-service 로그에 Received AI Response가 뜨고 에러 없이 처리가 완료되는지 확인.