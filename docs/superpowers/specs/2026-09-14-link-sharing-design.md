# 대본 링크 공유 설계

작성일: 2026-09-14 · 상태: 사용자 승인

## 목적

대본을 1대1로 편하게 주고받는다. 보내는 사람은 링크 하나를 메신저로 보내고, 받는 사람은 앱이 있으면 링크를 눌러 바로 가져오고, 없으면 웹에서 대본을 읽고 앱을 설치한다. 커뮤니티(공개 목록, 검색, 댓글)는 만들지 않는다.

## 정한 것

| 항목 | 결정 |
|---|---|
| 넣는 시점 | 첫 출시에 포함 |
| 방식 | 링크 (파일 전송이 아님) |
| 보내는 내용 | 작품명, 대화 형식 여부, 본문, 성별·나이대·태그, 노트(보낼 때 고름) |
| 보내지 않는 것 | 메모, 원본 사진, 연습 기록(녹음·영상), 내 역할, 즐겨찾기·모음 |
| 링크 수명 | 7일 뒤 자동 삭제, 보낸 사람은 그 전에 지울 수 있다 |
| 서버 | 기존 웹사이트(Astro, Vercel 프로젝트 `tacowasabii`, Hobby)에 서버 기능을 붙이고 저장은 Upstash Redis(Vercel Marketplace 무료 요금제) |
| 도메인 | `tacowasabii.vercel.app` (도메인을 바꾸면 앱 업데이트가 필요하다) |
| 링크 모양 | `https://tacowasabii.vercel.app/monologue/s/<ID>` |

## 구조와 흐름

```
[보내는 앱] --POST--> /api/monologue/shares --SET EX 7일--> [Upstash Redis]
     |  링크 + 삭제 비밀값
     v
 공유 시트(카톡 등) --링크--> [받는 사람]
                              |-- 앱 있음: App Links / Universal Links -> 앱이 GET /api/monologue/shares/<ID> -> 미리보기 -> 내 대본에 추가(기기 저장)
                              `-- 앱 없음/인앱 브라우저: /monologue/s/<ID> 웹 보기 -> 앱에서 열기 / 설치 버튼
```

- 받은 대본은 기기에 새 대본으로 저장되며, 저장 뒤에는 서버와 연결이 없다. 링크가 만료돼도 가져온 대본은 남는다.
- 보낸 사람은 앱 설정의 "보낸 링크"에서 7일 동안 링크를 복사하거나 지울 수 있다.

## 서버

### 저장

- 링크 ID: 암호학적 난수 16바이트를 base64url로 바꾼 22자. 삭제 비밀값: 난수 32바이트(base64url). 서버에는 비밀값의 SHA-256 해시만 저장한다.
- Redis 키 `monologue:share:<ID>`, 값은 JSON, `EX 604800`(7일).

```json
{
  "v": 1,
  "work": "새벽 세 시의 부엌",
  "dialogue": true,
  "body": "엄마: 이 시간에 뭐 하는 거야?\n수아: 물 마시러 나왔어.",
  "gender": "female",
  "ageRange": "thirties",
  "tags": ["가족", "갈등"],
  "note": null,
  "createdAt": "2026-09-14T13:00:00Z",
  "expiresAt": "2026-09-21T13:00:00Z",
  "deleteTokenHash": "<hex>"
}
```

- `gender`, `ageRange` 값은 앱의 `Gender`, `AgeRange` enum 이름을 그대로 쓴다. 서버는 알려진 값만 받는다.
- 입력 검사: `body`는 공백을 뺀 뒤 1자 이상 100,000자 이하, `note`는 20,000자 이하, `work`는 200자 이하, `tags`는 20개 이하·각 30자 이하, 요청 본문 전체 256KB 이하. 어기면 거절한다.

### API

| 요청 | 성공 | 실패 |
|---|---|---|
| `POST /api/monologue/shares` (JSON: 위 필드 중 `v`~`note`) | `201 {id, url, deleteToken, expiresAt}` | `400` 형식 오류, `413` 너무 큼, `429` 올리기 제한, `503` 저장소 오류 |
| `GET /api/monologue/shares/<ID>` | `200` 대본 JSON(`deleteTokenHash` 제외) | `404` 없음·만료(구분하지 않는다), `503` |
| `DELETE /api/monologue/shares/<ID>` (헤더 `Authorization: Bearer <deleteToken>`) | `204` | `403` 비밀값 불일치, `404`, `503` |

- 모든 API 응답과 웹 보기 페이지에 `Cache-Control: no-store`를 붙인다.
- 올리기 제한: IP를 SHA-256으로 해시한 값으로 `monologue:rl:<hash>:<floor(유닉스 초 / 3600)>` 카운터를 `INCR`하고 처음 만들 때 `EX 3600`을 건다. 1시간에 20개를 넘으면 `429`. 원래 IP는 저장하지 않는다. 가져오기·삭제는 제한하지 않는다.
- ID 형식(`^[A-Za-z0-9_-]{22}$`)이 아니면 Redis를 조회하지 않고 `404`.

### 웹 보기 페이지 `/monologue/s/<ID>`

- 요청마다 서버에서 그린다(`prerender = false`). 기존 페이지는 정적으로 둔다.
- 작품명, 태그, 본문(대화 대본은 인물별로 나눠 보여 준다), 노트, 남은 기간, "앱에서 열기"(`monologue://s/<ID>` — 카톡 인앱 브라우저처럼 같은 사이트 안에서 누른 링크로는 Universal Link가 앱을 열지 않으므로 앱 전용 주소를 쓴다), App Store·Google Play 설치 버튼. 스토어 주소가 아직 없으면 버튼 대신 "곧 출시돼요"를 보여 준다.
- 없거나 만료되면 "7일이 지나 사라졌거나 보낸 사람이 지운 링크예요" 페이지를 `404`로 보여 준다.
- `<meta name="robots" content="noindex">`와 `X-Robots-Tag: noindex`.
- 미리보기 메타: `og:title`은 작품명(없으면 본문 첫 줄), `og:description`은 "모노로그로 받은 대본 · 7일 뒤 사라져요". 본문은 미리보기에 넣지 않는다.
- 페이지 아래에 문제 링크 신고용 이메일을 적는다.

