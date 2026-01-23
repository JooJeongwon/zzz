ZZZ Project: Gamification Design Document
1. 개요 (Overview)
"연결의 시각화 (Visualizing Connection)" 단순히 앱을 자주 켜게 만드는 것이 아니라, 멀리 떨어져 있는 두 사람의 **생활 패턴(Status)**과 **대화(Context)**가 어떻게 연결되어 있는지를 게임적 요소로 시각화하여 몰입감을 높입니다.

2. 핵심 기능 (Core Features)
2.1. 러브 레벨 & 펫 진화 (Love Level & Evolution)

커플의 상호작용 빈도에 따라 펫이 성장하고 외형이 변하는 시스템입니다.

메커니즘 (Mechanism):

XP 획득: 상태 변경(기상/취침) 제때 하기(+10), 서로의 상태에 반응(Poke)하기(+5), 하루 대화 100마디 이상(+20).

레벨 시스템: Couple 엔티티에 xp 및 level 필드 추가.

진화 단계:

Lv.1 (Baby): 기본 픽셀 곰 (현재 PixelPet 상태).

Lv.10 (Teen): 액세서리 착용 (모자, 목걸이 등).

Lv.30 (Adult): 특수 오라(Aura) 및 화려한 픽셀 아트 적용.

구현 포인트 (Tech Spec):

Backend (core-service): Couple 도메인에 경험치 로직 추가. UserStatusService에서 상태 변경 시 XP 지급 로직 트리거.

Frontend (PixelPet.dart): level 파라미터를 받아 CustomPainter가 그리는 파츠(Parts)를 동적으로 변경.

2.2. 동기화 토템 (Sync Totem)

"우리가 같은 시간에 같은 행동을 하고 있다"는 것을 시각적인 탑(Totem)으로 표현합니다.

메커니즘 (Mechanism):

두 사용자의 UserStatus가 동일할 때(예: 둘 다 STUDY, 둘 다 SLEEP) 메인 화면 배경에 탑이 쌓이기 시작합니다.

지속 시간에 따라 탑이 높아지며, 특정 높이 도달 시 보상(코인, 특수 효과) 획득.

한 명이라도 상태가 바뀌면 탑 쌓기가 중단되고 기록(Record)으로 남습니다.

구현 포인트 (Tech Spec):

Backend: UserStatusService에서 상태 업데이트 시 상대방 상태 체크. 둘 다 같으면 SyncSession 시작 시간 기록.

Frontend: HomeScreen의 배경 레이어(Stack)에 SyncTotemWidget 배치. 실시간 타이머로 높이 렌더링.

2.3. 꿈의 기록 (Dream Log) - AI Narrative

두 사람이 잠든 사이에 AI가 생성해 주는 '우리만의 동화'입니다.

메커니즘 (Mechanism):

트리거: 두 사용자 모두 SLEEP 상태가 4시간 이상 지속될 때.

생성 로직:

RAG: 어제 나눈 대화 중 핵심 키워드/감정 추출 (예: '떡볶이', '힘든 과제').

LLM: "곰돌이 두 마리가 떡볶이 숲을 헤치고 과제 몬스터를 무찌르는 꿈" 시나리오 생성.

전달: 아침에 두 사용자가 모두 ONLINE이 되면 "꿈 일기가 도착했습니다" 알림 발송.

구현 포인트 (Tech Spec):

Backend (ai-service): rag_service.py에 generate_dream_log(couple_id) 메서드 추가.

Data: 벡터 DB(Pinecone)에서 최근 24시간 대화 쿼리 → Gemini에게 동화 프롬프트 전송.

2.4. 비트 월드 (Bit World) - [Implemented]

사용자의 라이프스타일이 펫이 사는 방(Room)의 인테리어로 반영됩니다.

메커니즘 (Mechanism):

지난주 UserStatus 통계를 기반으로 오브젝트 생성. (MVP: 현재 상태 기반 즉시 반영으로 구현됨)

STUDY 비중 높음 → 책상, 책가방, 안경, 커피.

BUSY 비중 높음 → 서류, 서류 가방, 넥타이, 구두.

SLEEP 비중 높음 → 포근한 침대, 달 무드등.

구현 포인트 (Tech Spec):

Backend: User Entity에 `decorationType` 필드 추가. 상태 변경 시 `updateDecorationType` 트리거.

Frontend: PixelPetPainter의 배경 그리기 로직(drawBackground) 확장. (StudyRoom, Office, Bedroom 구현 완료)

3. 기술 아키텍처 변경 사항 (Technical Changes)
3.1. Backend (Core Service)

Domain Model: Couple 엔티티에 level, currentXp, syncStartTime 필드 추가.

Event: UserStatusChangeEvent 발생 시 → GamificationService가 구독(Subscribe)하여 XP 계산 및 동기화 체크.

3.2. Backend (AI Service)

Endpoint: /api/v1/dream-log 생성 (Core Service의 스케줄러가 호출).

RAG Pipeline: 대화 내역 요약(Summarization) 및 스토리텔링(Storytelling) 전용 프롬프트 엔지니어링 필요.

3.3. App (Flutter)

Widget: PixelPet 위젯을 GamifiedPet으로 고도화 (레벨, 아이템, 배경 렌더링 포함).

Interaction: 펫 터치/드래그 제스처 감지하여 HapticFeedback 및 API 호출 연결.