---
name: releasing
description: Use when TestFlight 업로드, Play용 AAB/APK 빌드, pubspec 빌드 번호 올리기, Firestore 보안 규칙 배포가 필요할 때 (altool, appbundle, firebase deploy)
---

# 배포 파이프라인

전체 체크리스트·계정 작업·이력은 `docs/RELEASE_IOS.md`(정본), Play 설문은 `docs/PLAY_CONSOLE.md`. 여기는 검증된 명령만.

## 순서

1. **빌드 번호 올리기** — `pubspec.yaml`의 `version: 1.0.0+N`에서 `+N` 증가 (TestFlight·Play 모두 중복 거부).
2. **iOS 빌드 → 검증 → 업로드** (ASC API 키는 이 Mac의 `~/.appstoreconnect/private_keys/AuthKey_U2JSBK9MC7.p8`):

```bash
flutter build ipa --release   # build/ios/ipa/오늘출석.ipa
xcrun altool --validate-app --type ios -f "build/ios/ipa/오늘출석.ipa" \
  --apiKey U2JSBK9MC7 --apiIssuer 750c4f01-77df-4f2f-ace6-b2a1eaee618d
xcrun altool --upload-app   --type ios -f "build/ios/ipa/오늘출석.ipa" \
  --apiKey U2JSBK9MC7 --apiIssuer 750c4f01-77df-4f2f-ace6-b2a1eaee618d
```

3. **Android AAB** (릴리즈 서명은 `android/key.properties` 존재 시 자동):

```bash
flutter build appbundle --release
cp build/app/outputs/bundle/release/app-release.aab ~/Downloads/오늘출석-1.0.0+N.aab
```

4. **기록** — 업로드 성공 시 Delivery UUID를 `docs/RELEASE_IOS.md`의 "검증 완료 기록"에 추가하고 pubspec과 함께 커밋.

- iOS 빌드 ~5분 + 업로드 + AAB까지 한 세션이면 백그라운드 한 명령으로 묶어 순차 실행(flutter 도구 락 때문에 병렬 금지).
- `AuthKey_Z6A3BQKQC2.p8`은 APNs(푸시)용 — 업로드에 쓰지 않는다.

## Firestore 보안 규칙 배포

- 규칙 수정은 **사용자에게 먼저 설명·확인** (CLAUDE.md 규칙).
- `firebase deploy`와 Management API 스크립트 실행은 자동 모드 분류기에 막히는 경우가 많다. 막히면 사용자에게 아래 한 줄을 직접 실행하도록 요청:

```
! firebase deploy --only firestore:rules --project jigeum-yeogi-25737
```

- 배포 전까지 새 규칙에 의존하는 쓰기는 앱에서 "문제가 발생했어요"(permission-denied)로 나타난다 — 코드 버그로 오진하지 말 것.
