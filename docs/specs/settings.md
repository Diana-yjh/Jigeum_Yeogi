# 설정 탭 (settings) — 공통(선생님/학부모)

`lib/features/settings/settings_screen.dart`

# 설정 화면 (학부모)

전제: `design/CLAUDE.md`의 토큰과 공통 컴포넌트를 쓴다.

## 목적

내 계정 확인, 연결된 아이/선생님 관리, 알림 on/off. 자주 오는 화면이 아니므로 조용하게.

## 레이아웃 (위→아래)

세로 스크롤 `ListView`. 좌우 패딩 16, 카드 간 간격 10. 섹션 라벨은 카드 위에 12 textSecondary, 좌측 4 들여쓰기, 위 4 / 아래 6 여백.

1. 타이틀 `설정` 20 / w600
2. 프로필 카드
3. 섹션 `우리 아이`
4. 섹션 `알림`
5. 기타 카드
6. 로그아웃 텍스트
7. `ParentTabBar` (설정 활성)

### 2. 프로필 카드

`AppCard`, 탭하면 프로필 편집(미구현이면 no-op, chevron은 유지).
- 좌: 지름 40 원, 배경 divider, 이름 첫 글자 w600 textSecondary (아이 아바타와 색을 다르게 — 부모는 회색, 아이는 오렌지)
- 중: 이름 14 / w600, 아래 `학부모 · a@gmail.com` 12 textSecondary, ellipsis
- 우: chevron 아이콘 textMuted
- 기존 "이름 / 역할 / 이메일" 3행 표 구조는 삭제.

### 2.5 선생님 (섹션)
학부모는 **선생님을 여러 명 연결**할 수 있고, 각 선생님에게 **닉네임**을 붙인다.

- 데이터: `users/{uid}.teachers` 맵 `{코드: 닉네임}`. 본인 문서라 보안 규칙 변경 없음.
  구버전 계정(`user.teacherCode`만 있음)은 저장하지 않고 화면에서 파생 병합(기본 닉네임 "선생님").
- 행: **구분색 도트(탭=색 선택 다이얼로그, `AppColors.teacherPalette` 8색)** + 닉네임 + 코드(모노, 탭=복사) + 연필(닉네임 수정) + 🔗해제. 색은 `users.teacherColors`에 저장하고 해제 시 함께 삭제.
- **연결 해제**는 그 선생님 반에 자녀가 남아 있으면 막고 안내 스낵바.
- "선생님 추가" 행 → 다이얼로그: 6자리 코드(존재 검증) + 닉네임(비우면 "선생님"). `authRepository.addTeacher`.
- 예전의 "선생님 코드 카드 + 코드 변경(자녀 전체 삭제)" 플로우는 삭제 — 다중 연결로 대체.

### 3. 우리 아이

`AppCard(padding: h12 v4)`. 행 높이 약 40, 행 사이 `divider` 1px 선(첫 행 제외).

| 행 | 좌 | 우 |
|---|---|---|
| 아이 | `ChildAvatar(size: 24)` + 이름 14 | 학원명 12 textSecondary |
| 선생님 코드 | `선생님 코드` 14 | 6자리 코드, 모노스페이스, onPrimaryTint. 탭하면 클립보드 복사 + 스낵바 `복사했어요` |
| 아이 추가 | `아이 추가` 14 | `+` 아이콘 textMuted. 탭하면 코드 입력 플로우 |

아이가 여러 명이면 아이 행이 반복된다. **선생님이 2명 이상이면** 아이 이름 옆에 소속 선생님 닉네임을 캡션으로 표시한다. `teacherCode`가 빈 아이(선생님이 내보냄)는 항상 "연결된 선생님 없음" 캡션을 표시하고, 파생 선생님 목록에 빈 코드는 넣지 않는다. 아이 추가 다이얼로그는 선생님이 여럿이면 드롭다운으로 선택, 하나면 캡션으로 안내.

### 4. 알림

`AppCard(padding: h12 v4)`. 각 행 좌 라벨 14, 우 `Toggle`.

| 라벨 | 기본값 | 키 |
|---|---|---|
| 등원 알림 | on | `notifyCheckIn` |
| 하원 알림 | on | `notifyCheckOut` |
| 선생님 채팅 | on | `notifyChat` |

토글 변경 즉시 Firestore 사용자 문서에 저장. 저장 실패 시 토글 원복 + 스낵바.
(목업에서는 채팅이 off로 그려져 있지만 기본값은 on. 데모 데이터일 뿐.)

### 5. 기타

`AppCard(padding: h12 v4)`.
- `앱 버전` / `1.0.0` 12 textSecondary (`package_info_plus`에서 읽기)
- `문의하기` / chevron. 탭하면 메일 앱 또는 링크.

### 6. 로그아웃

카드 없이 중앙 정렬 텍스트 12 textSecondary, 위 6 / 아래 2 여백. 탭하면 `AlertDialog`로 확인 후 로그아웃.
기존 화면 하단의 오렌지 테두리 큰 버튼은 삭제한다. 파괴적 액션은 눈에 덜 띄게.

## 데이터

```dart
class ParentProfile {
  final String name;
  final String email;
  final List<LinkedChild> children;
  final NotificationPrefs notify;
}
class LinkedChild {
  final String name;
  final String academyName;
  final String teacherCode; // 6자리 고정
}
```

## 하지 말 것

- 설정 화면에 오렌지 면 넣지 않는다. 오렌지는 토글 on 상태와 선생님 코드 글자색까지만.
- 행 안에 아이콘을 좌측에 나열하지 않는다(iOS 설정 앱 스타일 금지). 라벨 텍스트만.
- 빈 공간을 채우려고 섹션을 더 만들지 않는다. 이 화면은 짧아도 된다.
