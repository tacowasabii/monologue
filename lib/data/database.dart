import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../domain/enums.dart';

part 'database.g.dart';

class Scripts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get work => text().nullable()();
  TextColumn get memo => text().nullable()();
  TextColumn get gender => textEnum<Gender>()();
  TextColumn get ageRange => textEnum<AgeRange>()();
  TextColumn get status => textEnum<PracticeStatus>()();
  BoolColumn get favorite => boolean()();
  TextColumn get body => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

class ScriptTags extends Table {
  IntColumn get scriptId => integer().references(Scripts, #id)();
  TextColumn get tag => text()();

  @override
  Set<Column> get primaryKey => {scriptId, tag};
}

class ScriptImages extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get scriptId => integer().references(Scripts, #id)();
  TextColumn get fileName => text()();
  IntColumn get position => integer()();
}

/// '1차 오디션', '입시'처럼 사용자가 만든 대본 묶음.
class Collections extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  DateTimeColumn get createdAt => dateTime()();
}

/// 대본은 여러 모음에 들어갈 수 있다.
class ScriptCollections extends Table {
  IntColumn get scriptId => integer().references(Scripts, #id)();
  IntColumn get collectionId => integer().references(Collections, #id)();

  @override
  Set<Column> get primaryKey => {scriptId, collectionId};
}

@DriftDatabase(tables: [Scripts, ScriptTags, ScriptImages, Collections, ScriptCollections])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

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
          // 4: 모음. 기존 대본은 그대로 두고 표만 더한다.
          if (from < 4) {
            await m.createTable(collections);
            await m.createTable(scriptCollections);
          }
        },
      );

  static QueryExecutor _openConnection() => driftDatabase(
        name: 'monologue',
        native: const DriftNativeOptions(databaseDirectory: getApplicationSupportDirectory),
      );
}
