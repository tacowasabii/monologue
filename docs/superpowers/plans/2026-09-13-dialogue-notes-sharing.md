# 대화 대본 · 몰입 읽기 · 대본 노트 · 1:1 공유 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 대본마다 독백/대화 형식을 고르고 내 역할을 강조해 읽으며, 전체 화면 몰입 읽기·대본 분석 노트·작품 맥락을 쓰고, 대본 하나를 `.monologue` 파일로 주고받게 한다.

**Architecture:** 본문은 평문으로 두고 순수 함수 `parseDialogue`가 읽을 때 대사로 나눈다. 형식·내 역할·노트는 `scripts` 테이블에 컬럼으로 붙이고(schemaVersion 4), 공유 파일은 백업 zip 형식(version 2)을 대본 1개로 재사용한다. 화면 꺼짐 방지와 받은 파일 전달은 기존 OCR처럼 네이티브 MethodChannel(`monologue/screen`, `monologue/incoming`)로 하고, Dart 쪽은 인터페이스로 감싸 `AppServices`에 주입한다.

**Tech Stack:** Flutter 3.47.3 / Dart 3.13, drift 2.35 (+ build_runner), archive 4.2, share_plus 13.3, file_picker 12.2. 새 패키지 없음.

**Spec:** `docs/superpowers/specs/2026-09-13-dialogue-notes-sharing-design.md`

**기준 코드:** `main` 79532b0 (제목·인물 칸을 메모로 바꾼 뒤). 시작 전에 `git log --oneline -1 main`이 이 커밋 이후인지 확인하고, 그 사이 `lib/data/database.dart`·`lib/ui/view/script_view_screen.dart`·`lib/ui/edit/script_edit_screen.dart`가 바뀌었으면 해당 Task의 코드 위치를 먼저 맞춘다.

## Global Constraints

- 한국어 UI만. 네트워크 통신 없음. 새 권한 없음. 새 pub 패키지 없음.
- 대본에는 제목·인물 칸이 없다. 화면에 쓰는 대본 이름은 `script.work ?? firstLineOf(script.body)`(`lib/domain/script_draft.dart`의 `firstLineOf`, 목록 카드와 같은 규칙).
- 보여 주기만 하는 한국어 글은 `keepWords`(`lib/ui/common/korean_text.dart`)로 감싸고, 복사할 때는 `withoutWordJoiners`로 뺀다. 입력칸에는 쓰지 않는다. 테스트에서 이런 글을 찾을 때는 `find.text(keepWords('…'))`.
- 본문(`body`)은 평문 그대로 저장한다. 대사 구분은 표시할 때만 한다.
- 대사 줄: `^이름\s*[:：]\s*대사`, 이름 1~12자, 숫자만인 이름·`http`로 시작하는 이름 제외. 이름 없는 줄은 빈 줄 전까지 앞 인물 대사, 줄 전체 `(…)`는 지문, 빈 줄 뒤 이름 없는 줄은 지문.
- 새 대본 형식 기본값: 대사 줄 2줄 이상이면 `대화`.
- 내 역할(`myRole`): 대본마다 저장, 칩을 누르면 즉시 `setMyRole`로 저장, 같은 칩을 다시 누르면 해제, 없으면 강조 없음.
- 노트 필드 8개: situation(상황), objective(원하는 것), obstacle(가로막는 것), author(작가), medium(매체: 영화·드라마·연극·뮤지컬·창작·기타), sourceUrl(출처 링크), synopsis(작품 줄거리), sceneContext(이 장면 앞뒤). 모두 nullable. 자유 메모는 기존 `memo` 칸.
- DB schemaVersion 4: `scripts.dialogue` bool 기본 false, `scripts.my_role`, 노트 컬럼 8개 nullable. `from < 3`은 기존 규칙(비우고 다시 만들기), `from == 3`은 컬럼 추가만.
- 백업·공유 zip: `backup.json`(format `monologue-backup`, **version 2**) + `images/<fileName>`. 대본 항목에 `dialogue`, `myRole`, `notes` 추가. version 1도 복원. 공유 파일 이름 `<대본 이름>.monologue`, 원본 사진 기본 제외.
- `ScriptRepository.update`는 노트와 내 역할을 바꾸지 않는다. 노트는 `updateNotes`, 내 역할은 `setMyRole`로만 바꾼다.
- 검색 대상: 작품명·메모·본문·작가.
- 기존 규칙 유지: 연습 상태는 UI에 없고 저장값은 보존. 테마 토큰은 `lib/ui/theme.dart`(`serifFamily`, `favoriteColor`), 선택 칩은 `PillChip`. `AppServices`에는 이미 `tips`(`AppTips`)가 있다.

---

## File Structure

| 파일 | 책임 | Task |
|---|---|---|
| `lib/domain/enums.dart` | `ScriptMedium` 추가 | 1 |
| `lib/domain/script_notes.dart` (새) | `ScriptNotes` 값 객체: 정리, 비었는지, JSON | 1 |
| `lib/domain/script_draft.dart` | `dialogue`, `myRole`, `notes` 필드 | 1 |
| `lib/data/database.dart` | v4 컬럼, 마이그레이션 | 2 |
| `lib/data/script_repository.dart` | 형식·역할·노트 저장, `updateNotes`, `setMyRole`, 작가 검색, `Script.notes` | 2 |
| `lib/domain/dialogue.dart` (새) | `parseDialogue`, `looksLikeDialogue`, `speakersOf` | 3 |
| `lib/ui/view/script_body.dart` (새) | 본문 표시(독백/대화, 내 역할 강조, 복사 시 보이지 않는 문자 제거) | 4 |
| `lib/ui/edit/script_edit_screen.dart` | 형식 선택 | 4 |
| `lib/ui/view/script_view_screen.dart` | 인물 칩, 노트 요약·버튼, 몰입 버튼, 공유 메뉴 | 4, 5, 6, 8 |
| `lib/ui/common/section_header.dart` (새) | 구역 제목(편집 화면의 `_section`을 옮김) | 5 |
| `lib/ui/notes/notes_screen.dart` (새) | 노트 편집 | 5 |
| `lib/platform/screen_awake.dart` (새) | 화면 꺼짐 방지 인터페이스 + 채널 구현 | 6 |
| `lib/ui/view/immersive_reader_screen.dart` (새) | 몰입 읽기 | 6 |
| `lib/backup/backup_service.dart` | version 2, `exportScript`, `importArchive` | 7 |
| `lib/platform/incoming_files.dart` (새) | 받은 파일 경로 인터페이스 + 채널 구현 | 8 |
| `lib/ui/share/share_script.dart` (새) | 공유 창(사진 포함 선택) → 공유 시트 | 8 |
| `lib/ui/share/import_flow.dart` (새) | 가져오기 확인 → 가져오기 → 대본 열기 | 8 |
| `lib/app_scope.dart`, `lib/main.dart`, `lib/app.dart`, `test/ui/test_harness.dart` | 새 서비스 주입, 받은 파일 수신 | 6, 8 |
| `lib/ui/settings/settings_screen.dart` | `파일에서 가져오기` | 8 |
| `ios/Runner/AppDelegate.swift`, `ios/Runner/Info.plist` | 화면·받은 파일 플러그인, 문서 타입 | 6, 8 |
| `android/app/src/main/kotlin/com/tacowasabii/monologue/MainActivity.kt`, `android/app/src/main/AndroidManifest.xml` | 채널, 인텐트 필터 | 6, 8 |
| `lib/ui/settings/how_to_screen.dart`, `docs/store-listing.md` | 사용 방법·소개 문구 | 9 |

---

### Task 1: 도메인 — 매체 enum, 대본 노트, 초안 필드

**Files:**
- Modify: `lib/domain/enums.dart`
- Create: `lib/domain/script_notes.dart`
- Modify: `lib/domain/script_draft.dart`
- Test: `test/domain/script_notes_test.dart` (새)

**Interfaces:**
- Produces: `enum ScriptMedium { film, drama, play, musical, original, other }` (+ `label`); `class ScriptNotes { situation, objective, obstacle, author, medium, sourceUrl, synopsis, sceneContext; static const empty; bool get isEmpty; ScriptNotes normalized(); Map<String, Object?> toJson(); factory ScriptNotes.fromJson(Map<String, Object?>); == }`; `ScriptDraft.dialogue` (bool, 기본 false), `ScriptDraft.myRole` (String?), `ScriptDraft.notes` (ScriptNotes, 기본 `ScriptNotes.empty`). `ScriptDraft.normalized()`가 `myRole`의 빈 값을 null로, 노트를 `normalized()`로 정리한다.

- [ ] **Step 1: 실패하는 테스트 작성**

`test/domain/script_notes_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:monologue/domain/enums.dart';
import 'package:monologue/domain/script_draft.dart';
import 'package:monologue/domain/script_notes.dart';

void main() {
  test('normalized는 앞뒤 공백을 지우고 빈 값은 null로 바꾼다', () {
    const raw = ScriptNotes(situation: '  새벽, 부엌  ', objective: '   ', author: '체호프');
    final n = raw.normalized();
    expect(n.situation, '새벽, 부엌');
    expect(n.objective, isNull);
    expect(n.author, '체호프');
  });

  test('isEmpty는 공백만 있거나 아무것도 없을 때 true', () {
    expect(ScriptNotes.empty.isEmpty, isTrue);
    expect(const ScriptNotes(obstacle: '  ').isEmpty, isTrue);
    expect(const ScriptNotes(medium: ScriptMedium.play).isEmpty, isFalse);
  });

  test('JSON으로 바꿨다 되돌리면 같다', () {
    const n = ScriptNotes(
      situation: '상황',
      objective: '목표',
      obstacle: '장애물',
      author: '작가',
      medium: ScriptMedium.drama,
      sourceUrl: 'https://example.com',
      synopsis: '줄거리',
      sceneContext: '앞뒤',
    );
    expect(ScriptNotes.fromJson(n.toJson()), n);
    expect(ScriptNotes.fromJson(const {}), ScriptNotes.empty);
  });

  test('초안 정리는 형식을 유지하고 역할·노트도 정리한다', () {
    const d = ScriptDraft(body: '첫 줄', dialogue: true, myRole: ' 민수 ', notes: ScriptNotes(situation: ' 새벽 '));
    final r = d.normalized();
    expect(r.dialogue, isTrue);
    expect(r.myRole, '민수');
    expect(r.notes.situation, '새벽');
    expect(const ScriptDraft(body: 'x', myRole: '  ').normalized().myRole, isNull);
  });
}
```

- [ ] **Step 2: 실패 확인**

Run: `flutter test test/domain/script_notes_test.dart`
Expected: FAIL — `script_notes.dart` 없음, `ScriptMedium`·`dialogue`·`myRole`·`notes` 정의 없음

- [ ] **Step 3: 구현**

`lib/domain/enums.dart` 끝에 추가:

```dart
enum ScriptMedium {
  film('영화'),
  drama('드라마'),
  play('연극'),
  musical('뮤지컬'),
  original('창작'),
  other('기타');

  const ScriptMedium(this.label);
  final String label;
}
```

`lib/domain/script_notes.dart`:

```dart
import 'enums.dart';

/// 대본 분석(상황·원하는 것·가로막는 것)과 작품 맥락. 모두 선택 입력이다. 자유 메모는 대본의 `memo` 칸을 쓴다.
class ScriptNotes {
  const ScriptNotes({
    this.situation,
    this.objective,
    this.obstacle,
    this.author,
    this.medium,
    this.sourceUrl,
    this.synopsis,
    this.sceneContext,
  });

  static const empty = ScriptNotes();

  /// 누가·어디서·언제·직전에 무슨 일
  final String? situation;
  final String? objective;
  final String? obstacle;
  final String? author;
  final ScriptMedium? medium;
  final String? sourceUrl;
  final String? synopsis;
  final String? sceneContext;

  bool get isEmpty =>
      medium == null &&
      [situation, objective, obstacle, author, sourceUrl, synopsis, sceneContext]
          .every((t) => t == null || t.trim().isEmpty);

  ScriptNotes normalized() {
    String? clean(String? s) => (s == null || s.trim().isEmpty) ? null : s.trim();
    return ScriptNotes(
      situation: clean(situation),
      objective: clean(objective),
      obstacle: clean(obstacle),
      author: clean(author),
      medium: medium,
      sourceUrl: clean(sourceUrl),
      synopsis: clean(synopsis),
      sceneContext: clean(sceneContext),
    );
  }

  Map<String, Object?> toJson() => {
        'situation': situation,
        'objective': objective,
        'obstacle': obstacle,
        'author': author,
        'medium': medium?.name,
        'sourceUrl': sourceUrl,
        'synopsis': synopsis,
        'sceneContext': sceneContext,
      };

  factory ScriptNotes.fromJson(Map<String, Object?> j) => ScriptNotes(
        situation: j['situation'] as String?,
        objective: j['objective'] as String?,
        obstacle: j['obstacle'] as String?,
        author: j['author'] as String?,
        medium: switch (j['medium']) {
          final String name => ScriptMedium.values.byName(name),
          _ => null,
        },
        sourceUrl: j['sourceUrl'] as String?,
        synopsis: j['synopsis'] as String?,
        sceneContext: j['sceneContext'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      other is ScriptNotes &&
      other.situation == situation &&
      other.objective == objective &&
      other.obstacle == obstacle &&
      other.author == author &&
      other.medium == medium &&
      other.sourceUrl == sourceUrl &&
      other.synopsis == synopsis &&
      other.sceneContext == sceneContext;

  @override
  int get hashCode => Object.hash(situation, objective, obstacle, author, medium, sourceUrl, synopsis, sceneContext);
}
```

