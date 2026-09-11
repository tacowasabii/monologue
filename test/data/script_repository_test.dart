import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monologue/data/database.dart';
import 'package:monologue/data/image_store.dart';
import 'package:monologue/data/script_repository.dart';
import 'package:monologue/domain/enums.dart';
import 'package:monologue/domain/script_draft.dart';
import 'package:monologue/domain/script_filter.dart';

void main() {
  late AppDatabase db;
  late Directory tmp;
  late ImageStore images;
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
    repo = ScriptRepository(db, images);
  });

  tearDown(() async {
    await db.close();
    await tmp.delete(recursive: true);
  });

  Future<List<String>> titles(ScriptFilter f) async =>
      (await repo.watchScripts(f).first).map((s) => s.script.title).toList();

  test('create는 대본·태그·이미지를 저장하고 이미지를 저장소로 복사한다', () async {
    final id = await repo.create(
      const ScriptDraft(title: '', body: '첫 줄\n본문', tags: ['슬픔', '분노']),
      imagePaths: [await fakeImage('a.png'), await fakeImage('b.png')],
    );
    final d = (await repo.watchScript(id).first)!;
    expect(d.script.title, '첫 줄');
    expect(d.tags, ['분노', '슬픔']);
    expect(d.images.map((i) => i.position), [0, 1]);
    for (final img in d.images) {
      expect(File(images.pathOf(img.fileName)).existsSync(), isTrue);
    }
  });

  test('검색은 제목·작품명·인물·본문 부분 일치', () async {
    await repo.create(const ScriptDraft(title: '햄릿 독백', body: '사느냐 죽느냐'));
    await repo.create(const ScriptDraft(title: 'B', work: '갈매기', body: '...'));
    await repo.create(const ScriptDraft(title: 'C', character: '니나', body: '...'));
    expect(await titles(const ScriptFilter(query: '죽느냐')), ['햄릿 독백']);
    expect(await titles(const ScriptFilter(query: '갈매')), ['B']);
    expect(await titles(const ScriptFilter(query: '니나')), ['C']);
  });

  test('성별·나이대 필터는 무관도 포함한다', () async {
    await repo.create(const ScriptDraft(title: '남20', body: 'x', gender: Gender.male, ageRange: AgeRange.twenties));
    await repo.create(const ScriptDraft(title: '여30', body: 'x', gender: Gender.female, ageRange: AgeRange.thirties));
    await repo.create(const ScriptDraft(title: '무관', body: 'x'));
    expect((await titles(const ScriptFilter(gender: Gender.male)))..sort(), ['남20', '무관']);
    expect((await titles(const ScriptFilter(ageRange: AgeRange.thirties)))..sort(), ['무관', '여30']);
  });

  test('태그·상태·즐겨찾기 필터', () async {
    final a = await repo.create(const ScriptDraft(title: 'A', body: 'x', tags: ['코미디']));
    await repo.create(const ScriptDraft(title: 'B', body: 'x', status: PracticeStatus.memorized));
    await repo.setFavorite(a, true);
    expect(await titles(const ScriptFilter(tag: '코미디')), ['A']);
    expect(await titles(const ScriptFilter(status: PracticeStatus.memorized)), ['B']);
    expect(await titles(const ScriptFilter(favoritesOnly: true)), ['A']);
  });

  test('최근 수정순으로 정렬한다', () async {
    final a = await repo.create(const ScriptDraft(title: 'A', body: 'x'));
    await repo.create(const ScriptDraft(title: 'B', body: 'x'));
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await repo.update(a, const ScriptDraft(title: 'A2', body: 'x'));
    expect(await titles(const ScriptFilter()), ['A2', 'B']);
  });

  test('update는 태그를 교체하고 새 이미지를 뒤에 붙인다', () async {
    final id = await repo.create(const ScriptDraft(title: 'A', body: 'x', tags: ['a']), imagePaths: [await fakeImage('1.png')]);
    await repo.update(id, const ScriptDraft(title: 'A', body: 'y', tags: ['b']), newImagePaths: [await fakeImage('2.png')]);
    final d = (await repo.watchScript(id).first)!;
    expect(d.tags, ['b']);
    expect(d.images.map((i) => i.position), [0, 1]);
    expect(await repo.allTags(), ['b']);
  });

  test('watchAllTags는 태그가 바뀌면 새 목록을 낸다', () async {
    final tags = repo.watchAllTags();
    expect(await tags.first, isEmpty);
    final id = await repo.create(const ScriptDraft(title: 'A', body: 'x', tags: ['코미디', '분노']));
    expect(await tags.first, ['분노', '코미디']);
    await repo.update(id, const ScriptDraft(title: 'A', body: 'x', tags: ['슬픔']));
    expect(await tags.first, ['슬픔']);
  });

  test('delete는 행과 이미지 파일을 지운다', () async {
    final id = await repo.create(const ScriptDraft(title: 'A', body: 'x', tags: ['t']), imagePaths: [await fakeImage('1.png')]);
    final file = images.pathOf((await repo.watchScript(id).first)!.images.single.fileName);
    await repo.delete(id);
    expect(await repo.watchScript(id).first, isNull);
    expect(File(file).existsSync(), isFalse);
    expect(await repo.allTags(), isEmpty);
  });

  test('이미지 복사 실패 시 아무것도 저장하지 않는다', () async {
    await expectLater(
      repo.create(const ScriptDraft(title: 'A', body: 'x'), imagePaths: [await fakeImage('ok.png'), '${tmp.path}/missing.png']),
      throwsA(isA<FileSystemException>()),
    );
    expect(await titles(const ScriptFilter()), isEmpty);
    expect(images.dir.listSync(), isEmpty);
  });
}
