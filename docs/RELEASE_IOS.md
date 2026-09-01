# iOS 배포 체크리스트

App Store(TestFlight 포함) 배포를 위한 준비 항목. 코드로 처리한 것과, 콘솔·계정에서 사람이 해야 하는 것을 나눠 적는다.

---

## 코드에서 처리 완료 ✅

| 항목 | 처리 내용 | 파일 |
|------|-----------|------|
| 앱 표시 이름 | `Jigeum Yeogi` → **지금여기** (`CFBundleDisplayName`·`CFBundleName`) | `ios/Runner/Info.plist` |
| 기본 언어 | `CFBundleDevelopmentRegion = ko`, `CFBundleLocalizations = [ko]` | `ios/Runner/Info.plist` |
| 수출 규정(암호화) | `ITSAppUsesNonExemptEncryption = false` — 업로드마다 뜨던 수동 질문 제거 | `ios/Runner/Info.plist` |
| 화면 방향 | 세로 전용 고정 (iPhone·iPad 모두) + `UIRequiresFullScreen=true` — iPad 멀티태스킹 미지원 선언. 이게 없으면 업로드 검증(90474)에서 4방향을 요구한다 | `ios/Runner/Info.plist` |
| 푸시 환경 | Release 구성만 `aps-environment = production`, Debug·Profile은 `development` 유지 | `ios/Runner/RunnerRelease.entitlements` |
| 개인정보 매니페스트 | 트래킹 없음 + 수집 항목(이메일·이름·사용자ID·출결 기록) + UserDefaults 사유(CA92.1) 선언 | `ios/Runner/PrivacyInfo.xcprivacy` |
| 번들 ID | `com.example.jigeumYeogi` → **`com.diana.jigeumYeogi`** (RunnerTests 포함) | `ios/Runner.xcodeproj/project.pbxproj` |
| 앱 아이콘 | 브랜드 로고로 교체. 소스는 모서리 알파를 그라디언트로 메운 1024px 불투명 PNG | `assets/icon/app_icon.png` → `ios/Runner/Assets.xcassets/AppIcon.appiconset/` |
| 런치 스크린 | 기본 Flutter 로고 → 브랜드 로고(120pt), 배경을 앱 배경색 `#FAF7F2`로 | `LaunchImage.imageset/`, `Base.lproj/LaunchScreen.storyboard` |
| Firebase iOS 앱 | 새 번들 ID로 앱 생성(`1:901669927711:ios:296302245906de2e2bce2a`) + 설정 파일 교체 + `firebase_options.dart` 재생성 | `ios/Runner/GoogleService-Info.plist`, `lib/firebase_options.dart` |
| Android 아이콘 | adaptive icon — 배경 `#F8815D` + 전경(핀만 추출, 안전 영역 62%) | `assets/icon/app_icon_foreground.png` → `android/app/src/main/res/` |
| 앱 설명 | `pubspec.yaml` 기본 문구 → 실제 설명 | `pubspec.yaml` |
| 스모크 테스트 | 로그인 우선 진입 개편에 맞게 갱신(기존 실패 상태였음) | `test/widget_test.dart` |
| Android 매니페스트 | 표시 이름 `지금여기`, 세로 고정(`screenOrientation=portrait`) | `android/app/src/main/AndroidManifest.xml` |
| Android 런치 스플래시 | iOS와 동일하게 배경 `#FAF7F2` + 로고 120dp. 다크 모드에서도 라이트 유지 | `res/drawable*/launch_background.xml`, `res/values*/styles.xml`, `res/values/colors.xml` |
| 계정 삭제 안내 페이지 | Play 데이터 안전 섹션이 요구하는 웹 URL | `docs/account-deletion/index.html` |

### 아이콘 갱신 방법
`assets/icon/app_icon.png`(1024×1024, 알파 없음)를 교체한 뒤 `dart run flutter_launcher_icons` 실행. 설정은 `pubspec.yaml`의 `flutter_launcher_icons` 블록에 있다.
iOS 아이콘은 알파 채널·둥근 모서리가 있으면 심사에서 거절되므로 **불투명 정사각형**이어야 한다.

### Firebase 앱 구성
프로젝트 `jigeum-yeogi-25737`에 앱 2개. (옛 `com.example.*` 앱 2개와 macOS 타깃은 2026-08-31 정리)

| 앱 | 번들 ID / 패키지명 | 용도 |
|----|-------------------|------|
| `지금여기 (iOS)` | `com.diana.jigeumYeogi` | iOS 배포. APNs 키 업로드 완료 |
| `지금여기 (Android)` | `com.diana.jigeumYeogi` | Android 배포 |

