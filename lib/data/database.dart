import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../domain/enums.dart';
import '../domain/legacy_notes.dart';

part 'database.g.dart';

class Scripts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get work => text().nullable()();
  TextColumn get memo => text().nullable()();
  TextColumn get status => textEnum<PracticeStatus>()();
  BoolColumn get favorite => boolean()();
  TextColumn get body => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get dialogue => boolean().withDefault(const Constant(false))();
  TextColumn get myRole => text().nullable()();

  /// 대본에 대해 형식 없이 자유롭게 적은 노트
  TextColumn get note => text().nullable()();
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

/// '1차 오디션', '워크숍'처럼 사용자가 만든 대본 묶음.
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

/// 버전 6·7에 있던 노트 칸: 백업 JSON 이름 → DB 칸 이름
const _legacyNoteColumns = {
  'situation': 'situation',
  'objective': 'objective',
  'obstacle': 'obstacle',
  'author': 'author',
  'medium': 'medium',
  'sourceUrl': 'source_url',
  'synopsis': 'synopsis',
  'sceneContext': 'scene_context',
};

@DriftDatabase(tables: [Scripts, ScriptTags, ScriptImages, Collections, ScriptCollections, ScriptMedia])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 9;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        // drift는 onUpgrade를 트랜잭션으로 감싸지 않아서, 올리는 도중에 앱이 꺼지면 반쯤 바뀐 DB가 남고
        // 다음 실행에서 같은 단계를 다시 하다 실패해 대본을 열 수 없게 된다.
        // 모든 단계와 버전 기록을 한 트랜잭션으로 묶어 끝까지 가거나 하나도 바뀌지 않게 한다
        onUpgrade: (m, from, to) => transaction(() async {
          await _upgrade(m, from);
          await customStatement('PRAGMA user_version = $to');
        }),
      );

  Future<void> _upgrade(Migrator m, int from) async {
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
    // 6: 대화 형식·내 역할. 이때 함께 더한 노트 칸들은 버전 8에서 노트 한 칸으로 바뀌어 여기서는 더하지 않는다
    if (from < 6) {
      await m.addColumn(scripts, scripts.dialogue);
      await m.addColumn(scripts, scripts.myRole);
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
    // 8: 노트를 자유 글 한 칸으로. 버전 6·7의 노트 칸 내용은 "상황: …"처럼 제목을 붙여 한 글로 옮기고 칸은 지운다
    if (from < 8) {
      await m.addColumn(scripts, scripts.note);
      if (from >= 6) {
        final rows = await customSelect('SELECT id, ${_legacyNoteColumns.values.join(', ')} FROM scripts').get();
        for (final row in rows) {
          final note = legacyNoteText({
            for (final MapEntry(key: key, value: column) in _legacyNoteColumns.entries) key: row.data[column],
          });
          if (note != null) {
            await customStatement('UPDATE scripts SET note = ? WHERE id = ?', [note, row.read<int>('id')]);
          }
        }
        for (final column in _legacyNoteColumns.values) {
          await m.dropColumn(scripts, column);
        }
      }
    }
    // 9: 성별·나이대 칸을 없앤다. 버전 3보다 오래된 DB는 위에서 지금 구조로 새로 만들었다
    if (from < 9) {
      await m.dropColumn(scripts, 'gender');
      await m.dropColumn(scripts, 'age_range');
    }
  }

  static QueryExecutor _openConnection() => driftDatabase(
        name: 'monologue',
        native: const DriftNativeOptions(databaseDirectory: getApplicationSupportDirectory),
      );
}
