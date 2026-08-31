# iOS 배포 체크리스트

App Store(TestFlight 포함) 배포를 위한 준비 항목. 코드로 처리한 것과, 콘솔·계정에서 사람이 해야 하는 것을 나눠 적는다.

---

## 코드에서 처리 완료 ✅

| 항목 | 처리 내용 | 파일 |
|------|-----------|------|
| 앱 표시 이름 | `Jigeum Yeogi` → **지금여기** (`CFBundleDisplayName`·`CFBundleName`) | `ios/Runner/Info.plist` |
| 기본 언어 | `CFBundleDevelopmentRegion = ko`, `CFBundleLocalizations = [ko]` | `ios/Runner/Info.plist` |
| 수출 규정(암호화) | `ITSAppUsesNonExemptEncryption = false` — 업로드마다 뜨던 수동 질문 제거 | `ios/Runner/Info.plist` |
| 화면 방향 | 세로 전용 고정 (iPhone·iPad 모두) | `ios/Runner/Info.plist` |
| 푸시 환경 | Release 구성만 `aps-environment = production`, Debug·Profile은 `development` 유지 | `ios/Runner/RunnerRelease.entitlements` |
| 개인정보 매니페스트 | 트래킹 없음 + 수집 항목(이메일·이름·사용자ID·출결 기록) + UserDefaults 사유(CA92.1) 선언 | `ios/Runner/PrivacyInfo.xcprivacy` |
| 번들 ID | `com.example.jigeumYeogi` → **`com.diana.jigeumYeogi`** (RunnerTests 포함) | `ios/Runner.xcodeproj/project.pbxproj` |
| 앱 아이콘 | 브랜드 로고로 교체. 소스는 모서리 알파를 그라디언트로 메운 1024px 불투명 PNG | `assets/icon/app_icon.png` → `ios/Runner/Assets.xcassets/AppIcon.appiconset/` |
| 런치 스크린 | 기본 Flutter 로고 → 브랜드 로고(120pt), 배경을 앱 배경색 `#FAF7F2`로 | `LaunchImage.imageset/`, `Base.lproj/LaunchScreen.storyboard` |
| Firebase iOS 앱 | 새 번들 ID로 앱 생성(`1:901669927711:ios:296302245906de2e2bce2a`) + 설정 파일 교체 + `firebase_options.dart` 재생성 | `ios/Runner/GoogleService-Info.plist`, `lib/firebase_options.dart` |
| Android 아이콘 | adaptive icon — 배경 `#F8815D` + 전경(핀만 추출, 안전 영역 62%) | `assets/icon/app_icon_foreground.png` → `android/app/src/main/res/` |
| 앱 설명 | `pubspec.yaml` 기본 문구 → 실제 설명 | `pubspec.yaml` |
| 스모크 테스트 | 로그인 우선 진입 개편에 맞게 갱신(기존 실패 상태였음) | `test/widget_test.dart` |

### 아이콘 갱신 방법
`assets/icon/app_icon.png`(1024×1024, 알파 없음)를 교체한 뒤 `dart run flutter_launcher_icons` 실행. 설정은 `pubspec.yaml`의 `flutter_launcher_icons` 블록에 있다.
iOS 아이콘은 알파 채널·둥근 모서리가 있으면 심사에서 거절되므로 **불투명 정사각형**이어야 한다.

### Firebase 앱 구성
프로젝트 `jigeum-yeogi-25737`에 앱이 4개 있다. **기존 2개는 지우지 말 것** — macOS 빌드가 옛 iOS 앱을 참조한다.

| 앱 | 번들 ID / 패키지명 | 쓰는 곳 |
|----|-------------------|---------|
| `지금여기 (iOS)` | `com.diana.jigeumYeogi` | **iOS 배포용 (현재)** |
| `지금여기 (Android)` | `com.diana.jigeumYeogi` | **Android 배포용 (현재)** |
| `jigeum_yeogi (ios)` | `com.example.jigeumYeogi` | macOS 빌드가 참조 중 |
| `jigeum_yeogi (android)` | `com.example.jigeum_yeogi` | 미사용(구 Android 앱) |

설정 파일은 모두 `.gitignore` 대상이라 clone 후 재생성이 필요하다:
```
flutterfire configure --project=jigeum-yeogi-25737 \
  --platforms=android,ios,macos \
  --ios-bundle-id=com.diana.jigeumYeogi \
  --macos-bundle-id=com.example.jigeumYeogi \
  --android-package-name=com.diana.jigeumYeogi
```

### 푸시 환경 분리에 대한 참고
`Release` 구성은 `RunnerRelease.entitlements`(production)를 사용한다.
- 아카이브(`flutter build ipa` / Xcode Archive)는 Release라서 자동으로 production APNs를 쓴다.
- `flutter run --release`를 **개발용 프로비저닝으로 실기기에 직접 설치**하려 하면 서명이 맞지 않아 실패할 수 있다. 실기기 디버깅은 `flutter run`(Debug) 또는 `--profile`을 쓴다.

