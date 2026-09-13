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
import 'package:monologue/domain/script_notes.dart';

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

  test('성별·나이대 필터는 무관도 포함한다', () async {
    await repo.create(const ScriptDraft(work: '남20', body: 'x', gender: Gender.male, ageRange: AgeRange.twenties));
    await repo.create(const ScriptDraft(work: '여30', body: 'x', gender: Gender.female, ageRange: AgeRange.thirties));
    await repo.create(const ScriptDraft(work: '무관', body: 'x'));
    expect((await works(const ScriptFilter(gender: Gender.male)))..sort(), ['남20', '무관']);
    expect((await works(const ScriptFilter(ageRange: AgeRange.thirties)))..sort(), ['무관', '여30']);
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

  test('이미지 복사 실패 시 아무것도 저장하지 않는다', () async {
    await expectLater(
      repo.create(const ScriptDraft(work: 'A', body: 'x'), imagePaths: [await fakeImage('ok.png'), '${tmp.path}/missing.png']),
      throwsA(isA<FileSystemException>()),
    );
    expect(await works(const ScriptFilter()), isEmpty);
    expect(images.dir.listSync(), isEmpty);
  });

  test('create는 형식·역할·노트를 저장하고 update는 형식만 바꾼다', () async {
    final id = await repo.create(const ScriptDraft(
      body: '민수: 안녕\n지영: 응',
      dialogue: true,
      myRole: '지영',
      notes: ScriptNotes(situation: '새벽', medium: ScriptMedium.play),
    ));
    await repo.update(id, const ScriptDraft(body: '민수: 안녕\n지영: 응', dialogue: false));
    final s = (await repo.watchScript(id).first)!.script;
    expect(s.dialogue, isFalse);
    expect(s.myRole, '지영');
    expect(s.notes, const ScriptNotes(situation: '새벽', medium: ScriptMedium.play));
  });

  test('updateNotes는 노트를 정리해 저장하고 수정 시각을 바꾼다', () async {
    final id = await repo.create(const ScriptDraft(body: 'x'));
    final before = (await repo.watchScript(id).first)!.script.updatedAt;
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await repo.updateNotes(id, const ScriptNotes(objective: '  용서받기 ', obstacle: ''));
    final s = (await repo.watchScript(id).first)!.script;
    expect(s.notes, const ScriptNotes(objective: '용서받기'));
    expect(s.updatedAt.isAfter(before), isTrue);
  });

  test('setMyRole은 역할을 저장하고 null이면 지운다', () async {
    final id = await repo.create(const ScriptDraft(body: '민수: 안녕', dialogue: true));
    await repo.setMyRole(id, '민수');
    expect((await repo.watchScript(id).first)!.script.myRole, '민수');
    await repo.setMyRole(id, null);
    expect((await repo.watchScript(id).first)!.script.myRole, isNull);
  });

  test('작가로도 검색된다', () async {
    await repo.create(const ScriptDraft(work: '갈매기', body: 'x', notes: ScriptNotes(author: '체호프')));
    await repo.create(const ScriptDraft(work: '햄릿', body: 'x'));
    expect(await works(const ScriptFilter(query: '체호프')), ['갈매기']);
  });
}
