import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import '../data/database.dart';
import '../data/image_store.dart';
import '../data/script_repository.dart';
import '../domain/enums.dart';
import '../domain/legacy_notes.dart';
import '../domain/script_draft.dart';

class BackupFormatException implements Exception {
  const BackupFormatException(this.message);

  final String message;

  @override
  String toString() => 'BackupFormatException: $message';
}

/// 백업에 든 연습 기록 하나
typedef _Take = ({MediaKind kind, String file, Duration? duration, DateTime createdAt});

class BackupService {
  BackupService(this.db, this.repo, this.images);

  static const format = 'monologue-backup';
  // 2: 대화 형식·내 역할·대본 노트를 더했다.
  // 3: 여러 칸이던 노트(notes)를 자유 글 한 칸(note)으로 바꿨다.
  // 4: 성별·나이대를 뺐다(예전 백업에 있으면 무시한다). 1~3도 계속 복원한다
  static const version = 4;
  static const _manifest = 'backup.json';

  final AppDatabase db;
  final ScriptRepository repo;
  final ImageStore images;

  /// 백업 파일을 만든다. [includeMedia]면 연습 기록(녹음·영상)도 넣는다.
  /// 파일을 하나씩 바로 압축 파일에 써서, 영상이 커도 메모리에 한꺼번에 올리지 않는다.
  Future<File> export(Directory outDir, {DateTime? now, bool includeMedia = false}) async {
    final scripts = await db.select(db.scripts).get();
    final tags = await db.select(db.scriptTags).get();
    final imgs = await (db.select(db.scriptImages)..orderBy([(i) => OrderingTerm.asc(i.position)])).get();
    final collectionNames = {for (final c in await db.select(db.collections).get()) c.id: c.name};
    final links = await db.select(db.scriptCollections).get();
    final takes = includeMedia ? await db.select(db.scriptMedia).get() : const <MediaItem>[];

    final stamp = DateFormat('yyyyMMdd').format(now ?? DateTime.now());
    final file = File(p.join(outDir.path, 'monologue-backup-$stamp.zip'));
    final encoder = ZipFileEncoder()..create(file.path);
    try {
      final entries = <Map<String, Object?>>[];
      for (final s in scripts) {
        final myImages = imgs.where((i) => i.scriptId == s.id).map((i) => i.fileName).toList();
        for (final name in myImages) {
          await encoder.addFile(File(images.pathOf(name)), 'images/$name');
        }
        final myTakes = takes.where((t) => t.scriptId == s.id).toList();
        for (final t in myTakes) {
          // 녹음·영상은 이미 압축된 형식이라 다시 압축하지 않고 그대로 담는다
          await encoder.addFile(File(repo.media.pathOf(t.fileName)), 'media/${t.fileName}', ZipFileEncoder.store);
        }
        entries.add({
          'work': s.work,
          'memo': s.memo,
          'status': s.status.name,
          'favorite': s.favorite,
          'body': s.body,
          'dialogue': s.dialogue,
          'myRole': s.myRole,
          'note': s.note,
          'createdAt': s.createdAt.toIso8601String(),
          'updatedAt': s.updatedAt.toIso8601String(),
          'tags': tags.where((t) => t.scriptId == s.id).map((t) => t.tag).toList(),
          // 모음은 기기마다 id가 달라서 이름으로 옮긴다
          'collections': [for (final l in links) if (l.scriptId == s.id) collectionNames[l.collectionId]!],
          // 모음 안 순서. 예전 앱은 모르는 칸이라 무시하고 복원한다
          'collectionOrder': {
            for (final l in links)
              if (l.scriptId == s.id) collectionNames[l.collectionId]!: l.position,
          },
          'images': myImages,
          if (includeMedia)
            'media': [
              for (final t in myTakes)
                {
                  'kind': t.kind.name,
                  'file': t.fileName,
                  'durationMs': t.durationMs,
                  'createdAt': t.createdAt.toIso8601String(),
                },
            ],
        });
      }
      encoder.addArchiveFile(
        ArchiveFile.string(_manifest, jsonEncode({'format': format, 'version': version, 'scripts': entries})),
      );
      await encoder.close();
    } catch (_) {
      // 반쯤 만들어진 백업 파일은 남기지 않는다
      await encoder.close().catchError((_) {});
      if (await file.exists()) await file.delete();
      rethrow;
    }
    return file;
  }