### 앱 링크 인증 파일

- `/.well-known/apple-app-site-association`: 팀 ID `3996SU7HLL`, 번들 ID `com.tacowasabii.monologue`, 경로 `/monologue/s/*`. `Content-Type: application/json`.
- `/.well-known/assetlinks.json`: 패키지 `com.tacowasabii.monologue`, SHA-256 지문 두 개 — 업로드 키 `6C:DB:D3:4B:C1:76:8C:D6:86:36:09:CE:4F:FC:00:7A:51:7D:85:13:0F:19:81:D3:50:B4:EB:80:BF:F5:37:C6`, Play 앱 서명 키(Play Console → 앱 무결성에서 받는다).

## 앱

### 보내기

- 대본 화면 ⋯ 메뉴에 "링크로 공유".
- 처음 한 번 안내 대화상자: "대본 글이 서버에 7일 동안 저장되고, 링크를 가진 사람은 누구나 볼 수 있어요." 확인해야 진행하고, 확인 여부는 SharedPreferences에 기억한다.
- 노트가 있으면 "노트도 함께 보낼까요?"(보내기 / 노트 빼고 보내기 / 취소).
- 올리는 동안 진행 표시. 성공하면 공유 시트에 `「작품명」 대본을 보냈어요\n<링크>`. 작품명이 없으면 본문 첫 줄을 쓴다. iPad에서는 누른 메뉴 버튼을 기준으로 공유 시트를 띄운다.
- 실패 안내: `413` → "대본이 너무 길어서 링크로 보낼 수 없어요", `429` → "잠시 뒤 다시 시도해 주세요", 연결 실패·`5xx` → "지금 링크를 만들 수 없어요. 인터넷 연결을 확인하고 다시 시도해 주세요".

### 받기

- `app_links`로 앱이 꺼진 상태에서 연 링크와 켜진 상태에서 받은 링크를 모두 받는다. `https://tacowasabii.vercel.app/monologue/s/<22자 ID>`와 `monologue://s/<22자 ID>`만 처리한다.
- 받은 대본 화면: 작품명, 성별·나이대·태그, 본문(대화 대본은 기존 `ScriptBody`로), 노트, "내 대본에 추가" 버튼.
- 추가하면 `ScriptRepository.create(ScriptDraft(...))`로 새 대본을 만들고 그 대본 화면으로 간다. 받은 ID와 만든 대본 id를 SharedPreferences에 기억해, 같은 링크를 다시 열면 "이미 추가한 대본이에요 · 열기"를 보여 준다(대본이 지워졌으면 다시 추가할 수 있다).
- 실패 안내: `404` → "7일이 지나 사라졌거나 보낸 사람이 지운 링크예요", 연결 실패 → "인터넷 연결을 확인해 주세요"(다시 시도 버튼).

### 보낸 링크 (설정 → 공유)

- SharedPreferences에 `[{id, url, deleteToken, work, expiresAt}]`를 JSON으로 저장한다. 데이터베이스 스키마는 바꾸지 않는다.
- 목록: 작품명, 남은 기간, 링크 복사, 지우기(서버 `DELETE` 성공 또는 `404`면 목록에서도 뺀다). 만료 시각이 지난 항목은 읽을 때 뺀다.
- 백업 파일에 넣지 않는다.

### 플랫폼 설정

