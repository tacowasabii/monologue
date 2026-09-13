import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monologue/backup/backup_service.dart';
import 'package:monologue/data/database.dart';
import 'package:monologue/data/image_store.dart';
import 'package:monologue/data/media_store.dart';
import 'package:monologue/data/script_repository.dart';
import 'package:monologue/domain/enums.dart';
import 'package:monologue/domain/script_draft.dart';
import 'package:monologue/domain/script_filter.dart';

class Env {
  Env(this.db, this.images, this.media) : repo = ScriptRepository(db, images, media);

  final AppDatabase db;
  final ImageStore images;
  final MediaStore media;
  final ScriptRepository repo;
  late final backup = BackupService(db, repo, images);
}

void main() {
  late Directory tmp;
  late List<Env> envs;

  Future<Env> newEnv(String name) async {
    final e = Env(
      AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true)),
      ImageStore(await Directory('${tmp.path}/$name').create()),
      MediaStore(await Directory('${tmp.path}/$name-media').create()),
    );
    envs.add(e);
    return e;
  }

  /// 고쳐 쓴 백업 바이트를 복원할 수 있게 파일로 저장한다.
  Future<String> saveZip(String name, List<int> bytes) async {
    final f = File('${tmp.path}/$name.zip');
    await f.writeAsBytes(bytes, flush: true);
    return f.path;
  }

  // 두 기기를 흉내 내려고 서로 다른 인메모리 DB를 일부러 동시에 연다
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('monologue_backup');
    envs = [];
  });

  tearDown(() async {
    for (final e in envs) {
      await e.db.close();
    }
    await tmp.delete(recursive: true);
  });

  test('내보낸 백업을 다른 기기에서 복원하면 내용이 같다', () async {
    final src = await newEnv('src');
    final img = File('${tmp.path}/shot.png')..writeAsBytesSync([9, 8, 7]);
    await src.repo.create(
      const ScriptDraft(
        work: '갈매기',
        memo: '4막 니나 독백',
        body: '나는 갈매기...',
        gender: Gender.female,
        ageRange: AgeRange.twenties,
        status: PracticeStatus.practicing,
        favorite: true,
        tags: ['슬픔'],
      ),
      imagePaths: [img.path],
    );
    await src.repo.create(const ScriptDraft(work: '두번째', body: '본문'));

    final zip = await src.backup.export(tmp, now: DateTime(2026, 9, 11));
    expect(zip.path.endsWith('monologue-backup-20260911.zip'), isTrue);

    final dst = await newEnv('dst');
    await dst.repo.create(const ScriptDraft(work: '기존', body: '유지'));
    expect(await dst.backup.restore(zip.path), 2);

    final list = await dst.repo.watchScripts(const ScriptFilter()).first;
    expect(list.map((s) => s.script.work).toSet(), {'갈매기', '두번째', '기존'});
    final nina = list.firstWhere((s) => s.script.work == '갈매기');
    final detail = (await dst.repo.watchScript(nina.script.id).first)!;
    expect(detail.script.memo, '4막 니나 독백');
    expect(detail.script.gender, Gender.female);
    expect(detail.script.status, PracticeStatus.practicing);
    expect(detail.script.favorite, isTrue);
    expect(detail.tags, ['슬픔']);
    expect(File(dst.images.pathOf(detail.images.single.fileName)).readAsBytesSync(), [9, 8, 7]);
  });

  test('모음도 함께 백업하고, 복원할 때 같은 이름의 모음에 합친다', () async {
    final src = await newEnv('src');
    final audition = await src.repo.createCollection('1차 오디션');
    final exam = await src.repo.createCollection('입시');
    await src.repo.create(ScriptDraft(work: 'A', body: 'x', collectionIds: [audition, exam]));
    await src.repo.create(const ScriptDraft(work: 'B', body: 'x'));
    final zip = await src.backup.export(tmp);

    final dst = await newEnv('dst');
    final existing = await dst.repo.createCollection('1차 오디션');
    expect(await dst.backup.restore(zip.path), 2);

    final counts = {for (final c in await dst.repo.watchCollections().first) c.collection.name: c.scriptCount};
    expect(counts, {'1차 오디션': 1, '입시': 1});
    expect((await dst.repo.findCollection('1차 오디션'))!.id, existing);
  });

  test('모음 정보가 없는 예전 백업도 복원한다', () async {
    final src = await newEnv('src');
    await src.repo.create(const ScriptDraft(work: 'A', body: 'x'));
    final bytes = await (await src.backup.export(tmp)).readAsBytes();
    final old = BackupService.debugRewriteManifest(bytes, (m) {
      for (final e in (m['scripts'] as List).cast<Map<String, Object?>>()) {
        e.remove('collections');
      }
      return m;
    });

    final dst = await newEnv('dst');
    expect(await dst.backup.restore(await saveZip('old', old)), 1);
    expect(await dst.repo.watchCollections().first, isEmpty);
  });

  group('연습 기록', () {
    Future<(Env, int)> sourceWithTake() async {
      final src = await newEnv('src');
      final id = await src.repo.create(const ScriptDraft(work: 'A', body: 'x'));
      final voice = File('${tmp.path}/voice.m4a')..writeAsBytesSync([5, 6, 7]);
      await src.repo.importMedia(id, kind: MediaKind.audio, sourcePath: voice.path, duration: const Duration(seconds: 42));
      return (src, id);
    }

    test('넣겠다고 하지 않으면 녹음·영상은 백업에 들어가지 않는다', () async {
      final (src, _) = await sourceWithTake();
      final zip = await src.backup.export(tmp);

      final dst = await newEnv('dst');
      expect(await dst.backup.restore(zip.path), 1);
      final script = (await dst.repo.watchScripts(const ScriptFilter()).first).single;
      expect(await dst.repo.watchMedia(script.script.id).first, isEmpty);
      expect(dst.media.dir.listSync(), isEmpty);
    });

    test('넣겠다고 하면 녹음·영상 파일과 길이·날짜까지 그대로 옮긴다', () async {
      final (src, srcId) = await sourceWithTake();
      final original = (await src.repo.watchMedia(srcId).first).single;
      final zip = await src.backup.export(tmp, includeMedia: true);

      final dst = await newEnv('dst');
      expect(await dst.backup.restore(zip.path), 1);
      final script = (await dst.repo.watchScripts(const ScriptFilter()).first).single;
      final take = (await dst.repo.watchMedia(script.script.id).first).single;
      expect(take.kind, MediaKind.audio);
      expect(take.durationMs, 42000);
      expect(take.createdAt, original.createdAt);
      expect(File(dst.media.pathOf(take.fileName)).readAsBytesSync(), [5, 6, 7]);
    });

    test('백업에 적힌 녹음 파일이 없으면 거부하고, 풀어 둔 파일을 남기지 않는다', () async {
      final src = await newEnv('src');
      final img = File('${tmp.path}/shot.png')..writeAsBytesSync([9, 8, 7]);
      await src.repo.create(const ScriptDraft(work: 'A', body: 'x'), imagePaths: [img.path]);
      final bytes = await (await src.backup.export(tmp)).readAsBytes();
      final broken = BackupService.debugRewriteManifest(bytes, (m) {
        final e = (m['scripts'] as List).cast<Map<String, Object?>>().single;
        e['media'] = [
          {'kind': 'audio', 'file': 'ghost.m4a', 'durationMs': 1000, 'createdAt': '2026-09-13T10:00:00.000+09:00'},
        ];
        return m;
      });

      final dst = await newEnv('dst');
      await expectLater(dst.backup.restore(await saveZip('broken', broken)), throwsA(isA<BackupFormatException>()));
      expect(await dst.repo.watchScripts(const ScriptFilter()).first, isEmpty);
      expect(dst.images.dir.listSync(), isEmpty);
      expect(dst.media.dir.listSync(), isEmpty);
    });
  });

  test('백업 파일이 아니면 거부하고 아무것도 바꾸지 않는다', () async {
    final dst = await newEnv('dst');
    await expectLater(
      dst.backup.restore(await saveZip('garbage', [1, 2, 3, 4])),
      throwsA(isA<BackupFormatException>()),
    );
    expect(await dst.repo.watchScripts(const ScriptFilter()).first, isEmpty);
    expect(dst.images.dir.listSync(), isEmpty);
  });

  test('형식이 다른 backup.json은 거부한다', () async {
    final src = await newEnv('src');
    await src.repo.create(const ScriptDraft(work: 'A', body: 'x'));
    final bytes = await (await src.backup.export(tmp)).readAsBytes();
    final dst = await newEnv('dst');
    final tampered = BackupService.debugRewriteManifest(bytes, (m) => m..['format'] = 'other');
    await expectLater(dst.backup.restore(await saveZip('tampered', tampered)), throwsA(isA<BackupFormatException>()));
  });
}
