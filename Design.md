📝 ZZZ Design System v2.0
Codename: Soft Minimalism Core Value: Flat, Matte, & Cozy (평평하고, 매트하며, 포근한)

이 문서는 ZZZ 프로젝트의 UI/UX 디자인 원칙, 컬러 시스템, 컴포넌트 가이드라인 및 구현 예시를 정의합니다. 모든 개발 사항은 본 문서를 기준으로 진행합니다.

1. 디자인 철학 및 원칙 (Design Principles)
"도구로서의 명료함과 정서적 안정감의 균형" 불안을 해소하는 앱의 목적에 맞춰, 시각적 자극을 최소화하고 정보와 감성을 명확하게 전달합니다.

No Gradients (단색 원칙): 모든 요소는 그라데이션 없이 단색(Solid Color) 면으로 처리하여 눈의 피로를 줄입니다.

Soft Corners (부드러운 모서리): 날카로운 직각을 배제하고 24px 이상의 넉넉한 Corner Radius를 적용합니다.

Depth via Stroke (선과 면): 그림자(Shadow) 사용을 지양하고, **연한 테두리(Stroke)와 면(Surface)**의 색상 차이로 깊이감을 표현합니다.

2. 컬러 팔레트 (Color Palette: "Matte Pastels")
채도를 낮추고 명도를 높여 '종이' 질감을 주는 무광 파스텔 톤을 사용합니다.

🎨 테마 컬러 (Theme Colors)

구분	Day Mode (Light)	Night Mode (Dark)	용도
Background	#FAFAFA	#2D3436	전체 화면 배경 (순백색 지양)
Surface	#FFFFFF	#353B48	카드, 다이얼로그 배경
Border	#EEEEEE	#4A5568	영역 구분을 위한 연한 테두리
Text Primary	#2D3436	#FAFAFA	제목, 주요 내용
Text Secondary	#A0AEC0	#718096	보조 설명, 날짜
🚥 상태 컬러 (Status Semantics)

상태 아이콘, 텍스트, 도트 캐릭터 배경에 사용합니다.

🟣 Sleep (수면): #A29BFE (차분한 라벤더) - 안정감

🟢 Study (집중): #55EFC4 (부드러운 민트) - Text는 어둡게 처리하여 가독성 확보

🔴 Busy (바쁨): #FF7675 (파스텔 핑크) - 부드러운 경고

🔵 Online (활동): #74B9FF (소프트 스카이) - 활기

3. 아이콘 시스템: "Pixel Pets" (도트 디자인)
다마고치 감성을 현대적으로 재해석한 16x16 Grid 기반의 Pixel Art를 사용합니다. 이미지가 아닌 코드로 그리는 것을 원칙으로 합니다.

캐릭터 가이드라인

Grid: 16x16

Style: 외곽선 없는(Borderless) 단색 채우기.

States:

Online: 눈을 뜨고 미소 짓는 기본 표정 🐻

Sleep: 눈을 감고 'Zzz' 표현이 떠 있는 상태 💤

Busy/Study: 안경을 쓰거나 땀을 흘리는 상태 👓

구현 방식 (Flutter Widget)

CustomPainter를 사용하여 UserStatus에 따라 패턴을 동적으로 렌더링합니다. (별도 PixelPet 위젯 활용)

4. UI 컴포넌트 및 구조 (UI Components)
A. 홈 화면 (Home Screen) - "Clean Cards"

화면을 크게 두 개의 영역으로 분할하되, 그라데이션이 아닌 카드(Card) 형태로 구분합니다.

Layout:

Partner Card (Top): 화면의 55%. 하단 좌/우 모서리 라운딩. 파트너의 도트 캐릭터(Pixel Pet)를 크게 배치.

My Card (Bottom): 화면 하단에 떠 있는(Floating) 컨트롤 패널 형태. 내 상태 변경 버튼 포함.

Visual Style:

아이콘 뒤에는 Glow 효과 대신 원형 배경(Circle Avatar) 사용.

텍스트 위계: 닉네임(Bold, 28pt) > 상태 텍스트(Medium, 16pt).

Interaction:

Ripple 제거: 물결 효과 대신 버튼이 눌리는 Scale Down (95%) 애니메이션 적용.

Haptic: 탭 시 가벼운 진동 피드백 (HapticFeedback.lightImpact()).

B. 상태 변경 다이얼로그 - "Super-Ellipse Grid"

Shape: 일반 둥근 사각형보다 부드러운 스쿼클(Squircle) 형태 적용 (ContinuousRectangleBorder).

Selection Style:

Unselected: 흰색 배경 + 연한 회색 테두리.

Selected: 파스텔 톤 꽉 찬 배경(Solid Fill) + 흰색 아이콘/텍스트 + 테두리 없음.