  /// [zipPath] 백업의 대본을 현재 데이터에 추가하고 추가한 개수를 돌려준다. 실패하면 아무것도 바꾸지 않는다.
  /// 같은 이름의 모음이 이미 있으면 그 모음에 넣는다. 파일에서 조금씩 읽어 풀어 쓴다.
  Future<int> restore(String zipPath) async {
    final input = InputFileStream(zipPath);
    final storedImages = <String>[];
    final storedMedia = <String>[];
    try {
      final (archive, entries) = _parse(input);
      final plans = <({
        ScriptDraft draft,
        List<String> collections,
        Map<String, int> collectionOrder,
        DateTime createdAt,
        DateTime updatedAt,
        List<String> images,
        List<(_Take, String)> takes,
      })>[];
      for (final e in entries) {
        final imageNames = <String>[];
        for (final name in (e['images'] as List).cast<String>()) {
          final stored = images.newFileName(p.extension(name));
          storedImages.add(stored);
          await _extract(archive, 'images/$name', images.pathOf(stored));
          imageNames.add(stored);
        }
        final takes = <(_Take, String)>[];
        for (final t in _mediaOf(e)) {
          final stored = repo.media.newFileName(p.extension(t.file));
          storedMedia.add(stored);
          await _extract(archive, 'media/${t.file}', repo.media.pathOf(stored));
          takes.add((t, stored));
        }
        plans.add((
          draft: _draftOf(e),
          collections: _collectionNamesOf(e),
          // 모음 안 순서. 순서 기능이 생기기 전에 만든 백업에는 없다
          collectionOrder: switch (e['collectionOrder']) {
            final Map<String, Object?> m => {
                for (final MapEntry(:key, :value) in m.entries)
                  if (value is int) key.trim(): value,
              },
            _ => const <String, int>{},
          },
          createdAt: DateTime.parse(e['createdAt'] as String),
          updatedAt: DateTime.parse(e['updatedAt'] as String),
          images: imageNames,
          takes: takes,
        ));
      }
      await db.transaction(() async {
        // 모음마다 (백업에 적힌 순서, 복원한 대본)
        final restoredOrder = <int, List<(int, int)>>{};
        for (final plan in plans) {
          final ids = [for (final n in plan.collections) await repo.collectionIdFor(n)];
          final id = await repo.insertRestored(
            plan.draft.withCollectionIds(ids),
            createdAt: plan.createdAt,
            updatedAt: plan.updatedAt,
            storedImageFileNames: plan.images,
          );
          for (final (i, name) in plan.collections.indexed) {
            if (plan.collectionOrder[name] case final position?) {
              restoredOrder.putIfAbsent(ids[i], () => []).add((position, id));
            }
          }
          for (final (take, stored) in plan.takes) {
            await repo.addMedia(
              id,
              kind: take.kind,
              storedFileName: stored,
              duration: take.duration,
              createdAt: take.createdAt,
            );
          }
        }
        // 같은 이름의 모음에 원래 있던 대본 뒤에, 백업에 적힌 차례대로 붙인다
        for (final MapEntry(key: collectionId, value: links) in restoredOrder.entries) {
          links.sort((a, b) => a.$1.compareTo(b.$1));
          await repo.appendToCollectionInOrder(collectionId, [for (final (_, scriptId) in links) scriptId]);
        }
      });
      return plans.length;
    } catch (e) {
      for (final name in storedImages) {
        await images.delete(name);
      }
      for (final name in storedMedia) {
        await repo.media.delete(name);
      }
      if (e is BackupFormatException) rethrow;
      throw BackupFormatException('$e');
    } finally {
      await input.close();
    }
  }

