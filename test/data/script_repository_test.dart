import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monologue/data/database.dart';
import 'package:monologue/data/image_store.dart';
import 'package:monologue/data/media_store.dart';
import 'package:monologue/data/script_repository.dart';
import 'package:monologue/domain/enums.dart';
import 'package:monologue/domain/script_draft.dart';
import 'package:monologue/domain/script_filter.dart';

void main() {
  late AppDatabase db;
  late Directory tmp;
  late ImageStore images;
  late MediaStore media;
  late ScriptRepository repo;

  Future<String> fakeImage(String name) async {
    final f = File('${tmp.path}/$name');
    await f.writeAsBytes([1, 2, 3, name.length]);
    return f.path;
  }

  setUp(() async {
    db = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    tmp = await Directory.systemTemp.createTemp('monologue_test');
    images = ImageStore(await Directory('${tmp.path}/store').create());
    media = MediaStore(await Directory('${tmp.path}/media').create());
    repo = ScriptRepository(db, images, media);
  });

  tearDown(() async {
    await db.close();
    await tmp.delete(recursive: true);
  });

  // 테스트마다 작품명으로 대본을 구분한다
  Future<List<String>> works(ScriptFilter f) async =>
      (await repo.watchScripts(f).first).map((s) => s.script.work!).toList();

  test('create는 대본·태그·이미지를 저장하고 이미지를 저장소로 복사한다', () async {
    final id = await repo.create(
      const ScriptDraft(body: ' 첫 줄\n본문 ', memo: '  ', tags: ['슬픔', '분노']),
      imagePaths: [await fakeImage('a.png'), await fakeImage('b.png')],
    );
    final d = (await repo.watchScript(id).first)!;
    expect(d.script.body, '첫 줄\n본문');
    expect(d.script.memo, isNull);
    expect(d.tags, ['분노', '슬픔']);
    expect(d.images.map((i) => i.position), [0, 1]);
    for (final img in d.images) {
      expect(File(images.pathOf(img.fileName)).existsSync(), isTrue);
    }
  });

  test('검색은 작품명·메모·본문 부분 일치', () async {
    await repo.create(const ScriptDraft(work: 'A', body: '사느냐 죽느냐'));
    await repo.create(const ScriptDraft(work: '갈매기', body: '...'));
    await repo.create(const ScriptDraft(work: 'C', memo: '니나 · 2차 오디션 지정 대사', body: '...'));
    expect(await works(const ScriptFilter(query: '죽느냐')), ['A']);
    expect(await works(const ScriptFilter(query: '갈매')), ['갈매기']);
    expect(await works(const ScriptFilter(query: '니나')), ['C']);
  });

  test('태그·즐겨찾기 필터', () async {
    final a = await repo.create(const ScriptDraft(work: 'A', body: 'x', tags: ['코미디']));
    await repo.create(const ScriptDraft(work: 'B', body: 'x'));
    await repo.setFavorite(a, true);
    expect(await works(const ScriptFilter(tag: '코미디')), ['A']);
    expect(await works(const ScriptFilter(favoritesOnly: true)), ['A']);
  });

  test('최근 수정순으로 정렬한다', () async {
    final a = await repo.create(const ScriptDraft(work: 'A', body: 'x'));
    await repo.create(const ScriptDraft(work: 'B', body: 'x'));
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await repo.update(a, const ScriptDraft(work: 'A2', body: 'x'));
    expect(await works(const ScriptFilter()), ['A2', 'B']);
  });

  test('update는 메모와 태그를 교체하고 새 이미지를 뒤에 붙인다', () async {
    final id = await repo.create(
      const ScriptDraft(work: 'A', body: 'x', memo: '처음 메모', tags: ['a']),
      imagePaths: [await fakeImage('1.png')],
    );
    await repo.update(
      id,
      const ScriptDraft(work: 'A', body: 'y', memo: '고친 메모', tags: ['b']),
      newImagePaths: [await fakeImage('2.png')],
    );
    final d = (await repo.watchScript(id).first)!;
    expect(d.script.memo, '고친 메모');
    expect(d.tags, ['b']);
    expect(d.images.map((i) => i.position), [0, 1]);
    expect(await repo.allTags(), ['b']);
  });

  test('watchAllTags는 태그가 바뀌면 새 목록을 낸다', () async {
    final tags = repo.watchAllTags();
    expect(await tags.first, isEmpty);
    final id = await repo.create(const ScriptDraft(work: 'A', body: 'x', tags: ['코미디', '분노']));
    expect(await tags.first, ['분노', '코미디']);
    await repo.update(id, const ScriptDraft(work: 'A', body: 'x', tags: ['슬픔']));
    expect(await tags.first, ['슬픔']);
  });

  test('delete는 행과 이미지 파일을 지운다', () async {
    final id = await repo.create(const ScriptDraft(work: 'A', body: 'x', tags: ['t']), imagePaths: [await fakeImage('1.png')]);
    final file = images.pathOf((await repo.watchScript(id).first)!.images.single.fileName);
    await repo.delete(id);
    expect(await repo.watchScript(id).first, isNull);
    expect(File(file).existsSync(), isFalse);
    expect(await repo.allTags(), isEmpty);
  });

  test('deleteAll은 고른 대본만 사진·연습 기록 파일과 함께 지운다', () async {
    final a = await repo.create(const ScriptDraft(work: 'A', body: 'x'), imagePaths: [await fakeImage('a.png')]);
    final b = await repo.create(const ScriptDraft(work: 'B', body: 'x'));
    await repo.create(const ScriptDraft(work: 'C', body: 'x'));
    final image = images.pathOf((await repo.watchScript(a).first)!.images.single.fileName);
    final take = media.newFileName('.m4a');
    File(media.pathOf(take)).writeAsBytesSync([1, 2, 3]);
    await repo.addMedia(b, kind: MediaKind.audio, storedFileName: take);

    await repo.deleteAll([a, b]);
    expect(await works(const ScriptFilter()), ['C']);
    expect(File(image).existsSync(), isFalse);
    expect(File(media.pathOf(take)).existsSync(), isFalse);
  });

  group('모음', () {
    test('대본을 여러 모음에 넣고, 모음으로 거르고, 대본 수를 센다', () async {
      final audition = await repo.createCollection(' 1차 오디션 ');
      final exam = await repo.createCollection('입시');
      final a = await repo.create(ScriptDraft(work: 'A', body: 'x', collectionIds: [audition, exam]));
      await repo.create(ScriptDraft(work: 'B', body: 'x', collectionIds: [audition]));
      await repo.create(const ScriptDraft(work: 'C', body: 'x'));

      expect((await works(ScriptFilter(collectionId: audition)))..sort(), ['A', 'B']);
      expect(await works(ScriptFilter(collectionId: exam)), ['A']);
      expect((await repo.watchScript(a).first)!.collectionIds, [audition, exam]..sort());
      final summaries = await repo.watchCollections().first;
      expect([for (final c in summaries) (c.collection.name, c.scriptCount)], [('1차 오디션', 2), ('입시', 1)]);
      expect(await repo.watchScriptCount().first, 3);
    });

    test('update는 모음 연결을 바꾸고, 대본을 지우면 연결도 지운다', () async {
      final audition = await repo.createCollection('1차 오디션');
      final exam = await repo.createCollection('입시');
      final id = await repo.create(ScriptDraft(work: 'A', body: 'x', collectionIds: [audition]));
      await repo.update(id, ScriptDraft(work: 'A', body: 'x', collectionIds: [exam]));
      expect((await repo.watchScript(id).first)!.collectionIds, [exam]);

      await repo.delete(id);
      expect([for (final c in await repo.watchCollections().first) c.scriptCount], [0, 0]);
    });

    test('모음 이름을 바꿀 수 있고, 모음을 지워도 대본은 남는다', () async {
      final audition = await repo.createCollection('1차 오디션');
      await repo.create(ScriptDraft(work: 'A', body: 'x', collectionIds: [audition]));
      await repo.renameCollection(audition, '2차 오디션');
      expect((await repo.findCollection('2차 오디션'))?.id, audition);

      await repo.deleteCollection(audition);
      expect(await repo.watchCollections().first, isEmpty);
      expect(await works(const ScriptFilter()), ['A']);
    });

    test('collectionIdFor는 같은 이름이면 있는 모음을 쓴다', () async {
      final audition = await repo.createCollection('1차 오디션');
      expect(await repo.collectionIdFor('1차 오디션'), audition);
      expect(await repo.collectionIdFor('입시'), isNot(audition));
      expect(await repo.watchCollections().first, hasLength(2));
    });

    test('removeFromCollection은 그 모음에서만 빼고, 대본과 다른 모음의 자리는 남긴다', () async {
      final audition = await repo.createCollection('1차 오디션');
      final workshop = await repo.createCollection('워크숍');
      final a = await repo.create(ScriptDraft(work: 'A', body: 'x', collectionIds: [audition, workshop]));
      await repo.create(ScriptDraft(work: 'B', body: 'x', collectionIds: [audition]));

      await repo.removeFromCollection(audition, [a]);
      expect(await works(ScriptFilter(collectionId: audition)), ['B']);
      expect(await works(ScriptFilter(collectionId: workshop)), ['A']);
      expect(await works(const ScriptFilter()), unorderedEquals(['A', 'B']));
    });
  });

  group('순서', () {
    Future<void> tick() => Future<void>.delayed(const Duration(milliseconds: 5));

    test('정렬 기준에 따라 최근 수정순, 최근 만든 순, 작품명순으로 보여 준다', () async {
      final b = await repo.create(const ScriptDraft(work: '나', body: 'x'));
      await tick();
      await repo.create(const ScriptDraft(work: '다', body: 'x'));
      await tick();
      // 작품명이 없으면 본문 첫머리로 줄 세운다
      await repo.create(const ScriptDraft(body: '가나다 본문'));
      await tick();
      await repo.update(b, const ScriptDraft(work: '나', body: 'y'));

      Future<List<String>> headings(ScriptSort sort) async => [
            for (final s in await repo.watchScripts(ScriptFilter(sort: sort)).first) s.script.work ?? s.script.body,
          ];
      expect(await headings(ScriptSort.updated), ['나', '가나다 본문', '다']);
      expect(await headings(ScriptSort.created), ['가나다 본문', '다', '나']);
      expect(await headings(ScriptSort.work), ['가나다 본문', '나', '다']);
    });

    test('모음에 새로 넣은 대본은 맨 위에 오고, 정한 순서를 모음마다 따로 기억한다', () async {
      final audition = await repo.createCollection('1차 오디션');
      final exam = await repo.createCollection('입시');
      final a = await repo.create(ScriptDraft(work: 'A', body: 'x', collectionIds: [audition, exam]));
      final b = await repo.create(ScriptDraft(work: 'B', body: 'x', collectionIds: [audition, exam]));
      final c = await repo.create(ScriptDraft(work: 'C', body: 'x', collectionIds: [audition]));
      expect(await works(ScriptFilter(collectionId: audition)), ['C', 'B', 'A']);

      await repo.reorderCollection(audition, [a, c, b]);
      expect(await works(ScriptFilter(collectionId: audition)), ['A', 'C', 'B']);
      expect(await works(ScriptFilter(collectionId: exam)), ['B', 'A']);

      // 내용을 고치거나 다른 모음에 더 넣어도 이미 정한 순서는 그대로다
      await tick();
      await repo.update(b, ScriptDraft(work: 'B', body: 'y', collectionIds: [audition, exam]));
      await repo.update(c, ScriptDraft(work: 'C', body: 'x', collectionIds: [audition, exam]));
      expect(await works(ScriptFilter(collectionId: audition)), ['A', 'C', 'B']);
      expect(await works(ScriptFilter(collectionId: exam)), ['C', 'B', 'A']);
    });

    test('appendToCollectionInOrder는 이미 있던 대본 뒤에 주어진 순서대로 붙인다', () async {
      final audition = await repo.createCollection('1차 오디션');
      await repo.create(ScriptDraft(work: '기존', body: 'x', collectionIds: [audition]));
      final a = await repo.create(ScriptDraft(work: 'A', body: 'x', collectionIds: [audition]));
      final b = await repo.create(ScriptDraft(work: 'B', body: 'x', collectionIds: [audition]));
      await repo.appendToCollectionInOrder(audition, [a, b]);
      expect(await works(ScriptFilter(collectionId: audition)), ['기존', 'A', 'B']);
    });

    test('즐겨찾기 수를 센다', () async {
      final a = await repo.create(const ScriptDraft(work: 'A', body: 'x', favorite: true));
      await repo.create(const ScriptDraft(work: 'B', body: 'x'));
      final count = repo.watchFavoriteCount();
      expect(await count.first, 1);
      await repo.setFavorite(a, false);
      expect(await count.first, 0);
    });
  });

  group('연습 기록', () {
    test('기록을 최근 순으로 보여 주고, 기록을 지우면 파일도 지운다', () async {
      final id = await repo.create(const ScriptDraft(work: 'A', body: 'x'));
      final video = await repo.importMedia(
        id,
        kind: MediaKind.video,
        sourcePath: await fakeImage('take1.mp4'),
        duration: const Duration(seconds: 90),
      );
      // 앱에서 녹음한 파일은 저장소에 바로 써진다
      final recorded = media.newFileName('.m4a');
      await File(media.pathOf(recorded)).writeAsBytes([1, 2]);
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await repo.addMedia(id, kind: MediaKind.audio, storedFileName: recorded, duration: const Duration(seconds: 42));

      final items = await repo.watchMedia(id).first;
      expect(items.map((m) => (m.kind, m.durationMs)), [(MediaKind.audio, 42000), (MediaKind.video, 90000)]);
      final videoFile = media.pathOf(items.last.fileName);
      expect(File(videoFile).existsSync(), isTrue);

      await repo.deleteMedia(video);
      expect(File(videoFile).existsSync(), isFalse);
      expect(await repo.watchMedia(id).first, hasLength(1));
    });

    test('대본을 지우면 연습 기록과 파일도 함께 지운다', () async {
      final id = await repo.create(const ScriptDraft(work: 'A', body: 'x'));
      await repo.importMedia(id, kind: MediaKind.audio, sourcePath: await fakeImage('voice.m4a'));
      final file = media.pathOf((await repo.watchMedia(id).first).single.fileName);

      await repo.delete(id);
      expect(File(file).existsSync(), isFalse);
      expect(await repo.watchMedia(id).first, isEmpty);
    });

    test('mediaSizeBytes는 연습 기록 파일 크기를 모두 더한다', () async {
      final id = await repo.create(const ScriptDraft(work: 'A', body: 'x'));
      await repo.importMedia(id, kind: MediaKind.audio, sourcePath: await fakeImage('a.m4a'));
      await repo.importMedia(id, kind: MediaKind.video, sourcePath: await fakeImage('b.mp4'));
      expect(await repo.mediaSizeBytes(), 8); // fakeImage는 4바이트짜리 파일을 만든다
    });
  });

  test('이미지 복사 실패 시 아무것도 저장하지 않는다', () async {
    await expectLater(
      repo.create(const ScriptDraft(work: 'A', body: 'x'), imagePaths: [await fakeImage('ok.png'), '${tmp.path}/missing.png']),
      throwsA(isA<FileSystemException>()),
    );
    expect(await works(const ScriptFilter()), isEmpty);
    expect(images.dir.listSync(), isEmpty);
  });

  test('create는 형식·역할·노트를 저장하고 update는 노트를 건드리지 않는다', () async {
    final id = await repo.create(const ScriptDraft(
      body: '민수: 안녕\n지영: 응',
      dialogue: true,
      myRole: '지영',
      note: '새벽\n\n지영은 먼저 말하고 싶지 않다',
    ));
    await repo.update(id, const ScriptDraft(body: '민수: 안녕\n지영: 응', dialogue: false));
    final s = (await repo.watchScript(id).first)!.script;
    expect(s.dialogue, isFalse);
    expect(s.myRole, '지영');
    expect(s.note, '새벽\n\n지영은 먼저 말하고 싶지 않다');
  });

  test('updateNote는 앞뒤 공백을 다듬어 저장하고 수정 시각을 바꾸며, 비우면 노트를 지운다', () async {
    final id = await repo.create(const ScriptDraft(body: 'x'));
    final before = (await repo.watchScript(id).first)!.script.updatedAt;
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await repo.updateNote(id, '  용서받고 싶다\n');
    final s = (await repo.watchScript(id).first)!.script;
    expect(s.note, '용서받고 싶다');
    expect(s.updatedAt.isAfter(before), isTrue);

    await repo.updateNote(id, '   ');
    expect((await repo.watchScript(id).first)!.script.note, isNull);
  });

  test('setMyRole은 역할을 저장하고 null이면 지운다', () async {
    final id = await repo.create(const ScriptDraft(body: '민수: 안녕', dialogue: true));
    await repo.setMyRole(id, '민수');
    expect((await repo.watchScript(id).first)!.script.myRole, '민수');
    await repo.setMyRole(id, null);
    expect((await repo.watchScript(id).first)!.script.myRole, isNull);
  });

  test('노트 내용으로도 검색된다', () async {
    await repo.create(const ScriptDraft(work: '갈매기', body: 'x', note: '작가: 체호프'));
    await repo.create(const ScriptDraft(work: '햄릿', body: 'x'));
    expect(await works(const ScriptFilter(query: '체호프')), ['갈매기']);
  });
}
