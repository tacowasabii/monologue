import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import '../data/database.dart';
import '../data/image_store.dart';
import '../data/script_repository.dart';
import '../domain/enums.dart';
import '../domain/script_draft.dart';
import '../domain/script_notes.dart';

class BackupFormatException implements Exception {
  const BackupFormatException(this.message);

  final String message;

  @override
  String toString() => 'BackupFormatException: $message';
}

class BackupService {
  BackupService(this.db, this.repo, this.images);

  static const format = 'monologue-backup';
  // 2: 대화 형식·내 역할·대본 노트를 더했다. 1도 계속 복원한다
  static const version = 2;
  static const _manifest = 'backup.json';

  final AppDatabase db;
  final ScriptRepository repo;
  final ImageStore images;

  Future<File> export(Directory outDir, {DateTime? now}) async {
    final scripts = await db.select(db.scripts).get();
    final tags = await db.select(db.scriptTags).get();
    final imgs = await (db.select(db.scriptImages)..orderBy([(i) => OrderingTerm.asc(i.position)])).get();

    final archive = Archive();
    final entries = <Map<String, Object?>>[];
    for (final s in scripts) {
      final myImages = imgs.where((i) => i.scriptId == s.id).map((i) => i.fileName).toList();
      for (final name in myImages) {
        archive.addFile(ArchiveFile.bytes('images/$name', await File(images.pathOf(name)).readAsBytes()));
      }
      entries.add({
        'work': s.work,
        'memo': s.memo,
        'gender': s.gender.name,
        'ageRange': s.ageRange.name,
        'status': s.status.name,
        'favorite': s.favorite,
        'body': s.body,
        'dialogue': s.dialogue,
        'myRole': s.myRole,
        'notes': s.notes.toJson(),
        'createdAt': s.createdAt.toIso8601String(),
        'updatedAt': s.updatedAt.toIso8601String(),
        'tags': tags.where((t) => t.scriptId == s.id).map((t) => t.tag).toList(),
        'images': myImages,
      });
    }
    archive.addFile(ArchiveFile.string(_manifest, jsonEncode({'format': format, 'version': version, 'scripts': entries})));

    final stamp = DateFormat('yyyyMMdd').format(now ?? DateTime.now());
    final file = File(p.join(outDir.path, 'monologue-backup-$stamp.zip'));
    await file.writeAsBytes(ZipEncoder().encodeBytes(archive), flush: true);
    return file;
  }

  /// 백업의 대본을 현재 데이터에 추가하고 추가한 개수를 돌려준다. 실패하면 아무것도 바꾸지 않는다.
  Future<int> restore(List<int> zipBytes) async {
    final (archive, entries) = _parse(zipBytes);
    final stored = <String>[];
    try {
      final plans = <(ScriptDraft, DateTime, DateTime, List<String>)>[];
      for (final e in entries) {
        final names = <String>[];
        for (final name in (e['images'] as List).cast<String>()) {
          final bytes = archive.findFile('images/$name')?.readBytes();
          if (bytes == null) throw BackupFormatException('missing image $name');
          final storedName = await images.importBytes(bytes, p.extension(name));
          stored.add(storedName);
          names.add(storedName);
        }
        plans.add((
          _draftOf(e),
          DateTime.parse(e['createdAt'] as String),
          DateTime.parse(e['updatedAt'] as String),
          names,
        ));
      }
      await db.transaction(() async {
        for (final (draft, created, updated, names) in plans) {
          await repo.insertRestored(draft, createdAt: created, updatedAt: updated, storedImageFileNames: names);
        }
      });
      return plans.length;
    } catch (e) {
      for (final name in stored) {
        await images.delete(name);
      }
      if (e is BackupFormatException) rethrow;
      throw BackupFormatException('$e');
    }
  }

  (Archive, List<Map<String, Object?>>) _parse(List<int> zipBytes) {
    try {
      final archive = ZipDecoder().decodeBytes(zipBytes);
      final manifestBytes = archive.findFile(_manifest)?.readBytes();
      if (manifestBytes == null) throw const BackupFormatException('no manifest');
      final m = jsonDecode(utf8.decode(manifestBytes)) as Map<String, Object?>;
      if (m['format'] != format) throw const BackupFormatException('wrong format');
      final v = m['version'];
      if (v is! int || v > version) throw const BackupFormatException('unsupported version');
      final entries = (m['scripts'] as List).cast<Map<String, Object?>>();
      entries.forEach(_draftOf); // 쓰기 전에 전체를 검증한다
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
        gender: Gender.values.byName(e['gender'] as String),
        ageRange: AgeRange.values.byName(e['ageRange'] as String),
        status: PracticeStatus.values.byName(e['status'] as String),
        favorite: e['favorite'] as bool,
        tags: (e['tags'] as List).cast<String>(),
        // version 1 백업에는 없는 칸이라 기본값을 쓴다
        dialogue: e['dialogue'] as bool? ?? false,
        myRole: e['myRole'] as String?,
        notes: switch (e['notes']) {
          final Map<String, Object?> m => ScriptNotes.fromJson(m),
          _ => ScriptNotes.empty,
        },
      );

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