  Future<void> _extract(Archive archive, String entryName, String outPath) async {
    final entry = archive.findFile(entryName);
    if (entry == null) throw BackupFormatException('missing $entryName');
    final out = OutputFileStream(outPath);
    try {
      entry.writeContent(out);
    } finally {
      await out.close();
    }
  }

  (Archive, List<Map<String, Object?>>) _parse(InputStream input) {
    try {
      final archive = ZipDecoder().decodeStream(input);
      final manifestBytes = archive.findFile(_manifest)?.readBytes();
      if (manifestBytes == null) throw const BackupFormatException('no manifest');
      final m = jsonDecode(utf8.decode(manifestBytes)) as Map<String, Object?>;
      if (m['format'] != format) throw const BackupFormatException('wrong format');
      final v = m['version'];
      if (v is! int || v > version) throw const BackupFormatException('unsupported version');
      final entries = (m['scripts'] as List).cast<Map<String, Object?>>();
      // 쓰기 전에 전체를 검증한다
      for (final e in entries) {
        _draftOf(e);
        _collectionNamesOf(e);
        _mediaOf(e);
      }
      return (archive, entries);
    } on BackupFormatException {
      rethrow;
    } catch (e) {
      throw BackupFormatException('$e');
    }
  }

  ScriptDraft _draftOf(Map<String, Object?> e) => ScriptDraft(
        body: e['body'] as String,
        work: e['work'] as String?,
        memo: e['memo'] as String?,
        status: PracticeStatus.values.byName(e['status'] as String),
        favorite: e['favorite'] as bool,
        tags: (e['tags'] as List).cast<String>(),
        // version 1 백업에는 없는 칸이라 기본값을 쓴다
        dialogue: e['dialogue'] as bool? ?? false,
        myRole: e['myRole'] as String?,
        // version 2 백업은 노트가 여러 칸(notes)이라 제목을 붙여 한 글로 합친다
        note: e['note'] as String? ??
            switch (e['notes']) {
              final Map<String, Object?> m => legacyNoteText(m),
              _ => null,
            },
      );

  /// 대본이 든 모음 이름들. 모음 기능이 생기기 전에 만든 백업에는 없다.
  List<String> _collectionNamesOf(Map<String, Object?> e) =>
      [for (final n in (e['collections'] as List?) ?? const []) (n as String).trim()]..removeWhere((n) => n.isEmpty);

  /// 연습 기록. 녹음·영상을 넣지 않고 내보냈거나 예전에 만든 백업에는 없다.
  List<_Take> _mediaOf(Map<String, Object?> e) => [
        for (final m in ((e['media'] as List?) ?? const []).cast<Map<String, Object?>>())
          (
            kind: MediaKind.values.byName(m['kind'] as String),
            file: m['file'] as String,
            duration: switch (m['durationMs']) {
              final int ms => Duration(milliseconds: ms),
              _ => null,
            },
            createdAt: DateTime.parse(m['createdAt'] as String),
          ),
      ];

  @visibleForTesting
  static List<int> debugRewriteManifest(
    List<int> zipBytes,
    Map<String, Object?> Function(Map<String, Object?>) edit,
  ) {
    final archive = ZipDecoder().decodeBytes(zipBytes);
    final out = Archive();
    for (final f in archive.files) {
      if (f.name == _manifest) {
        final m = jsonDecode(utf8.decode(f.readBytes()!)) as Map<String, Object?>;
        out.addFile(ArchiveFile.string(_manifest, jsonEncode(edit(m))));
      } else {
        out.addFile(ArchiveFile.bytes(f.name, f.readBytes()!));
      }
    }
    return ZipEncoder().encodeBytes(out);
  }
}
