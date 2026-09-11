import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monologue/backup/backup_service.dart';
import 'package:monologue/data/database.dart';
import 'package:monologue/data/image_store.dart';
import 'package:monologue/data/script_repository.dart';
import 'package:monologue/domain/enums.dart';
import 'package:monologue/domain/script_draft.dart';
import 'package:monologue/domain/script_filter.dart';

class Env {
  Env(this.db, this.images) : repo = ScriptRepository(db, images);

  final AppDatabase db;
  final ImageStore images;
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
    );
    envs.add(e);
    return e;
  }

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
        title: '갈매기',
        work: '갈매기',
        character: '니나',
        body: '나는 갈매기...',
        gender: Gender.female,
        ageRange: AgeRange.twenties,
        status: PracticeStatus.practicing,
        favorite: true,
        tags: ['슬픔'],
      ),
      imagePaths: [img.path],
    );
    await src.repo.create(const ScriptDraft(title: '두번째', body: '본문'));

    final zip = await src.backup.export(tmp, now: DateTime(2026, 9, 11));
    expect(zip.path.endsWith('monologue-backup-20260911.zip'), isTrue);

    final dst = await newEnv('dst');
    await dst.repo.create(const ScriptDraft(title: '기존', body: '유지'));
    expect(await dst.backup.restore(await zip.readAsBytes()), 2);

    final list = await dst.repo.watchScripts(const ScriptFilter()).first;
    expect(list.map((s) => s.script.title).toSet(), {'갈매기', '두번째', '기존'});
    final nina = list.firstWhere((s) => s.script.title == '갈매기');
    final detail = (await dst.repo.watchScript(nina.script.id).first)!;
    expect(detail.script.character, '니나');
    expect(detail.script.gender, Gender.female);
    expect(detail.script.status, PracticeStatus.practicing);
    expect(detail.script.favorite, isTrue);
    expect(detail.tags, ['슬픔']);
    expect(File(dst.images.pathOf(detail.images.single.fileName)).readAsBytesSync(), [9, 8, 7]);
  });

  test('백업 파일이 아니면 거부하고 아무것도 바꾸지 않는다', () async {
    final dst = await newEnv('dst');
    await expectLater(dst.backup.restore([1, 2, 3, 4]), throwsA(isA<BackupFormatException>()));
    expect(await dst.repo.watchScripts(const ScriptFilter()).first, isEmpty);
    expect(dst.images.dir.listSync(), isEmpty);
  });

  test('형식이 다른 backup.json은 거부한다', () async {
    final src = await newEnv('src');
    await src.repo.create(const ScriptDraft(title: 'A', body: 'x'));
    final bytes = await (await src.backup.export(tmp)).readAsBytes();
    final dst = await newEnv('dst');
    final tampered = BackupService.debugRewriteManifest(bytes, (m) => m..['format'] = 'other');
    await expectLater(dst.backup.restore(tampered), throwsA(isA<BackupFormatException>()));
  });
}
