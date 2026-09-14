# 대본 링크 공유 — 앱 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 모노로그 앱에서 대본을 링크로 보내고, 받은 링크를 열어 내 대본으로 추가하고, 보낸 링크를 관리한다. 개인정보 문서도 함께 바꾼다.

**Architecture:** 서버 통신(`ShareClient`), 기기 기록(`ShareHistory`), 들어오는 링크(`LinkSource`)를 `AppServices`에 넣고, 화면은 `lib/ui/share/`에 둔다. 서버 계약은 서버 계획이 배포한 `https://tacowasabii.vercel.app/api/monologue/shares`다. 데이터베이스 스키마는 바꾸지 않고 기록은 SharedPreferences에 JSON으로 둔다.

**Tech Stack:** Flutter 3.47 / Dart 3.13, `http` ^1.6.0(`MockClient`로 테스트), `app_links` ^7.2.1, `share_plus` 13.3, `shared_preferences`(`SharedPreferencesAsync`), drift(스키마 8 그대로).

**Spec:** `docs/superpowers/specs/2026-09-14-link-sharing-design.md`

**선행 조건:** `docs/superpowers/plans/2026-09-14-link-sharing-server.md`가 끝나 운영 API가 동작한다(Task 9의 문서는 서버 계획의 `SHARE_DATA_LOCATION`을 읽는다).

**작업 저장소:** `/Users/tacowasabii/orca/workspaces/monologue/hagfish` (git worktree, 브랜치 `redesign-ui-polish`). Task 9는 `/Users/tacowasabii/website`도 고친다.

## Global Constraints

- 링크: `https://tacowasabii.vercel.app/monologue/s/<ID>`와 `monologue://s/<ID>`, ID 정규식 `^[A-Za-z0-9_-]{22}$`
- API 기본 주소: `https://tacowasabii.vercel.app/api/monologue/shares`
- 올리는 JSON: `{"v":1,"work","dialogue","body","gender","ageRange","tags","note"}` — `gender`·`ageRange`는 `Gender`·`AgeRange` enum `name`
- 보내지 않는 것: 메모, 원본 사진, 연습 기록, 내 역할, 즐겨찾기·모음
- 데이터베이스 스키마(`schemaVersion => 8`)를 바꾸지 않는다.
- SharedPreferences 키: `share.sent`, `share.received`, `share.noticeSeen`
- 화면 문구(그대로 쓴다):
  - 메뉴: `링크로 공유`
  - 첫 안내: 제목 `링크로 공유`, 본문 `대본 글이 서버에 7일 동안 저장되고, 링크를 가진 사람은 누구나 볼 수 있어요. 메모, 사진, 연습 기록은 보내지 않아요.`, 버튼 `취소`/`확인`
  - 노트 선택: 제목 `노트도 함께 보낼까요?`, 버튼 `취소`/`노트 빼고 보내기`/`함께 보내기`
  - 공유 시트 글: `「<제목>」 대본을 보냈어요\n<링크>`
  - 실패: `대본이 너무 길어서 링크로 보낼 수 없어요`, `잠시 뒤 다시 시도해 주세요`, `지금 링크를 만들 수 없어요. 인터넷 연결을 확인하고 다시 시도해 주세요`, `공유 화면을 열지 못했어요`
  - 받은 대본: 앱 바 `받은 대본`, 버튼 `내 대본에 추가`, `이미 추가한 대본이에요`(버튼 `열기`), `7일이 지나 사라졌거나 보낸 사람이 지운 링크예요`, `인터넷 연결을 확인해 주세요`(버튼 `다시 시도`), 남은 기간 `<n>일 뒤 링크가 사라져요. 추가한 대본은 계속 남아요.`
  - 보낸 링크: 앱 바·설정 줄 `보낸 링크`, 설정 설명 `7일 동안 링크를 복사하거나 지울 수 있어요`, 빈 목록 `7일 안에 보낸 링크가 없어요`, 남은 기간 `<n>일 뒤 사라져요`, 툴팁 `링크 복사`/`지우기`, 확인 제목 `이 링크를 지울까요?`, 본문 `받은 사람도 더 이상 열 수 없어요. 이미 추가한 대본은 받은 사람 기기에 남아요.`, 버튼 `취소`/`지우기`, 알림 `링크를 복사했어요`, `링크를 지웠어요`, `지우지 못했어요. 인터넷 연결을 확인해 주세요`
- 공유 Android 에뮬레이터·iOS 시뮬레이터는 다른 세션과 같이 쓴다. 기기에 설치·실행하는 단계는 컨트롤러가 사용자에게 확인받은 뒤에만 한다.
- 커밋 메시지 끝에 `Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>`. 태스크마다 커밋한다. main으로 합치는 것은 Task 10에서만.
- 매 태스크 끝에 `flutter analyze`가 `No issues found!`여야 한다.

## File Structure

| 파일 | 책임 |
|---|---|
| `lib/share/share_link.dart` | 서버 주소 상수, URI → 공유 ID |
| `lib/share/share_payload.dart` | `SharePayload`: 상세 → JSON, JSON → `ScriptDraft` |
| `lib/share/sent_link.dart` | `SentLink`, `daysLeft` |
| `lib/share/share_client.dart` | `ShareResult` 계열, `ShareClient` |
| `lib/share/share_history.dart` | 보낸 링크·받은 링크·첫 안내 기록 |
| `lib/share/link_source.dart` | `LinkSource`, `PlatformLinkSource`(app_links) |
| `lib/ui/share/share_script_flow.dart` | 보내기 흐름 함수 |
| `lib/ui/share/received_script_screen.dart` | 받은 대본 화면 |
| `lib/ui/share/sent_links_screen.dart` | 보낸 링크 화면 |
| `lib/ui/share/incoming_links.dart` | 링크가 오면 받은 대본 화면을 연다 |
| `lib/app_scope.dart`, `lib/main.dart`, `lib/app.dart` (수정) | 서비스 연결, 내비게이터 키 |
| `lib/ui/view/script_view_screen.dart` (수정) | ⋯ 메뉴 항목 |
| `lib/ui/settings/settings_screen.dart`, `lib/ui/settings/how_to_screen.dart` (수정) | 설정 줄, 사용법 |
| `test/ui/test_harness.dart`, `integration_test/platform_test.dart` (수정) | 새 서비스 |
| `android/app/src/main/AndroidManifest.xml`, `ios/Runner/Info.plist`, `ios/Runner/Runner.entitlements`, `ios/Runner.xcodeproj/project.pbxproj` | 앱 링크 |

---

### Task 1: 공유 링크 판별과 서버 JSON 형식

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/share/share_link.dart`
- Create: `lib/share/share_payload.dart`
- Create: `lib/share/sent_link.dart`
- Test: `test/share/share_link_test.dart`, `test/share/share_payload_test.dart`

**Interfaces:**
- Produces:
  - `const shareHost = 'tacowasabii.vercel.app'`, `final Uri shareApiBase`, `String? shareIdFromUri(Uri uri)`
  - `class SharePayload { const SharePayload({required String body, String? work, bool dialogue = false, Gender gender = Gender.any, AgeRange ageRange = AgeRange.any, List<String> tags = const [], String? note, DateTime? expiresAt}); factory SharePayload.fromDetail(ScriptDetail d, {required bool includeNote}); factory SharePayload.fromJson(Object? json); String get title; Map<String, Object?> toJson(); ScriptDraft toDraft(); }`
  - `class SentLink { const SentLink({required String id, required String url, required String deleteToken, required String title, required DateTime expiresAt}); Map<String, Object?> toJson(); static SentLink? tryFromJson(Object? json); }`
  - `int daysLeft(DateTime expiresAt, DateTime now)` — 1~7

- [ ] **Step 1: 의존성 추가**

```bash
cd /Users/tacowasabii/orca/workspaces/monologue/hagfish
flutter pub add app_links:^7.2.1 http:^1.6.0
```

Expected: `pubspec.yaml` `dependencies`에 `app_links: ^7.2.1`, `http: ^1.6.0`.

- [ ] **Step 2: 실패하는 테스트 작성**

`test/share/share_link_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:monologue/share/share_link.dart';

void main() {
  final id = 'Ab3_-${'x' * 17}';

  test('웹 링크와 앱 전용 주소에서 ID를 꺼낸다', () {
    expect(shareIdFromUri(Uri.parse('https://tacowasabii.vercel.app/monologue/s/$id')), id);
    expect(shareIdFromUri(Uri.parse('https://tacowasabii.vercel.app/monologue/s/$id/')), id);
    expect(shareIdFromUri(Uri.parse('monologue://s/$id')), id);
  });

  test('다른 주소나 모양이 다른 ID는 무시한다', () {
    expect(shareIdFromUri(Uri.parse('http://tacowasabii.vercel.app/monologue/s/$id')), isNull);
    expect(shareIdFromUri(Uri.parse('https://example.com/monologue/s/$id')), isNull);
    expect(shareIdFromUri(Uri.parse('https://tacowasabii.vercel.app/monologue/s/short')), isNull);
    expect(shareIdFromUri(Uri.parse('https://tacowasabii.vercel.app/monologue/privacy')), isNull);
    expect(shareIdFromUri(Uri.parse('https://tacowasabii.vercel.app/monologue/s/$id/extra')), isNull);
    expect(shareIdFromUri(Uri.parse('monologue://other/$id')), isNull);
  });

  test('API 주소', () {
    expect(shareApiBase.toString(), 'https://tacowasabii.vercel.app/api/monologue/shares');
  });
}
```

`test/share/share_payload_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:monologue/domain/enums.dart';
import 'package:monologue/share/sent_link.dart';
import 'package:monologue/share/share_payload.dart';

