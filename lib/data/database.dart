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

  /// 모음 안에서의 순서. 작을수록 위에 보인다. 모음마다 따로 정한다.
  IntColumn get position => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {scriptId, collectionId};
}

/// 대본에 남긴 연습 기록(녹음·영상). 파일은 MediaStore에 따로 둔다.
@DataClassName('MediaItem')
class ScriptMedia extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get scriptId => integer().references(Scripts, #id)();
  TextColumn get kind => textEnum<MediaKind>()();
  TextColumn get fileName => text()();
  IntColumn get durationMs => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

@DriftDatabase(tables: [Scripts, ScriptTags, ScriptImages, Collections, ScriptCollections, ScriptMedia])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 7;

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
          // 5: 연습 기록(녹음·영상)
          if (from < 5) {
            await m.createTable(scriptMedia);
          }
          // 6: 대화 형식·내 역할·대본 노트. 칸만 더하므로 대본은 그대로 남는다
          if (from < 6) {
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
          // 7: 모음 안 순서. 버전 4보다 오래된 DB는 위에서 순서 칸이 있는 표를 새로 만들었다.
          // 지금까지 모음에서 보이던 순서(최근 수정순)를 처음 순서로 삼는다
          if (from < 7) {
            if (from >= 4) await m.addColumn(scriptCollections, scriptCollections.position);
            final links = await customSelect(
              'SELECT sc.script_id, sc.collection_id FROM script_collections sc '
              'JOIN scripts s ON s.id = sc.script_id '
              'ORDER BY sc.collection_id, s.updated_at DESC, s.id DESC',
            ).get();
            final next = <int, int>{};
            for (final link in links) {
              final collectionId = link.read<int>('collection_id');
              final position = next[collectionId] ?? 0;
              next[collectionId] = position + 1;
              await customStatement(
                'UPDATE script_collections SET position = ? WHERE script_id = ? AND collection_id = ?',
                [position, link.read<int>('script_id'), collectionId],
              );
            }
          }
        },
      );

  static QueryExecutor _openConnection() => driftDatabase(
        name: 'monologue',
        native: const DriftNativeOptions(databaseDirectory: getApplicationSupportDirectory),
      );
}