`lib/domain/script_draft.dart` — import `script_notes.dart` 추가. 생성자 마지막에:

```dart
    this.tags = const [],
    this.dialogue = false,
    this.myRole,
    this.notes = ScriptNotes.empty,
  });
```

필드 추가(`final List<String> tags;` 아래):

```dart
  final bool dialogue;

  /// 대화 대본에서 강조해 읽을 인물 이름
  final String? myRole;
  final ScriptNotes notes;
```

`normalized()`의 `ScriptDraft(...)` 마지막 인자 뒤에:

```dart
      dialogue: dialogue,
      myRole: blankToNull(myRole),
      notes: notes.normalized(),
```

- [ ] **Step 4: 통과 확인**

Run: `flutter test test/domain`
Expected: PASS

- [ ] **Step 5: 커밋**

```bash
git add lib/domain test/domain
git commit -m "feat: add script notes, medium enum, dialogue flag, and role to drafts"
```

---

### Task 2: DB v4 마이그레이션과 저장소

**Files:**
- Modify: `lib/data/database.dart`
- Regenerate: `lib/data/database.g.dart`
- Modify: `lib/data/script_repository.dart`
- Test: `test/data/migration_test.dart`, `test/data/script_repository_test.dart`

**Interfaces:**
- Consumes: `ScriptNotes`, `ScriptMedium`, `ScriptDraft.dialogue/myRole/notes` (Task 1)
- Produces: `Script.dialogue` (bool), `Script.myRole` (String?), `Script.situation … Script.sceneContext` (drift 생성 필드); `extension ScriptRowNotes on Script { ScriptNotes get notes }`; `Future<void> ScriptRepository.updateNotes(int id, ScriptNotes notes)` (수정 시각 갱신); `Future<void> ScriptRepository.setMyRole(int id, String? role)` (수정 시각 그대로); `create`/`insertRestored`는 형식·역할·노트 저장, `update`는 형식만 저장

- [ ] **Step 1: 실패하는 테스트 작성**

`test/data/migration_test.dart` — `_v1Schema` 아래에 버전 3 정의를 추가한다:

```dart
// 메모 칸이 생긴 버전 3의 테이블 정의
const _v3Schema = [
  'CREATE TABLE IF NOT EXISTS "scripts" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "work" TEXT NULL, '
      '"memo" TEXT NULL, "gender" TEXT NOT NULL, "age_range" TEXT NOT NULL, "status" TEXT NOT NULL, '
      '"favorite" INTEGER NOT NULL CHECK ("favorite" IN (0, 1)), "body" TEXT NOT NULL, '
      '"created_at" TEXT NOT NULL, "updated_at" TEXT NOT NULL);',
  'CREATE TABLE IF NOT EXISTS "script_tags" ("script_id" INTEGER NOT NULL REFERENCES scripts (id), '
      '"tag" TEXT NOT NULL, PRIMARY KEY ("script_id", "tag"));',
  'CREATE TABLE IF NOT EXISTS "script_images" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
      '"script_id" INTEGER NOT NULL REFERENCES scripts (id), "file_name" TEXT NOT NULL, "position" INTEGER NOT NULL);',
];
```

`main()` 끝에 테스트 추가:

```dart
  test('버전 3 DB는 대본을 그대로 두고 형식·역할·노트 칸을 더한다', () async {
    final file = File('${tmp.path}/monologue.sqlite');
    final v3 = sqlite3.open(file.path);
    for (final sql in _v3Schema) {
      v3.execute(sql);
    }
    v3.execute(
      'INSERT INTO scripts (work, memo, gender, age_range, status, favorite, body, created_at, updated_at) '
      "VALUES ('햄릿', '1차 오디션', 'any', 'any', 'notStarted', 0, '사느냐 죽느냐', "
      "'2026-09-13T10:00:00.000+09:00', '2026-09-13T10:00:00.000+09:00')",
    );
    v3.execute("INSERT INTO script_tags (script_id, tag) VALUES (1, '고뇌')");
    v3.execute('PRAGMA user_version = 3');
    v3.close();

    final db = AppDatabase(NativeDatabase(file));
    final row = await db.select(db.scripts).getSingle();
    expect(row.work, '햄릿');
    expect(row.memo, '1차 오디션');
    expect(row.dialogue, isFalse);
    expect(row.myRole, isNull);
    expect(row.situation, isNull);
    expect(row.medium, isNull);
    expect((await db.select(db.scriptTags).getSingle()).tag, '고뇌');
    await db.close();
  });
```

`test/data/script_repository_test.dart` — import `package:monologue/domain/script_notes.dart` 추가, `main()` 끝에:

```dart
  test('create는 형식·역할·노트를 저장하고 update는 형식만 바꾼다', () async {
    final id = await repo.create(const ScriptDraft(
      body: '민수: 안녕\n지영: 응',
      dialogue: true,
      myRole: '지영',
      notes: ScriptNotes(situation: '새벽', medium: ScriptMedium.play),
    ));
    await repo.update(id, const ScriptDraft(body: '민수: 안녕\n지영: 응', dialogue: false));
    final s = (await repo.watchScript(id).first)!.script;
    expect(s.dialogue, isFalse);
    expect(s.myRole, '지영');
    expect(s.notes, const ScriptNotes(situation: '새벽', medium: ScriptMedium.play));
  });

  test('updateNotes는 노트를 정리해 저장하고 수정 시각을 바꾼다', () async {
    final id = await repo.create(const ScriptDraft(body: 'x'));
    final before = (await repo.watchScript(id).first)!.script.updatedAt;
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await repo.updateNotes(id, const ScriptNotes(objective: '  용서받기 ', obstacle: ''));
    final s = (await repo.watchScript(id).first)!.script;
    expect(s.notes, const ScriptNotes(objective: '용서받기'));
    expect(s.updatedAt.isAfter(before), isTrue);
  });

  test('setMyRole은 역할을 저장하고 null이면 지운다', () async {
    final id = await repo.create(const ScriptDraft(body: '민수: 안녕', dialogue: true));
    await repo.setMyRole(id, '민수');
    expect((await repo.watchScript(id).first)!.script.myRole, '민수');
    await repo.setMyRole(id, null);
    expect((await repo.watchScript(id).first)!.script.myRole, isNull);
  });

  test('작가로도 검색된다', () async {
    await repo.create(const ScriptDraft(work: '갈매기', body: 'x', notes: ScriptNotes(author: '체호프')));
    await repo.create(const ScriptDraft(work: '햄릿', body: 'x'));
    final found = await repo.watchScripts(const ScriptFilter(query: '체호프')).first;
    expect(found.map((s) => s.script.work), ['갈매기']);
  });
```

- [ ] **Step 2: 실패 확인**

Run: `flutter test test/data`
Expected: FAIL — `dialogue`, `myRole`, `situation`, `notes`, `updateNotes`, `setMyRole` 정의 없음

- [ ] **Step 3: 스키마와 마이그레이션 구현**

`lib/data/database.dart` — `Scripts`의 `updatedAt` 아래에 추가:

```dart
  BoolColumn get dialogue => boolean().withDefault(const Constant(false))();
  TextColumn get myRole => text().nullable()();
  TextColumn get situation => text().nullable()();
  TextColumn get objective => text().nullable()();
  TextColumn get obstacle => text().nullable()();
  TextColumn get author => text().nullable()();
  TextColumn get medium => textEnum<ScriptMedium>().nullable()();
  TextColumn get sourceUrl => text().nullable()();
  TextColumn get synopsis => text().nullable()();
  TextColumn get sceneContext => text().nullable()();
```

`AppDatabase`의 `schemaVersion`과 `migration`을 바꾼다:

```dart
  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          // 버전 1(제목 칸)·2(인물 칸)는 출시 전 빌드라 옮길 대본이 없다. 비우고 새 구조로 다시 만든다.
          if (from < 3) {
            for (final table in allTables) {
              await m.deleteTable(table.actualTableName);
            }
            await m.createAll();
            return;
          }
          // 버전 4: 대화 형식·내 역할·대본 노트. 칸만 더하므로 대본은 그대로 남는다
          if (from < 4) {
            for (final column in <GeneratedColumn>[
              scripts.dialogue,
              scripts.myRole,
              scripts.situation,
              scripts.objective,
              scripts.obstacle,
              scripts.author,
              scripts.medium,
              scripts.sourceUrl,
              scripts.synopsis,
              scripts.sceneContext,
            ]) {
              await m.addColumn(scripts, column);
            }
          }
        },
      );
```

코드 생성:

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: `lib/data/database.g.dart` 갱신, 오류 없음

- [ ] **Step 4: 저장소 구현**

`lib/data/script_repository.dart` — import 추가:

```dart
import '../domain/script_notes.dart';
```

`class ScriptSummary` 앞에:

```dart
extension ScriptRowNotes on Script {
  ScriptNotes get notes => ScriptNotes(
        situation: situation,
        objective: objective,
        obstacle: obstacle,
        author: author,
        medium: medium,
        sourceUrl: sourceUrl,
        synopsis: synopsis,
        sceneContext: sceneContext,
      );
}
```

`watchScripts`의 검색 조건에 작가 추가:

```dart
          e = e & (s.work.like(pattern) | s.memo.like(pattern) | s.body.like(pattern) | s.author.like(pattern));
```

`insertRestored`의 insert에 두 값을 넣고, `_replaceTags` 앞에서 노트를 쓴다:

```dart
            body: d.body,
            dialogue: Value(d.dialogue),
            myRole: Value(d.myRole),
            createdAt: createdAt,
            updatedAt: updatedAt,
          ));
      await (db.update(db.scripts)..where((s) => s.id.equals(id))).write(_notesCompanion(d.notes));
      await _replaceTags(id, d.tags);
```

`update`의 `ScriptsCompanion(...)`에 `dialogue: Value(d.dialogue),`를 추가하고, 메서드 위에 주석:

```dart
  /// 대본 내용과 형식을 바꾼다. 노트는 [updateNotes], 내 역할은 [setMyRole]로만 바꾼다.
```

`setFavorite` 위에 추가:

```dart
  Future<void> updateNotes(int id, ScriptNotes notes) =>
      (db.update(db.scripts)..where((s) => s.id.equals(id)))
          .write(_notesCompanion(notes.normalized()).copyWith(updatedAt: Value(DateTime.now())));

  /// 보기 화면에서 칩을 누를 때 바로 저장한다. 목록 순서가 바뀌지 않게 수정 시각은 그대로 둔다.
  Future<void> setMyRole(int id, String? role) =>
      (db.update(db.scripts)..where((s) => s.id.equals(id))).write(ScriptsCompanion(myRole: Value(role)));

  ScriptsCompanion _notesCompanion(ScriptNotes n) => ScriptsCompanion(
        situation: Value(n.situation),
        objective: Value(n.objective),
        obstacle: Value(n.obstacle),
        author: Value(n.author),
        medium: Value(n.medium),
        sourceUrl: Value(n.sourceUrl),
        synopsis: Value(n.synopsis),
        sceneContext: Value(n.sceneContext),
      );
```

- [ ] **Step 5: 통과 확인**

Run: `flutter test test/data && flutter analyze`
Expected: PASS, `No issues found!`

- [ ] **Step 6: 커밋**

```bash
git add lib/data test/data
git commit -m "feat: schema v4 with dialogue flag, role, and script notes"
```

---
### Task 3: 대사 나누기 (순수 함수)

**Files:**
- Create: `lib/domain/dialogue.dart`
- Test: `test/domain/dialogue_test.dart` (새)

**Interfaces:**
- Produces: `class DialogueLine { final String? speaker; final String text; final bool direction; }` (값 비교 가능); `List<DialogueLine> parseDialogue(String body)`; `bool looksLikeDialogue(String body)` (대사 줄 2줄 이상); `List<String> speakersOf(List<DialogueLine> lines)` (처음 나온 순서, 중복 없음)