void main() {
  test('서버로 보낼 JSON은 버전과 enum 이름을 쓴다', () {
    const payload = SharePayload(
      body: '엄마: 뭐 해?',
      work: '새벽 세 시의 부엌',
      dialogue: true,
      gender: Gender.female,
      ageRange: AgeRange.fiftiesPlus,
      tags: ['가족'],
    );
    expect(payload.toJson(), {
      'v': 1,
      'work': '새벽 세 시의 부엌',
      'dialogue': true,
      'body': '엄마: 뭐 해?',
      'gender': 'female',
      'ageRange': 'fiftiesPlus',
      'tags': ['가족'],
      'note': null,
    });
  });

  test('받은 JSON을 읽어 새 대본 초안으로 만든다', () {
    final payload = SharePayload.fromJson({
      'v': 1,
      'work': '햄릿',
      'dialogue': false,
      'body': '사느냐 죽느냐',
      'gender': 'male',
      'ageRange': 'twenties',
      'tags': ['고전'],
      'note': '고뇌',
      'createdAt': '2026-09-14T12:00:00.000Z',
      'expiresAt': '2026-09-21T12:00:00.000Z',
    });
    expect(payload.expiresAt, DateTime.utc(2026, 9, 21, 12));
    final draft = payload.toDraft();
    expect(draft.work, '햄릿');
    expect(draft.body, '사느냐 죽느냐');
    expect(draft.gender, Gender.male);
    expect(draft.ageRange, AgeRange.twenties);
    expect(draft.tags, ['고전']);
    expect(draft.note, '고뇌');
    expect(draft.dialogue, isFalse);
    expect(draft.memo, isNull);
    expect(draft.myRole, isNull);
  });

  test('모르는 성별·나이대는 무관으로, 빈 작품명·노트는 없음으로 읽는다', () {
    final payload = SharePayload.fromJson(
        {'body': '대사', 'dialogue': false, 'tags': <Object?>[], 'gender': 'x', 'ageRange': 'y', 'work': ' ', 'note': ''});
    expect(payload.gender, Gender.any);
    expect(payload.ageRange, AgeRange.any);
    expect(payload.work, isNull);
    expect(payload.note, isNull);
    expect(payload.title, '대사');
  });

  test('형식이 틀리면 FormatException', () {
    expect(() => SharePayload.fromJson('x'), throwsFormatException);
    expect(() => SharePayload.fromJson({'body': ' ', 'dialogue': false, 'tags': <Object?>[]}), throwsFormatException);
    expect(() => SharePayload.fromJson({'body': 'a', 'dialogue': 'no', 'tags': <Object?>[]}), throwsFormatException);
    expect(() => SharePayload.fromJson({'body': 'a', 'dialogue': false, 'tags': [1]}), throwsFormatException);
  });

  test('보낸 링크 기록은 JSON으로 저장했다 읽을 수 있고, 망가진 값은 버린다', () {
    final link = SentLink(
      id: 'A' * 22,
      url: 'https://tacowasabii.vercel.app/monologue/s/${'A' * 22}',
      deleteToken: 'secret',
      title: '햄릿',
      expiresAt: DateTime.utc(2026, 9, 21, 12),
    );
    final back = SentLink.tryFromJson(link.toJson())!;
    expect(back.id, link.id);
    expect(back.url, link.url);
    expect(back.deleteToken, 'secret');
    expect(back.title, '햄릿');
    expect(back.expiresAt, link.expiresAt);
    expect(SentLink.tryFromJson({'id': 1}), isNull);
  });

  test('남은 날짜는 올림해서 1~7일로 센다', () {
    final now = DateTime.utc(2026, 9, 14, 12);
    expect(daysLeft(now.add(const Duration(days: 7)), now), 7);
    expect(daysLeft(now.add(const Duration(days: 3)), now), 3);
    expect(daysLeft(now.add(const Duration(hours: 1)), now), 1);
    expect(daysLeft(now.subtract(const Duration(hours: 1)), now), 1);
  });
}
```

- [ ] **Step 3: 실패 확인**

Run: `flutter test test/share/`
Expected: FAIL — `Error: Couldn't resolve the package 'monologue' ... share/share_link.dart` (파일 없음)

- [ ] **Step 4: 구현**

`lib/share/share_link.dart`:

```dart
/// 공유 링크와 공유 API가 있는 사이트. 바꾸면 앱 링크 설정(iOS 연결 도메인, Android 인텐트 필터)도 함께 바꾼다.
const shareHost = 'tacowasabii.vercel.app';

final shareApiBase = Uri.https(shareHost, '/api/monologue/shares');

final _shareId = RegExp(r'^[A-Za-z0-9_-]{22}$');

/// [uri]가 대본 공유 링크면 ID를 준다.
/// 메신저에서 누르는 `https://tacowasabii.vercel.app/monologue/s/<ID>`와
/// 웹 보기의 "앱에서 열기"가 여는 `monologue://s/<ID>`를 받는다.
String? shareIdFromUri(Uri uri) {
  final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  String? candidate;
  if (uri.scheme == 'https' && uri.host == shareHost && segments.length == 3 && segments[0] == 'monologue' && segments[1] == 's') {
    candidate = segments[2];
  } else if (uri.scheme == 'monologue' && uri.host == 's' && segments.length == 1) {
    candidate = segments[0];
  }
  return candidate != null && _shareId.hasMatch(candidate) ? candidate : null;
}
```

`lib/share/share_payload.dart`:

```dart
import '../data/script_repository.dart';
import '../domain/enums.dart';
import '../domain/script_draft.dart';

/// 링크로 주고받는 대본 내용. 메모, 사진, 연습 기록, 내 역할은 담지 않는다.
class SharePayload {
  const SharePayload({
    required this.body,
    this.work,
    this.dialogue = false,
    this.gender = Gender.any,
    this.ageRange = AgeRange.any,
    this.tags = const [],
    this.note,
    this.expiresAt,
  });

  factory SharePayload.fromDetail(ScriptDetail detail, {required bool includeNote}) {
    final s = detail.script;
    return SharePayload(
      body: s.body,
      work: s.work,
      dialogue: s.dialogue,
      gender: s.gender,
      ageRange: s.ageRange,
      tags: detail.tags,
      note: includeNote ? s.note : null,
    );
  }

  /// 서버 응답을 읽는다. 형식이 맞지 않으면 [FormatException].
  factory SharePayload.fromJson(Object? json) {
    if (json is! Map<String, Object?>) throw const FormatException('share');
    final body = json['body'];
    if (body is! String || body.trim().isEmpty) throw const FormatException('body');
    final dialogue = json['dialogue'];
    if (dialogue is! bool) throw const FormatException('dialogue');
    final tags = json['tags'];
    if (tags is! List || tags.any((t) => t is! String)) throw const FormatException('tags');
    String? text(String key) {
      final value = json[key];
      if (value == null) return null;
      if (value is! String) throw FormatException(key);
      return value.trim().isEmpty ? null : value;
    }

    final expires = json['expiresAt'];
    return SharePayload(
      body: body,
      work: text('work'),
      dialogue: dialogue,
      gender: Gender.values.asNameMap()[json['gender']] ?? Gender.any,
      ageRange: AgeRange.values.asNameMap()[json['ageRange']] ?? AgeRange.any,
      tags: tags.cast<String>(),
      note: text('note'),
      expiresAt: expires is String ? DateTime.tryParse(expires) : null,
    );
  }

  final String body;
  final String? work;
  final bool dialogue;
  final Gender gender;
  final AgeRange ageRange;
  final List<String> tags;
  final String? note;

  /// 서버에서 받은 대본에만 있다
  final DateTime? expiresAt;

  /// 작품명, 없으면 본문 첫 줄
  String get title => work ?? firstLineOf(body);

  Map<String, Object?> toJson() => {
        'v': 1,
        'work': work,
        'dialogue': dialogue,
        'body': body,
        'gender': gender.name,
        'ageRange': ageRange.name,
        'tags': tags,
        'note': note,
      };

  ScriptDraft toDraft() => ScriptDraft(
        body: body,
        work: work,
        dialogue: dialogue,
        gender: gender,
        ageRange: ageRange,
        tags: tags,
        note: note,
      );
}
```

`lib/share/sent_link.dart`:

```dart
import 'dart:math' as math;

/// 이 기기에서 보낸 공유 링크. [deleteToken]이 있어야 서버에서 지울 수 있다.
class SentLink {
  const SentLink({
    required this.id,
    required this.url,
    required this.deleteToken,
    required this.title,
    required this.expiresAt,
  });

  final String id;
  final String url;
  final String deleteToken;
  final String title;
  final DateTime expiresAt;

  Map<String, Object?> toJson() => {
        'id': id,
        'url': url,
        'deleteToken': deleteToken,
        'title': title,
        'expiresAt': expiresAt.toUtc().toIso8601String(),
      };

  static SentLink? tryFromJson(Object? json) {
    if (json is! Map<String, Object?>) return null;
    final id = json['id'];
    final url = json['url'];
    final token = json['deleteToken'];
    final title = json['title'];
    final expires = json['expiresAt'];
    if (id is! String || url is! String || token is! String || title is! String || expires is! String) return null;
    final expiresAt = DateTime.tryParse(expires);
    if (expiresAt == null) return null;
    return SentLink(id: id, url: url, deleteToken: token, title: title, expiresAt: expiresAt);
  }
}

/// 링크가 사라질 때까지 남은 날짜. 하루가 안 남아도 1일로, 링크 수명(7일)보다 크게 보이지 않게 한다.
int daysLeft(DateTime expiresAt, DateTime now) {
  final days = (expiresAt.difference(now).inMinutes / (24 * 60)).ceil();
  return math.max(1, math.min(7, days));
}
```

- [ ] **Step 5: 통과 확인**

Run: `flutter test test/share/ && flutter analyze`
Expected: PASS (9 tests), `No issues found!`

- [ ] **Step 6: 커밋**

```bash
git add pubspec.yaml pubspec.lock lib/share test/share
git commit -m "feat(share): link parsing and the share payload format

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: 공유 서버 클라이언트

**Files:**
- Create: `lib/share/share_client.dart`
- Test: `test/share/share_client_test.dart`

**Interfaces:**
- Consumes: Task 1 `shareApiBase`, `SharePayload`, `SentLink`
- Produces:
  - `sealed class ShareResult<T>`; `ShareOk<T>(T value)`, `ShareMissing<T>()`, `ShareTooLarge<T>()`, `ShareRateLimited<T>()`, `ShareFailed<T>()`
  - `class ShareClient { ShareClient(http.Client http, {Uri? base}); Future<ShareResult<SentLink>> upload(SharePayload payload); Future<ShareResult<SharePayload>> fetch(String id); Future<ShareResult<void>> delete(SentLink link); }`

- [ ] **Step 1: 실패하는 테스트 작성**

`test/share/share_client_test.dart`:

```dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:monologue/share/sent_link.dart';
import 'package:monologue/share/share_client.dart';
import 'package:monologue/share/share_payload.dart';

http.Response jsonResponse(Object? body, int status) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

void main() {
  final id = 'A' * 22;
  const payload = SharePayload(body: '사느냐 죽느냐', work: '햄릿', tags: ['고전']);

  test('올리면 링크 기록을 돌려준다', () async {
    late http.Request sent;
    final client = ShareClient(MockClient((request) async {
      sent = request;
      return jsonResponse({
        'id': id,
        'url': 'https://tacowasabii.vercel.app/monologue/s/$id',
        'deleteToken': 'secret',
        'expiresAt': '2026-09-21T12:00:00.000Z',
      }, 201);
    }));

    final result = await client.upload(payload);

    expect(sent.method, 'POST');
    expect(sent.url.toString(), 'https://tacowasabii.vercel.app/api/monologue/shares');
    expect(jsonDecode(sent.body), payload.toJson());
    final link = (result as ShareOk<SentLink>).value;
    expect(link.id, id);
    expect(link.deleteToken, 'secret');
    expect(link.title, '햄릿');
    expect(link.expiresAt, DateTime.utc(2026, 9, 21, 12));
  });

  test('올리기 실패는 이유별로 나눈다', () async {
    Future<ShareResult<SentLink>> uploadWith(int status) =>
        ShareClient(MockClient((_) async => http.Response('', status))).upload(payload);
    expect(await uploadWith(413), isA<ShareTooLarge<SentLink>>());
    expect(await uploadWith(429), isA<ShareRateLimited<SentLink>>());
    expect(await uploadWith(503), isA<ShareFailed<SentLink>>());
    final offline = ShareClient(MockClient((_) async => throw http.ClientException('offline')));
    expect(await offline.upload(payload), isA<ShareFailed<SentLink>>());
  });

  test('가져오기는 한글 본문을 그대로 읽고, 없으면 ShareMissing', () async {
    final client = ShareClient(MockClient((request) async {
      expect(request.url.path, '/api/monologue/shares/$id');
      return jsonResponse({'v': 1, 'work': null, 'dialogue': true, 'body': '민수: 안녕', 'gender': 'any', 'ageRange': 'any', 'tags': <String>[], 'note': null}, 200);
    }));
    final result = await client.fetch(id);
    expect((result as ShareOk<SharePayload>).value.body, '민수: 안녕');

    expect(await ShareClient(MockClient((_) async => http.Response('', 404))).fetch(id), isA<ShareMissing<SharePayload>>());
    expect(await ShareClient(MockClient((_) async => http.Response('{', 200))).fetch(id), isA<ShareFailed<SharePayload>>());
  });

  test('지우기는 비밀값을 Bearer로 보내고, 없는 링크는 ShareMissing', () async {
    final link = SentLink(id: id, url: 'u', deleteToken: 'secret', title: 't', expiresAt: DateTime.utc(2026, 9, 21));
    late http.Request sent;
    final ok = await ShareClient(MockClient((request) async {
      sent = request;
      return http.Response('', 204);
    })).delete(link);
    expect(ok, isA<ShareOk<void>>());
    expect(sent.method, 'DELETE');
    expect(sent.url.path, '/api/monologue/shares/$id');
    expect(sent.headers['Authorization'], 'Bearer secret');

    expect(await ShareClient(MockClient((_) async => http.Response('', 404))).delete(link), isA<ShareMissing<void>>());
    expect(await ShareClient(MockClient((_) async => http.Response('', 403))).delete(link), isA<ShareFailed<void>>());
  });
}
```

- [ ] **Step 2: 실패 확인**

Run: `flutter test test/share/share_client_test.dart`
Expected: FAIL — `share_client.dart` 없음

- [ ] **Step 3: 구현**

`lib/share/share_client.dart`:

```dart
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'sent_link.dart';
import 'share_link.dart';
import 'share_payload.dart';

sealed class ShareResult<T> {
  const ShareResult();
}

class ShareOk<T> extends ShareResult<T> {
  const ShareOk(this.value);
  final T value;
}

/// 링크가 없거나 7일이 지났거나 보낸 사람이 지웠다
class ShareMissing<T> extends ShareResult<T> {
  const ShareMissing();
}

class ShareTooLarge<T> extends ShareResult<T> {
  const ShareTooLarge();
}

class ShareRateLimited<T> extends ShareResult<T> {
  const ShareRateLimited();
}

/// 연결 실패, 서버 오류, 알아볼 수 없는 응답
class ShareFailed<T> extends ShareResult<T> {
  const ShareFailed();
}

class ShareClient {
  ShareClient(this._http, {Uri? base}) : _base = base ?? shareApiBase;

  final http.Client _http;
  final Uri _base;

  static const _timeout = Duration(seconds: 15);

  Uri _item(String id) => _base.replace(pathSegments: [..._base.pathSegments, id]);

  Future<ShareResult<SentLink>> upload(SharePayload payload) => _guard(() async {
        final res = await _http
            .post(_base, headers: {'Content-Type': 'application/json'}, body: jsonEncode(payload.toJson()))
            .timeout(_timeout);
        switch (res.statusCode) {
          case 201:
            final json = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, Object?>;
            return ShareOk(SentLink(
              id: json['id']! as String,
              url: json['url']! as String,
              deleteToken: json['deleteToken']! as String,
              title: payload.title,
              expiresAt: DateTime.parse(json['expiresAt']! as String),
            ));
          case 413:
            return const ShareTooLarge();
          case 429:
            return const ShareRateLimited();
          default:
            return const ShareFailed();
        }
      });

  Future<ShareResult<SharePayload>> fetch(String id) => _guard(() async {
        final res = await _http.get(_item(id)).timeout(_timeout);
        if (res.statusCode == 404) return const ShareMissing();
        if (res.statusCode != 200) return const ShareFailed();
        return ShareOk(SharePayload.fromJson(jsonDecode(utf8.decode(res.bodyBytes))));
      });

  Future<ShareResult<void>> delete(SentLink link) => _guard(() async {
        final res = await _http
            .delete(_item(link.id), headers: {'Authorization': 'Bearer ${link.deleteToken}'})
            .timeout(_timeout);
        return switch (res.statusCode) {
          204 => const ShareOk<void>(null),
          404 => const ShareMissing<void>(),
          _ => const ShareFailed<void>(),
        };
      });

  /// 연결 끊김, 시간 초과, 망가진 응답은 모두 실패로 본다
  Future<ShareResult<T>> _guard<T>(Future<ShareResult<T>> Function() run) async {
    try {
      return await run();
    } catch (_) {
      return ShareFailed<T>();
    }
  }
}
```

- [ ] **Step 4: 통과 확인**

Run: `flutter test test/share/ && flutter analyze`
Expected: PASS (13 tests), `No issues found!`

- [ ] **Step 5: 커밋**

```bash
git add lib/share/share_client.dart test/share/share_client_test.dart
git commit -m "feat(share): client for uploading, fetching and deleting shared scripts

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 3: 보낸 링크·받은 링크 기록

**Files:**
- Create: `lib/share/share_history.dart`
- Test: `test/share/share_history_test.dart`

**Interfaces:**
- Consumes: Task 1 `SentLink`
- Produces: `class ShareHistory { static Future<ShareHistory> load({DateTime Function() now}); List<SentLink> get sent; Future<void> addSent(SentLink link); Future<void> removeSent(String id); int? receivedScriptId(String shareId); Future<void> markReceived(String shareId, int scriptId); bool get noticeSeen; Future<void> markNoticeSeen(); }`

- [ ] **Step 1: 실패하는 테스트 작성**

`test/share/share_history_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:monologue/share/sent_link.dart';
import 'package:monologue/share/share_history.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

SentLink link(String id, DateTime expiresAt) =>
    SentLink(id: id, url: 'https://tacowasabii.vercel.app/monologue/s/$id', deleteToken: 't-$id', title: '대본 $id', expiresAt: expiresAt);

void main() {
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  test('보낸 링크는 다시 불러와도 남고, 최근 것부터, 만료된 것은 빠진다', () async {
    var now = DateTime.utc(2026, 9, 14);
    final history = await ShareHistory.load(now: () => now);
    await history.addSent(link('a', DateTime.utc(2026, 9, 21)));
    await history.addSent(link('b', DateTime.utc(2026, 9, 15)));

    final reloaded = await ShareHistory.load(now: () => now);
    expect(reloaded.sent.map((l) => l.id), ['b', 'a']);
    expect(reloaded.sent.first.deleteToken, 't-b');

    now = DateTime.utc(2026, 9, 16);
    expect(reloaded.sent.map((l) => l.id), ['a']);

    await reloaded.removeSent('a');
    expect((await ShareHistory.load(now: () => now)).sent, isEmpty);
  });

  test('받은 링크로 만든 대본 id와 첫 공유 안내 확인을 기억한다', () async {
    final history = await ShareHistory.load();
    expect(history.receivedScriptId('x'), isNull);
    expect(history.noticeSeen, isFalse);

    await history.markReceived('x', 42);
    await history.markNoticeSeen();

    final reloaded = await ShareHistory.load();
    expect(reloaded.receivedScriptId('x'), 42);
    expect(reloaded.noticeSeen, isTrue);
  });
}
```

- [ ] **Step 2: 실패 확인**

Run: `flutter test test/share/share_history_test.dart`
Expected: FAIL — `share_history.dart` 없음

- [ ] **Step 3: 구현**

`lib/share/share_history.dart`:

```dart
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'sent_link.dart';

/// 이 기기에서 보낸 링크, 받은 링크로 만든 대본, 첫 공유 안내 확인 여부를 기억한다. 백업 파일에는 넣지 않는다.
class ShareHistory {
  ShareHistory._(this._prefs, this._sent, this._received, this._noticeSeen, this._now);

  static const _sentKey = 'share.sent';
  static const _receivedKey = 'share.received';
  static const _noticeKey = 'share.noticeSeen';

  final SharedPreferencesAsync _prefs;
  final List<SentLink> _sent;
  final Map<String, int> _received;
  bool _noticeSeen;
  final DateTime Function() _now;

  static Future<ShareHistory> load({DateTime Function() now = DateTime.now}) async {
    final prefs = SharedPreferencesAsync();

    Object? decode(String? raw) {
      if (raw == null) return null;
      try {
        return jsonDecode(raw);
      } on FormatException {
        return null;
      }
    }

    final sentJson = decode(await prefs.getString(_sentKey));
    final sent = [
      if (sentJson is List)
        for (final item in sentJson) ?SentLink.tryFromJson(item),
    ];
    final receivedJson = decode(await prefs.getString(_receivedKey));
    final received = <String, int>{
      if (receivedJson is Map)
        for (final entry in receivedJson.entries)
          if (entry.key is String && entry.value is int) entry.key as String: entry.value as int,
    };
    return ShareHistory._(prefs, sent, received, (await prefs.getBool(_noticeKey)) ?? false, now);
  }

  /// 아직 만료되지 않은 보낸 링크, 최근 것부터
  List<SentLink> get sent {
    final now = _now();
    return [
      for (final link in _sent.reversed)
        if (link.expiresAt.isAfter(now)) link,
    ];
  }

  Future<void> addSent(SentLink link) async {
    final now = _now();
    _sent
      ..removeWhere((l) => !l.expiresAt.isAfter(now))
      ..add(link);
    await _saveSent();
  }

  Future<void> removeSent(String id) async {
    _sent.removeWhere((l) => l.id == id);
    await _saveSent();
  }

  int? receivedScriptId(String shareId) => _received[shareId];

  Future<void> markReceived(String shareId, int scriptId) async {
    _received[shareId] = scriptId;
    await _prefs.setString(_receivedKey, jsonEncode(_received));
  }

  bool get noticeSeen => _noticeSeen;

  Future<void> markNoticeSeen() async {
    _noticeSeen = true;
    await _prefs.setBool(_noticeKey, true);
  }

  Future<void> _saveSent() => _prefs.setString(_sentKey, jsonEncode([for (final l in _sent) l.toJson()]));
}
```

- [ ] **Step 4: 통과 확인**

Run: `flutter test test/share/ && flutter analyze`
Expected: PASS (15 tests), `No issues found!`

- [ ] **Step 5: 커밋**

```bash
git add lib/share/share_history.dart test/share/share_history_test.dart
git commit -m "feat(share): remember sent links, received links and the first-share notice

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 4: 서비스 연결(앱·테스트 하네스·기기 테스트)

**Files:**
- Create: `lib/share/link_source.dart`
- Modify: `lib/app_scope.dart`
- Modify: `lib/main.dart`
- Modify: `test/ui/test_harness.dart`
- Modify: `integration_test/platform_test.dart:160-172`

