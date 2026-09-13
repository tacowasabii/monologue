import 'package:drift/drift.dart';

import '../domain/enums.dart';
import '../domain/script_draft.dart';
import '../domain/script_filter.dart';
import 'database.dart';
import 'image_store.dart';

class ScriptSummary {
  const ScriptSummary(this.script, this.tags);

  final Script script;
  final List<String> tags;
}

class ScriptDetail {
  const ScriptDetail(this.script, this.tags, this.images, this.collectionIds);

  final Script script;
  final List<String> tags;
  final List<ScriptImage> images;
  final List<int> collectionIds;
}

class CollectionSummary {
  const CollectionSummary(this.collection, this.scriptCount);

  final Collection collection;
  final int scriptCount;
}

class ScriptRepository {
  ScriptRepository(this.db, this.images);

  final AppDatabase db;
  final ImageStore images;

  Stream<List<ScriptSummary>> watchScripts(ScriptFilter f) {
    final q = db.select(db.scripts)
      ..where((s) {
        Expression<bool> e = const Constant(true);
        final text = f.query.trim();
        if (text.isNotEmpty) {
          final pattern = '%$text%';
          e = e & (s.work.like(pattern) | s.memo.like(pattern) | s.body.like(pattern));
        }
        // 성별·나이대가 '무관'인 대본은 어느 조건에도 맞는다
        if (f.gender != null) e = e & s.gender.isIn([f.gender!.name, Gender.any.name]);
        if (f.ageRange != null) e = e & s.ageRange.isIn([f.ageRange!.name, AgeRange.any.name]);
        if (f.favoritesOnly) e = e & s.favorite.equals(true);
        if (f.tag != null) {
          e = e &
              existsQuery(db.select(db.scriptTags)
                ..where((t) => t.scriptId.equalsExp(s.id) & t.tag.equals(f.tag!)));
        }
        if (f.collectionId != null) {
          e = e &
              existsQuery(db.select(db.scriptCollections)
                ..where((sc) => sc.scriptId.equalsExp(s.id) & sc.collectionId.equals(f.collectionId!)));
        }
        return e;
      })
      ..orderBy([(s) => OrderingTerm.desc(s.updatedAt), (s) => OrderingTerm.desc(s.id)]);
    return q.watch().asyncMap(_withTags);
  }

  Stream<int> watchScriptCount() {
    final count = db.scripts.id.count();
    return (db.selectOnly(db.scripts)..addColumns([count])).watchSingle().map((r) => r.read(count) ?? 0);
  }

  Future<List<ScriptSummary>> _withTags(List<Script> rows) async {
    if (rows.isEmpty) return const [];
    final tagRows =
        await (db.select(db.scriptTags)..where((t) => t.scriptId.isIn(rows.map((r) => r.id)))).get();
    final byScript = <int, List<String>>{};
    for (final t in tagRows) {
      byScript.putIfAbsent(t.scriptId, () => []).add(t.tag);
    }
    return [for (final r in rows) ScriptSummary(r, (byScript[r.id] ?? [])..sort())];
  }

  Stream<ScriptDetail?> watchScript(int id) {
    return (db.select(db.scripts)..where((s) => s.id.equals(id))).watchSingleOrNull().asyncMap((script) async {
      if (script == null) return null;
      final tags = await (db.select(db.scriptTags)..where((t) => t.scriptId.equals(id))).get();
      final imgs = await (db.select(db.scriptImages)
            ..where((i) => i.scriptId.equals(id))
            ..orderBy([(i) => OrderingTerm.asc(i.position)]))
          .get();
      final links = await (db.select(db.scriptCollections)..where((sc) => sc.scriptId.equals(id))).get();
      return ScriptDetail(
        script,
        tags.map((t) => t.tag).toList()..sort(),
        imgs,
        links.map((l) => l.collectionId).toList()..sort(),
      );
    });
  }

  Future<List<String>> _importAll(List<String> paths) async {
    final stored = <String>[];
    try {
      for (final path in paths) {
        stored.add(await images.importFile(path));
      }
      return stored;
    } catch (_) {
      await _deleteFiles(stored);
      rethrow;
    }
  }

  Future<void> _deleteFiles(List<String> fileNames) async {
    for (final name in fileNames) {
      await images.delete(name);
    }
  }

  Future<int> create(ScriptDraft draft, {List<String> imagePaths = const []}) async {
    final stored = await _importAll(imagePaths);
    final now = DateTime.now();
    try {
      return await insertRestored(draft, createdAt: now, updatedAt: now, storedImageFileNames: stored);
    } catch (_) {
      await _deleteFiles(stored);
      rethrow;
    }
  }

  /// 이미 저장소에 들어간 이미지 파일명으로 대본을 추가한다(백업 복원에서도 사용).
  Future<int> insertRestored(
    ScriptDraft draft, {
    required DateTime createdAt,
    required DateTime updatedAt,
    required List<String> storedImageFileNames,
  }) {
    final d = draft.normalized();
    return db.transaction(() async {
      final id = await db.into(db.scripts).insert(ScriptsCompanion.insert(
            work: Value(d.work),
            memo: Value(d.memo),
            gender: d.gender,
            ageRange: d.ageRange,
            status: d.status,
            favorite: d.favorite,
            body: d.body,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ));
      await _replaceTags(id, d.tags);
      await _replaceCollections(id, d.collectionIds);
      await _appendImages(id, storedImageFileNames);
      return id;
    });
  }

