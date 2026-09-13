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

void main() {
  late Directory tmp;

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
    final columns = await db.customSelect("SELECT name FROM pragma_table_info('scripts')").get();
    expect(columns.map((c) => c.read<String>('name')), allOf(contains('memo'), isNot(contains('title')), isNot(contains('character_name'))));

    // 옛 구조가 남아 있으면 제목 칸(NOT NULL) 때문에 저장이 실패한다
    await db.into(db.scripts).insert(ScriptsCompanion.insert(
          memo: const Value('메모'),
          gender: Gender.any,
          ageRange: AgeRange.any,
          status: PracticeStatus.notStarted,
          favorite: false,
          body: '새 대본',
          createdAt: DateTime(2026, 9, 13),
          updatedAt: DateTime(2026, 9, 13),
        ));
    expect((await db.select(db.scripts).getSingle()).memo, '메모');

    await db.close();
  });
}