- [ ] **Step 1: 실패하는 테스트 작성**

`test/domain/dialogue_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:monologue/domain/dialogue.dart';

DialogueLine say(String who, String text) => DialogueLine(speaker: who, text: text);
DialogueLine note(String text) => DialogueLine(text: text, direction: true);

void main() {
  test('이름: 대사 줄을 인물별로 나눈다', () {
    expect(parseDialogue('민수: 왜 그랬어?\n지영: 몰라.'), [say('민수', '왜 그랬어?'), say('지영', '몰라.')]);
  });

  test('이름 없는 줄은 빈 줄 전까지 앞 인물 대사로 이어진다', () {
    expect(parseDialogue('민수: 왜\n그랬어?\n\n지영: 몰라'), [say('민수', '왜\n그랬어?'), say('지영', '몰라')]);
  });

  test('괄호로만 된 줄은 지문이고, 지문 뒤 이름 없는 줄은 같은 인물 대사다', () {
    expect(parseDialogue('(문이 열린다)\n민수 : 누구야?\n(웃으며)\n나야'), [
      note('(문이 열린다)'),
      say('민수', '누구야?'),
      note('(웃으며)'),
      say('민수', '나야'),
    ]);
  });

  test('빈 줄 뒤에 이름 없이 오는 줄은 지문이다', () {
    expect(parseDialogue('민수: 가\n\n무대가 어두워진다\n조명이 꺼진다'), [
      say('민수', '가'),
      note('무대가 어두워진다\n조명이 꺼진다'),
    ]);
  });

  test('전각 콜론은 대사로, 숫자·링크·긴 문장 앞 콜론은 대사로 보지 않는다', () {
    final lines = parseDialogue('지영：응\n10:30\nhttps://a.b');
    expect(lines, [say('지영', '응\n10:30\nhttps://a.b')]);
    expect(parseDialogue('이것은 열세 글자를 넘는 긴 문장: 끝'), [note('이것은 열세 글자를 넘는 긴 문장: 끝')]);
  });

  test('이름만 있는 줄 다음 줄은 그 인물 대사가 된다', () {
    expect(parseDialogue('민수:\n왜 그랬어?'), [say('민수', '왜 그랬어?')]);
  });

  test('looksLikeDialogue는 대사 줄이 2줄 이상일 때 true', () {
    expect(looksLikeDialogue('민수: 가\n지영: 와'), isTrue);
    expect(looksLikeDialogue('시간: 새벽 세 시\n나는 늘 괜찮다고 말했어.'), isFalse);
  });

  test('speakersOf는 처음 나온 순서로 중복 없이 준다', () {
    expect(speakersOf(parseDialogue('지영: 1\n민수: 2\n지영: 3')), ['지영', '민수']);
  });
}
```

- [ ] **Step 2: 실패 확인**

Run: `flutter test test/domain/dialogue_test.dart`
Expected: FAIL — `dialogue.dart` 없음

- [ ] **Step 3: 구현**

`lib/domain/dialogue.dart`:

```dart
/// 대본의 한 덩어리. [speaker]가 있으면 그 인물의 대사, [direction]이면 지문이다.
class DialogueLine {
  const DialogueLine({this.speaker, required this.text, this.direction = false});

  final String? speaker;
  final String text;
  final bool direction;

  @override
  bool operator ==(Object other) =>
      other is DialogueLine && other.speaker == speaker && other.text == text && other.direction == direction;

  @override
  int get hashCode => Object.hash(speaker, text, direction);

  @override
  String toString() => direction ? 'note($text)' : 'say($speaker, $text)';
}

// 이름은 1~12자, 콜론은 반각·전각 모두
final _speakerLine = RegExp(r'^([^:：]{1,12}?)\s*[:：]\s*(.*)$');
final _digitsOnly = RegExp(r'^\d+$');

(String, String)? _splitSpeaker(String line) {
  final m = _speakerLine.firstMatch(line);
  if (m == null) return null;
  final name = m.group(1)!.trim();
  if (name.isEmpty || _digitsOnly.hasMatch(name) || name.toLowerCase().startsWith('http')) return null;
  return (name, m.group(2)!.trim());
}

/// 평문 본문을 대사·지문으로 나눈다. 규칙은 설계 문서의 "대사 인식 규칙"을 따른다.
List<DialogueLine> parseDialogue(String body) {
  final out = <DialogueLine>[];
  String? current;
  var joinable = false; // 바로 앞 줄에 이어 붙일 수 있는지

  void appendToLast(String line) {
    final last = out.removeLast();
    out.add(DialogueLine(
      speaker: last.speaker,
      text: last.text.isEmpty ? line : '${last.text}\n$line',
      direction: last.direction,
    ));
  }

  for (final raw in body.split('\n')) {
    final line = raw.trim();
    if (line.isEmpty) {
      current = null;
      joinable = false;
      continue;
    }
    if (line.startsWith('(') && line.endsWith(')')) {
      out.add(DialogueLine(text: line, direction: true));
      joinable = false;
      continue;
    }
    final split = _splitSpeaker(line);
    if (split != null) {
      current = split.$1;
      out.add(DialogueLine(speaker: split.$1, text: split.$2));
    } else if (joinable) {
      appendToLast(line);
    } else if (current != null) {
      out.add(DialogueLine(speaker: current, text: line));
    } else {
      out.add(DialogueLine(text: line, direction: true));
    }
    joinable = true;
  }
  return out;
}

bool looksLikeDialogue(String body) =>
    body.split('\n').where((l) => _splitSpeaker(l.trim()) != null).length >= 2;

List<String> speakersOf(List<DialogueLine> lines) => [
      ...{
        for (final l in lines)
          if (l.speaker != null) l.speaker!,
      },
    ];
```

- [ ] **Step 4: 통과 확인**

Run: `flutter test test/domain/dialogue_test.dart`
Expected: PASS (8 tests)

- [ ] **Step 5: 커밋**

```bash
git add lib/domain/dialogue.dart test/domain/dialogue_test.dart
git commit -m "feat: parse speaker-labeled dialogue from plain script text"
```

---

### Task 4: 대화 대본 표시 · 형식 선택 · 내 역할 강조

**Files:**
- Create: `lib/ui/view/script_body.dart`
- Modify: `lib/ui/edit/script_edit_screen.dart`
- Modify: `lib/ui/view/script_view_screen.dart`
- Test: `test/ui/script_body_test.dart` (새), `test/ui/script_edit_screen_test.dart`, `test/ui/script_view_screen_test.dart`

**Interfaces:**
- Consumes: `parseDialogue`, `looksLikeDialogue`, `speakersOf` (Task 3); `Script.dialogue`, `Script.myRole`, `ScriptRepository.setMyRole`, `ScriptDraft.dialogue` (Task 1–2); `keepWords`, `withoutWordJoiners`
- Produces: `class ScriptBody extends StatelessWidget { ScriptBody({required String body, required bool dialogue, required double fontSize, String? focusSpeaker, bool selectable = true}) }` — 고를 수 있는 글은 `SelectableText(keepWords(…))`이고 복사하면 보이지 않는 문자를 뺀다. 인물 이름은 `Text(name)`, 지문은 `Text(keepWords(…))`. Task 6 몰입 읽기에서 `selectable: false`로 쓴다.

- [ ] **Step 1: 실패하는 테스트 작성**

`test/ui/script_body_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monologue/ui/common/korean_text.dart';
import 'package:monologue/ui/theme.dart';
import 'package:monologue/ui/view/script_body.dart';

Widget host(Widget child) =>
    MaterialApp(theme: buildTheme(Brightness.light), home: Scaffold(body: SingleChildScrollView(child: child)));

Finder selectableOf(String text) => find.byWidgetPredicate((w) => w is SelectableText && w.data == keepWords(text));

void main() {
  testWidgets('독백은 본문을 한 덩어리로 보여준다', (tester) async {
    await tester.pumpWidget(host(const ScriptBody(body: '나는 늘 괜찮다고 말했어.', dialogue: false, fontSize: 20)));
    expect(selectableOf('나는 늘 괜찮다고 말했어.'), findsOneWidget);
  });

  testWidgets('대화는 인물 이름을 따로 보여주고 강조 인물이 아닌 대사는 흐리게 한다', (tester) async {
    await tester.pumpWidget(host(const ScriptBody(
      body: '민수: 왜 그랬어?\n지영: 몰라.\n(침묵)',
      dialogue: true,
      fontSize: 20,
      focusSpeaker: '지영',
    )));
    expect(find.text('민수'), findsOneWidget);
    expect(find.text('지영'), findsOneWidget);
    expect(find.text(keepWords('(침묵)')), findsOneWidget);
    double alphaOf(String text) => tester.widget<SelectableText>(selectableOf(text)).style!.color!.a;
    expect(alphaOf('몰라.'), 1.0);
    expect(alphaOf('왜 그랬어?'), lessThan(0.5));
  });

  testWidgets('selectable이 false면 고를 수 없는 글로 보여준다', (tester) async {
    await tester.pumpWidget(host(const ScriptBody(body: '민수: 가자', dialogue: true, fontSize: 20, selectable: false)));
    expect(find.byType(SelectableText), findsNothing);
    expect(find.text(keepWords('가자')), findsOneWidget);
  });
}
```

`test/ui/script_edit_screen_test.dart` — `main()` 끝에:

```dart
  testWidgets('인물 대사가 두 줄 이상인 새 대본은 대화 형식으로 시작해 저장된다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    await tester.pumpWidget(h.wrap(const ScriptEditScreen(initialBody: '민수: 왜 그랬어?\n지영: 몰라.')));
    await tester.pumpAndSettle();
    expect(tester.widget<SegmentedButton<bool>>(find.byType(SegmentedButton<bool>)).selected, {true});
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    final list = await tester.runAsync(() => h.services.repo.watchScripts(const ScriptFilter()).first);
    expect(list!.single.script.dialogue, isTrue);
    await tester.runAsync(h.db.close);
  });
```

`test/ui/script_view_screen_test.dart` — import `package:monologue/ui/common/korean_text.dart` 추가, `main()` 끝에:

```dart
  testWidgets('대화 대본은 저장된 내 역할을 강조하고, 칩을 누르면 역할이 바뀌어 저장된다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    final id = (await tester.runAsync(() => h.services.repo.create(const ScriptDraft(
          work: '장면',
          body: '민수: 왜 그랬어?\n지영: 몰라.',
          dialogue: true,
          myRole: '지영',
        ))))!;
    await tester.pumpWidget(h.wrap(ScriptViewScreen(scriptId: id)));
    await tester.pumpAndSettle();

    double alphaOf(String text) => tester
        .widget<SelectableText>(find.byWidgetPredicate((w) => w is SelectableText && w.data == keepWords(text)))
        .style!
        .color!
        .a;
    expect(alphaOf('왜 그랬어?'), lessThan(0.5));

    await tester.tap(find.widgetWithText(FilterChip, '민수'));
    await tester.pumpAndSettle();
    expect(alphaOf('왜 그랬어?'), 1.0);
    expect(alphaOf('몰라.'), lessThan(0.5));
    final saved = await tester.runAsync(() => h.services.repo.watchScript(id).first);
    expect(saved!.script.myRole, '민수');
    await tester.runAsync(h.db.close);
  });
```

- [ ] **Step 2: 실패 확인**

Run: `flutter test test/ui`
Expected: FAIL — `script_body.dart` 없음, `SegmentedButton<bool>` 없음, 인물 칩 없음

- [ ] **Step 3: 본문 위젯 구현**

`lib/ui/view/script_body.dart` (보기 화면 본문에 있던 복사 메뉴를 옮겨 온다):

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/dialogue.dart';
import '../common/korean_text.dart';
import '../theme.dart';

/// 대본 본문. 대화 형식이면 인물 이름을 대사 위에 두고, [focusSpeaker]가 아닌 대사는 흐리게 한다.
/// 띄어쓰기에서만 줄이 바뀌도록 [keepWords]로 보여 주고, 복사할 때는 보이지 않는 문자를 뺀다.
class ScriptBody extends StatelessWidget {
  const ScriptBody({
    super.key,
    required this.body,
    required this.dialogue,
    required this.fontSize,
    this.focusSpeaker,
    this.selectable = true,
  });

  final String body;
  final bool dialogue;
  final double fontSize;
  final String? focusSpeaker;

  /// 몰입 읽기처럼 탭이 다른 일을 해야 하는 화면에서는 글자 선택을 끈다
  final bool selectable;

