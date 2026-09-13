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

@DriftDatabase(tables: [Scripts, ScriptTags, ScriptImages])
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

  static QueryExecutor _openConnection() => driftDatabase(
        name: 'monologue',
        native: const DriftNativeOptions(databaseDirectory: getApplicationSupportDirectory),
      );
}
