# 출시 절차

## 준비된 것

- 번들 ID / applicationId: `com.tacowasabii.monologue`, 버전 `1.0.0+4` (`pubspec.yaml`)
- 앱 아이콘: `assets/icon/` → `dart run flutter_launcher_icons`
- Android 업로드 키: `~/.monologue-keys/upload-keystore.jks` + `key.properties` (저장소 밖, `android/key.properties`는 gitignore).
  **이 폴더를 안전한 곳(비밀번호 관리자, 외장 저장소)에 백업할 것.** 잃어버리면 Play Console에서 업로드 키 재설정을 요청해야 한다.
- 개인정보처리방침: https://monologue.ink/privacy
- 등록 문구: `docs/store-listing.md`

## 빌드

```bash
flutter test
scripts/build-release.sh "바뀐 점 한 줄"   # releases/<버전>/app-release.aab, monologue-android-test.apk, BUILD.txt
flutter build ipa --release                 # Apple 계정·서명 설정 후
```

Android는 `scripts/build-release.sh`가 서명 키 연결, AAB·APK 빌드, `releases/<버전>/`(main 체크아웃, git 제외)에 복사, `BUILD.txt`(커밋·versionCode·서명 인증서·SHA-256) 작성을 한 번에 한다.
스토어에는 그 폴더의 파일을 올리고, 출시 노트는 같은 폴더의 `release-notes.txt`에 남긴다(`CLAUDE.md`의 "출시 파일 보관").
이미 Play에 올린 버전이면 스크립트가 멈추니 아래 "버전 올리기"부터 한다.

## Apple App Store