**Interfaces:**
- Consumes: Task 2 `ShareClient`, Task 3 `ShareHistory`
- Produces:
  - `abstract class LinkSource { Stream<Uri> get links; }`, `class PlatformLinkSource implements LinkSource`
  - `AppServices.shareClient`, `AppServices.shareHistory`, `AppServices.links`
  - 테스트용: `Harness.shareServer`(`FakeShareServer` — `handler`, `requests`, `client`), `Harness.links`(`FakeLinkSource` — `open(Uri)`), 최상위 함수 `http.Response jsonResponse(Object? body, int status)`

- [ ] **Step 1: 링크 소스**

`lib/share/link_source.dart`:

```dart
import 'package:app_links/app_links.dart';

/// 앱을 여는 링크. 테스트에서는 가짜로 바꾼다.
abstract class LinkSource {
  /// 앱이 꺼진 상태에서 링크로 켰을 때의 링크도 처음에 한 번 흘려보낸다.
  Stream<Uri> get links;
}

class PlatformLinkSource implements LinkSource {
  final _appLinks = AppLinks();

  @override
  Stream<Uri> get links => _appLinks.uriLinkStream;
}
```

- [ ] **Step 2: AppServices에 필드 추가**

`lib/app_scope.dart` import 목록에 추가:

```dart
import 'share/link_source.dart';
import 'share/share_client.dart';
import 'share/share_history.dart';
```

생성자 `required this.screen,` 다음 줄에 추가:

```dart
    required this.shareClient,
    required this.shareHistory,
    required this.links,
```

필드 `final ScreenAwake screen;` 다음 줄에 추가:

```dart
  final ShareClient shareClient;
  final ShareHistory shareHistory;
  final LinkSource links;
```

- [ ] **Step 3: main.dart 연결**

`lib/main.dart` import에 추가:

```dart
import 'package:http/http.dart' as http;

import 'share/link_source.dart';
import 'share/share_client.dart';
import 'share/share_history.dart';
```

(`package:` import는 기존 `package:flutter/services.dart` 아래, 상대 import는 기존 상대 import 목록의 알파벳 순서 자리에 둔다.) `screen: PlatformScreenAwake(),` 다음 줄에 추가:

```dart
      shareClient: ShareClient(http.Client()),
      shareHistory: await ShareHistory.load(),
      links: PlatformLinkSource(),
```

- [ ] **Step 4: 테스트 하네스**

`test/ui/test_harness.dart` import에 추가:

```dart
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:monologue/share/link_source.dart';
import 'package:monologue/share/share_client.dart';
import 'package:monologue/share/share_history.dart';
```

`class Harness` 위에 추가:

```dart
/// 공유 서버 대신 [handler]가 답한다. 받은 요청은 [requests]에 남긴다. 기본은 서버 오류(503).
class FakeShareServer {
  http.Response Function(http.Request request) handler = (_) => http.Response('', 503);
  final requests = <http.Request>[];

  late final MockClient client = MockClient((request) async {
    requests.add(request);
    return handler(request);
  });
}

/// 앱을 여는 링크를 테스트에서 직접 흘려보낸다
class FakeLinkSource implements LinkSource {
  final _controller = StreamController<Uri>.broadcast();

  @override
  Stream<Uri> get links => _controller.stream;

  void open(Uri uri) => _controller.add(uri);
}

http.Response jsonResponse(Object? body, int status) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
```

`Harness`를 다음처럼 바꾼다(기존 필드·인자는 그대로 두고 두 개를 더한다):

```dart
class Harness {
  Harness._(this.db, this.services, this.recorder, this.picker, this.screen, this.shareServer, this.links);

  final AppDatabase db;
  final AppServices services;
  final FakeRecorder recorder;
  final FakeMediaPicker picker;
  final FakeScreenAwake screen;
  final FakeShareServer shareServer;
  final FakeLinkSource links;
```

`create()` 안에서 `final screen = FakeScreenAwake();` 다음에:

```dart
    final shareServer = FakeShareServer();
    final links = FakeLinkSource();
```

`AppServices(` 인자 `screen: screen,` 다음에:

```dart
        shareClient: ShareClient(shareServer.client),
        shareHistory: await ShareHistory.load(),
        links: links,
```

`return Harness._(` 인자 끝 `screen,` 다음에 `shareServer,` `links,`를 추가한다.

- [ ] **Step 5: 기기 통합 테스트**

`integration_test/platform_test.dart` import에 추가:

```dart
import 'package:http/http.dart' as http;
import 'package:monologue/share/link_source.dart';
import 'package:monologue/share/share_client.dart';
import 'package:monologue/share/share_history.dart';
```

`AppServices(` 인자 `screen: PlatformScreenAwake(),` 다음에:

```dart
        shareClient: ShareClient(http.Client()),
        shareHistory: await ShareHistory.load(),
        links: PlatformLinkSource(),
```

- [ ] **Step 6: 전체 확인**

Run: `flutter analyze && flutter test`
Expected: `No issues found!`, `All tests passed!` (기존 157개 + Task 1~3의 15개)

- [ ] **Step 7: 커밋**

```bash
git add lib/share/link_source.dart lib/app_scope.dart lib/main.dart test/ui/test_harness.dart integration_test/platform_test.dart
git commit -m "feat(share): wire the share client, history and incoming links into app services

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 5: 대본 화면에서 링크로 공유

**Files:**
- Create: `lib/ui/share/share_script_flow.dart`
- Modify: `lib/ui/view/script_view_screen.dart` (⋯ 메뉴)
- Test: `test/ui/share_script_flow_test.dart`

**Interfaces:**
- Consumes: Task 1 `SharePayload.fromDetail`; Task 2 `ShareClient.upload`, `ShareResult`; Task 3 `ShareHistory.noticeSeen/markNoticeSeen/addSent`; Task 4 `Harness.shareServer`, `jsonResponse`
- Produces: `Future<void> shareScriptByLink(BuildContext context, ScriptDetail detail, {Rect? anchor})`

- [ ] **Step 1: share_plus 채널 이름 확인**

Run: `grep -n "MethodChannel(" -A2 ~/.pub-cache/hosted/pub.dev/share_plus_platform_interface-*/lib/method_channel/method_channel_share.dart; grep -n "'text'" ~/.pub-cache/hosted/pub.dev/share_plus_platform_interface-*/lib/method_channel/method_channel_share.dart`
Expected: 채널 `'dev.fluttercommunity.plus/share'`, 메서드 `'share'`, 인자 키 `'text'`. 다르면 아래 테스트의 채널·키를 실제 값으로 바꾼다.

- [ ] **Step 2: 실패하는 테스트 작성**

`test/ui/share_script_flow_test.dart`:

```dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:monologue/domain/script_draft.dart';
import 'package:monologue/ui/view/script_view_screen.dart';

import 'test_harness.dart';

const shareChannel = MethodChannel('dev.fluttercommunity.plus/share');

void main() {
  late List<MethodCall> shareCalls;

  setUp(() {
    shareCalls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(shareChannel, (call) async {
      shareCalls.add(call);
      return 'dev.fluttercommunity.plus/share/success';
    });
  });

  tearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(shareChannel, null));

  final id = 'A' * 22;

  Future<void> openShareMenu(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('링크로 공유'));
    await tester.pumpAndSettle();
  }

  testWidgets('처음 공유하면 안내를 보여 주고, 노트를 뺄지 고른 뒤 링크를 만들어 공유 시트에 넘긴다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    final scriptId = (await tester.runAsync(
      () => h.services.repo.create(const ScriptDraft(work: '갈매기', memo: '비공개 메모', body: '나는 갈매기', note: '호숫가')),
    ))!;
    h.shareServer.handler = (_) => jsonResponse({
          'id': id,
          'url': 'https://tacowasabii.vercel.app/monologue/s/$id',
          'deleteToken': 'secret',
          'expiresAt': DateTime.now().add(const Duration(days: 7)).toUtc().toIso8601String(),
        }, 201);

    await tester.pumpWidget(h.wrap(ScriptViewScreen(scriptId: scriptId)));
    await tester.pumpAndSettle();
    await openShareMenu(tester);

    expect(find.textContaining('7일 동안 저장'), findsOneWidget);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.text('노트도 함께 보낼까요?'), findsOneWidget);
    await tester.tap(find.text('노트 빼고 보내기'));
    await tester.pumpAndSettle();

    final body = jsonDecode(h.shareServer.requests.single.body) as Map<String, Object?>;
    expect(body['work'], '갈매기');
    expect(body['note'], isNull);
    expect(body.containsKey('memo'), isFalse);
    expect(h.services.shareHistory.noticeSeen, isTrue);
    expect(h.services.shareHistory.sent.single.id, id);
    final text = (shareCalls.single.arguments as Map)['text'] as String;
    expect(text, '「갈매기」 대본을 보냈어요\nhttps://tacowasabii.vercel.app/monologue/s/$id');
    await tester.runAsync(h.db.close);
  });

  testWidgets('안내를 이미 봤고 노트가 없으면 바로 올리고, 너무 길면 알려 준다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    await tester.runAsync(h.services.shareHistory.markNoticeSeen);
    final scriptId = (await tester.runAsync(() => h.services.repo.create(const ScriptDraft(work: '긴 대본', body: '대사'))))!;
    h.shareServer.handler = (_) => http.Response('', 413);

    await tester.pumpWidget(h.wrap(ScriptViewScreen(scriptId: scriptId)));
    await tester.pumpAndSettle();
    await openShareMenu(tester);

    expect(find.text('노트도 함께 보낼까요?'), findsNothing);
    expect(find.text('대본이 너무 길어서 링크로 보낼 수 없어요'), findsOneWidget);
    expect(shareCalls, isEmpty);
    expect(h.services.shareHistory.sent, isEmpty);
    await tester.runAsync(h.db.close);
  });

  testWidgets('서버에 닿지 못하면 다시 시도하라고 알려 준다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    await tester.runAsync(h.services.shareHistory.markNoticeSeen);
    final scriptId = (await tester.runAsync(() => h.services.repo.create(const ScriptDraft(body: '대사'))))!;

    await tester.pumpWidget(h.wrap(ScriptViewScreen(scriptId: scriptId)));
    await tester.pumpAndSettle();
    await openShareMenu(tester);

    expect(find.text('지금 링크를 만들 수 없어요. 인터넷 연결을 확인하고 다시 시도해 주세요'), findsOneWidget);
    await tester.runAsync(h.db.close);
  });
}
```

- [ ] **Step 3: 실패 확인**

Run: `flutter test test/ui/share_script_flow_test.dart`
Expected: FAIL — `find.text('링크로 공유')` 찾지 못함

- [ ] **Step 4: 보내기 흐름 구현**

`lib/ui/share/share_script_flow.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../app_scope.dart';
import '../../data/script_repository.dart';
import '../../share/share_client.dart';
import '../../share/share_payload.dart';

