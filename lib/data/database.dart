import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../domain/enums.dart';

part 'database.g.dart';

class Scripts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get work => text().nullable()();
  TextColumn get character => text().named('character_name').nullable()();
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

@DriftDatabase(tables: [Scripts, ScriptTags, ScriptImages])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() => driftDatabase(
        name: 'monologue',
        native: const DriftNativeOptions(databaseDirectory: getApplicationSupportDirectory),
      );
}
