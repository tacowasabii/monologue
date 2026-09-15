# 모노로그 작업 안내

Flutter 앱 "모노로그"(com.tacowasabii.monologue)와 앱 사이트(`site/`, https://monologue.ink)를 함께 두는 저장소다.
사용자에게 보이는 답은 한국어로 쓴다.

## 앱 사이트 (`site/`)

- 소개 페이지(`/`), 개인정보처리방침(`/privacy`), 공유 대본 페이지(`/s/<ID>`), 공유 API(`/api/shares`), 앱 링크 파일(`/.well-known/…`), 테스트 APK(`/downloads/…`)가 모두 여기 있다.
- Astro + Vercel 프로젝트 `monologue`, 도메인 monologue.ink. 배포: `cd site && vercel --prod`
- **사이트만 고쳐도 배포에는 그 폴더의 `site/public/downloads/` APK가 함께 올라간다.** 이 APK는 git에 없어서 worktree에는 옛 파일이 남아 있기 쉽고, 그대로 배포하면 최신 테스트 APK를 덮어쓴다(2026-09-15 실제로 있었음). 배포 전에 `shasum -a 256`으로 `~/monologue/releases/<최신 버전>/monologue-android-test.apk`와 같은지 확인하고, 다르면 복사한 뒤 배포한다. 배포 후에도 받은 파일의 SHA-256으로 확인한다(버전이 달라도 크기가 같을 수 있어 content-length로는 모른다).
- 검증: `cd site && npm test` (빌드 + vitest)
- 개인 사이트 `~/website`(tacowasabii.vercel.app)에는 모노로그 코드가 없다. 옛 `/monologue…`, `/api/monologue/shares…` 주소를 monologue.ink로 넘기는 `vercel.json` 리다이렉트만 남아 있으니 모노로그 작업으로 건드리지 않는다.

## 테스트 APK

사용자에게 보이는 앱 변경을 main에 병합했으면 소개 페이지 APK도 함께 바꾼다.

1. `scripts/build-release.sh "바뀐 점 한 줄"`로 AAB와 테스트 APK를 만든다(아래 "출시 파일 보관").
2. `cp releases/<버전>/monologue-android-test.apk site/public/downloads/monologue-android-test.apk` (`.gitignore`로 git에서는 빠지지만, Vercel은 `.vercelignore`를 따르므로 배포에는 포함된다).
3. 크기가 바뀌었으면 `site/src/pages/index.astro`의 "APK …MB" 문구를 고친다.
4. `site/.vercel/project.json`의 `projectName`이 `monologue`인지 확인한다. 연결이 없거나 다르면 `vercel --prod --yes`가 새 프로젝트를 만들어 거기에 배포한다.
5. `cd site && vercel --prod` 후 `curl -sI https://monologue.ink/downloads/monologue-android-test.apk`로 content-length가 올린 파일 크기와 같은지 확인한다.

## 출시 파일 보관

스토어에 올리거나 배포할 AAB·APK·IPA는 이 저장소의 `releases/<pubspec 버전>/`(예: `releases/1.0.0+3/`)에 모은다. git에는 올리지 않는다(`.gitignore`).
worktree(`~/orca/workspaces/monologue/…`)의 `build/`는 세션이 끝나면 지워질 수 있으니, 어디서 빌드했든 main 체크아웃(`~/monologue`)의 `releases/`에 둔다.

- Android 출시 빌드는 `scripts/build-release.sh ["바뀐 점 한 줄"]`로 한다. 한 번에 하는 일:
  - 서명 키(`~/.monologue-keys/key.properties`)를 잠깐 넣었다가 뺀다.
  - `flutter build appbundle`, `flutter build apk --split-per-abi`
  - main 체크아웃의 `releases/<버전>/`에 `app-release.aab`(Play 업로드용), `monologue-android-test.apk`(arm64 테스트 APK)를 복사한다.
  - `BUILD.txt`에 날짜, 빌드한 곳, 커밋, versionCode, 서명 인증서, 파일별 SHA-256을 적는다.
  - worktree에서 실행해도 main 체크아웃의 `releases/`에 넣는다.
- 커밋하지 않은 변경이 있으면 멈춘다. `BUILD.txt`의 커밋과 파일 내용이 어긋나기 때문이다.
- 그 버전 폴더에 AAB가 이미 있으면 멈춘다. Play에 올린 versionCode는 다시 올릴 수 없으니 `pubspec.yaml`의 빌드 번호를 먼저 올린다. 올리지 않은 빌드를 다시 만들 때만 `--overwrite`를 붙인다.
- 스토어에 적은 출시 노트는 같은 폴더의 `release-notes.txt`에 남긴다.

## 공유 서버 주의

- Vercel 환경 변수 `SHARE_RATE_LIMIT_SECRET`(프로젝트 `monologue`)을 지우거나 바꾸지 않는다. 없으면 공유 올리기·보기·지우기가 모두 503이 된다. 비밀값과 Upstash 토큰은 출력하지 않는다.
- `site/astro.config.mjs`의 `security.checkOrigin: false`는 일부러 끈 것이다. 앱의 DELETE 요청에는 Origin이 없어서 켜면 403이 난다.
- 공유 주소를 바꿀 때는 함께 바꾼다: `lib/share/share_link.dart`(shareHost), `android/app/src/main/AndroidManifest.xml`, `ios/Runner/Runner.entitlements`, `site/public/.well-known/*`, `site/src/lib/share/http.ts`(SITE_ORIGIN), 설정 화면의 개인정보처리방침 주소, `docs/store-listing.md`.

## 앱

- 검증: `flutter analyze`, `flutter test`. 실제 OCR은 `flutter test integration_test/ocr_test.dart -d <기기>`, 네이티브 플러그인은 `integration_test/platform_test.dart`로 확인한다.
- 출시 빌드·버전 올리기는 `docs/release.md`, 스토어 문구는 `docs/store-listing.md`를 따른다.
- 서명 키는 저장소 밖 `~/.monologue-keys`에 있다. `android/key.properties`는 커밋하지 않는다.

## 여러 세션이 함께 쓸 때

- main 체크아웃과 worktree들이 에뮬레이터·시뮬레이터를 같이 쓴다. 설치·실행 전에 다른 세션이 쓰고 있는지 확인한다.
- drift 스키마 버전(`lib/data/database.dart`의 `schemaVersion`)과 `pubspec.yaml` 버전은 다른 브랜치와 겹치기 쉽다. 올리기 전에 main의 최신 값을 확인한다.
