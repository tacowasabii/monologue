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

void main() {
  late Directory tmp;

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