/// 대본 화면 ⋯ 메뉴의 "링크로 공유". [anchor]는 iPad에서 공유 시트를 띄울 자리.
Future<void> shareScriptByLink(BuildContext context, ScriptDetail detail, {Rect? anchor}) async {
  final services = AppScope.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final rootNavigator = Navigator.of(context, rootNavigator: true);
  void snack(String text) => messenger.showSnackBar(SnackBar(content: Text(text)));

  if (!services.shareHistory.noticeSeen) {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('링크로 공유'),
        content: const Text('대본 글이 서버에 7일 동안 저장되고, 링크를 가진 사람은 누구나 볼 수 있어요. 메모, 사진, 연습 기록은 보내지 않아요.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('확인')),
        ],
      ),
    );
    if (ok != true) return;
    await services.shareHistory.markNoticeSeen();
  }

  var includeNote = false;
  if (detail.script.note != null) {
    if (!context.mounted) return;
    final choice = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('노트도 함께 보낼까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('노트 빼고 보내기')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('함께 보내기')),
        ],
      ),
    );
    if (choice == null) return;
    includeNote = choice;
  }

  if (!context.mounted) return;
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PopScope(canPop: false, child: Center(child: CircularProgressIndicator())),
  );
  final result = await services.shareClient.upload(SharePayload.fromDetail(detail, includeNote: includeNote));
  rootNavigator.pop();

  switch (result) {
    case ShareOk(:final value):
      await services.shareHistory.addSent(value);
      try {
        await SharePlus.instance.share(ShareParams(
          text: '「${value.title}」 대본을 보냈어요\n${value.url}',
          sharePositionOrigin: anchor,
        ));
      } catch (_) {
        snack('공유 화면을 열지 못했어요');
      }
    case ShareTooLarge():
      snack('대본이 너무 길어서 링크로 보낼 수 없어요');
    case ShareRateLimited():
      snack('잠시 뒤 다시 시도해 주세요');
    case ShareMissing() || ShareFailed():
      snack('지금 링크를 만들 수 없어요. 인터넷 연결을 확인하고 다시 시도해 주세요');
  }
}
```

- [ ] **Step 5: ⋯ 메뉴에 항목 추가**

`lib/ui/view/script_view_screen.dart`:

1. import에 `import '../share/share_script_flow.dart';` 추가(상대 import 알파벳 순서 자리).
2. `_ScriptViewScreenState` 필드에 추가:

```dart
  /// iPad에서 공유 시트를 ⋯ 버튼 옆에 띄우려고 버튼 위치를 잰다
  final _menuKey = GlobalKey();