설정 파일은 모두 `.gitignore` 대상이라 clone 후 재생성이 필요하다:
```
flutterfire configure --project=jigeum-yeogi-25737 \
  --platforms=android,ios \
  --ios-bundle-id=com.diana.jigeumYeogi \
  --android-package-name=com.diana.jigeumYeogi
```

### 푸시 환경 분리에 대한 참고
`Release` 구성은 `RunnerRelease.entitlements`(production)를 사용한다.
- 아카이브(`flutter build ipa` / Xcode Archive)는 Release라서 자동으로 production APNs를 쓴다.
- `flutter run --release`를 **개발용 프로비저닝으로 실기기에 직접 설치**하려 하면 서명이 맞지 않아 실패할 수 있다. 실기기 디버깅은 `flutter run`(Debug) 또는 `--profile`을 쓴다.

---

## 남은 작업 (배포 전 필수)

### 1. APNs 인증키 ✅ 완료
`AuthKey_Z6A3BQKQC2.p8`을 Firebase `지금여기 (iOS)` 앱에 업로드했다(2026-08-31). TestFlight 빌드에서 등하원 푸시 검증 가능.

### 2. Android — Play 배포

`applicationId`·`namespace`·Kotlin 패키지는 `com.diana.jigeumYeogi`로 통일됐고 Firebase Android 앱도 등록돼 있다. 아이콘·스플래시·세로 고정·한글 라벨까지 코드 쪽은 끝났다.

#### 2-1. 릴리즈 키스토어 ✅ 생성 완료 (2026-09-01)
- 키스토어: `~/jigeum-yeogi-upload.jks` (PKCS12, alias `upload`, CN=Jigeum Yeogi, 2054년까지 유효)
- 비밀번호: `android/key.properties`에만 있음(gitignore). **두 파일을 비밀번호 관리자·별도 저장소에 반드시 백업할 것** — 잃어버리면 Play 업로드 키 재설정 절차를 밟아야 한다.
- 검증: `flutter build appbundle --release` / `apk --release` 산출물 서명이 `CN=Jigeum Yeogi`.
- 다른 Mac에서 빌드하려면 두 파일을 같은 경로에 두거나 `key.properties`의 `storeFile`을 고친다.

Play는 **앱 서명 키를 Google이 관리**(Play App Signing)하고, 이 키스토어는 "업로드 키"가 된다. 첫 업로드 때 Play Console이 자동으로 등록한다.

#### 2-2. Play Console 준비물
- [ ] Google Play 개발자 계정 (1회 $25) → **앱 만들기** (이름 지금여기, 기본 언어 한국어, 앱, 무료)
- [ ] **개인정보처리방침 URL**: `https://diana-yjh.github.io/Jigeum_Yeogi/privacy/`
- [ ] **계정 삭제 URL** (데이터 안전 → 계정 삭제 요구사항): `https://diana-yjh.github.io/Jigeum_Yeogi/account-deletion/`
- [ ] **데이터 안전 설문** — 수집: 이메일·이름·사용자 ID·앱 활동(출결). 공유 없음, 전송 암호화, 삭제 요청 가능. `PrivacyInfo.xcprivacy`와 같은 내용
- [ ] 콘텐츠 등급 설문 (교육/유틸리티 — 전체이용가)
- [ ] 타겟층: 아동 대상 아님(이용자는 선생님·학부모). "어린이 및 가족" 프로그램 미참여
- [ ] 스토어 등록정보: 짧은 설명(80자), 전체 설명(4000자), **스크린샷 휴대전화 최소 2장**(16:9~9:16), **그래픽 이미지 1024×500** 필수, 아이콘 512×512(`assets/icon/app_icon.png` 축소)
- [ ] 심사용 테스트 계정(선생님/학부모) + 선생님 코드 — "앱 액세스" 섹션에 기입

#### 2-3. 업로드
```bash
flutter build appbundle --release        # build/app/outputs/bundle/release/app-release.aab
```
Play Console → 테스트 → **내부 테스트** → 새 버전 만들기 → AAB 업로드. 내부 테스트는 심사 없이 즉시 배포되며 이메일 목록으로 최대 100명. 프로덕션으로 갈 때는 **비공개 테스트 12명 × 14일** 요건(개인 개발자 계정, 2023-11 이후 생성)을 먼저 채워야 한다.

재업로드 시 `pubspec.yaml`의 빌드 번호(`+1`)를 올린다 — Play는 versionCode 중복을 거부한다.