---

## 남은 작업 (배포 전 필수)

### 1. APNs 인증키 업로드 ⛔ 푸시 차단
`flutter build ipa` 실행 시 Xcode 자동 서명이 App ID `com.diana.jigeumYeogi`와 배포 인증서·프로비저닝 프로파일을 만들었고, Push Notifications capability도 함께 켜졌다(IPA 엔타이틀먼트에 `aps-environment = production` 확인). 남은 건 APNs 키다.

1. Apple Developer → Keys → **APNs Auth Key(.p8)** 생성 (Key ID 기록, Team ID `283MVWC922`)
2. Firebase 콘솔 → 프로젝트 설정 → 클라우드 메시징 → **`지금여기 (iOS)` 앱**에 .p8 업로드
   ⚠️ iOS 앱이 두 개다. 기존 `jigeum_yeogi (ios)`가 아니라 **새로 만든 앱**에 올려야 한다

이게 없으면 릴리즈 빌드에서 등하원 푸시가 발송되지 않는다.

### 2. Android 남은 작업 (배포 시)
`applicationId`·`namespace`·Kotlin 패키지를 `com.diana.jigeumYeogi`로 통일하고 Firebase Android 앱도 새로 등록했다. 남은 건 Play 스토어 배포 시점의 작업이다.

- [ ] **릴리즈 서명 키스토어 생성** — Gradle 설정은 붙어 있다. `android/key.properties`가 있으면 그 키로, 없으면 디버그 키로 폴백한다(현재는 폴백 상태라 Play 업로드 불가).

  ```bash
  # 1) 키스토어 생성 — 비밀번호는 직접 입력한다. 잃어버리면 앱 업데이트가 영구히 불가하니 안전하게 보관할 것
  "/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/keytool" \
    -genkeypair -v -keystore ~/jigeum-yeogi-upload.jks \
    -storetype PKCS12 -keyalg RSA -keysize 2048 -validity 10000 -alias upload

  # 2) android/key.properties.example 을 복사해 값 채우기 (key.properties·*.jks 는 .gitignore 대상)
  cp android/key.properties.example android/key.properties

  # 3) 확인
  flutter build appbundle --release
  ```

### 3. App Store Connect 준비물
- [ ] 앱 등록(번들 ID 선택), 기본 언어 한국어
- [ ] **개인정보처리방침 URL** — 정본 `docs/privacy/index.html`. GitHub Pages(Settings → Pages → main `/docs`)를 켜면 `https://diana-yjh.github.io/Jigeum_Yeogi/privacy/` 로 열린다. 등록. 절차는 `docs/PRIVACY_POLICY.md`
- [ ] 앱 개인정보 보호(App Privacy) 설문 — `PrivacyInfo.xcprivacy`와 일치하게 작성
- [ ] 스크린샷: 6.9"(또는 6.7") 및 13" iPad — 세로
- [ ] 심사 메모: **선생님/학부모 테스트 계정**과 선생님 코드 제공 (계정 없으면 심사 진행 불가)
- [ ] 계정 삭제 경로 안내 — 설정 → 회원탈퇴 (App Store 필수 요건, 구현 완료됨)

---

## 빌드·업로드

```bash
flutter build ipa --release          # build/ios/ipa/지금여기.ipa
```

업로드는 둘 중 하나:
- **Transporter** 앱에 `build/ios/ipa/*.ipa` 드래그 앤 드롭
- `xcrun altool --upload-app --type ios -f build/ios/ipa/*.ipa --apiKey <KEY_ID> --apiIssuer <ISSUER_ID>`
  (App Store Connect → 사용자 및 액세스 → 통합 → App Store Connect API 키 발급 필요)

업로드 전에 App Store Connect에 앱 레코드가 먼저 등록되어 있어야 한다.

버전은 `pubspec.yaml`의 `version: 1.0.0+1`에서 관리한다. 재업로드 시 빌드 번호(`+1`)를 반드시 올린다.

### 검증 완료 기록
- **`flutter build ipa --release` 성공 → `build/ios/ipa/지금여기.ipa` (30MB)**
  - 서명: `Apple Distribution: YeJin Hong (283MVWC922)`
  - 프로파일: `iOS Team Store Provisioning Profile: com.diana.jigeumYeogi`
  - 엔타이틀먼트: `aps-environment = production`, `get-task-allow = false`, `beta-reports-active = true`(TestFlight)
- `flutter build ios --release --no-codesign` 성공 (Runner.app 44.0MB)
- 산출물 확인: 번들 ID `com.diana.jigeumYeogi`, 표시 이름 `지금여기`, 세로 전용, `ITSAppUsesNonExemptEncryption=false`, `PrivacyInfo.xcprivacy` 번들 포함, AppIcon·LaunchImage 자산 카탈로그 반영
- `flutter build apk --release` 성공 — APK 패키지명 `com.diana.jigeumYeogi`, minSdk 24, adaptive icon 반영
- `flutter analyze` 이슈 0 / `flutter test` 통과
