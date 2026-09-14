import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monologue/data/database.dart';
import 'package:monologue/domain/enums.dart';
import 'package:sqlite3/sqlite3.dart';

// 제목 칸이 있던 출시 전 버전 1의 테이블 정의 그대로(에뮬레이터의 실제 DB에서 꺼냈다)
const _v1Schema = [
  'CREATE TABLE IF NOT EXISTS "scripts" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "title" TEXT NOT NULL, '
      '"work" TEXT NULL, "character_name" TEXT NULL, "gender" TEXT NOT NULL, "age_range" TEXT NOT NULL, '
      '"status" TEXT NOT NULL, "favorite" INTEGER NOT NULL CHECK ("favorite" IN (0, 1)), "body" TEXT NOT NULL, '
      '"created_at" TEXT NOT NULL, "updated_at" TEXT NOT NULL);',
  'CREATE TABLE IF NOT EXISTS "script_tags" ("script_id" INTEGER NOT NULL REFERENCES scripts (id), '
      '"tag" TEXT NOT NULL, PRIMARY KEY ("script_id", "tag"));',
  'CREATE TABLE IF NOT EXISTS "script_images" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
      '"script_id" INTEGER NOT NULL REFERENCES scripts (id), "file_name" TEXT NOT NULL, "position" INTEGER NOT NULL);',
];

// 모음이 생기기 전 버전 3의 테이블 정의 그대로(에뮬레이터의 실제 DB에서 꺼냈다)
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

// 연습 기록이 생기기 전 버전 4: 버전 3에 모음 표 두 개가 더해졌다(에뮬레이터의 실제 DB에서 꺼냈다)
const _v4Schema = [
  ..._v3Schema,
  'CREATE TABLE IF NOT EXISTS "collections" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
      '"name" TEXT NOT NULL UNIQUE, "created_at" TEXT NOT NULL);',
  'CREATE TABLE IF NOT EXISTS "script_collections" ("script_id" INTEGER NOT NULL REFERENCES scripts (id), '
      '"collection_id" INTEGER NOT NULL REFERENCES collections (id), PRIMARY KEY ("script_id", "collection_id"));',
];

// 연습 기록 표가 생긴 버전 5: 대화 형식·노트 칸이 생기기 전
const _v5Schema = [
  ..._v4Schema,
  'CREATE TABLE IF NOT EXISTS "script_media" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
      '"script_id" INTEGER NOT NULL REFERENCES scripts (id), "kind" TEXT NOT NULL, "file_name" TEXT NOT NULL, '
      '"duration_ms" INTEGER NULL, "created_at" TEXT NOT NULL);',
];

// 버전 6은 버전 5의 scripts 표에 형식·역할과 여러 노트 칸을 더한 구조다
const _v6ScriptColumns = [
  '"dialogue" INTEGER NOT NULL DEFAULT 0 CHECK ("dialogue" IN (0, 1))',
  '"my_role" TEXT NULL',
  '"situation" TEXT NULL',
  '"objective" TEXT NULL',
  '"obstacle" TEXT NULL',
  '"author" TEXT NULL',
  '"medium" TEXT NULL',
  '"source_url" TEXT NULL',
  '"synopsis" TEXT NULL',
  '"scene_context" TEXT NULL',
];

void createV6(Database db) {
  for (final sql in _v5Schema) {
    db.execute(sql);
  }
  for (final column in _v6ScriptColumns) {
    db.execute('ALTER TABLE scripts ADD COLUMN $column');
  }
}

Future<List<String>> scriptColumns(AppDatabase db) async =>
    [for (final c in await db.customSelect("SELECT name FROM pragma_table_info('scripts')").get()) c.read<String>('name')];