### 3. App Store Connect 준비물
- [x] 앱 등록, 기본 언어 한국어
- [ ] **개인정보처리방침 URL** — 정본 `docs/privacy/index.html`. GitHub Pages(Settings → Pages → main `/docs`)를 켜면 `https://diana-yjh.github.io/Jigeum_Yeogi/privacy/` 로 열린다. 이 주소를 등록한다. 절차는 `docs/PRIVACY_POLICY.md`
- [ ] 앱 개인정보 보호(App Privacy) 설문 — `PrivacyInfo.xcprivacy`와 일치하게 작성
- [ ] 스크린샷: 6.9"(또는 6.7") 및 13" iPad — 세로
- [ ] 심사 메모: 테스트 계정 — 선생님 `review.teacher@jigeumyeogi.test` / `Review-Teacher-2026`, 학부모 `review.parent@jigeumyeogi.test` / `Review-Parent-2026`, 선생님 코드 `374512` (자세한 안내문은 `docs/PLAY_CONSOLE.md` 1번)
- [ ] 계정 삭제 경로 안내 — 설정 → 회원탈퇴 (App Store 필수 요건, 구현 완료됨)

---

## 빌드·업로드

```bash
flutter build ipa --release          # build/ios/ipa/지금여기.ipa
```

업로드(App Store Connect API 키 사용, 발급 완료):

```bash
# 검증 → 업로드. 키 파일은 ~/.appstoreconnect/private_keys/AuthKey_U2JSBK9MC7.p8 (gitignore 밖, 이 Mac에만 있음)
xcrun altool --validate-app --type ios -f build/ios/ipa/지금여기.ipa \
  --apiKey U2JSBK9MC7 --apiIssuer 750c4f01-77df-4f2f-ace6-b2a1eaee618d
xcrun altool --upload-app   --type ios -f build/ios/ipa/지금여기.ipa \
  --apiKey U2JSBK9MC7 --apiIssuer 750c4f01-77df-4f2f-ace6-b2a1eaee618d
```

- Key ID·Issuer ID는 비밀이 아니다. **`.p8` 파일만** 비밀 — 다른 Mac에서 하려면 App Store Connect에서 키를 새로 발급받는다(재다운로드 불가).
- `~/.appstoreconnect/private_keys/`에 `AuthKey_Z6A3BQKQC2.p8`도 있는데 이건 **APNs 키**(Firebase 푸시용)다. 업로드에는 쓰지 않는다.
- 대안: Transporter 앱에 IPA 드래그 앤 드롭.

### TestFlight 흐름
1. 업로드 후 App Store Connect → TestFlight 탭에서 빌드가 "처리 중" → 10~30분 뒤 사용 가능
2. 첫 빌드는 **수출 규정 준수 정보** 질문이 뜰 수 있다 → `ITSAppUsesNonExemptEncryption=false`를 넣어 뒀으므로 보통 자동 통과
3. **내부 테스터**(App Store Connect 사용자, 최대 100명)는 심사 없이 즉시 설치 가능. **외부 테스터**는 첫 빌드에 한해 간단한 베타 심사가 있다
4. 테스터는 TestFlight 앱(App Store에서 설치)으로 초대 메일의 링크를 열어 설치한다

버전은 `pubspec.yaml`의 `version: 1.0.0+1`에서 관리한다. 재업로드 시 빌드 번호(`+1`)를 반드시 올린다.

### 검증 완료 기록
- **TestFlight 업로드 성공 (2026-08-31)** — 1.0.0 (2), Delivery UUID `261d2514-e178-43fd-9356-d334e9b07347` (알림함·이름 수정·다자녀 달력·배경·오전/오후 표기 포함)
- TestFlight 업로드 성공 (2026-08-31) — 1.0.0 (1), Delivery UUID `77ac7bc4-a819-4ea0-8dee-9a6f831013b0`
- **`flutter build ipa --release` 성공 → `build/ios/ipa/지금여기.ipa` (30MB)**
  - 서명: `Apple Distribution: YeJin Hong (283MVWC922)`
  - 프로파일: `iOS Team Store Provisioning Profile: com.diana.jigeumYeogi`
  - 엔타이틀먼트: `aps-environment = production`, `get-task-allow = false`, `beta-reports-active = true`(TestFlight)
- `flutter build ios --release --no-codesign` 성공 (Runner.app 44.0MB)
- 산출물 확인: 번들 ID `com.diana.jigeumYeogi`, 표시 이름 `지금여기`, 세로 전용, `ITSAppUsesNonExemptEncryption=false`, `PrivacyInfo.xcprivacy` 번들 포함, AppIcon·LaunchImage 자산 카탈로그 반영
- `flutter build apk --release` 성공 — APK 패키지명 `com.diana.jigeumYeogi`, minSdk 24, adaptive icon 반영
- `flutter analyze` 이슈 0 / `flutter test` 통과