  Future<void> update(int id, ScriptDraft draft, {List<String> newImagePaths = const []}) async {
    final stored = await _importAll(newImagePaths);
    final d = draft.normalized();
    try {
      await db.transaction(() async {
        await (db.update(db.scripts)..where((s) => s.id.equals(id))).write(ScriptsCompanion(
              work: Value(d.work),
              memo: Value(d.memo),
              gender: Value(d.gender),
              ageRange: Value(d.ageRange),
              status: Value(d.status),
              favorite: Value(d.favorite),
              body: Value(d.body),
              updatedAt: Value(DateTime.now()),
            ));
        await _replaceTags(id, d.tags);
        await _replaceCollections(id, d.collectionIds);
        await _appendImages(id, stored);
      });
    } catch (_) {
      await _deleteFiles(stored);
      rethrow;
    }
  }

  Future<void> _replaceTags(int id, List<String> tags) async {
    await (db.delete(db.scriptTags)..where((t) => t.scriptId.equals(id))).go();
    await db.batch((b) => b.insertAll(
          db.scriptTags,
          [for (final t in tags) ScriptTagsCompanion.insert(scriptId: id, tag: t)],
        ));
  }

  Future<void> _replaceCollections(int id, List<int> collectionIds) async {
    await (db.delete(db.scriptCollections)..where((sc) => sc.scriptId.equals(id))).go();
    await db.batch((b) => b.insertAll(
          db.scriptCollections,
          [for (final c in collectionIds) ScriptCollectionsCompanion.insert(scriptId: id, collectionId: c)],
        ));
  }

  Future<void> _appendImages(int id, List<String> fileNames) async {
    if (fileNames.isEmpty) return;
    final maxPos = db.scriptImages.position.max();
    final row = await (db.selectOnly(db.scriptImages)
          ..addColumns([maxPos])
          ..where(db.scriptImages.scriptId.equals(id)))
        .getSingle();
    final start = (row.read(maxPos) ?? -1) + 1;
    await db.batch((b) => b.insertAll(db.scriptImages, [
          for (var i = 0; i < fileNames.length; i++)
            ScriptImagesCompanion.insert(scriptId: id, fileName: fileNames[i], position: start + i),
        ]));
  }

  Future<void> setFavorite(int id, bool value) =>
      (db.update(db.scripts)..where((s) => s.id.equals(id))).write(ScriptsCompanion(favorite: Value(value)));

  Future<void> delete(int id) async {
    final imgs = await (db.select(db.scriptImages)..where((i) => i.scriptId.equals(id))).get();
    await db.transaction(() async {
      await (db.delete(db.scriptTags)..where((t) => t.scriptId.equals(id))).go();
      await (db.delete(db.scriptImages)..where((i) => i.scriptId.equals(id))).go();
      await (db.delete(db.scriptCollections)..where((sc) => sc.scriptId.equals(id))).go();
      await (db.delete(db.scripts)..where((s) => s.id.equals(id))).go();
    });
    await _deleteFiles([for (final img in imgs) img.fileName]);
  }

  JoinedSelectStatement<$ScriptTagsTable, dynamic> _distinctTags() =>
      db.selectOnly(db.scriptTags, distinct: true)..addColumns([db.scriptTags.tag]);

  List<String> _readTags(List<TypedResult> rows) => rows.map((r) => r.read(db.scriptTags.tag)!).toList()..sort();

  Future<List<String>> allTags() async => _readTags(await _distinctTags().get());

  Stream<List<String>> watchAllTags() => _distinctTags().watch().map(_readTags);

  // ── 모음 ──

  OrderingTerm _collectionOrder($CollectionsTable c) => OrderingTerm.asc(c.createdAt);

  /// 만든 순서대로, 모음마다 든 대본 수와 함께.
  Stream<List<CollectionSummary>> watchCollections() {
    final count = db.scriptCollections.scriptId.count();
    final q = db.select(db.collections).join([
      leftOuterJoin(db.scriptCollections, db.scriptCollections.collectionId.equalsExp(db.collections.id)),
    ])
      ..addColumns([count])
      ..groupBy([db.collections.id])
      ..orderBy([_collectionOrder(db.collections), OrderingTerm.asc(db.collections.id)]);
    return q.watch().map((rows) => [
          for (final r in rows) CollectionSummary(r.readTable(db.collections), r.read(count) ?? 0),
        ]);
  }

  Stream<List<Collection>> watchAllCollections() =>
      (db.select(db.collections)..orderBy([(c) => _collectionOrder(c), (c) => OrderingTerm.asc(c.id)])).watch();

  Future<Collection?> findCollection(String name) =>
      (db.select(db.collections)..where((c) => c.name.equals(name.trim()))).getSingleOrNull();

  Future<int> createCollection(String name) =>
      db.into(db.collections).insert(CollectionsCompanion.insert(name: name.trim(), createdAt: DateTime.now()));

  /// 같은 이름의 모음이 있으면 그 모음을, 없으면 새로 만들어 id를 준다(백업 복원에서 사용).
  Future<int> collectionIdFor(String name) async => (await findCollection(name))?.id ?? await createCollection(name);

  Future<void> renameCollection(int id, String name) =>
      (db.update(db.collections)..where((c) => c.id.equals(id))).write(CollectionsCompanion(name: Value(name.trim())));

  /// 모음만 지우고 안에 든 대본은 남긴다.
  Future<void> deleteCollection(int id) => db.transaction(() async {
        await (db.delete(db.scriptCollections)..where((sc) => sc.collectionId.equals(id))).go();
        await (db.delete(db.collections)..where((c) => c.id.equals(id))).go();
      });
}