  static Widget _copyWithoutJoiners(BuildContext context, EditableTextState editable) =>
      AdaptiveTextSelectionToolbar.buttonItems(
        anchors: editable.contextMenuAnchors,
        buttonItems: [
          for (final item in editable.contextMenuButtonItems)
            if (item.type == ContextMenuButtonType.copy)
              item.copyWith(onPressed: () {
                final value = editable.textEditingValue;
                Clipboard.setData(ClipboardData(text: withoutWordJoiners(value.selection.textInside(value.text))));
                editable.hideToolbar();
              })
            else
              item,
        ],
      );

  Widget _text(String value, TextStyle style) => selectable
      ? SelectableText(keepWords(value), style: style, contextMenuBuilder: _copyWithoutJoiners)
      : Text(keepWords(value), style: style);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final base = TextStyle(fontFamily: serifFamily, fontSize: fontSize, height: 1.85, color: scheme.onSurface);
    if (!dialogue) return _text(body, base);

    Widget line(DialogueLine l) {
      if (l.direction) {
        return Text(keepWords(l.text), style: base.copyWith(fontSize: fontSize * 0.85, color: scheme.onSurfaceVariant));
      }
      final focused = focusSpeaker == l.speaker;
      final dim = focusSpeaker != null && !focused;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.speaker!,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: focused ? scheme.primary : scheme.onSurfaceVariant.withValues(alpha: dim ? 0.5 : 1),
            ),
          ),
          const SizedBox(height: 2),
          _text(l.text, base.copyWith(color: scheme.onSurface.withValues(alpha: dim ? 0.38 : 1))),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final l in parseDialogue(body))
          Padding(padding: EdgeInsets.only(bottom: fontSize * 0.9), child: line(l)),
      ],
    );
  }
}
```

- [ ] **Step 4: 편집 화면에 형식 선택 추가**

`lib/ui/edit/script_edit_screen.dart`:

import 추가:

```dart
import '../../domain/dialogue.dart';
```

상태 필드(`late bool _favorite;` 아래):

```dart
  late bool _dialogue;
```

`initState`의 `_favorite = ...` 아래:

```dart
    _dialogue = s?.dialogue ?? looksLikeDialogue(widget.initialBody);
```

`_save()`의 `ScriptDraft(...)`에서 `tags: _tags,` 다음 줄:

```dart
      dialogue: _dialogue,
```

`build` 첫 줄(`const gap = ...` 위)에:

```dart
    final theme = Theme.of(context);
```

`_section('본문'),`과 본문 `TextFormField` 사이에:

```dart
                SegmentedButton<bool>(
                  expandedInsets: EdgeInsets.zero,
                  segments: const [
                    ButtonSegment(value: false, label: Text('독백')),
                    ButtonSegment(value: true, label: Text('대화')),
                  ],
                  selected: {_dialogue},
                  showSelectedIcon: false,
                  onSelectionChanged: (v) => setState(() {
                    _dialogue = v.first;
                    _dirty = true;
                  }),
                ),
                if (_dialogue)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      keepWords('줄 앞에 이름과 콜론을 쓰면 인물 대사로 보여요. 괄호로만 된 줄은 지문이에요.'),
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                const SizedBox(height: 12),
```

본문 `TextFormField`의 `decoration`을 형식에 따라 바꾼다(`const` 제거):

```dart
                  decoration: InputDecoration(
                    hintText: _dialogue ? '민수: 왜 그랬어?\n지영: 몰라.' : '대본 내용을 입력하세요',
                    contentPadding: const EdgeInsets.all(18),
                  ),
```

- [ ] **Step 5: 보기 화면에 인물 칩과 본문 위젯 적용**

`lib/ui/view/script_view_screen.dart`:

import 추가(`package:flutter/services.dart`는 본문 위젯으로 옮겨 가므로 지운다):

```dart
import '../../domain/dialogue.dart';
import '../common/pill_chip.dart';
import 'script_body.dart';
```

`build`의 `final hasLabels = ...` 아래:

```dart
        final speakers = s.dialogue ? speakersOf(parseDialogue(s.body)) : const <String>[];
        final focus = speakers.contains(s.myRole) ? s.myRole : null;
```

`if (memo != null) Padding(...)` 블록 바로 뒤에 인물 칩:

```dart
              if (speakers.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: source != null || hasLabels || memo != null ? 20 : 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('내 역할', style: theme.textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          for (final name in speakers)
                            PillChip(
                              label: name,
                              selected: name == focus,
                              onSelected: (_) => services.repo.setMyRole(s.id, name == focus ? null : name),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
```

구분선 조건을 인물 칩까지 포함하도록 바꾼다:

```dart
              if (source != null || hasLabels || memo != null || speakers.isNotEmpty) ...[
```

본문 `ListenableBuilder`의 `builder` 전체(복사 메뉴가 붙은 `SelectableText`)를 교체:

```dart
                builder: (context, _) => ScriptBody(
                  body: s.body,
                  dialogue: s.dialogue,
                  fontSize: services.settings.fontSize,
                  focusSpeaker: focus,
                ),
```

- [ ] **Step 6: 통과 확인**

Run: `flutter test test/ui && flutter analyze`
Expected: PASS(기존 복사 테스트 포함), `No issues found!`

- [ ] **Step 7: 커밋**

```bash
git add lib/ui test/ui
git commit -m "feat: dialogue format with speaker names and a saved role focus"
```

---

### Task 5: 대본 노트 화면과 요약 카드

**Files:**
- Create: `lib/ui/common/section_header.dart`
- Create: `lib/ui/notes/notes_screen.dart`
- Modify: `lib/ui/edit/script_edit_screen.dart` (구역 제목을 공용 위젯으로)
- Modify: `lib/ui/view/script_view_screen.dart`
- Test: `test/ui/notes_screen_test.dart` (새), `test/ui/script_view_screen_test.dart`

**Interfaces:**
- Consumes: `ScriptNotes`, `ScriptMedium` (Task 1); `Script.notes`, `ScriptRepository.updateNotes` (Task 2); 보기 화면의 `speakers` 변수 (Task 4); `PillChip`, `keepWords`
- Produces: `class SectionHeader extends StatelessWidget { SectionHeader(String text, {bool first = false}) }`; `class NotesScreen extends StatefulWidget { NotesScreen({required Script script}) }`

- [ ] **Step 1: 실패하는 테스트 작성**

`test/ui/notes_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monologue/data/script_repository.dart';
import 'package:monologue/domain/enums.dart';
import 'package:monologue/domain/script_draft.dart';
import 'package:monologue/domain/script_notes.dart';
import 'package:monologue/ui/notes/notes_screen.dart';

import 'test_harness.dart';

void main() {
  testWidgets('노트를 적고 저장하면 대본에 반영된다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    final script = (await tester.runAsync(() async {
      final id = await h.services.repo.create(const ScriptDraft(work: '갈매기', body: 'x'));
      return (await h.services.repo.watchScript(id).first)!.script;
    }))!;
    await tester.pumpWidget(h.wrap(NotesScreen(script: script)));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, '상황'), '호숫가 무대, 공연 직후');
    await tester.enterText(find.widgetWithText(TextFormField, '원하는 것'), '인정받기');
    await tester.ensureVisible(find.text('연극'));
    await tester.tap(find.text('연극'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    final saved = (await tester.runAsync(() => h.services.repo.watchScript(script.id).first))!.script.notes;
    expect(saved, const ScriptNotes(situation: '호숫가 무대, 공연 직후', objective: '인정받기', medium: ScriptMedium.play));
    await tester.runAsync(h.db.close);
  });
}
```

`test/ui/script_view_screen_test.dart` — import `package:monologue/domain/script_notes.dart` 추가, `main()` 끝에:

```dart
  testWidgets('상황이나 원하는 것이 있으면 본문 위에 요약을 보여준다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    final id = (await tester.runAsync(() => h.services.repo.create(const ScriptDraft(
          work: '독백',
          body: '괜찮다는 말은 참 편리하더라.',
          notes: ScriptNotes(situation: '새벽 세 시, 부엌', objective: '들키지 않기'),
        ))))!;
    await tester.pumpWidget(h.wrap(ScriptViewScreen(scriptId: id)));
    await tester.pumpAndSettle();
    expect(find.text(keepWords('새벽 세 시, 부엌')), findsOneWidget);
    expect(find.text(keepWords('들키지 않기')), findsOneWidget);
    await tester.runAsync(h.db.close);
  });
```

- [ ] **Step 2: 실패 확인**

Run: `flutter test test/ui/notes_screen_test.dart test/ui/script_view_screen_test.dart`
Expected: FAIL — `notes_screen.dart` 없음, 요약 없음

- [ ] **Step 3: 공용 구역 제목 위젯**

`lib/ui/common/section_header.dart` (편집 화면의 `_section`을 옮긴 것):

```dart
import 'package:flutter/material.dart';

