# 개인정보처리방침

정본은 **`docs/privacy/index.html`** 한 곳에서만 관리한다. (이 문서에 내용을 중복해 두지 않는다 — 두 벌이 되면 어긋난다.)

## 공개 URL

App Store Connect와 Google Play는 공개 URL을 요구한다. GitHub Pages로 `docs/` 폴더를 서빙하면 별도 호스팅 없이 된다.

1. GitHub 저장소 → **Settings → Pages**
2. Source: *Deploy from a branch* / Branch: **main** / Folder: **/docs** → Save
3. 1~2분 뒤 아래 주소로 열린다:

```
https://diana-yjh.github.io/Jigeum_Yeogi/privacy/
```

이 주소를 App Store Connect(앱 정보 → 개인정보 처리방침 URL)와 Play Console(앱 콘텐츠 → 개인정보처리방침)에 등록한다.

> 저장소가 비공개로 바뀌면 Pages도 내려가므로, 그 경우 다른 호스팅으로 옮겨야 한다.

## 내용을 고칠 때

- 수집 항목·삭제 동작은 코드와 맞아야 한다. 기준: `firestore.rules`, `functions/index.js`(onUserDelete·onStudentDelete), `lib/models/*.dart`.
- 시행일·공고일(12조)을 함께 갱신한다. 이용자 권리에 중요한 변경은 30일 전 고지로 적어 두었다.
- `PrivacyInfo.xcprivacy`(iOS 개인정보 매니페스트)와 App Store Connect의 App Privacy 설문도 같은 내용이어야 한다.