void main() {
  late Directory tmp;

  test('버전 4 DB는 대본과 모음을 그대로 두고 연습 기록 표만 더한다', () async {
    final file = File('${tmp.path}/v4.sqlite');
    final v4 = sqlite3.open(file.path);
    for (final sql in _v4Schema) {
      v4.execute(sql);
    }
    v4.execute(
      'INSERT INTO scripts (work, memo, gender, age_range, status, favorite, body, created_at, updated_at) '
      "VALUES ('햄릿', NULL, 'any', 'any', 'notStarted', 0, '그분이 미치셨다니', "
      "'2026-09-13T10:00:00.000+09:00', '2026-09-13T10:00:00.000+09:00')",
    );
    v4.execute("INSERT INTO collections (name, created_at) VALUES ('1차 오디션', '2026-09-13T10:00:00.000+09:00')");
    v4.execute('INSERT INTO script_collections (script_id, collection_id) VALUES (1, 1)');
    v4.execute('PRAGMA user_version = 4');
    v4.close();

    final db = AppDatabase(NativeDatabase(file));
    expect((await db.select(db.scripts).getSingle()).work, '햄릿');
    expect((await db.select(db.collections).getSingle()).name, '1차 오디션');
    expect(await db.select(db.scriptCollections).get(), hasLength(1));
    expect(await db.select(db.scriptMedia).get(), isEmpty);

    // 새 표에 바로 쓸 수 있어야 한다
    await db.into(db.scriptMedia).insert(ScriptMediaCompanion.insert(
          scriptId: 1,
          kind: MediaKind.audio,
          fileName: 'take.m4a',
          createdAt: DateTime(2026, 9, 13),
        ));
    expect((await db.select(db.scriptMedia).getSingle()).fileName, 'take.m4a');
    await db.close();
  });

  test('버전 3 DB는 대본을 그대로 두고 모음 표만 더한다', () async {
    final file = File('${tmp.path}/v3.sqlite');
    final v3 = sqlite3.open(file.path);
    for (final sql in _v3Schema) {
      v3.execute(sql);
    }
    v3.execute(
      'INSERT INTO scripts (work, memo, gender, age_range, status, favorite, body, created_at, updated_at) '
      "VALUES ('햄릿', '오필리어', 'female', 'twenties', 'notStarted', 0, '그분이 미치셨다니', "
      "'2026-09-13T10:00:00.000+09:00', '2026-09-13T10:00:00.000+09:00')",
    );
    v3.execute("INSERT INTO script_tags (script_id, tag) VALUES (1, '슬픔')");
    v3.execute('PRAGMA user_version = 3');
    v3.close();

    final db = AppDatabase(NativeDatabase(file));
    final script = await db.select(db.scripts).getSingle();
    expect(script.work, '햄릿');
    expect((await db.select(db.scriptTags).getSingle()).tag, '슬픔');
    expect(await db.select(db.collections).get(), isEmpty);

    // 새 표에 바로 쓸 수 있어야 한다
    final collectionId = await db.into(db.collections).insert(
          CollectionsCompanion.insert(name: '1차 오디션', createdAt: DateTime(2026, 9, 13)),
        );
    await db.into(db.scriptCollections).insert(
          ScriptCollectionsCompanion.insert(scriptId: script.id, collectionId: collectionId),
        );
    expect(await db.select(db.scriptCollections).get(), hasLength(1));
    await db.close();
  });

  setUp(() async => tmp = await Directory.systemTemp.createTemp('monologue_migration'));
  tearDown(() => tmp.delete(recursive: true));

  test('출시 전 버전 1 DB는 비우고 새 구조로 다시 만든다', () async {
    final file = File('${tmp.path}/monologue.sqlite');
    final v1 = sqlite3.open(file.path);
    for (final sql in _v1Schema) {
      v1.execute(sql);
    }
    v1.execute(
      'INSERT INTO scripts (title, work, character_name, gender, age_range, status, favorite, body, created_at, updated_at) '
      "VALUES ('제목', NULL, NULL, 'any', 'any', 'notStarted', 0, '본문', "
      "'2026-09-11T10:00:00.000+09:00', '2026-09-11T10:00:00.000+09:00')",
    );
    v1.execute("INSERT INTO script_tags (script_id, tag) VALUES (1, '슬픔')");
    v1.execute('PRAGMA user_version = 1');
    v1.close();

    final db = AppDatabase(NativeDatabase(file));
    expect(await db.select(db.scripts).get(), isEmpty);
    expect(await db.select(db.scriptTags).get(), isEmpty);
    expect(await scriptColumns(db), allOf(contains('memo'), isNot(contains('title')), isNot(contains('character_name'))));

    // 옛 구조가 남아 있으면 제목 칸(NOT NULL) 때문에 저장이 실패한다
    await db.into(db.scripts).insert(ScriptsCompanion.insert(
          memo: const Value('메모'),
          status: PracticeStatus.notStarted,
          favorite: false,
          body: '새 대본',
          createdAt: DateTime(2026, 9, 13),
          updatedAt: DateTime(2026, 9, 13),
        ));
    expect((await db.select(db.scripts).getSingle()).memo, '메모');

    await db.close();
  });

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
    expect(row.note, isNull);
    expect((await db.select(db.scriptTags).getSingle()).tag, '고뇌');
    await db.close();
  });

  test('버전 5 DB는 대본·모음·연습 기록을 그대로 두고 형식·역할·노트 칸을 더한다', () async {
    final file = File('${tmp.path}/v5.sqlite');
    final v5 = sqlite3.open(file.path);
    for (final sql in _v5Schema) {
      v5.execute(sql);
    }
    v5.execute(
      'INSERT INTO scripts (work, memo, gender, age_range, status, favorite, body, created_at, updated_at) '
      "VALUES ('햄릿', NULL, 'any', 'any', 'notStarted', 0, '사느냐 죽느냐', "
      "'2026-09-14T10:00:00.000+09:00', '2026-09-14T10:00:00.000+09:00')",
    );
    v5.execute("INSERT INTO collections (name, created_at) VALUES ('1차 오디션', '2026-09-14T10:00:00.000+09:00')");
    v5.execute('INSERT INTO script_collections (script_id, collection_id) VALUES (1, 1)');
    v5.execute(
      'INSERT INTO script_media (script_id, kind, file_name, duration_ms, created_at) '
      "VALUES (1, 'audio', 'take.m4a', 42000, '2026-09-14T10:00:00.000+09:00')",
    );
    v5.execute('PRAGMA user_version = 5');
    v5.close();

    final db = AppDatabase(NativeDatabase(file));
    final row = await db.select(db.scripts).getSingle();
    expect(row.work, '햄릿');
    expect(row.dialogue, isFalse);
    expect(row.myRole, isNull);
    expect(row.note, isNull);
    expect(await db.select(db.scriptCollections).get(), hasLength(1));
    expect((await db.select(db.scriptMedia).getSingle()).durationMs, 42000);
    await db.close();
  });

  test('버전 6 DB는 모음 연결을 그대로 두고, 지금까지 보이던 최근 수정순을 모음 안 순서로 삼는다', () async {
    final file = File('${tmp.path}/v6.sqlite');
    final v6 = sqlite3.open(file.path);
    createV6(v6);
    v6.execute(
      'INSERT INTO scripts (work, memo, gender, age_range, status, favorite, body, created_at, updated_at) VALUES '
      "('오래전에 고친 대본', NULL, 'any', 'any', 'notStarted', 0, 'x', "
      "'2026-09-10T10:00:00.000+09:00', '2026-09-10T10:00:00.000+09:00'), "
      "('최근에 고친 대본', NULL, 'any', 'any', 'notStarted', 0, 'x', "
      "'2026-09-10T10:00:00.000+09:00', '2026-09-14T10:00:00.000+09:00')",
    );
    v6.execute("INSERT INTO collections (name, created_at) VALUES ('1차 오디션', '2026-09-14T10:00:00.000+09:00')");
    v6.execute('INSERT INTO script_collections (script_id, collection_id) VALUES (1, 1), (2, 1)');
    v6.execute('PRAGMA user_version = 6');
    v6.close();

    final db = AppDatabase(NativeDatabase(file));
    final links = await (db.select(db.scriptCollections)..orderBy([(l) => OrderingTerm.asc(l.position)])).get();
    expect([for (final l in links) (l.scriptId, l.position)], [(2, 0), (1, 1)]);
    await db.close();
  });

  test('버전 7 DB는 여러 노트 칸을 제목 붙인 노트 한 글로 합치고 예전 칸은 지운다', () async {
    final file = File('${tmp.path}/v7.sqlite');
    final v7 = sqlite3.open(file.path);
    createV6(v7);
    v7.execute('ALTER TABLE script_collections ADD COLUMN "position" INTEGER NOT NULL DEFAULT 0');
    v7.execute(
      'INSERT INTO scripts (work, memo, gender, age_range, status, favorite, body, created_at, updated_at, '
      'dialogue, my_role, situation, medium, source_url) VALUES '
      "('갈매기', '니나', 'any', 'any', 'notStarted', 1, '나는 갈매기', "
      "'2026-09-14T10:00:00.000+09:00', '2026-09-14T10:00:00.000+09:00', 1, '니나', '호숫가 무대', 'play', "
      "'https://example.com'), "
      "('햄릿', NULL, 'any', 'any', 'notStarted', 0, '사느냐 죽느냐', "
      "'2026-09-14T10:00:00.000+09:00', '2026-09-14T10:00:00.000+09:00', 0, NULL, NULL, NULL, NULL)",
    );
    v7.execute('PRAGMA user_version = 7');
    v7.close();

    final db = AppDatabase(NativeDatabase(file));
    final rows = await (db.select(db.scripts)..orderBy([(s) => OrderingTerm.asc(s.id)])).get();
    expect(rows[0].note, '상황: 호숫가 무대\n\n매체: 연극\n\n출처 링크: https://example.com');
    expect((rows[0].work, rows[0].memo, rows[0].favorite, rows[0].dialogue, rows[0].myRole), ('갈매기', '니나', true, true, '니나'));
    expect(rows[1].note, isNull);
    expect(
      await scriptColumns(db),
      allOf(contains('note'), isNot(contains('situation')), isNot(contains('source_url')), isNot(contains('medium'))),
    );
    await db.close();
  });

  test('올리는 도중에 실패하면 DB를 조금도 바꾸지 않아서, 반쯤 바뀐 채로 남지 않는다', () async {
    final file = File('${tmp.path}/v7_fails.sqlite');
    final v7 = sqlite3.open(file.path);
    createV6(v7);
    v7.execute('ALTER TABLE script_collections ADD COLUMN "position" INTEGER NOT NULL DEFAULT 0');
    v7.execute(
      'INSERT INTO scripts (work, gender, age_range, status, favorite, body, created_at, updated_at, situation) '
      "VALUES ('갈매기', 'any', 'any', 'notStarted', 0, 'x', "
      "'2026-09-14T10:00:00.000+09:00', '2026-09-14T10:00:00.000+09:00', '호숫가 무대')",
    );
    // 칸에 색인이 걸려 있으면 노트 칸을 지우는 마지막 단계에서 실패한다. 노트 칸 추가·내용 합치기는 이미 한 뒤다
    v7.execute('CREATE INDEX scripts_situation ON scripts (situation)');
    v7.execute('PRAGMA user_version = 7');
    v7.close();

    final db = AppDatabase(NativeDatabase(file));
    await expectLater(db.select(db.scripts).get(), throwsA(anything));
    await db.close().catchError((_) {});

    final raw = sqlite3.open(file.path);
    addTearDown(raw.close);
    expect(raw.select('PRAGMA user_version').single.values.single, 7);
    final columns = [for (final r in raw.select("SELECT name FROM pragma_table_info('scripts')")) r['name']];
    expect(columns, allOf(contains('situation'), isNot(contains('note'))));
    expect(raw.select('SELECT situation FROM scripts').single['situation'], '호숫가 무대');
  });
  test('버전 8 DB는 대본·태그·노트를 그대로 두고 성별·나이대 칸을 지운다', () async {
    final file = File('${tmp.path}/v8.sqlite');
    final v8 = sqlite3.open(file.path);
    for (final sql in _v5Schema) {
      v8.execute(sql);
    }
    for (final column in [
      '"dialogue" INTEGER NOT NULL DEFAULT 0 CHECK ("dialogue" IN (0, 1))',
      '"my_role" TEXT NULL',
      '"note" TEXT NULL',
    ]) {
      v8.execute('ALTER TABLE scripts ADD COLUMN $column');
    }
    v8.execute('ALTER TABLE script_collections ADD COLUMN "position" INTEGER NOT NULL DEFAULT 0');
    v8.execute(
      'INSERT INTO scripts (work, memo, gender, age_range, status, favorite, body, created_at, updated_at, note) '
      "VALUES ('갈매기', '니나', 'female', 'twenties', 'notStarted', 1, '나는 갈매기', "
      "'2026-09-14T10:00:00.000+09:00', '2026-09-14T10:00:00.000+09:00', '호숫가 무대')",
    );
    v8.execute("INSERT INTO script_tags (script_id, tag) VALUES (1, '슬픔')");
    v8.execute('PRAGMA user_version = 8');
    v8.close();

    final db = AppDatabase(NativeDatabase(file));
    final row = await db.select(db.scripts).getSingle();
    expect((row.work, row.memo, row.favorite, row.note), ('갈매기', '니나', true, '호숫가 무대'));
    expect((await db.select(db.scriptTags).getSingle()).tag, '슬픔');
    expect(await scriptColumns(db), allOf(isNot(contains('gender')), isNot(contains('age_range')), contains('note')));
    await db.close();
  });
}