/// 구역 제목과 오른쪽으로 이어지는 가는 선
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.text, {super.key, this.first = false});

  final String text;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(top: first ? 4 : 32, bottom: 14),
      child: Row(
        children: [
          Text(
            text,
            style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}
```

`lib/ui/edit/script_edit_screen.dart`: `import '../common/section_header.dart';` 추가, `_section` 메서드를 지우고 호출을 바꾼다 — `_section('기본 정보', first: true)` → `const SectionHeader('기본 정보', first: true)`, `_section('배역')` → `const SectionHeader('배역')`, `_section('즐겨찾기 · 태그')` → `const SectionHeader('즐겨찾기 · 태그')`, `_section('본문')` → `const SectionHeader('본문')`.

- [ ] **Step 4: 노트 화면 구현**

`lib/ui/notes/notes_screen.dart`:

```dart
import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../data/database.dart';
import '../../data/script_repository.dart';
import '../../domain/enums.dart';
import '../../domain/script_notes.dart';
import '../common/pill_chip.dart';
import '../common/section_header.dart';

/// 대본 분석과 작품 맥락을 적는다. 저장 버튼을 누를 때만 반영한다.
class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key, required this.script});

  final Script script;

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  late final ScriptNotes _initial = widget.script.notes.normalized();
  late final _situation = TextEditingController(text: _initial.situation);
  late final _objective = TextEditingController(text: _initial.objective);
  late final _obstacle = TextEditingController(text: _initial.obstacle);
  late final _author = TextEditingController(text: _initial.author);
  late final _sourceUrl = TextEditingController(text: _initial.sourceUrl);
  late final _synopsis = TextEditingController(text: _initial.synopsis);
  late final _sceneContext = TextEditingController(text: _initial.sceneContext);
  late ScriptMedium? _medium = _initial.medium;
  bool _saving = false;
  bool _leaving = false;

  List<TextEditingController> get _controllers =>
      [_situation, _objective, _obstacle, _author, _sourceUrl, _synopsis, _sceneContext];

  ScriptNotes get _notes => ScriptNotes(
        situation: _situation.text,
        objective: _objective.text,
        obstacle: _obstacle.text,
        author: _author.text,
        medium: _medium,
        sourceUrl: _sourceUrl.text,
        synopsis: _synopsis.text,
        sceneContext: _sceneContext.text,
      ).normalized();

  bool get _dirty => !_leaving && _notes != _initial;

  @override
  void initState() {
    super.initState();
    for (final c in _controllers) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  /// PopScope가 바뀐 상태를 읽은 뒤에 닫히도록 다음 프레임에 pop한다.
  void _leave() {
    setState(() => _leaving = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await AppScope.of(context).repo.updateNotes(widget.script.id, _notes);
      if (mounted) _leave();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('저장하지 못했어요. 다시 시도해 주세요.')));
    }
  }

  Future<void> _confirmLeave() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: const Text('저장하지 않고 나갈까요? 적은 내용은 사라져요.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('계속 쓰기')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('나가기')),
        ],
      ),
    );
    if (leave == true && mounted) _leave();
  }

  Widget _field(TextEditingController c, String label, {String? hint, int minLines = 1, TextInputType? keyboard}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: c,
          minLines: minLines,
          maxLines: null,
          keyboardType: keyboard ?? TextInputType.multiline,
          decoration: InputDecoration(labelText: label, hintText: hint, alignLabelWithHint: minLines > 1),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('노트'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 38),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('저장'),
                ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionHeader('분석', first: true),
              _field(_situation, '상황', hint: '누가, 어디서, 언제, 바로 전에 무슨 일이 있었나요', minLines: 2),
              _field(_objective, '원하는 것', hint: '이 인물이 상대에게서 얻고 싶은 것'),
              _field(_obstacle, '가로막는 것', hint: '그걸 얻지 못하게 막는 것'),
              const SectionHeader('작품 맥락'),
              _field(_author, '작가'),
              Text('매체', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final m in ScriptMedium.values)
                    PillChip(
                      label: m.label,
                      selected: m == _medium,
                      onSelected: (_) => setState(() => _medium = m == _medium ? null : m),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _field(_sourceUrl, '출처 링크', keyboard: TextInputType.url),
              _field(_synopsis, '작품 줄거리', minLines: 3),
              _field(_sceneContext, '이 장면 앞뒤', hint: '이 장면 직전과 직후에 일어나는 일', minLines: 3),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: 보기 화면에 노트 버튼과 요약 카드**

`lib/ui/view/script_view_screen.dart` — import 추가:

```dart
import '../../domain/script_notes.dart';
import '../notes/notes_screen.dart';
```

AppBar `actions`에서 `글자 크기` IconButton을 지우고 그 자리에 노트 버튼:

```dart
              IconButton(
                tooltip: '노트',
                icon: const Icon(Icons.sticky_note_2_outlined),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => NotesScreen(script: s)),
                ),
              ),
```

`PopupMenuButton`의 `onSelected`에 `else if (v == 'fontSize') { _showFontSize(services.settings); }`를 넣고, `itemBuilder`의 `delete` 항목 앞에:

```dart
                  const PopupMenuItem(
                    value: 'fontSize',
                    child: _MenuRow(icon: Icons.format_size_rounded, text: '글자 크기'),
                  ),
```

`build`의 `final focus = ...`(Task 4) 아래:

```dart
        final notes = s.notes;
        final showNotes = notes.situation != null || notes.objective != null;
```

인물 칩 블록(Task 4) 뒤에:

```dart
              if (showNotes)
                Padding(
                  padding: EdgeInsets.only(
                    top: source != null || hasLabels || memo != null || speakers.isNotEmpty ? 20 : 0,
                  ),
                  child: _NotesSummary(
                    notes: notes,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => NotesScreen(script: s)),
                    ),
                  ),
                ),
```

구분선 조건에 `|| showNotes`를 더한다:

```dart
              if (source != null || hasLabels || memo != null || speakers.isNotEmpty || showNotes) ...[
```

파일 끝에 위젯 추가:

```dart
class _NotesSummary extends StatelessWidget {
  const _NotesSummary({required this.notes, required this.onTap});

  final ScriptNotes notes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    Widget row(String label, String value) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.labelMedium?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(
                keepWords(value),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
            ],
          ),
        );
    return Material(
      color: scheme.surfaceContainerLowest,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: scheme.outlineVariant)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (notes.situation case final v?) row('상황', v),
              if (notes.objective case final v?) row('원하는 것', v),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: 통과 확인**

Run: `flutter test test/ui && flutter analyze`
Expected: PASS, `No issues found!`

- [ ] **Step 7: 커밋**

```bash
git add lib/ui test/ui
git commit -m "feat: script analysis and work context notes"
```

---

### Task 6: 몰입 읽기

**Files:**
- Create: `lib/platform/screen_awake.dart`
- Create: `lib/ui/view/immersive_reader_screen.dart`
- Modify: `lib/app_scope.dart`, `lib/main.dart`, `test/ui/test_harness.dart`
- Modify: `lib/ui/view/script_view_screen.dart` (몰입 읽기 버튼)
- Modify: `ios/Runner/AppDelegate.swift`, `android/app/src/main/kotlin/com/tacowasabii/monologue/MainActivity.kt`
- Test: `test/ui/immersive_reader_screen_test.dart` (새)

**Interfaces:**
- Consumes: `ScriptBody(selectable: false)` (Task 4), `Script.notes` (Task 2), `firstLineOf`, `keepWords`, `ReadingSettings`
- Produces: `abstract interface class ScreenAwake { Future<void> keepOn(bool on); }`, `PlatformScreenAwake`; `AppServices.screen` (ScreenAwake); 테스트용 `FakeScreenAwake` (`calls: List<bool>`)와 `Harness.screen`; `ImmersiveReaderScreen({required Script script, String? focusSpeaker})`

- [ ] **Step 1: 실패하는 테스트 작성**

`test/ui/immersive_reader_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monologue/domain/script_draft.dart';
import 'package:monologue/domain/script_notes.dart';
import 'package:monologue/ui/common/korean_text.dart';
import 'package:monologue/ui/view/immersive_reader_screen.dart';

import 'test_harness.dart';

void main() {
  testWidgets('몰입 읽기는 화면 꺼짐을 막고, 닫으면 풀고, 탭하면 메뉴가 나온다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    final script = (await tester.runAsync(() async {
      final id = await h.services.repo.create(const ScriptDraft(
        work: '독백',
        body: '괜찮다는 말은 참 편리하더라.',
        notes: ScriptNotes(situation: '새벽 세 시, 부엌'),
      ));
      return (await h.services.repo.watchScript(id).first)!.script;
    }))!;
    await tester.pumpWidget(h.wrap(ImmersiveReaderScreen(script: script)));
    await tester.pumpAndSettle();

    expect(h.screen.calls, [true]);
    expect(find.text(keepWords('새벽 세 시, 부엌')), findsOneWidget);
    expect(find.byTooltip('몰입 읽기 닫기').hitTestable(), findsNothing);

    await tester.tap(find.text(keepWords('괜찮다는 말은 참 편리하더라.')));
    await tester.pumpAndSettle();
    expect(find.byTooltip('몰입 읽기 닫기').hitTestable(), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    expect(h.screen.calls, [true, false]);
    await tester.runAsync(h.db.close);
  });
}
```

- [ ] **Step 2: 실패 확인**

Run: `flutter test test/ui/immersive_reader_screen_test.dart`
Expected: FAIL — `immersive_reader_screen.dart`, `h.screen` 없음

- [ ] **Step 3: 화면 꺼짐 방지 서비스와 주입**

`lib/platform/screen_awake.dart`:

```dart
import 'package:flutter/services.dart';

abstract interface class ScreenAwake {
  Future<void> keepOn(bool on);
}

/// iOS: `isIdleTimerDisabled`(AppDelegate.swift), Android: `FLAG_KEEP_SCREEN_ON`(MainActivity.kt).
class PlatformScreenAwake implements ScreenAwake {
  static const _channel = MethodChannel('monologue/screen');

  @override
  Future<void> keepOn(bool on) => _channel.invokeMethod<void>('keepOn', {'on': on});
}
```

`lib/app_scope.dart` — import `platform/screen_awake.dart`, `AppServices`에 `required this.screen,`과 `final ScreenAwake screen;` 추가.

`lib/main.dart` — import `platform/screen_awake.dart`, `AppServices(...)`의 `tips: ...` 다음에 `screen: PlatformScreenAwake(),` 추가.

`test/ui/test_harness.dart` — import `package:monologue/platform/screen_awake.dart`, 가짜 구현을 `FakeRecognizer` 아래에 추가:

```dart
class FakeScreenAwake implements ScreenAwake {
  final calls = <bool>[];

  @override
  Future<void> keepOn(bool on) async => calls.add(on);
}
```

`Harness`를 바꾼다:

```dart
class Harness {
  Harness._(this.db, this.services, this.screen);

  final AppDatabase db;
  final AppServices services;
  final FakeScreenAwake screen;

  static Future<Harness> create() async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final db = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    final images = ImageStore(Directory.systemTemp.createTempSync('monologue_ui'));
    final repo = ScriptRepository(db, images);
    final screen = FakeScreenAwake();
    return Harness._(
      db,
      AppServices(
        repo: repo,
        images: images,
        ocr: FakeRecognizer(),
        backup: BackupService(db, repo, images),
        settings: await ReadingSettings.load(),
        tips: await AppTips.load(),
        screen: screen,
      ),
      screen,
    );
  }
```

(`wrap`은 그대로 둔다.)

- [ ] **Step 4: 몰입 읽기 화면 구현**

`lib/ui/view/immersive_reader_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_scope.dart';
import '../../data/database.dart';
import '../../data/script_repository.dart';
import '../../domain/script_draft.dart';
import '../../platform/screen_awake.dart';
import '../common/korean_text.dart';
import 'script_body.dart';

/// 메뉴 없이 대본만 보여준다. 상태 표시줄을 숨기고 화면이 꺼지지 않게 하며, 탭하면 메뉴가 나온다.
class ImmersiveReaderScreen extends StatefulWidget {
  const ImmersiveReaderScreen({super.key, required this.script, this.focusSpeaker});

  final Script script;
  final String? focusSpeaker;

  @override
  State<ImmersiveReaderScreen> createState() => _ImmersiveReaderScreenState();
}