- iOS: `ios/Runner/Runner.entitlements`에 `com.apple.developer.associated-domains` = `applinks:tacowasabii.vercel.app`, Xcode 프로젝트의 `CODE_SIGN_ENTITLEMENTS`에 연결. `Info.plist`에 URL 스킴 `monologue`와 `FlutterDeepLinkingEnabled` = NO(링크는 `app_links`가 받는다).
- Android: `MainActivity`에 `android:autoVerify="true"` 인텐트 필터(VIEW, DEFAULT, BROWSABLE, `https`, 호스트 `tacowasabii.vercel.app`, `pathPrefix` `/monologue/s/`), `monologue://s` 인텐트 필터, `flutter_deeplinking_enabled` = false 메타데이터.
- 새 패키지: `app_links`, `http`.

### 코드 단위

| 단위 | 하는 일 |
|---|---|
| `lib/share/share_payload.dart` | `ScriptDraft` ↔ 서버 JSON 변환, 받은 JSON 검사 |
| `lib/share/sent_link.dart` | 보낸 링크 한 건과 남은 날짜 계산 |
| `lib/share/share_client.dart` | 올리기·가져오기·지우기 HTTP 요청, 결과를 성공/없음/너무 큼/제한/실패로 나눈다 |
| `lib/share/share_link.dart` | URI가 공유 링크인지 판별하고 ID를 꺼낸다 |
| `lib/share/share_history.dart` | 보낸 링크 목록, 받은 ID 기억, 첫 공유 안내 확인 여부 |
| `lib/share/link_source.dart` | `app_links` 구독(테스트에서 가짜로 바꾼다) |
| `lib/ui/share/incoming_links.dart` | 링크가 오면 받은 대본 화면을 연다 |
| `lib/ui/share/…` | 보내기 흐름, 받은 대본 화면, 보낸 링크 화면 |

`AppServices`에 `ShareClient`, `ShareHistory`, `LinkSource`를 넣어 테스트에서 가짜로 바꿀 수 있게 한다.

## 개인정보 문서

공유 기능과 같은 빌드로 바꾼다.

- 개인정보처리방침: "링크로 공유할 때" 항목 — 보내는 항목, 7일 보관과 직접 삭제, 링크를 가진 사람은 볼 수 있음, 남용 방지용 IP 해시 1시간 사용, 처리 위탁(Vercel, Upstash)과 국외 이전(이전받는 자, 국가, 항목, 목적, 보유 기간; 저장 지역은 Upstash 설치 때 확인해 적는다). 기존 "외부로 보내지 않는다" 문구는 "공유를 누를 때만 보낸다"로 고친다.
- Google Play 데이터 보안: "앱 활동 → 기타 사용자 생성 콘텐츠" 수집함 추가 — 선택 사항, 제3자 공유 없음, 목적 앱 기능, 전송 중 암호화, 7일 뒤 자동 삭제.
- App Store 개인정보 라벨: "사용자 콘텐츠 – 기타 사용자 콘텐츠" 수집, 앱 기능, 신원과 연결하지 않음, 추적 없음.
- 스토어 설명과 소개 페이지의 "대본이 외부로 전송되지 않아요"를 공유 때만 보낸다는 내용으로 고친다.

## 테스트

- 웹사이트(vitest): 입력 검사 경계값, ID·비밀값 형식, 비밀값 해시 비교, 올리기 제한, 삭제 권한, 없는 ID `404`를 가짜 Redis로 확인한다. `astro build`가 통과하고 기존 페이지가 정적으로 남는지 확인한다. 배포 뒤 실제 주소로 올리기·가져오기·웹 보기·지우기를 한 번씩 확인한다.
- 앱: `share_payload` 변환 왕복, `share_link` 판별(다른 호스트·짧은 ID 거절), `share_client` 상태 코드별 결과(`MockClient`), `share_store` 만료 정리, 보내기 흐름(첫 안내, 노트 선택, 실패 안내), 받은 대본 화면(추가 → 대본 생성, 중복 안내, 만료 안내), 보낸 링크 지우기를 위젯·단위 테스트로 확인한다.
- 기기: iOS 시뮬레이터에서 `xcrun simctl openurl`로 링크 열기. Android 에뮬레이터는 다른 세션과 같이 쓰므로 사용 전에 확인받는다. 카톡에서 누르는 실제 흐름은 TestFlight와 Play 비공개 테스트 빌드로 확인한다.

## 순서

1. Upstash Redis 연결, 서버 API, 웹 보기 페이지, 앱 링크 인증 파일을 만들고 배포한다(Play 앱 서명 키 지문은 받는 대로 추가).
2. 앱 보내기·받기·보낸 링크를 만든다.
3. 개인정보처리방침, 스토어 설명, 데이터 보안·개인정보 라벨 답변을 바꾼다.
4. 새 빌드를 올린다.

## 범위 밖

공개 목록·검색·댓글, 계정·로그인, 사진·녹음 공유, 링크 기간 연장, 받은 대본의 원본 갱신, 커스텀 도메인.
