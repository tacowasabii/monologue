# 출시 절차

## 준비된 것

- 번들 ID / applicationId: `com.tacowasabii.monologue`, 버전 `1.0.0+1` (`pubspec.yaml`)
- 앱 아이콘: `assets/icon/` → `dart run flutter_launcher_icons`
- Android 업로드 키: `~/.monologue-keys/upload-keystore.jks` + `key.properties` (저장소 밖, `android/key.properties`는 gitignore).
  **이 폴더를 안전한 곳(비밀번호 관리자, 외장 저장소)에 백업할 것.** 잃어버리면 Play Console에서 업로드 키 재설정을 요청해야 한다.
- 개인정보처리방침: https://tacowasabii.vercel.app/monologue/privacy
- 등록 문구: `docs/store-listing.md`

## 빌드

```bash
flutter test
flutter build appbundle --release          # build/app/outputs/bundle/release/app-release.aab
flutter build ipa --release                 # Apple 계정·서명 설정 후
```

## Apple App Store

1. [Apple Developer Program](https://developer.apple.com/programs/) 가입 (연 $99, 본인 인증에 며칠 걸릴 수 있음)
2. Certificates, Identifiers & Profiles → Identifiers에서 `com.tacowasabii.monologue` 등록
3. Xcode에서 `ios/Runner.xcworkspace` 열기 → Runner 타깃 → Signing & Capabilities → Team 선택, Automatically manage signing
4. App Store Connect → 새 앱 (이름 "모노로그", 기본 언어 한국어, 번들 ID 선택)
5. `flutter build ipa --release` → Transporter 앱 또는 `xcrun altool`로 업로드
6. TestFlight에서 iPhone과 iPad에 설치해 확인. iPad는 가로·세로 전환, 목록 옆에 대본이 열리는지, Split View·Slide Over로 창을 줄였을 때, 카메라 촬영, 백업 공유 시트 위치, 백업 복원을 본다
7. 등록 정보·스크린샷·개인정보 라벨("데이터를 수집하지 않음") 입력 → 심사 제출
   - 심사 메모: "로그인 없음. 사진 선택 또는 촬영 후 텍스트 인식. 모든 데이터는 기기에만 저장."

## Google Play

1. [Play Console](https://play.google.com/console) 개인 개발자 계정 생성 ($25 1회, 신원 확인)
2. 앱 만들기 → 이름 "모노로그", 무료, 앱
3. 앱 콘텐츠: 개인정보처리방침 URL, 광고 없음, 데이터 보안(ML Kit 진단 정보 때문에 "수집함" — 답은 `docs/store-listing.md`의 표), 콘텐츠 등급 설문, 타깃 연령
4. **Play 앱 서명** 사용(기본값). `app-release.aab` 업로드 → 업로드 키 인증서 자동 등록
5. 개인 계정은 프로덕션 출시 전에 **비공개 테스트** 요건이 있다(작성 시점 기준 테스터 12명 이상이 14일 연속 참여). 제출 시점의 Play Console 안내를 다시 확인할 것
6. 비공개 테스트 트랙에 테스터 초대 → 기간 충족 후 프로덕션 신청

## 참고

- 최소 버전: iOS 16.0(Apple Vision 한글 인식), Android는 Flutter 기본 minSdk.
- `app-release.aab`는 모든 CPU용이 들어 있어 약 76MB지만, Play가 기기별로 나눠 배포하므로 실제 다운로드는 훨씬 작다. iOS 앱은 약 21MB.
- 글자 인식은 네이티브 채널 `monologue/ocr`: Android `MainActivity.kt`(ML Kit 한글), iOS `AppDelegate.swift`(Vision). 실제 기기 확인은
  `flutter test integration_test/ocr_test.dart -d <기기 ID>`.

## 문제 해결

- iOS 시뮬레이터에서 "Unable to find a destination matching the provided destination specifier"가 나오면
  `ios/Flutter/Generated.xcconfig`에 `EXCLUDED_ARCHS[sdk=iphonesimulator*]=i386 arm64`가 남아 있는지 본다.
  arm64를 지원하지 않던 플러그인을 뺀 뒤 생기는 낡은 설정이다. `flutter build ios --simulator --debug --config-only`로 다시 만든다.
- Xcode가 "iOS 26.x is not installed"라고 하면 `xcodebuild -downloadPlatform iOS`.
- macOS의 `/usr/bin/keytool`, `jarsigner`는 Java가 없으면 아무것도 출력하지 않는다. Android Studio에 든 것을 쓴다:
  `"/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/jarsigner" -verify -verbose -certs app-release.aab`
- git worktree에서 릴리스 빌드할 때는 `android/key.properties`가 없으므로 `ln -s ~/.monologue-keys/key.properties android/key.properties`.

## 버전 올리기

`pubspec.yaml`의 `version: 1.0.1+2`처럼 이름과 빌드 번호를 함께 올린다(빌드 번호는 스토어마다 항상 증가).