class _ImmersiveReaderScreenState extends State<ImmersiveReaderScreen> {
  ScreenAwake? _screen;
  bool _chrome = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_screen != null) return;
    _screen = AppScope.of(context).screen..keepOn(true);
  }

  @override
  void dispose() {
    _screen?.keepOn(false);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final settings = AppScope.of(context).settings;
    final s = widget.script;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _chrome = !_chrome),
        child: Stack(
          children: [
            SafeArea(
              child: ListenableBuilder(
                listenable: settings,
                builder: (context, _) => ListView(
                  padding: const EdgeInsets.fromLTRB(28, 56, 28, 120),
                  children: [
                    Text(keepWords(s.work ?? firstLineOf(s.body)), style: theme.textTheme.headlineSmall),
                    if (s.notes.situation case final situation?)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          keepWords(situation),
                          style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant, height: 1.6),
                        ),
                      ),
                    const SizedBox(height: 40),
                    ScriptBody(
                      body: s.body,
                      dialogue: s.dialogue,
                      fontSize: settings.fontSize,
                      focusSpeaker: widget.focusSpeaker,
                      selectable: false,
                    ),
                  ],
                ),
              ),
            ),
            IgnorePointer(
              ignoring: !_chrome,
              child: AnimatedOpacity(
                opacity: _chrome ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        IconButton.filledTonal(
                          tooltip: '몰입 읽기 닫기',
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                        const Spacer(),
                        IconButton.filledTonal(
                          tooltip: '글자 작게',
                          icon: const Icon(Icons.text_decrease_rounded),
                          onPressed: () => settings.setFontSize(settings.fontSize - 2),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          tooltip: '글자 크게',
                          icon: const Icon(Icons.text_increase_rounded),
                          onPressed: () => settings.setFontSize(settings.fontSize + 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

(`ReadingSettings.setFontSize`가 14~32로 자른다.)

- [ ] **Step 5: 보기 화면에 몰입 읽기 버튼**

`lib/ui/view/script_view_screen.dart` — import `immersive_reader_screen.dart`, 대본이 있을 때의 `Scaffold`에:

```dart
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => ImmersiveReaderScreen(script: s, focusSpeaker: focus),
            )),
            icon: const Icon(Icons.menu_book_rounded),
            label: const Text('몰입 읽기'),
          ),
```

`ListView`의 `padding`을 `EdgeInsets.fromLTRB(24, 4, 24, 112)`로 늘려 버튼이 본문 끝을 가리지 않게 한다.

- [ ] **Step 6: 네이티브 구현**

`ios/Runner/AppDelegate.swift` — `didInitializeImplicitFlutterEngine`의 OCR 등록 뒤에:

```swift
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "MonologueScreenPlugin") {
      ScreenPlugin.register(with: registrar)
    }
```

파일 끝에:

```swift
/// 몰입 읽기 동안 화면이 꺼지지 않게 한다. Dart의 `PlatformScreenAwake`와 짝을 이룬다.
final class ScreenPlugin: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "monologue/screen", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(ScreenPlugin(), channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "keepOn", let args = call.arguments as? [String: Any], let on = args["on"] as? Bool else {
      result(FlutterMethodNotImplemented)
      return
    }
    UIApplication.shared.isIdleTimerDisabled = on
    result(nil)
  }
}
```

`MainActivity.kt` — `import android.view.WindowManager` 추가, `configureFlutterEngine`의 OCR 채널 등록 뒤에:

```kotlin
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "monologue/screen").setMethodCallHandler { call, result ->
            if (call.method != "keepOn") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            if (call.argument<Boolean>("on") == true) {
                window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            } else {
                window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            }
            result.success(null)
        }
```

- [ ] **Step 7: 통과 확인**

Run: `flutter test && flutter analyze && flutter build ios --simulator --debug`
Expected: 전체 PASS, `No issues found!`, `✓ Built`

- [ ] **Step 8: 기기 확인**

시뮬레이터에서 대본 보기 → `몰입 읽기`: 상태 표시줄이 사라지는지, 탭하면 닫기·글자 크기 버튼이 나오는지, 닫으면 상태 표시줄이 돌아오는지 확인한다. Android 에뮬레이터에서도 같은 확인을 한다(`flutter build apk --debug`).

- [ ] **Step 9: 커밋**

```bash
git add lib test ios/Runner/AppDelegate.swift android/app/src/main/kotlin
git commit -m "feat: immersive reading mode that keeps the screen on"
```

---

### Task 7: 백업 형식 v2와 대본 하나 내보내기·가져오기

**Files:**
- Modify: `lib/backup/backup_service.dart`
- Test: `test/backup/backup_service_test.dart`

**Interfaces:**
- Consumes: `Script.notes/dialogue/myRole`, `ScriptRepository.insertRestored` (Task 2), `ScriptNotes.toJson/fromJson` (Task 1), `firstLineOf`
- Produces: `BackupService.version == 2`; `Future<File> BackupService.exportScript(int id, Directory outDir, {bool includeImages = false})` → `<대본 이름>.monologue`; `Future<List<int>> BackupService.importArchive(List<int> zipBytes)` → 새 대본 id 목록(실패 시 `BackupFormatException`, 아무것도 바꾸지 않음); `restore`는 계속 개수를 돌려준다

- [ ] **Step 1: 실패하는 테스트 작성**

`test/backup/backup_service_test.dart` — import `package:monologue/domain/script_notes.dart` 추가, `main()` 끝에:

```dart
  test('version 2 백업은 대화 형식·내 역할·노트를 옮긴다', () async {
    final src = await newEnv('src');
    await src.repo.create(const ScriptDraft(
      work: '장면',
      body: '민수: 가\n지영: 와',
      dialogue: true,
      myRole: '지영',
      notes: ScriptNotes(situation: '새벽', author: '작가', medium: ScriptMedium.play),
    ));
    final bytes = await (await src.backup.export(tmp)).readAsBytes();
    final dst = await newEnv('dst');
    await dst.backup.restore(bytes);
    final s = (await dst.repo.watchScripts(const ScriptFilter()).first).single.script;
    expect(s.dialogue, isTrue);
    expect(s.myRole, '지영');
    expect(s.notes, const ScriptNotes(situation: '새벽', author: '작가', medium: ScriptMedium.play));
  });

  test('version 1 백업도 복원하고 형식은 독백, 역할·노트는 비운다', () async {
    final src = await newEnv('src');
    await src.repo.create(
      const ScriptDraft(work: '옛 대본', body: '본문', dialogue: true, myRole: '민수', notes: ScriptNotes(obstacle: 'o')),
    );
    final bytes = await (await src.backup.export(tmp)).readAsBytes();
    final v1 = BackupService.debugRewriteManifest(bytes, (m) {
      m['version'] = 1;
      for (final e in (m['scripts'] as List).cast<Map<String, Object?>>()) {
        e
          ..remove('dialogue')
          ..remove('myRole')
          ..remove('notes');
      }
      return m;
    });
    final dst = await newEnv('dst');
    expect(await dst.backup.restore(v1), 1);
    final s = (await dst.repo.watchScripts(const ScriptFilter()).first).single.script;
    expect(s.work, '옛 대본');
    expect(s.dialogue, isFalse);
    expect(s.myRole, isNull);
    expect(s.notes.isEmpty, isTrue);
  });

  test('exportScript는 대본 하나를 사진 없이 .monologue 파일로 만들고 importArchive로 받는다', () async {
    final src = await newEnv('src');
    final img = File('${tmp.path}/shot.png')..writeAsBytesSync([1, 2, 3]);
    final id = await src.repo.create(
      const ScriptDraft(work: '갈매기', body: '나는 갈매기', tags: ['희망'], notes: ScriptNotes(objective: '인정받기')),
      imagePaths: [img.path],
    );
    await src.repo.create(const ScriptDraft(work: '다른 대본', body: 'x'));

    final file = await src.backup.exportScript(id, tmp);
    expect(file.path.endsWith('/갈매기.monologue'), isTrue);

    final dst = await newEnv('dst');
    final ids = await dst.backup.importArchive(await file.readAsBytes());
    expect(ids, hasLength(1));
    final detail = (await dst.repo.watchScript(ids.single).first)!;
    expect(detail.script.work, '갈매기');
    expect(detail.tags, ['희망']);
    expect(detail.script.notes.objective, '인정받기');
    expect(detail.images, isEmpty);
  });

  test('exportScript에서 사진 포함을 켜면 사진도 옮기고, 이름은 작품명이 없으면 본문 첫 줄에서 못 쓰는 글자를 바꾼다', () async {
    final src = await newEnv('src');
    final img = File('${tmp.path}/shot.png')..writeAsBytesSync([4, 5, 6]);
    final id = await src.repo.create(const ScriptDraft(body: '누구/왜?\n둘째 줄'), imagePaths: [img.path]);

    final file = await src.backup.exportScript(id, tmp, includeImages: true);
    expect(file.path.endsWith('/누구_왜_.monologue'), isTrue);

    final dst = await newEnv('dst');
    final ids = await dst.backup.importArchive(await file.readAsBytes());
    final detail = (await dst.repo.watchScript(ids.single).first)!;
    expect(File(dst.images.pathOf(detail.images.single.fileName)).readAsBytesSync(), [4, 5, 6]);
  });
```

- [ ] **Step 2: 실패 확인**

Run: `flutter test test/backup`
Expected: FAIL — `exportScript`, `importArchive` 없음, 형식·역할·노트가 옮겨지지 않음

- [ ] **Step 3: 구현**

`lib/backup/backup_service.dart` — import `../domain/script_notes.dart` 추가, `static const version = 2;`.

`export`를 공용 함수로 나누고 `exportScript`를 더한다(기존 `export` 본문 전체를 아래로 교체):

```dart
  Future<File> export(Directory outDir, {DateTime? now}) async {
    final scripts = await db.select(db.scripts).get();
    final archive = await _archiveOf(scripts, includeImages: true);
    final stamp = DateFormat('yyyyMMdd').format(now ?? DateTime.now());
    final file = File(p.join(outDir.path, 'monologue-backup-$stamp.zip'));
    await file.writeAsBytes(ZipEncoder().encodeBytes(archive), flush: true);
    return file;
  }

  /// 대본 하나를 공유용 `.monologue` 파일로 만든다. 원본 사진은 [includeImages]일 때만 넣는다.
  Future<File> exportScript(int id, Directory outDir, {bool includeImages = false}) async {
    final script = await (db.select(db.scripts)..where((s) => s.id.equals(id))).getSingle();
    final archive = await _archiveOf([script], includeImages: includeImages);
    final file = File(p.join(outDir.path, '${_fileNameOf(script.work ?? firstLineOf(script.body))}.monologue'));
    await file.writeAsBytes(ZipEncoder().encodeBytes(archive), flush: true);
    return file;
  }

  Future<Archive> _archiveOf(List<Script> scripts, {required bool includeImages}) async {
    final ids = scripts.map((s) => s.id).toList();
    final tags = await (db.select(db.scriptTags)..where((t) => t.scriptId.isIn(ids))).get();
    final imgs = await (db.select(db.scriptImages)
          ..where((i) => i.scriptId.isIn(ids))
          ..orderBy([(i) => OrderingTerm.asc(i.position)]))
        .get();

    final archive = Archive();
    final entries = <Map<String, Object?>>[];
    for (final s in scripts) {
      final myImages =
          includeImages ? imgs.where((i) => i.scriptId == s.id).map((i) => i.fileName).toList() : <String>[];
      for (final name in myImages) {
        archive.addFile(ArchiveFile.bytes('images/$name', await File(images.pathOf(name)).readAsBytes()));
      }
      entries.add({
        'work': s.work,
        'memo': s.memo,
        'gender': s.gender.name,
        'ageRange': s.ageRange.name,
        'status': s.status.name,
        'favorite': s.favorite,
        'body': s.body,
        'dialogue': s.dialogue,
        'myRole': s.myRole,
        'notes': s.notes.toJson(),
        'createdAt': s.createdAt.toIso8601String(),
        'updatedAt': s.updatedAt.toIso8601String(),
        'tags': tags.where((t) => t.scriptId == s.id).map((t) => t.tag).toList(),
        'images': myImages,
      });
    }
    archive.addFile(ArchiveFile.string(_manifest, jsonEncode({'format': format, 'version': version, 'scripts': entries})));
    return archive;
  }

  static String _fileNameOf(String name) {
    final cleaned = name.replaceAll(RegExp(r'[\\/:*?"<>|\n\r]'), '_').trim();
    if (cleaned.isEmpty) return '대본';
    return cleaned.length <= 40 ? cleaned : cleaned.substring(0, 40);
  }
```

`restore`를 `importArchive`로 옮기고 새 id를 모은다(기존 `restore` 본문 전체를 아래로 교체):

```dart
  /// 백업의 대본을 현재 데이터에 추가하고 추가한 개수를 돌려준다. 실패하면 아무것도 바꾸지 않는다.
  Future<int> restore(List<int> zipBytes) async => (await importArchive(zipBytes)).length;

  /// 백업·공유 파일의 대본을 새 대본으로 추가하고 새 id를 돌려준다. 실패하면 아무것도 바꾸지 않는다.
  Future<List<int>> importArchive(List<int> zipBytes) async {
    final (archive, entries) = _parse(zipBytes);
    final stored = <String>[];
    try {
      final plans = <(ScriptDraft, DateTime, DateTime, List<String>)>[];
      for (final e in entries) {
        final names = <String>[];
        for (final name in (e['images'] as List).cast<String>()) {
          final bytes = archive.findFile('images/$name')?.readBytes();
          if (bytes == null) throw BackupFormatException('missing image $name');
          final storedName = await images.importBytes(bytes, p.extension(name));
          stored.add(storedName);
          names.add(storedName);
        }
        plans.add((
          _draftOf(e),
          DateTime.parse(e['createdAt'] as String),
          DateTime.parse(e['updatedAt'] as String),
          names,
        ));
      }
      return await db.transaction(() async {
        final ids = <int>[];
        for (final (draft, created, updated, names) in plans) {
          ids.add(await repo.insertRestored(draft, createdAt: created, updatedAt: updated, storedImageFileNames: names));
        }
        return ids;
      });
    } catch (e) {
      for (final name in stored) {
        await images.delete(name);
      }
      if (e is BackupFormatException) rethrow;
      throw BackupFormatException('$e');
    }
  }
```

`_draftOf`의 `tags:` 다음에 세 필드를 더한다(version 1에는 없으므로 기본값):

```dart
        dialogue: e['dialogue'] as bool? ?? false,
        myRole: e['myRole'] as String?,
        notes: switch (e['notes']) {
          final Map<String, Object?> m => ScriptNotes.fromJson(m),
          _ => ScriptNotes.empty,
        },
```

- [ ] **Step 4: 통과 확인**

Run: `flutter test test/backup && flutter analyze`
Expected: PASS(기존 테스트 + 새 4개), `No issues found!`

- [ ] **Step 5: 커밋**

```bash
git add lib/backup test/backup
git commit -m "feat: backup format v2 with single-script .monologue export and import"
```

---

### Task 8: 1:1 공유 — 보내기·받기

**Files:**
- Create: `lib/platform/incoming_files.dart`
- Create: `lib/ui/share/import_flow.dart`
- Create: `lib/ui/share/share_script.dart`
- Modify: `lib/app_scope.dart`, `lib/main.dart`, `lib/app.dart`, `test/ui/test_harness.dart`
- Modify: `lib/ui/view/script_view_screen.dart` (메뉴 `공유하기`)
- Modify: `lib/ui/settings/settings_screen.dart` (`파일에서 가져오기`)
- Modify: `ios/Runner/AppDelegate.swift`, `ios/Runner/Info.plist`
- Modify: `android/app/src/main/kotlin/com/tacowasabii/monologue/MainActivity.kt`, `android/app/src/main/AndroidManifest.xml`
- Test: `test/ui/import_flow_test.dart` (새), `test/ui/share_script_test.dart` (새)

**Interfaces:**
- Consumes: `BackupService.exportScript`, `BackupService.importArchive`, `BackupFormatException` (Task 7); `ScriptViewScreen`; `Harness.screen` (Task 6)
- Produces: `abstract interface class IncomingFiles { Stream<String> get paths; }`, `PlatformIncomingFiles`; `AppServices.incoming`; 테스트용 `FakeIncomingFiles`(`controller: StreamController<String>`)와 `Harness.incoming`; `Future<void> importScriptFile(BuildContext context, List<int> bytes)`; `Future<void> shareScript(BuildContext context, ScriptDetail detail)`; `class ShareScriptSheet extends StatefulWidget { ShareScriptSheet({required ScriptDetail detail, required int imageCount}) }` — `공유하기`를 누르면 `bool`(사진 포함 여부)로 창을 닫는다
- 채널 `monologue/incoming`: Dart → 네이티브 `takePending`(앱이 켜지며 받은 경로 목록), 네이티브 → Dart `onFiles`(`List<String>`)

- [ ] **Step 1: 실패하는 테스트 작성**

`test/ui/import_flow_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:monologue/app.dart';
import 'package:monologue/app_scope.dart';
import 'package:monologue/domain/script_draft.dart';
import 'package:monologue/ui/common/korean_text.dart';
import 'package:monologue/ui/view/script_view_screen.dart';

import 'test_harness.dart';

void main() {
  testWidgets('받은 .monologue 파일은 확인한 뒤 가져오고 그 대본을 연다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    final path = (await tester.runAsync(() async {
      final id = await h.services.repo.create(const ScriptDraft(work: '받은 대본', body: '민수: 안녕'));
      final dir = await Directory.systemTemp.createTemp('monologue_share');
      final file = await h.services.backup.exportScript(id, dir);
      await h.services.repo.delete(id);
      return file.path;
    }))!;
    await tester.pumpWidget(AppScope(services: h.services, child: const MonologueApp()));
    await tester.pumpAndSettle();

    await tester.runAsync(() async {
      h.incoming.controller.add(path);
      await Future<void>.delayed(const Duration(milliseconds: 100)); // 실제 파일 읽기
    });
    await tester.pumpAndSettle();
    expect(find.text('대본 가져오기'), findsOneWidget);

    await tester.tap(find.text('가져오기'));
    await tester.pumpAndSettle();
    expect(find.byType(ScriptViewScreen), findsOneWidget);
    expect(find.text(keepWords('받은 대본')), findsOneWidget);
    await tester.runAsync(h.db.close);
  });

  testWidgets('모노로그 파일이 아니면 알려주고 아무것도 추가하지 않는다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    final path = (await tester.runAsync(() async {
      final dir = await Directory.systemTemp.createTemp('monologue_share');
      return (await File('${dir.path}/broken.monologue').writeAsBytes([1, 2, 3])).path;
    }))!;
    await tester.pumpWidget(AppScope(services: h.services, child: const MonologueApp()));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      h.incoming.controller.add(path);
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    await tester.tap(find.text('가져오기'));
    await tester.pumpAndSettle();
    expect(find.text('모노로그 파일이 아니거나 손상됐어요'), findsOneWidget);
    expect(find.textContaining('아직 대본이 없어요'), findsOneWidget);
    await tester.runAsync(h.db.close);
  });
}
```

`test/ui/share_script_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monologue/domain/script_draft.dart';
import 'package:monologue/ui/share/share_script.dart';

import 'test_harness.dart';

void main() {
  testWidgets('공유 창은 원본 사진을 기본으로 빼고, 켜면 포함으로 돌려준다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    final detail = (await tester.runAsync(() async {
      final id = await h.services.repo.create(const ScriptDraft(work: '갈매기', body: 'x'));
      return (await h.services.repo.watchScript(id).first)!;
    }))!;
    bool? picked;
    await tester.pumpWidget(h.wrap(Builder(
      builder: (context) => TextButton(
        onPressed: () async => picked = await showModalBottomSheet<bool>(
          context: context,
          builder: (_) => ShareScriptSheet(detail: detail, imageCount: 2),
        ),
        child: const Text('열기'),
      ),
    )));
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value, isFalse);

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.text('공유하기'));
    await tester.pumpAndSettle();
    expect(picked, isTrue);
    await tester.runAsync(h.db.close);
  });
}
```

- [ ] **Step 2: 실패 확인**

Run: `flutter test test/ui/import_flow_test.dart test/ui/share_script_test.dart`
Expected: FAIL — `h.incoming`, `share_script.dart` 없음

- [ ] **Step 3: 받은 파일 서비스와 주입**

`lib/platform/incoming_files.dart`:

```dart
import 'dart:async';

import 'package:flutter/services.dart';

abstract interface class IncomingFiles {
  /// 다른 앱에서 모노로그로 연 파일 경로. 앱이 켜지면서 받은 파일도 처음 구독할 때 흘려준다.
  Stream<String> get paths;
}

/// iOS: `IncomingFilePlugin`(AppDelegate.swift), Android: MainActivity.kt의 `receive`.
class PlatformIncomingFiles implements IncomingFiles {
  static const _channel = MethodChannel('monologue/incoming');
  final _controller = StreamController<String>.broadcast();
  bool _started = false;

  @override
  Stream<String> get paths {
    if (!_started) {
      _started = true;
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'onFiles') (call.arguments as List).cast<String>().forEach(_controller.add);
      });
      _channel.invokeListMethod<String>('takePending').then((pending) => pending?.forEach(_controller.add));
    }
    return _controller.stream;
  }
}
```

`lib/app_scope.dart` — import `platform/incoming_files.dart`, `AppServices`에 `required this.incoming,`과 `final IncomingFiles incoming;` 추가.

`lib/main.dart` — import `platform/incoming_files.dart`, `AppServices(...)`의 `screen: ...` 다음에 `incoming: PlatformIncomingFiles(),` 추가.

`test/ui/test_harness.dart` — import `dart:async`와 `package:monologue/platform/incoming_files.dart`. `FakeScreenAwake` 아래에:

```dart
class FakeIncomingFiles implements IncomingFiles {
  final controller = StreamController<String>.broadcast();

  @override
  Stream<String> get paths => controller.stream;
}
```

`Harness`의 생성자를 `Harness._(this.db, this.services, this.screen, this.incoming);`로, 필드에 `final FakeIncomingFiles incoming;`를 더하고, `create()`에서 `final incoming = FakeIncomingFiles();`를 만들어 `AppServices(... screen: screen, incoming: incoming)`와 `Harness._(db, AppServices(...), screen, incoming)`에 넘긴다.

- [ ] **Step 4: 가져오기 흐름**

`lib/ui/share/import_flow.dart`:

```dart
import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../backup/backup_service.dart';
import '../view/script_view_screen.dart';

/// 받은 파일을 확인한 뒤 새 대본으로 추가한다. 대본이 하나면 그 대본을 연다.
Future<void> importScriptFile(BuildContext context, List<int> bytes) async {
  final backup = AppScope.of(context).backup;
  final navigator = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('대본 가져오기'),
      content: const Text('받은 파일의 대본을 내 목록에 추가할까요? 지금 있는 대본은 그대로 남아요.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('가져오기')),
      ],
    ),
  );
  if (ok != true) return;
  try {
    final ids = await backup.importArchive(bytes);
    if (ids.length == 1) {
      navigator.push(MaterialPageRoute<void>(builder: (_) => ScriptViewScreen(scriptId: ids.single)));
    } else {
      messenger.showSnackBar(SnackBar(content: Text('대본 ${ids.length}개를 가져왔어요')));
    }
  } on BackupFormatException {
    messenger.showSnackBar(const SnackBar(content: Text('모노로그 파일이 아니거나 손상됐어요')));
  }
}
```

`lib/app.dart` — 받은 파일을 앱 어디서든 처리하도록 `StatefulWidget`으로 바꾼다(파일 전체 교체):

```dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_scope.dart';
import 'ui/list/script_list_screen.dart';
import 'ui/share/import_flow.dart';
import 'ui/theme.dart';

class MonologueApp extends StatefulWidget {
  const MonologueApp({super.key});

  @override
  State<MonologueApp> createState() => _MonologueAppState();
}

class _MonologueAppState extends State<MonologueApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<String>? _incoming;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _incoming ??= AppScope.of(context).incoming.paths.listen(_open);
  }

  @override
  void dispose() {
    _incoming?.cancel();
    super.dispose();
  }

  Future<void> _open(String path) async {
    // 앱이 켜지면서 받은 파일이면 첫 화면이 그려진 뒤에 연다
    if (_navigatorKey.currentContext == null) await WidgetsBinding.instance.endOfFrame;
    final List<int> bytes;
    try {
      bytes = await File(path).readAsBytes();
    } on FileSystemException {
      return;
    }
    final context = _navigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    await importScriptFile(context, bytes);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: '모노로그',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      locale: const Locale('ko'),
      supportedLocales: const [Locale('ko')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const ScriptListScreen(),
    );
  }
}
```

- [ ] **Step 5: 공유 창과 보기 화면 메뉴**

`lib/ui/share/share_script.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../app_scope.dart';
import '../../data/script_repository.dart';
import '../../domain/script_draft.dart';

/// 사진 포함 여부를 고른 뒤 `.monologue` 파일을 시스템 공유 시트로 보낸다.
Future<void> shareScript(BuildContext context, ScriptDetail detail) async {
  final backup = AppScope.of(context).backup;
  final messenger = ScaffoldMessenger.of(context);
  final box = context.findRenderObject() as RenderBox?;
  final includeImages = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    builder: (_) => ShareScriptSheet(detail: detail, imageCount: detail.images.length),
  );
  if (includeImages == null) return;
  try {
    final file = await backup.exportScript(detail.script.id, await getTemporaryDirectory(), includeImages: includeImages);
    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path, mimeType: 'application/octet-stream')],
      // iPad는 공유 시트 위치가 필요하다
      sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
    ));
  } catch (_) {
    messenger.showSnackBar(const SnackBar(content: Text('공유 파일을 만들지 못했어요.')));
  }
}

class ShareScriptSheet extends StatefulWidget {
  const ShareScriptSheet({super.key, required this.detail, required this.imageCount});

  final ScriptDetail detail;
  final int imageCount;

  @override
  State<ShareScriptSheet> createState() => _ShareScriptSheetState();
}

class _ShareScriptSheetState extends State<ShareScriptSheet> {
  bool _withImages = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = widget.detail.script;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '‘${s.work ?? firstLineOf(s.body)}’ 보내기',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              '받는 사람이 이 파일을 모노로그로 열면 대본과 노트가 추가돼요.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            if (widget.imageCount > 0)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('원본 사진 포함'),
                subtitle: Text('사진 ${widget.imageCount}장 · 다른 내용이 찍혀 있지 않은지 확인하세요'),
                value: _withImages,
                onChanged: (v) => setState(() => _withImages = v),
              ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, _withImages),
              icon: const Icon(Icons.ios_share_rounded, size: 20),
              label: const Text('공유하기'),
            ),
          ],
        ),
      ),
    );
  }
}
```

`lib/ui/view/script_view_screen.dart` — import `../share/share_script.dart`, 메뉴 `onSelected`에 `else if (v == 'share') { shareScript(context, d); }`, `itemBuilder`의 `delete` 항목 앞에:

```dart
                  const PopupMenuItem(
                    value: 'share',
                    child: _MenuRow(icon: Icons.ios_share_rounded, text: '공유하기'),
                  ),
```

- [ ] **Step 6: 설정의 가져오기**

`lib/ui/settings/settings_screen.dart` — import `../share/import_flow.dart`. `_restore` 메서드 전체를 아래로 교체한다(백업 zip과 공유 파일을 같은 흐름으로):

```dart
  Future<void> _import() async {
    final file = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: ['zip', 'monologue']);
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    await importScriptFile(context, bytes);
  }
```

`BackupFormatException`을 더 쓰지 않아 `../../backup/backup_service.dart` import가 쓰이지 않으면 지운다(`flutter analyze`로 확인). 백업 카드의 두 번째 타일을 바꾼다:

```dart
                _SettingTile(
                  icon: Icons.file_open_outlined,
                  title: '파일에서 가져오기',
                  subtitle: '백업 파일이나 공유받은 대본을 추가해요',
                  enabled: !_busy,
                  onTap: _import,
                ),
```

- [ ] **Step 7: iOS — 문서 타입과 받은 파일 플러그인**

`ios/Runner/Info.plist` — 최상위 `<dict>` 안(`UIApplicationSceneManifest` 앞)에 추가:

```xml
	<key>CFBundleDocumentTypes</key>
	<array>
		<dict>
			<key>CFBundleTypeName</key>
			<string>모노로그 대본</string>
			<key>CFBundleTypeRole</key>
			<string>Viewer</string>
			<key>LSHandlerRank</key>
			<string>Owner</string>
			<key>LSItemContentTypes</key>
			<array>
				<string>com.tacowasabii.monologue.script</string>
			</array>
		</dict>
	</array>
	<key>UTExportedTypeDeclarations</key>
	<array>
		<dict>
			<key>UTTypeIdentifier</key>
			<string>com.tacowasabii.monologue.script</string>
			<key>UTTypeDescription</key>
			<string>모노로그 대본</string>
			<key>UTTypeConformsTo</key>
			<array>
				<string>public.data</string>
			</array>
			<key>UTTypeTagSpecification</key>
			<dict>
				<key>public.filename-extension</key>
				<array>
					<string>monologue</string>
				</array>
			</dict>
		</dict>
	</array>
	<key>LSSupportsOpeningDocumentsInPlace</key>
	<false/>
```

`ios/Runner/AppDelegate.swift` — `didInitializeImplicitFlutterEngine`에 등록 추가:

```swift
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "MonologueIncomingFilePlugin") {
      IncomingFilePlugin.register(with: registrar)
    }
```

파일 끝에(시그니처는 `Flutter.framework/Headers/FlutterSceneLifeCycle.h`의 `FlutterSceneLifeCycleDelegate`):

```swift
/// 다른 앱에서 연 `.monologue` 파일 경로를 Dart로 넘긴다. Dart의 `PlatformIncomingFiles`와 짝을 이룬다.
/// Dart가 준비되기 전에 받은 파일은 모아 두었다가 `takePending`에 돌려주고, 이후 파일은 `onFiles`로 보낸다.
final class IncomingFilePlugin: NSObject, FlutterPlugin, FlutterSceneLifeCycleDelegate {
  private let channel: FlutterMethodChannel
  private var pending: [String] = []
  private var dartReady = false

  init(channel: FlutterMethodChannel) {
    self.channel = channel
  }

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "monologue/incoming", binaryMessenger: registrar.messenger())
    let instance = IncomingFilePlugin(channel: channel)
    registrar.addMethodCallDelegate(instance, channel: channel)
    registrar.addSceneDelegate(instance)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "takePending" else {
      result(FlutterMethodNotImplemented)
      return
    }
    dartReady = true
    result(pending)
    pending.removeAll()
  }

  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions?
  ) -> Bool {
    guard let contexts = connectionOptions?.urlContexts else { return false }
    return receive(contexts)
  }

  func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) -> Bool {
    return receive(URLContexts)
  }

  private func receive(_ contexts: Set<UIOpenURLContext>) -> Bool {
    let paths = contexts.map(\.url).filter { $0.isFileURL && $0.pathExtension == "monologue" }.map(\.path)
    guard !paths.isEmpty else { return false }
    if dartReady {
      channel.invokeMethod("onFiles", arguments: paths)
    } else {
      pending.append(contentsOf: paths)
    }
    return true
  }
}
```

- [ ] **Step 8: Android — 인텐트 필터와 받은 파일 복사**

`android/app/src/main/AndroidManifest.xml` — `MainActivity`의 LAUNCHER `intent-filter` 뒤에:

```xml
            <!-- 카카오톡·파일 앱 등에서 받은 .monologue 파일 열기 -->
            <intent-filter>
                <action android:name="android.intent.action.VIEW"/>
                <category android:name="android.intent.category.DEFAULT"/>
                <data android:scheme="content"/>
                <data android:mimeType="application/octet-stream"/>
            </intent-filter>
            <intent-filter>
                <action android:name="android.intent.action.SEND"/>
                <category android:name="android.intent.category.DEFAULT"/>
                <data android:mimeType="application/octet-stream"/>
            </intent-filter>
```

`MainActivity.kt` — import 추가:

```kotlin
import android.content.Intent
import android.os.Build
```

클래스 필드:

```kotlin
    private var incomingChannel: MethodChannel? = null
    private val pendingFiles = mutableListOf<String>()
    private var dartReady = false
```

`configureFlutterEngine` 끝에:

```kotlin
        incomingChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "monologue/incoming").also { channel ->
            channel.setMethodCallHandler { call, result ->
                if (call.method != "takePending") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                dartReady = true
                result.success(pendingFiles.toList())
                pendingFiles.clear()
            }
        }
        receive(intent)
```

클래스에 메서드 추가:

```kotlin
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        receive(intent)
    }

    /** 받은 content:// 파일을 캐시로 복사하고 경로를 Dart(PlatformIncomingFiles)로 넘긴다. */
    private fun receive(intent: Intent?) {
        val uri: Uri = when (intent?.action) {
            Intent.ACTION_VIEW -> intent.data
            Intent.ACTION_SEND ->
                if (Build.VERSION.SDK_INT >= 33) intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
                else @Suppress("DEPRECATION") intent.getParcelableExtra(Intent.EXTRA_STREAM)
            else -> null
        } ?: return
        intent.action = null // 화면 회전 등으로 다시 처리하지 않게
        val path = try {
            val dir = File(cacheDir, "incoming").apply { mkdirs() }
            val file = File(dir, "${System.currentTimeMillis()}.monologue")
            val input = contentResolver.openInputStream(uri) ?: return
            input.use { src -> file.outputStream().use { src.copyTo(it) } }
            file.path
        } catch (e: Exception) {
            return
        }
        if (dartReady) incomingChannel?.invokeMethod("onFiles", listOf(path)) else pendingFiles.add(path)
    }
```

(모노로그 파일이 아닌 파일이 들어와도 Dart의 `importArchive`가 거부하고 "모노로그 파일이 아니거나 손상됐어요"를 보여준다.)

- [ ] **Step 9: 통과 확인**

Run: `flutter test && flutter analyze && flutter build ios --simulator --debug && flutter build apk --debug`
Expected: 전체 PASS, `No issues found!`, 두 빌드 성공

- [ ] **Step 10: 기기 확인**

1. iOS 시뮬레이터: 대본 보기 → ⋯ → `공유하기` → `파일에 저장`으로 `.monologue`를 저장한다. 대본을 지운 뒤 파일 앱에서 그 파일을 눌러 모노로그로 열리는지, 확인 대화상자 → 가져오기 → 대본 화면이 열리는지 확인한다. 앱을 완전히 종료한 상태에서도 한 번 더 확인한다(`takePending` 경로).
2. Android 에뮬레이터: `adb push <파일> /sdcard/Download/` 후 파일 앱에서 열기, 다른 앱의 공유 메뉴로 모노로그에 보내기를 확인한다.
3. 실제 카카오톡에서 받은 파일은 실기기에서 확인한다. 목록에 모노로그가 안 보이면 받은 MIME을 `adb logcat`으로 확인해 인텐트 필터에 더한다.
4. 설정 → `파일에서 가져오기`로 `.zip` 백업과 `.monologue` 파일이 둘 다 선택되는지 확인한다. iOS에서 `.monologue`가 흐리게 나오면 `FileType.any`로 바꾸고 `importArchive`의 검증에 맡긴다.

- [ ] **Step 11: 커밋**

```bash
git add lib test ios/Runner android/app/src/main
git commit -m "feat: share a script as a .monologue file and open received files"
```

---

### Task 9: 사용 방법·소개 문구와 전체 확인

**Files:**
- Modify: `lib/ui/settings/how_to_screen.dart`
- Modify: `docs/store-listing.md`
- Modify: `docs/superpowers/specs/2026-09-13-dialogue-notes-sharing-design.md` (상태)
- Test: `test/ui/how_to_screen_test.dart`

**Interfaces:**
- Consumes: Task 1–8 결과 전체 (화면 이름·버튼 이름: `내 역할`, `노트`, `몰입 읽기`, `공유하기`, `파일에서 가져오기`)

- [ ] **Step 1: 실패하는 테스트로 바꾸기**

`test/ui/how_to_screen_test.dart`의 테스트를 교체:

```dart
  testWidgets('사용 방법에 모든 안내가 있다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HowToScreen()));
    await tester.pumpAndSettle();

    for (final title in [
      '사진으로 대본 만들기',
      '대본에 넣을 문단 고르기',
      '확인 필요 표시',
      '원본 사진 보관',
      '대화 대본과 내 역할',
      '대본 노트',
      '몰입 읽기',
      '대본 보내고 받기',
      '폰을 바꿀 때는 백업',
    ]) {
      await tester.scrollUntilVisible(find.text(title), 200);
      expect(find.text(title), findsOneWidget, reason: title);
    }
    // 사진첩을 비워도 된다는 핵심 내용이 들어 있어야 한다
    expect(find.textContaining(keepWords('사진첩에서 캡처를 지워도')), findsOneWidget);
    // 복원 메뉴 이름이 바뀐 것이 반영돼야 한다
    expect(find.textContaining(keepWords('파일에서 가져오기')), findsWidgets);
  });
```

- [ ] **Step 2: 실패 확인**

Run: `flutter test test/ui/how_to_screen_test.dart`
Expected: FAIL — `대화 대본과 내 역할` 없음

- [ ] **Step 3: 사용 방법 항목 추가·수정**

`lib/ui/settings/how_to_screen.dart`의 `items`에서 `원본 사진 보관` 항목 뒤, `폰을 바꿀 때는 백업` 항목 앞에 넣는다:

```dart
    (
      Icons.forum_outlined,
      '대화 대본과 내 역할',
      "편집 화면에서 형식을 '대화'로 두고 줄 앞에 '민수: '처럼 이름을 쓰면 인물별로 나눠 보여요. "
          '대본 화면에서 내 역할을 고르면 그 인물 대사만 또렷하게 보이고, 고른 역할은 대본마다 기억해요.',
    ),
    (
      Icons.sticky_note_2_outlined,
      '대본 노트',
      '대본 화면의 노트 버튼으로 상황, 원하는 것, 가로막는 것과 작품 줄거리, 이 장면 앞뒤를 적어 둘 수 있어요. '
          '상황과 원하는 것은 본문 위에 요약으로 보여요.',
    ),
    (
      Icons.menu_book_rounded,
      '몰입 읽기',
      '대본 화면 아래 몰입 읽기를 누르면 메뉴 없이 대본만 화면 가득 보여요. '
          '읽는 동안 화면이 꺼지지 않고, 화면을 한 번 누르면 닫기와 글자 크기 버튼이 나와요.',
    ),
    (
      Icons.send_rounded,
      '대본 보내고 받기',
      '대본 화면의 ⋯ 메뉴 → 공유하기로 대본을 파일 하나로 보내요. 받은 사람이 그 파일을 모노로그로 열면 대본과 노트가 추가돼요. '
          '원본 사진은 공유 창에서 켰을 때만 함께 보내요. 파일을 저장해 뒀다면 설정 → 파일에서 가져오기로도 넣을 수 있어요.',
    ),
```

`폰을 바꿀 때는 백업` 항목의 본문을 바꾼다:

```dart
      '대본은 이 폰에만 저장돼요. 설정 → 백업 내보내기로 대본과 사진을 파일 하나로 만들어 두고, 새 폰에서 설정 → 파일에서 가져오기로 넣으세요.',
```

- [ ] **Step 4: 통과 확인**

Run: `flutter test test/ui/how_to_screen_test.dart`
Expected: PASS

- [ ] **Step 5: 스토어 소개 문구 갱신**

`docs/store-listing.md`의 설명 블록에서 `■ 연습에 집중` 문단(두 줄)을 아래 두 문단으로 바꾼다:

```
■ 대본을 이해하고 몰입하기
대화 장면은 인물별로 나눠 보여주고, 내 역할의 대사만 또렷하게 볼 수 있어요. 상황·원하는 것·가로막는 것 같은 분석 노트와 작품 줄거리·앞뒤 장면을 대본 옆에 적어 두고, 몰입 읽기 모드에서는 화면을 가득 채워 대본만 읽어요.

■ 친구에게 대본 보내기
대본 하나를 파일로 만들어 카카오톡이나 메일로 보내면, 받은 사람도 모노로그에서 바로 열어 추가할 수 있어요.
```

`## 스크린샷 (촬영 목록)`의 목록을 바꾼다:

```
1. 목록 화면 — 대본 여러 개, 태그가 보이게
2. 대화 대본 보기 — 내 역할 강조가 보이게
3. 몰입 읽기 화면
4. 대본 노트(분석·작품 맥락) 화면
5. 사진 선택 후 순서 정렬 화면
```

`## 개인정보 라벨`은 바꾸지 않는다(공유는 사용자가 시스템 공유 시트로 직접 보내며, 개발자에게 전송되는 데이터 없음).

- [ ] **Step 6: 설계 문서 상태 표시**

`docs/superpowers/specs/2026-09-13-dialogue-notes-sharing-design.md` 둘째 줄을 `작성일: 2026-09-13 · 상태: 구현됨`으로 바꾼다.

- [ ] **Step 7: 전체 확인**

Run: `flutter analyze && flutter test && flutter build ios --simulator --debug && flutter build apk --debug`
Expected: `No issues found!`, 전체 PASS, 두 빌드 성공

- [ ] **Step 8: 업데이트 시나리오 확인 (v3 DB → v4)**

1. 이 작업 전 커밋(`main` 79532b0 이후 이 브랜치가 갈라진 지점)을 시뮬레이터에 설치하고 대본 두 개(사진 포함 하나, 메모 있는 것 하나)를 만든다.
2. 이 브랜치 빌드를 앱 삭제 없이 설치해 연다.
3. 두 대본과 메모·사진이 그대로 있고, 편집 화면 형식이 `독백`이며, 노트 화면이 비어 있는지 확인한다.
4. 설정 → 백업 내보내기로 만든 zip을 `파일에서 가져오기`로 다시 넣어 복원되는지 확인한다.

- [ ] **Step 9: 커밋**

```bash
git add lib/ui/settings/how_to_screen.dart test/ui/how_to_screen_test.dart docs/store-listing.md docs/superpowers/specs/2026-09-13-dialogue-notes-sharing-design.md
git commit -m "docs: explain dialogue view, notes, immersive reading, and sharing"
```