```

3. `PopupMenuButton<String>(` 바로 다음 줄에 `key: _menuKey,`를 추가한다.
4. `onSelected`의 `if (v == 'images') {` 앞에 추가:

```dart
                  if (v == 'share') {
                    final box = _menuKey.currentContext?.findRenderObject() as RenderBox?;
                    shareScriptByLink(context, d, anchor: box == null ? null : box.localToGlobal(Offset.zero) & box.size);
                    return;
                  }
```

5. `itemBuilder: (_) => [` 바로 다음 줄에 추가:

```dart
                  const PopupMenuItem(
                    value: 'share',
                    child: _MenuRow(icon: Icons.link_rounded, text: '링크로 공유'),
                  ),
```

- [ ] **Step 6: 통과 확인**

Run: `flutter test test/ui/share_script_flow_test.dart && flutter analyze && flutter test`
Expected: 새 3개 PASS, `No issues found!`, 전체 `All tests passed!`

- [ ] **Step 7: 커밋**

```bash
git add lib/ui/share/share_script_flow.dart lib/ui/view/script_view_screen.dart test/ui/share_script_flow_test.dart
git commit -m "feat(share): share a script by link from the script menu

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 6: 받은 링크 열기

**Files:**
- Create: `lib/ui/share/received_script_screen.dart`
- Create: `lib/ui/share/incoming_links.dart`
- Modify: `lib/app.dart`
- Test: `test/ui/received_script_screen_test.dart`

**Interfaces:**
- Consumes: Task 1 `shareIdFromUri`, `daysLeft`, `SharePayload.toDraft/title`; Task 2 `ShareClient.fetch`; Task 3 `receivedScriptId/markReceived`; Task 4 `AppServices.links`, `Harness.links.open`
- Produces: `class ReceivedScriptScreen extends StatefulWidget { const ReceivedScriptScreen({Key? key, required String shareId}); }`, `class IncomingLinks extends StatefulWidget { const IncomingLinks({Key? key, required GlobalKey<NavigatorState> navigatorKey, required Widget child}); }`, `MonologueApp`은 `StatefulWidget`(생성자 `const MonologueApp({Key? key})` 그대로)

- [ ] **Step 1: 실패하는 테스트 작성**

`test/ui/received_script_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:monologue/app.dart';
import 'package:monologue/app_scope.dart';
import 'package:monologue/ui/common/korean_text.dart';
import 'package:monologue/ui/share/received_script_screen.dart';
import 'package:monologue/ui/view/script_view_screen.dart';

import 'test_harness.dart';

void main() {
  final id = 'B' * 22;

  Map<String, Object?> hamlet() => {
        'v': 1,
        'work': '햄릿',
        'dialogue': false,
        'body': '사느냐 죽느냐',
        'gender': 'male',
        'ageRange': 'twenties',
        'tags': ['고전'],
        'note': '고뇌하는 왕자',
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'expiresAt': DateTime.now().add(const Duration(days: 7)).toUtc().toIso8601String(),
      };

  testWidgets('받은 대본을 보여 주고, 추가하면 내 대본이 되며, 같은 링크는 이미 추가했다고 알려 준다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    h.shareServer.handler = (_) => jsonResponse(hamlet(), 200);

    await tester.pumpWidget(h.wrap(ReceivedScriptScreen(shareId: id)));
    await tester.pumpAndSettle();
    expect(find.text(keepWords('햄릿')), findsOneWidget);
    expect(find.text(keepWords('사느냐 죽느냐')), findsOneWidget);
    expect(find.text(keepWords('고뇌하는 왕자')), findsOneWidget);
    expect(find.text('#고전'), findsOneWidget);
    expect(find.textContaining('일 뒤 링크가 사라져요'), findsOneWidget);

    await tester.tap(find.text('내 대본에 추가'));
    await tester.pumpAndSettle();
    expect(find.byType(ScriptViewScreen), findsOneWidget);
    final count = await tester.runAsync(() => h.services.repo.watchScriptCount().first);
    expect(count, 1);

    // 앞 화면에서 이동한 기록이 남지 않게 앱을 새로 만든다
    await tester.pumpWidget(KeyedSubtree(key: UniqueKey(), child: h.wrap(ReceivedScriptScreen(shareId: id))));
    await tester.pumpAndSettle();
    expect(find.text(keepWords('이미 추가한 대본이에요')), findsOneWidget);
    expect(h.shareServer.requests, hasLength(1));
    await tester.runAsync(h.db.close);
  });

  testWidgets('만료된 링크와 연결 실패를 구분해 알려 주고, 다시 시도할 수 있다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    h.shareServer.handler = (_) => http.Response('', 404);
    await tester.pumpWidget(h.wrap(ReceivedScriptScreen(shareId: id)));
    await tester.pumpAndSettle();
    expect(find.text(keepWords('7일이 지나 사라졌거나 보낸 사람이 지운 링크예요')), findsOneWidget);
    expect(find.text('내 대본에 추가'), findsNothing);

    h.shareServer.handler = (_) => http.Response('', 503);
    // 앞 화면에서 이동한 기록이 남지 않게 앱을 새로 만든다
    await tester.pumpWidget(KeyedSubtree(key: UniqueKey(), child: h.wrap(ReceivedScriptScreen(shareId: id))));
    await tester.pumpAndSettle();
    expect(find.text(keepWords('인터넷 연결을 확인해 주세요')), findsOneWidget);

    h.shareServer.handler = (_) => jsonResponse(hamlet(), 200);
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text(keepWords('사느냐 죽느냐')), findsOneWidget);
    await tester.runAsync(h.db.close);
  });

  testWidgets('앱이 공유 링크를 받으면 받은 대본 화면을 열고, 다른 링크는 무시한다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    await tester.pumpWidget(AppScope(services: h.services, child: const MonologueApp()));
    await tester.pumpAndSettle();

    h.links.open(Uri.parse('https://tacowasabii.vercel.app/monologue/privacy'));
    await tester.pumpAndSettle();
    expect(find.byType(ReceivedScriptScreen), findsNothing);

    h.links.open(Uri.parse('monologue://s/$id'));
    await tester.pumpAndSettle();
    expect(find.byType(ReceivedScriptScreen), findsOneWidget);
    await tester.runAsync(h.db.close);
  });
}
```

- [ ] **Step 2: 실패 확인**

Run: `flutter test test/ui/received_script_screen_test.dart`
Expected: FAIL — `received_script_screen.dart` 없음

- [ ] **Step 3: 받은 대본 화면**

`lib/ui/share/received_script_screen.dart`:

```dart
import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../domain/enums.dart';
import '../../share/sent_link.dart';
import '../../share/share_client.dart';
import '../../share/share_payload.dart';
import '../common/adaptive.dart';
import '../common/korean_text.dart';
import '../view/script_body.dart';
import '../view/script_view_screen.dart';

typedef _Loaded = ({int? existingScriptId, ShareResult<SharePayload>? result});

/// 받은 공유 링크의 대본을 보여 주고 내 대본으로 추가한다.
class ReceivedScriptScreen extends StatefulWidget {
  const ReceivedScriptScreen({super.key, required this.shareId});

  final String shareId;

  @override
  State<ReceivedScriptScreen> createState() => _ReceivedScriptScreenState();
}

class _ReceivedScriptScreenState extends State<ReceivedScriptScreen> {
  Future<_Loaded>? _loaded;
  bool _adding = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loaded ??= _load();
  }

  Future<_Loaded> _load() async {
    final services = AppScope.of(context);
    final existing = services.shareHistory.receivedScriptId(widget.shareId);
    // 이미 추가한 대본이 남아 있으면 서버에 묻지 않는다(지웠으면 다시 추가할 수 있다)
    if (existing != null && await services.repo.watchScript(existing).first != null) {
      return (existingScriptId: existing, result: null);
    }
    return (existingScriptId: null, result: await services.shareClient.fetch(widget.shareId));
  }

  void _openScript(int id) =>
      Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => ScriptViewScreen(scriptId: id)));

  Future<void> _add(SharePayload payload) async {
    final services = AppScope.of(context);
    setState(() => _adding = true);
    final id = await services.repo.create(payload.toDraft());
    await services.shareHistory.markReceived(widget.shareId, id);
    if (mounted) _openScript(id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('받은 대본')),
      body: FutureBuilder<_Loaded>(
        future: _loaded,
        builder: (context, snap) {
          final loaded = snap.data;
          if (loaded == null) return const Center(child: CircularProgressIndicator());
          final existing = loaded.existingScriptId;
          if (existing != null) {
            return _Message(
              icon: Icons.check_circle_outline_rounded,
              text: '이미 추가한 대본이에요',
              actionLabel: '열기',
              onAction: () => _openScript(existing),
            );
          }
          return switch (loaded.result!) {
            ShareOk(:final value) => _Preview(payload: value),
            ShareMissing() => const _Message(icon: Icons.link_off_rounded, text: '7일이 지나 사라졌거나 보낸 사람이 지운 링크예요'),
            _ => _Message(
                icon: Icons.wifi_off_rounded,
                text: '인터넷 연결을 확인해 주세요',
                actionLabel: '다시 시도',
                onAction: () => setState(() => _loaded = _load()),
              ),
          };
        },
      ),
      bottomNavigationBar: FutureBuilder<_Loaded>(
        future: _loaded,
        builder: (context, snap) {
          final result = snap.data?.result;
          if (snap.data?.existingScriptId != null || result is! ShareOk<SharePayload>) return const SizedBox.shrink();
          return SafeArea(
            child: Padding(
              padding: readablePadding(MediaQuery.sizeOf(context).width, const EdgeInsets.fromLTRB(20, 12, 20, 12)),
              child: FilledButton(
                onPressed: _adding ? null : () => _add(result.value),
                child: const Text('내 대본에 추가'),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.payload});

  final SharePayload payload;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final settings = AppScope.of(context).settings;
    final labels = [
      if (payload.gender != Gender.any) payload.gender.label,
      if (payload.ageRange != AgeRange.any) payload.ageRange.label,
      for (final t in payload.tags) '#$t',
    ];
    final expiresAt = payload.expiresAt;
    final note = payload.note;
    return ListView(
      padding: readablePadding(MediaQuery.sizeOf(context).width, const EdgeInsets.fromLTRB(24, 8, 24, 32)),
      children: [
        Text(keepWords(payload.title), style: theme.textTheme.headlineMedium?.copyWith(height: 1.3)),
        if (labels.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [for (final l in labels) Chip(label: Text(l), visualDensity: VisualDensity.compact)],
            ),
          ),
        if (expiresAt != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              '${daysLeft(expiresAt, DateTime.now())}일 뒤 링크가 사라져요. 추가한 대본은 계속 남아요.',
              style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        if (note != null)
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('노트', style: theme.textTheme.labelLarge?.copyWith(color: scheme.primary)),
                    const SizedBox(height: 6),
                    Text(keepWords(note), style: theme.textTheme.bodyMedium?.copyWith(height: 1.6)),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 24),
        ListenableBuilder(
          listenable: settings,
          builder: (context, _) => ScriptBody(
            body: payload.body,
            dialogue: payload.dialogue,
            fontSize: settings.fontSize,
            selectable: false,
          ),
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.actionLabel, this.onAction});

  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = actionLabel;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(keepWords(text), textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
            if (label != null) ...[
              const SizedBox(height: 16),
              FilledButton.tonal(onPressed: onAction, child: Text(label)),
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: 들어오는 링크와 앱 루트**

`lib/ui/share/incoming_links.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../share/share_link.dart';
import 'received_script_screen.dart';

/// 앱을 여는 공유 링크를 받아 받은 대본 화면을 연다.
class IncomingLinks extends StatefulWidget {
  const IncomingLinks({super.key, required this.navigatorKey, required this.child});

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  State<IncomingLinks> createState() => _IncomingLinksState();
}

class _IncomingLinksState extends State<IncomingLinks> {
  StreamSubscription<Uri>? _subscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _subscription ??= AppScope.of(context).links.links.listen(_open);
  }

  void _open(Uri uri) {
    if (!mounted) return;
    final id = shareIdFromUri(uri);
    if (id == null) return;
    final navigator = widget.navigatorKey.currentState;
    // 링크로 앱을 처음 켜면 첫 화면을 그리기 전에 링크가 올 수 있다
    if (navigator == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _open(uri));
      return;
    }
    navigator.push(MaterialPageRoute<void>(builder: (_) => ReceivedScriptScreen(shareId: id)));
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
```

`lib/app.dart` 전체:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'ui/home/home_screen.dart';
import 'ui/share/incoming_links.dart';
import 'ui/theme.dart';

class MonologueApp extends StatefulWidget {
  const MonologueApp({super.key});

  @override
  State<MonologueApp> createState() => _MonologueAppState();
}

class _MonologueAppState extends State<MonologueApp> {
  /// 공유 링크가 오면 어느 화면에 있든 받은 대본 화면을 올린다
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return IncomingLinks(
      navigatorKey: _navigatorKey,
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        title: '모노로그',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        locale: const Locale('ko'),
        supportedLocales: const [Locale('ko')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const HomeScreen(),
      ),
    );
  }
}
```

- [ ] **Step 5: 통과 확인**

Run: `flutter test test/ui/received_script_screen_test.dart && flutter analyze && flutter test`
Expected: 새 3개 PASS, `No issues found!`, 전체 `All tests passed!`

- [ ] **Step 6: 커밋**

```bash
git add lib/ui/share/received_script_screen.dart lib/ui/share/incoming_links.dart lib/app.dart test/ui/received_script_screen_test.dart
git commit -m "feat(share): open shared links and add the received script

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 7: 보낸 링크 화면, 설정 줄, 사용법

**Files:**
- Create: `lib/ui/share/sent_links_screen.dart`
- Modify: `lib/ui/settings/settings_screen.dart` (`section('정보')` 앞)
- Modify: `lib/ui/settings/how_to_screen.dart` (백업 항목 앞)
- Modify: `test/ui/how_to_screen_test.dart`
- Test: `test/ui/sent_links_screen_test.dart`

**Interfaces:**
- Consumes: Task 1 `SentLink`, `daysLeft`; Task 2 `ShareClient.delete`; Task 3 `ShareHistory.sent/addSent/removeSent`
- Produces: `class SentLinksScreen extends StatefulWidget { const SentLinksScreen({Key? key}); }`

- [ ] **Step 1: 실패하는 테스트 작성**

`test/ui/sent_links_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:monologue/share/sent_link.dart';
import 'package:monologue/ui/common/korean_text.dart';
import 'package:monologue/ui/share/sent_links_screen.dart';

import 'test_harness.dart';

void main() {
  final id = 'C' * 22;
  SentLink hamlet() => SentLink(
        id: id,
        url: 'https://tacowasabii.vercel.app/monologue/s/$id',
        deleteToken: 'secret',
        title: '햄릿',
        expiresAt: DateTime.now().add(const Duration(days: 3)),
      );

  testWidgets('보낸 링크를 남은 기간과 함께 보여 주고, 복사할 수 있다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    await tester.runAsync(() => h.services.shareHistory.addSent(hamlet()));
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));

    await tester.pumpWidget(h.wrap(const SentLinksScreen()));
    await tester.pumpAndSettle();
    expect(find.text('햄릿'), findsOneWidget);
    expect(find.text('3일 뒤 사라져요'), findsOneWidget);

    await tester.tap(find.byTooltip('링크 복사'));
    await tester.pumpAndSettle();
    expect(copied, 'https://tacowasabii.vercel.app/monologue/s/$id');
    expect(find.text('링크를 복사했어요'), findsOneWidget);
    await tester.runAsync(h.db.close);
  });

  testWidgets('지우면 서버에서 지우고 목록에서도 빼며, 실패하면 남겨 둔다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    await tester.runAsync(() => h.services.shareHistory.addSent(hamlet()));
    await tester.pumpWidget(h.wrap(const SentLinksScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('지우기'));
    await tester.pumpAndSettle();
    expect(find.text('이 링크를 지울까요?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, '지우기'));
    await tester.pumpAndSettle();
    expect(find.text('지우지 못했어요. 인터넷 연결을 확인해 주세요'), findsOneWidget);
    expect(find.text('햄릿'), findsOneWidget);

    h.shareServer.handler = (_) => http.Response('', 204);
    await tester.tap(find.byTooltip('지우기'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '지우기'));
    await tester.pumpAndSettle();
    expect(find.text(keepWords('7일 안에 보낸 링크가 없어요')), findsOneWidget);
    expect(h.shareServer.requests.last.method, 'DELETE');
    expect(h.shareServer.requests.last.headers['Authorization'], 'Bearer secret');
    expect(h.services.shareHistory.sent, isEmpty);
    await tester.runAsync(h.db.close);
  });
}
```

`test/ui/how_to_screen_test.dart`의 제목 목록에서 `'몰입 읽기',`와 `'기기를 바꿀 때는 백업',` 사이에 `'링크로 대본 보내기',`를 넣는다.

- [ ] **Step 2: 실패 확인**

Run: `flutter test test/ui/sent_links_screen_test.dart test/ui/how_to_screen_test.dart`
Expected: FAIL — `sent_links_screen.dart` 없음, 사용법에 `링크로 대본 보내기` 없음

- [ ] **Step 3: 보낸 링크 화면**

`lib/ui/share/sent_links_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_scope.dart';
import '../../share/sent_link.dart';
import '../../share/share_client.dart';
import '../common/adaptive.dart';
import '../common/korean_text.dart';

/// 설정 → 보낸 링크. 7일 동안 링크를 다시 복사하거나 먼저 지운다.
class SentLinksScreen extends StatefulWidget {
  const SentLinksScreen({super.key});

  @override
  State<SentLinksScreen> createState() => _SentLinksScreenState();
}

class _SentLinksScreenState extends State<SentLinksScreen> {
  final _deleting = <String>{};

  void _snack(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _copy(SentLink link) async {
    await Clipboard.setData(ClipboardData(text: link.url));
    if (mounted) _snack('링크를 복사했어요');
  }

  Future<void> _delete(SentLink link) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('이 링크를 지울까요?'),
        content: const Text('받은 사람도 더 이상 열 수 없어요. 이미 추가한 대본은 받은 사람 기기에 남아요.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('지우기')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final services = AppScope.of(context);
    setState(() => _deleting.add(link.id));
    final result = await services.shareClient.delete(link);
    if (result is ShareOk || result is ShareMissing) {
      await services.shareHistory.removeSent(link.id);
      if (mounted) _snack('링크를 지웠어요');
    } else if (mounted) {
      _snack('지우지 못했어요. 인터넷 연결을 확인해 주세요');
    }
    if (mounted) setState(() => _deleting.remove(link.id));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final links = AppScope.of(context).shareHistory.sent;
    final now = DateTime.now();
    return Scaffold(
      appBar: AppBar(title: const Text('보낸 링크')),
      body: links.isEmpty
          ? Center(
              child: Text(
                keepWords('7일 안에 보낸 링크가 없어요'),
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            )
          : ListView.separated(
              padding: readablePadding(MediaQuery.sizeOf(context).width, const EdgeInsets.fromLTRB(20, 8, 20, 40)),
              itemCount: links.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final link = links[i];
                return Card(
                  child: ListTile(
                    title: Text(link.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text('${daysLeft(link.expiresAt, now)}일 뒤 사라져요'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(tooltip: '링크 복사', icon: const Icon(Icons.copy_rounded), onPressed: () => _copy(link)),
                        IconButton(
                          tooltip: '지우기',
                          icon: const Icon(Icons.delete_outline_rounded),
                          onPressed: _deleting.contains(link.id) ? null : () => _delete(link),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
```

- [ ] **Step 4: 설정 줄**

`lib/ui/settings/settings_screen.dart`:

1. import에 `import '../share/sent_links_screen.dart';` 추가.
2. `          section('정보'),` 바로 앞에 추가:

```dart
          section('공유'),
          Card(
            clipBehavior: Clip.antiAlias,
            child: _SettingTile(
              icon: Icons.link_rounded,
              title: '보낸 링크',
              subtitle: '7일 동안 링크를 복사하거나 지울 수 있어요',
              trailing: Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SentLinksScreen())),
            ),
          ),
```

- [ ] **Step 5: 사용법 항목**

`lib/ui/settings/how_to_screen.dart`의 `items`에서 `Icons.ios_share_rounded,` 항목(`'기기를 바꿀 때는 백업'`) 바로 앞에 추가:

```dart
    (
      Icons.link_rounded,
      '링크로 대본 보내기',
      "대본 화면 ⋯ 메뉴의 '링크로 공유'로 링크를 만들어 메신저로 보내요. 받은 사람은 링크를 눌러 내 대본에 추가하고, 앱이 없으면 웹에서 읽을 수 있어요. "
          '링크는 7일 뒤 사라지고, 설정 → 보낸 링크에서 먼저 지울 수도 있어요. 메모, 사진, 연습 기록은 보내지 않아요.',
    ),
```

- [ ] **Step 6: 통과 확인**

Run: `flutter test test/ui/sent_links_screen_test.dart test/ui/how_to_screen_test.dart && flutter analyze && flutter test`
Expected: PASS, `No issues found!`, 전체 `All tests passed!`

- [ ] **Step 7: 커밋**

```bash
git add lib/ui/share/sent_links_screen.dart lib/ui/settings/settings_screen.dart lib/ui/settings/how_to_screen.dart test/ui/sent_links_screen_test.dart test/ui/how_to_screen_test.dart
git commit -m "feat(share): manage sent links from settings and explain link sharing

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 8: 앱 링크 플랫폼 설정

**Files:**
- Modify: `android/app/src/main/AndroidManifest.xml`
- Create: `ios/Runner/Runner.entitlements`
- Modify: `ios/Runner/Info.plist`
- Modify: `ios/Runner.xcodeproj/project.pbxproj`

**Interfaces:**
- Consumes: Global Constraints의 호스트·경로·스킴
- Produces: Android·iOS가 공유 링크로 앱을 연다

- [ ] **Step 1: Android 매니페스트**

```bash
python3 - <<'PY'
p = 'android/app/src/main/AndroidManifest.xml'
s = open(p, encoding='utf-8').read()
anchor = '''                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
'''
assert s.count(anchor) == 1, s.count(anchor)
addition = '''            <!-- 링크는 app_links가 받으므로 Flutter 기본 딥 링크 처리를 끈다 -->
            <meta-data android:name="flutter_deeplinking_enabled" android:value="false" />
            <!-- 공유 링크: https://tacowasabii.vercel.app/monologue/s/<ID> -->
            <intent-filter android:autoVerify="true">
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data android:scheme="https" android:host="tacowasabii.vercel.app" android:pathPrefix="/monologue/s/" />
            </intent-filter>
            <!-- 웹 보기의 "앱에서 열기": monologue://s/<ID> -->
            <intent-filter>
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data android:scheme="monologue" android:host="s" />
            </intent-filter>
'''
open(p, 'w', encoding='utf-8').write(s.replace(anchor, anchor + addition))
print('manifest updated')
PY
```

Expected: `manifest updated`

- [ ] **Step 2: iOS entitlements와 Info.plist**

`ios/Runner/Runner.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.developer.associated-domains</key>
	<array>
		<string>applinks:tacowasabii.vercel.app</string>
	</array>
</dict>
</plist>
```

```bash
plutil -insert FlutterDeepLinkingEnabled -bool NO ios/Runner/Info.plist
plutil -insert CFBundleURLTypes -json '[{"CFBundleURLName":"com.tacowasabii.monologue","CFBundleURLSchemes":["monologue"]}]' ios/Runner/Info.plist
plutil -lint ios/Runner/Info.plist
```

Expected: `ios/Runner/Info.plist: OK`. (`FlutterDeepLinkingEnabled`나 `CFBundleURLTypes`가 이미 있다는 오류가 나면 `-insert` 대신 `-replace`로 같은 값을 쓴다.)

- [ ] **Step 3: Xcode 빌드 설정에 entitlements 연결**

```bash
python3 - <<'PY'
import re
p = 'ios/Runner.xcodeproj/project.pbxproj'
s = open(p, encoding='utf-8').read()
assert 'CODE_SIGN_ENTITLEMENTS' not in s
pattern = re.compile(r'^(\s*)PRODUCT_BUNDLE_IDENTIFIER = com\.tacowasabii\.monologue;$', re.M)
matches = pattern.findall(s)
assert len(matches) == 3, len(matches)
s = pattern.sub(lambda m: f'{m.group(1)}CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;\n{m.group(0)}', s)
open(p, 'w', encoding='utf-8').write(s)
print('entitlements linked in 3 build configurations')
PY
```

Expected: `entitlements linked in 3 build configurations` (Runner 타깃의 Debug·Release·Profile)

- [ ] **Step 4: 빌드 확인(기기에 설치하지 않는다)**

```bash
flutter build apk --debug 2>&1 | tail -2
flutter build ios --simulator --debug 2>&1 | tail -2
```

Expected: 두 빌드 모두 `✓ Built ...`

- [ ] **Step 5: 링크 열기 확인(컨트롤러가 사용자에게 확인받은 뒤에만)**

iOS 시뮬레이터를 쓸 수 있으면:

```bash
xcrun simctl list devices booted
flutter run -d <부팅된 시뮬레이터 ID> --debug &
# 앱이 뜬 뒤, 운영 API로 만든 실제 링크 ID로:
xcrun simctl openurl booted "monologue://s/<서버 계획 Task 6에서 만든 확인용 ID 또는 새로 만든 ID>"
```

Expected: 앱에 `받은 대본` 화면이 뜬다(만료·삭제된 ID면 `7일이 지나 사라졌거나…` 안내). Universal Link(`https://…`)는 연결 도메인 인증이 서명된 빌드에서만 되므로 TestFlight에서 확인한다(Task 10).

사용자가 기기 사용을 허락하지 않으면 이 단계를 건너뛰고, 건너뛰었다고 보고에 적는다.

- [ ] **Step 6: 커밋**

```bash
git add android/app/src/main/AndroidManifest.xml ios/Runner/Runner.entitlements ios/Runner/Info.plist ios/Runner.xcodeproj/project.pbxproj
git commit -m "feat(share): open share links in the app on Android and iOS

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 9: 개인정보처리방침·소개 페이지·스토어 문서

**Files:**
- Modify: `/Users/tacowasabii/website/src/pages/monologue/privacy.astro`
- Modify: `/Users/tacowasabii/website/src/pages/monologue/index.astro`
- Modify (조건부): `/Users/tacowasabii/website/public/.well-known/assetlinks.json`, `/Users/tacowasabii/website/tests/build.test.ts`
- Modify: `docs/store-listing.md`
- Modify: `docs/release.md`

**Interfaces:**
- Consumes: 서버 계획의 `SHARE_DATA_LOCATION`(`/Users/tacowasabii/website/src/lib/monologue-share/site.ts`)

- [ ] **Step 1: 개인정보처리방침**

`privacy.astro` 프런트매터를 다음으로 바꾼다(날짜는 배포하는 날로):

```astro
---
import { SHARE_DATA_LOCATION } from '../../lib/monologue-share/site';

const updated = '2026년 9월 14일';
---
```

`updated`의 날짜를 이 단계를 실행하는 날짜로 바꾼다(형식 `YYYY년 M월 D일`).

다음 문장을 바꾼다.

- 찾기: `<p>모노로그에는 회원가입이나 로그인이 없고, 사용자가 만든 대본·사진·노트·연습 기록을 개발자나 외부 서버로 보내지 않습니다. 개발자는 이용자의 개인정보를 수집하거나 보관하지 않습니다.</p>`
- 바꾸기: `<p>모노로그에는 회원가입이나 로그인이 없습니다. 대본·사진·노트·연습 기록은 기기에 저장되며, 사용자가 '링크로 공유'를 누른 대본만 아래 "링크로 대본을 보낼 때"에 적은 대로 서버에 7일 동안 저장합니다. 그 밖에 개발자가 이용자의 개인정보를 수집하거나 보관하지 않습니다.</p>`

- 찾기: `<p>개인정보를 제3자에게 제공하지 않으며, 광고나 별도의 분석 도구를 넣지 않습니다. Android 글자 인식에 쓰는 Google ML Kit가 보내는 진단 정보는 위 "수집하는 개인정보"를 참고해 주세요.</p>`
- 바꾸기: `<p>개인정보를 제3자에게 제공하지 않으며, 광고나 별도의 분석 도구를 넣지 않습니다. Android 글자 인식에 쓰는 Google ML Kit가 보내는 진단 정보는 위 "수집하는 개인정보"를, 링크로 공유한 대본의 처리는 "링크로 대본을 보낼 때"를 참고해 주세요.</p>`

`<section>` 중 `<h2>제3자 제공 및 광고</h2>`가 있는 섹션 바로 앞에 추가:

```astro
      <section>
        <h2>링크로 대본을 보낼 때</h2>
        <p>대본 화면에서 '링크로 공유'를 누를 때만, 그 대본의 작품명·대화 형식 여부·본문·성별·나이대·태그와 사용자가 함께 보내기로 고른 노트를 서버에 저장합니다. 메모, 원본 사진, 연습 기록, 내 역할은 보내지 않습니다.</p>
        <ul>
          <li>보관 기간: 저장한 때부터 7일입니다. 7일이 지나면 자동으로 삭제되며, 보낸 사람은 앱의 설정 → 보낸 링크에서 그 전에 지울 수 있습니다.</li>
          <li>링크를 가진 사람은 누구나 대본을 볼 수 있습니다. 링크 주소는 짐작할 수 없게 만들고, 검색 엔진에 노출하지 않습니다.</li>
          <li>짧은 시간에 너무 많이 올리는 것을 막기 위해 접속 IP 주소를 되돌릴 수 없는 값(해시)으로 바꿔 1시간 동안만 횟수를 셉니다. IP 주소 자체는 저장하지 않습니다.</li>
          <li>받은 사람이 앱에서 추가한 대본은 받은 사람의 기기에 저장되며, 링크가 삭제된 뒤에도 남습니다.</li>
        </ul>
        <h3>처리 위탁 및 국외 이전</h3>
        <div class="table-wrap">
          <table>
            <thead>
              <tr><th>이전받는 자</th><th>국가·지역</th><th>이전 항목</th><th>목적</th><th>보유 기간</th></tr>
            </thead>
            <tbody>
              <tr>
                <td>{SHARE_DATA_LOCATION.functions.company}</td>
                <td>{SHARE_DATA_LOCATION.functions.country}</td>
                <td>공유한 대본 내용, 접속 IP 주소</td>
                <td>공유 링크 서버 운영</td>
                <td>요청을 처리하는 동안(서비스 운영 기록은 Vercel의 보관 정책에 따름)</td>
              </tr>
              <tr>
                <td>{SHARE_DATA_LOCATION.storage.company}</td>
                <td>{SHARE_DATA_LOCATION.storage.country}</td>
                <td>공유한 대본 내용, IP 주소 해시</td>
                <td>공유한 대본 보관</td>
                <td>대본 7일, IP 주소 해시 1시간</td>
              </tr>
            </tbody>
          </table>
        </div>
        <p>이전 시기와 방법: 사용자가 '링크로 공유'를 누를 때 암호화된 통신(HTTPS)으로 전송합니다. 링크 공유를 쓰지 않으면 이전되지 않습니다.</p>
      </section>
```

`<style is:global>`의 `ul { … }` 규칙 뒤에 추가:

```css
  h3 {
    margin: 20px 0 6px;
    font-size: 15px;
  }
  .table-wrap {
    overflow-x: auto;
  }
  table {
    width: 100%;
    border-collapse: collapse;
    font-size: 14px;
    line-height: 1.6;
  }
  th,
  td {
    padding: 8px 6px;
    border-top: 1px solid rgba(127, 127, 127, 0.3);
    text-align: left;
    vertical-align: top;
  }
```

- [ ] **Step 2: 소개 페이지 기능 문구**

`index.astro`의 `features` 배열에서:

- 찾기: `  ['내 기기에만 저장', '로그인이 없고 글자 인식도 기기 안에서 해요. 기기를 바꿀 땐 백업 파일로 옮겨요.'],`
- 바꾸기:

```ts
  ['링크로 보내기', '링크 하나로 대본을 보내면 받은 사람이 눌러서 바로 추가해요. 앱이 없어도 웹에서 읽을 수 있고, 링크는 7일 뒤 사라져요.'],
  ['내 기기에 저장', '로그인이 없고 글자 인식도 기기 안에서 해요. 링크로 공유한 대본만 7일 동안 서버에 올라가요. 기기를 바꿀 땐 백업 파일로 옮겨요.'],
```

- [ ] **Step 3: Play 앱 서명 키 지문(받았을 때만)**

컨트롤러가 사용자에게 Play Console → 테스트 및 출시 → 앱 무결성 → 앱 서명 키 인증서의 SHA-256 값을 받았으면:
- `public/.well-known/assetlinks.json`의 `sha256_cert_fingerprints` 배열에 그 값을 두 번째 항목으로 추가한다.
- `tests/build.test.ts`의 `expect(links[0].target.sha256_cert_fingerprints).toContain(...)` 아래에 같은 값을 기대하는 `toContain` 줄을 추가한다.

받지 못했으면 건너뛰고, `docs/release.md`(Step 5)의 할 일로 남긴다.

- [ ] **Step 4: 웹사이트 확인·커밋·배포**

```bash
cd /Users/tacowasabii/website
rm -rf dist .vercel/output && npm test
git add src/pages/monologue public/.well-known tests/build.test.ts
git commit -m "monologue: explain link sharing in the privacy policy and intro page

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
vercel --prod --yes
curl -s https://tacowasabii.vercel.app/monologue/privacy | grep -oE "링크로 대본을 보낼 때|처리 위탁 및 국외 이전|Upstash, Inc\." | sort -u
curl -s https://tacowasabii.vercel.app/monologue | grep -o "링크로 보내기"
```

Expected: 테스트 통과, 배포 Ready, `링크로 대본을 보낼 때`, `처리 위탁 및 국외 이전`, `Upstash, Inc.`, `링크로 보내기`

- [ ] **Step 5: 저장소 문서**

```bash
cd /Users/tacowasabii/orca/workspaces/monologue/hagfish
python3 - <<'PY'
p = 'docs/store-listing.md'
s = open(p, encoding='utf-8').read()
edits = [
    ('■ 내 기기에만 저장\n로그인이 없고 대본이 외부로 전송되지 않아요. 글자 인식도 기기 안에서 처리해요. 기기를 바꿀 땐 백업 파일로 옮기면 돼요.',
     '■ 링크로 대본 보내기\n링크 하나로 대본을 친구에게 보내요. 받은 사람은 눌러서 바로 내 대본에 추가하고, 앱이 없어도 웹에서 읽을 수 있어요. 링크는 7일 뒤 사라져요.\n\n■ 내 기기에 저장\n로그인 없이 대본은 기기에 저장돼요. 글자 인식도 기기 안에서 처리하고, 링크로 공유한 대본만 7일 동안 서버에 올라가요. 기기를 바꿀 땐 백업 파일로 옮기면 돼요.'),
    ('- "앱 개인정보 보호": **데이터를 수집하지 않음**. iPhone·iPad는 글자 인식에 Apple Vision을 쓰고, 외부로 데이터를 보내는 SDK가 없다.',
     '- "앱 개인정보 보호": **사용자 콘텐츠 → 기타 사용자 콘텐츠** 수집 — 용도 "앱 기능", 사용자 신원과 연결하지 않음, 추적에 사용하지 않음. 링크로 공유한 대본이 서버에 7일 동안 저장되기 때문이다. iPhone·iPad는 글자 인식에 Apple Vision을 써서 그 밖에 외부로 데이터를 보내는 SDK는 없다.'),
    ('대본·사진·노트·녹음은 기기 밖으로 나가지 않는다.',
     '사용자가 링크로 공유한 대본(작품명·본문·성별·나이대·태그·고른 경우 노트)도 서버에 7일 동안 저장되므로 함께 신고한다. 사진·녹음·메모는 기기 밖으로 나가지 않는다.'),
    ('| 사용자가 데이터 삭제를 요청할 수 있나요? | 아니요 (개발자가 보관하는 데이터가 없음) |',
     '| 사용자가 데이터 삭제를 요청할 수 있나요? | 예 (앱의 설정 → 보낸 링크에서 지우기, 7일 뒤 자동 삭제) |'),
    ('| 기기 또는 기타 ID → 기기 또는 기타 ID | 예 | 아니요 | 아니요 (필수) | 분석 |',
     '| 기기 또는 기타 ID → 기기 또는 기타 ID | 예 | 아니요 | 아니요 (필수) | 분석 |\n| 앱 활동 → 기타 사용자 생성 콘텐츠 | 예 | 아니요 | 예 (링크로 공유할 때만) | 앱 기능 |'),
    ('- `INTERNET`, `ACCESS_NETWORK_STATE`: ML Kit 진단 정보 전송 라이브러리(`datatransport`)와 미디어 재생 라이브러리가 추가',
     '- `INTERNET`, `ACCESS_NETWORK_STATE`: 링크 공유, ML Kit 진단 정보 전송 라이브러리(`datatransport`), 미디어 재생 라이브러리'),
    ('(ML Kit 진단 정보 설명 포함)', '(ML Kit 진단 정보, 링크 공유 설명 포함)'),
]
for old, new in edits:
    assert s.count(old) == 1, (old[:40], s.count(old))
    s = s.replace(old, new)
s = s.replace(
    '제출 전에 Play Console의 데이터 유형 설명과 위 ML Kit 안내가 바뀌지 않았는지 다시 확인한다.',
    '링크 공유의 올리기 제한에 쓰는 IP 주소는 해시로 1시간 동안만 처리하고 저장하지 않아 Play 기준 "일시적으로 처리"로 보고 따로 신고하지 않는다. 제출 전에 Play Console의 데이터 유형·일시적 처리 설명과 위 ML Kit 안내가 바뀌지 않았는지 다시 확인한다.',
)
open(p, 'w', encoding='utf-8').write(s)

p = 'docs/release.md'
s = open(p, encoding='utf-8').read()
edits = [
    ('   - 심사 메모: "로그인 없음. 사진 선택 또는 촬영 후 텍스트 인식. 모든 데이터는 기기에만 저장."',
     '   - 심사 메모: "로그인 없음. 사진 선택 또는 촬영 후 텍스트 인식. 대본은 기기에 저장되고, 대본 화면 ⋯ → 링크로 공유를 누른 대본만 7일 동안 서버에 저장됨. 받은 링크를 누르면 앱에서 \'내 대본에 추가\'로 가져옴." 심사 직전에 앱에서 만든 공유 링크 하나를 메모에 붙인다.'),
    ('데이터 보안(ML Kit 진단 정보 때문에 "수집함"',
     '데이터 보안(ML Kit 진단 정보와 링크 공유 때문에 "수집함"'),
]
for old, new in edits:
    assert s.count(old) == 1, (old[:40], s.count(old))
    s = s.replace(old, new)
s = s.replace(
    '4. **Play 앱 서명** 사용(기본값). `app-release.aab` 업로드 → 업로드 키 인증서 자동 등록',
    '4. **Play 앱 서명** 사용(기본값). `app-release.aab` 업로드 → 업로드 키 인증서 자동 등록. 그 뒤 앱 무결성 화면의 앱 서명 키 SHA-256을 웹사이트 `public/.well-known/assetlinks.json`에 추가하고 배포해야 Android에서 공유 링크가 앱으로 열린다',
)
open(p, 'w', encoding='utf-8').write(s)
print('docs updated')
PY
```

Expected: `docs updated`. `assert`가 실패하면 해당 파일을 열어 실제 문장을 확인하고, 같은 뜻으로 바꿀 문장을 찾아 `edits`의 찾기 값을 고친 뒤 다시 실행한다.

- [ ] **Step 6: 커밋**

```bash
git add docs/store-listing.md docs/release.md
git commit -m "docs: declare shared scripts in store privacy answers and the review note

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 10: 마무리 확인과 main 반영

**Files:** 없음(확인·병합)

- [ ] **Step 1: 전체 확인**

```bash
cd /Users/tacowasabii/orca/workspaces/monologue/hagfish
flutter analyze && flutter test 2>&1 | tail -2
git status --short
```

Expected: `No issues found!`, `All tests passed!`, 작업 트리 깨끗함

- [ ] **Step 2: main 빨리 감기**

```bash
MAIN=/Users/tacowasabii/monologue
git -C $MAIN status --short
git merge-base --is-ancestor "$(git -C $MAIN rev-parse HEAD)" HEAD && echo "main is ancestor"
```

main 체크아웃에 `.gitignore` 말고 다른 변경이 없고 `main is ancestor`가 나오면:

```bash
git -C $MAIN fetch -q "$PWD" HEAD && git -C $MAIN merge --ff-only -q FETCH_HEAD && git -C $MAIN log --oneline -1
```

main이 다른 세션 커밋으로 앞서 있으면 멈추고 컨트롤러에게 알린다(이 브랜치를 main 위로 옮길지 사용자에게 묻는다).

- [ ] **Step 3: 남은 수동 확인을 보고에 적는다**

- Universal Link(iOS)·App Link(Android) 자동 열림은 서명된 빌드(TestFlight, Play 비공개 테스트)에서 카톡으로 링크를 보내 확인한다.
- Play 앱 서명 키 지문을 아직 넣지 않았다면 Android App Link는 Play에서 받은 앱에서 브라우저로 열린다(웹 보기의 "앱에서 열기"는 동작).
