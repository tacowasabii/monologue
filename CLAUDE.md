# 모노로그 작업 안내

Flutter 앱 "모노로그"(com.tacowasabii.monologue)와 앱 사이트(`site/`, https://monologue.ink)를 함께 두는 저장소다.
사용자에게 보이는 답은 한국어로 쓴다.

## 앱 사이트 (`site/`)

- 소개 페이지(`/`), 개인정보처리방침(`/privacy`), 공유 대본 페이지(`/s/<ID>`), 공유 API(`/api/shares`), 앱 링크 파일(`/.well-known/…`), 테스트 APK(`/downloads/…`)가 모두 여기 있다.
- Astro + Vercel 프로젝트 `monologue`, 도메인 monologue.ink. 배포: `cd site && vercel --prod`
- 검증: `cd site && npm test` (빌드 + vitest)
- 개인 사이트 `~/website`(tacowasabii.vercel.app)에는 모노로그 코드가 없다. 옛 `/monologue…`, `/api/monologue/shares…` 주소를 monologue.ink로 넘기는 `vercel.json` 리다이렉트만 남아 있으니 모노로그 작업으로 건드리지 않는다.

## 테스트 APK

사용자에게 보이는 앱 변경을 main에 병합했으면 소개 페이지 APK도 함께 바꾼다.

1. `cp ~/.monologue-keys/key.properties android/key.properties && flutter build apk --release --split-per-abi`, 끝나면 `rm android/key.properties`
2. `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`를 `site/public/downloads/monologue-android-test.apk`로 복사한다 (`.gitignore`로 git에서는 빠지지만, Vercel은 `.vercelignore`를 따르므로 배포에는 포함된다).
3. 크기가 바뀌었으면 `site/src/pages/index.astro`의 "APK …MB" 문구를 고친다.
4. `cd site && vercel --prod` 후 `curl -sI https://monologue.ink/downloads/monologue-android-test.apk`로 content-length를 확인한다.
5. 올린 APK를 아래 "출시 파일 보관" 폴더에도 복사한다.

## 출시 파일 보관

스토어에 올리거나 배포할 AAB·APK·IPA는 빌드한 폴더에 두지 않는다. worktree(`~/orca/workspaces/monologue/…`)의 `build/`는 세션이 끝나면 지워질 수 있고, 여러 폴더에 옛 파일이 섞여 헷갈린다.

- 어디서 빌드했든 `~/monologue-releases/<pubspec 버전>/`(예: `~/monologue-releases/1.0.0+2/`)에 복사한다. Play 업로드용은 `app-release.aab`, 테스트 APK는 `monologue-android-test.apk` 이름을 쓴다.
- 같은 폴더의 `BUILD.txt`에 빌드한 커밋, 날짜, versionCode, 파일별 SHA-256(`shasum -a 256`)을 적는다.
- 같은 버전을 다시 빌드하면 파일을 덮어쓰고 `BUILD.txt`도 고친다. 버전을 올렸으면 새 폴더를 만든다.

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