Time Selector: 휠 스크롤 대신 Chip Group [ 30분 | 1시간 | 2시간 | 해제 ] 사용.

C. 채팅 화면 - "Paper Cut"

Background: 무늬 없는 단색 배경 (#FAFAFA or #F0F2F5).

Bubbles: 그림자(Shadow) 완전 제거.

Me: 짙은 회색 배경 + 흰색 글씨.

Partner: 흰색 배경 + 검은 글씨 + 연한 테두리.

AI Persona: 연한 라벤더 배경(#F3E5F5) + 짙은 보라색 글씨. (테두리 없음)

Recap (요약): 카드 형태가 아닌, 심플한 구분선(Divider) 텍스트로 처리.

Example: ----- 🌙 수면 중 발생한 대화 요약 -----

5. 구현 가이드 (Implementation Guide)
📐 Typography

깔끔하고 시원한 느낌을 위해 자간과 행간을 조정합니다.

Dart
TextStyle get baseTextStyle => TextStyle(
  fontFamily: 'Pretendard Rounded', // 또는 NanumSquareRounded
  color: Color(0xFF2D3436),
  letterSpacing: -0.5, // 자간을 좁혀 단단한 느낌
  height: 1.4,         // 행간을 넓혀 가독성 확보
);
📦 Card Decoration

그림자 대신 테두리(Border)를 우선 사용합니다.

Dart
BoxDecoration get cleanCardDecoration => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(32), // 넉넉한 라운딩
  border: Border.all(
    color: Color(0xFFEEEEEE), // 아주 연한 회색
    width: 1.5,
  ),
  // boxShadow: [] // 그림자 제거 원칙
);
🔳 Squircle Shape (스쿼클)

다이얼로그나 주요 버튼에 적용합니다.

Dart
ShapeDecoration get squircleDecoration => ShapeDecoration(
  color: Colors.white,
  shape: ContinuousRectangleBorder(
    borderRadius: BorderRadius.circular(40),
  ),
);
💫 Animations

Breathing: 홈 화면 캐릭터는 3초 주기로 살짝(5px) 위아래로 움직이는 '숨쉬기 애니메이션' 적용.

Hero: 홈 → 채팅 화면 전환 시 프로필/캐릭터에 Hero 위젯 필수 적용.

Design Checkpoint 개발 완료 후 다음 항목을 점검하세요.

[x] 화면에 그라데이션이 사용되지 않았는가?

[x] 그림자(Shadow) 대신 테두리(Border)로 구분감이 표현되었는가?

[x] 모든 모서리가 둥글게(24px+) 처리되었는가?

[x] 텍스트의 자간(-0.5)과 행간(1.4)이 적용되었는가?

[x] 캐릭터가 이미지가 아닌 코드로 그려진 Pixel Art인가?
## 6. 구현 현황 (Implementation Status) - 2026.01.20

### ✅ 완료된 작업 (Completed)
1. **Design System Foundation**
   - `lib/theme/colors.dart`: Matte Pastels 컬러 팔레트 구현 (#FAFAFA, #2D3436 등).
   - `lib/theme/text_styles.dart`: Typography 스타일 정의 (Google Fonts `M PLUS Rounded 1c` 적용).
   - `lib/theme/app_theme.dart`: Material3 테마에 Design System 적용.

2. **Core Components**
   - `CleanCard`: 그림자 제거, 테두리(Border) 기반의 카드 컴포넌트 구현.
   - `PixelPet`: 16x16 Pixel Art + **숨쉬기(Breathing) & 눈 깜빡임(Blink)** 애니메이션 구현.
   - `ScaleTap` / `CleanCard`: Scale Down (95%) 인터랙션 및 **Haptic Feedback** 적용 완료.
   - `StatusChangeDialog`: Squircle 형태, Chip Group Time Selector, Haptic Feedback 적용.
   - `LoadingDots`: 커스텀 로딩 애니메이션 및 Empty State 디자인 적용.

3. **Screen Refactoring**
   - **Home Screen**: 
     - Partner Card (Top 55%) + My Control Panel (Bottom 45%).
     - Safe Area (Notch) 대응 완료.
     - Localization (한글화) 및 Empty State (Pixel Pet + Call logic) 개선.
   - **Chat Screen**: 
     - "Paper Cut" 스타일 (No Shadow) & Styled Bubbles.
     - 메시지 빌더 로직 리팩토링 및 한글 날짜 포맷 적용.

### 🔜 진행 예정 작업 (Next Steps)
1. **Remaining Screens**
   - 로그인/회원가입 화면에 디자인 시스템 적용.
   - 커플 연결 화면(Connect Couple) UI 개선.
   - 런치 스크린(Splash) 디자인 적용.