1. [Apple Developer Program](https://developer.apple.com/programs/) 개인(Individual)으로 가입 (연 $99, Apple ID 2단계 인증 필요).
   iPhone의 Apple Developer 앱에서 가입하면 신분증 인증이 빠르다. 개인 계정은 스토어 판매자 이름에 본명이 나온다
2. Xcode → Settings → Accounts에 그 Apple ID 추가 → `ios/Runner.xcworkspace` → Runner 타깃 → Signing & Capabilities →
   Team을 유료 팀으로, Automatically manage signing. 번들 ID와 배포 인증서는 Xcode가 만든다.
   지금 들어 있는 `DEVELOPMENT_TEAM = 3996SU7HLL`이 유료 팀 ID와 같은지 확인할 것.
   App ID에 Associated Domains 기능(링크로 공유가 쓰는 Universal Link)이 켜져 있는지 확인한다. Automatically manage signing이면
   Xcode가 자동으로 추가하지만, 아카이브가 entitlements 오류로 실패하면 [Apple 개발자 포털](https://developer.apple.com/account/resources/identifiers/list)에서
   해당 App ID를 열어 Associated Domains을 직접 켠다
3. [App Store Connect](https://appstoreconnect.apple.com) → 앱 → 새로운 앱: iOS, 이름 "모노로그", 기본 언어 한국어, 번들 ID 선택, SKU `monologue-ios`.
   앱 이름은 스토어 전체에서 하나뿐이라 이미 쓰이면 "모노로그 - 독백 대본 노트"처럼 바꾼다
4. `flutter build ipa --release` → `open build/ios/archive/Runner.xcarchive` → Organizer에서 Distribute App → App Store Connect → Upload.
   `Info.plist`에 `ITSAppUsesNonExemptEncryption = false`가 있어 수출 규정 질문 없이 처리된다(10~30분)
5. TestFlight에서 iPhone과 iPad에 설치해 확인. iPad는 가로·세로 전환, 목록 옆에 대본이 열리는지, Split View·Slide Over로 창을 줄였을 때, 카메라 촬영, 백업 공유 시트 위치, 백업 복원을 본다.
   링크로 공유도 함께 본다: iPhone·iPad 각각에서 카카오톡·메모 앱에 붙인 `https://monologue.ink/s/…` 링크를 눌러
   앱이 열리는지(Universal Link), iPad에서 '링크로 공유' 시트가 뜨는 위치를 확인한다.
   **기기에서 링크 확인은 반드시 TestFlight(또는 release) 빌드로 한다** — Flutter 툴링 밖에서 실행한 iOS 디버그 빌드는
   app_links가 링크를 등록하지 않아 앱이 열리지 않는다
6. App Store Connect → 앱 개인정보 보호 페이지의 개인정보처리방침 URL을 `https://monologue.ink/privacy`로 맞춘다
7. 등록 정보 입력 (`docs/store-listing.md`)
   - 스크린샷: 6.9" iPhone 칸에 `docs/store-assets/ios-iphone-*.png`, 13" iPad 칸에 `ios-ipad-*.png`. iPad를 지원하므로 iPad 칸도 필수다
   - 앱 개인정보 보호 "사용자 콘텐츠 → 기타 사용자 콘텐츠" 수집(앱 기능, 신원과 연결하지 않음, 추적 없음 — 답은 docs/store-listing.md), 연령 등급 설문, 가격 무료
   - EU에 내면 디지털 서비스법(DSA) 거래자 여부를 답해야 한다. 거래자면 주소·전화번호가 공개되니, 싫으면 사용 가능 국가에서 EU를 뺀다
   - 심사 정보: 로그인 필요 없음. 메모 "로그인 없음. 사진 선택 또는 촬영 후 텍스트 인식. 대본은 기기에 저장되고, 대본 화면 ⋯ → 링크로 공유를 누른 대본만 7일 동안 서버에 저장됨. 받은 링크를 누르면 앱에서 '내 대본에 추가'로 가져옴." 심사 직전에 앱에서 만든 공유 링크 하나를 메모에 붙인다.
     **붙인 링크는 7일 뒤 만료되니, 제출할 때(재제출 포함)마다 새로 만들어 붙인다**
8. 버전 페이지에서 빌드 선택 → 심사에 추가 → 제출 (보통 1~2일). 거절 사유는 App Store Connect 메시지로 온다

iPad 지원(`TARGETED_DEVICE_FAMILY = "1,2"`)은 한 번 출시하면 이후 업데이트에서 뺄 수 없다.

## Google Play

1. [Play Console](https://play.google.com/console) 개인 개발자 계정 생성 ($25 1회, 신원 확인)
2. 앱 만들기 → 이름 "모노로그", 무료, 앱
3. 앱 콘텐츠: 개인정보처리방침 URL을 `https://monologue.ink/privacy`로 입력, 광고 없음, 데이터 보안(ML Kit 진단 정보와 링크 공유 때문에 "수집함" — 답은 `docs/store-listing.md`의 표), 콘텐츠 등급 설문, 타깃 연령
4. **Play 앱 서명** 사용(기본값). `app-release.aab` 업로드 → 업로드 키 인증서 자동 등록. 앱 서명 키 SHA-256은 웹사이트 `site/public/.well-known/assetlinks.json`에 이미 들어 있다(바뀌면 거기서 고치고 `cd site && vercel --prod`로 배포)
5. 개인 계정은 프로덕션 출시 전에 **비공개 테스트** 요건이 있다(작성 시점 기준 테스터 12명 이상이 14일 연속 참여). 제출 시점의 Play Console 안내를 다시 확인할 것
6. 비공개 테스트 빌드를 설치한 뒤 `adb shell pm get-app-links com.tacowasabii.monologue`로 `monologue.ink`이
   `verified`로 나오는지 확인한다(링크로 공유가 앱에서 바로 열리려면 필요하다). 아니라면 `site/public/.well-known/assetlinks.json` 배포와
   서명 키 SHA-256이 맞는지 다시 본다
7. Play Console → 앱 콘텐츠 → 개인정보처리방침의 URL을 `https://monologue.ink/privacy`로 갱신
8. 비공개 테스트 트랙에 테스터 초대 → 기간 충족 후 프로덕션 신청

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
- git worktree에서도 `scripts/build-release.sh`가 서명 키를 잠깐 넣었다가 빼고, 결과는 main 체크아웃의 `releases/`에 넣는다. 스크립트 없이 직접 빌드할 때만 `ln -s ~/.monologue-keys/key.properties android/key.properties`.

## 버전 올리기

`pubspec.yaml`의 `version: 1.0.1+2`처럼 이름과 빌드 번호를 함께 올린다(빌드 번호는 스토어마다 항상 증가).
