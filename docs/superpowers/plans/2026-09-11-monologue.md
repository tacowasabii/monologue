# 모노로그 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 사진(사진첩 다중 선택·카메라)에서 한글을 인식해 독백 대본을 저장·검색·열람하는 Flutter 앱(iOS·Android)을 스토어 제출 직전 상태까지 만든다.

**Architecture:** 로컬 전용. drift(SQLite)에 대본·태그·이미지 메타, 원본 이미지는 앱 지원 디렉터리에 복사. ML Kit 한글 모델로 기기 내 인식 후 순수 함수 `assembleText`로 본문 조립. 서비스는 `AppScope`(InheritedWidget)로 주입, 화면은 drift `watch()` 스트림 + StreamBuilder.

**Tech Stack:** Flutter 3.47.3 / Dart 3.13, drift 2.35 + drift_flutter + sqlite3 3.5, google_mlkit_text_recognition 0.17.1, image_picker 1.2.3, archive 4.2.0, share_plus 13.3.0, file_picker 12.2.0, shared_preferences 2.5.5, url_launcher 6.3.2, package_info_plus, path_provider, path, intl, flutter_localizations, flutter_launcher_icons 0.14.4.

**Spec:** `docs/superpowers/specs/2026-09-11-monologue-design.md`

## Global Constraints

- 앱 이름 "모노로그", 번들 ID/applicationId `com.tacowasabii.monologue`, 버전 1.0.0+1.
- iOS 최소 15.5. 한국어 UI만 (`Locale('ko')`, flutter_localizations).
- 네트워크 통신 코드 없음(개인정보처리방침 링크를 브라우저로 여는 것만 예외).
- enum 값: Gender{any 무관, male 남, female 여}, AgeRange{any 무관, teens 10대, twenties 20대, thirties 30대, forties 40대, fiftiesPlus 50대 이상}, PracticeStatus{notStarted 연습 전, practicing 연습 중, memorized 다 외움}.
- 성별·나이대 필터는 선택값 + `무관`을 함께 보여준다.
- 제목이 비면 본문 첫 비어있지 않은 줄의 앞 20자.
- 텍스트 조립: 블록 안 줄은 공백으로(줄 끝 `-`면 붙임), 블록 사이·이미지 사이는 빈 줄 하나, 위→아래(같으면 왼→오) 정렬.
- 백업: `monologue-backup-YYYYMMDD.zip` = `backup.json`(format `monologue-backup`, version 1) + `images/<fileName>`. 복원은 항상 추가, 실패 시 아무것도 바꾸지 않음.
- 개인정보처리방침 URL: `https://tacowasabii.vercel.app/monologue/privacy`.

## File Structure

| 파일 | 책임 |
|---|---|
| `lib/main.dart` | 서비스 생성, `runApp` |
| `lib/app.dart` | MaterialApp, 테마, 로컬라이제이션 |
| `lib/app_scope.dart` | `AppServices` + `AppScope` InheritedWidget |
| `lib/domain/enums.dart` | Gender, AgeRange, PracticeStatus (+label) |
| `lib/domain/script_draft.dart` | `ScriptDraft`, `defaultTitle()` |
| `lib/domain/script_filter.dart` | `ScriptFilter` |
| `lib/data/database.dart` | drift 테이블·AppDatabase |
| `lib/data/image_store.dart` | 이미지 파일 복사·삭제·경로 |
| `lib/data/script_repository.dart` | 대본 CRUD, 검색·필터 스트림, 태그 목록 |
| `lib/ocr/assemble_text.dart` | `OcrBlock`, `assembleText()`, `joinLines()` |
| `lib/ocr/text_recognizer.dart` | `TextRecognizing` 인터페이스 + ML Kit 구현 |
| `lib/backup/backup_service.dart` | zip 내보내기·복원 |
| `lib/settings/reading_settings.dart` | 글자 크기(shared_preferences) |
| `lib/ui/list/script_list_screen.dart` | 목록·검색·필터 |
| `lib/ui/list/filter_bar.dart` | 필터 칩 |
| `lib/ui/view/script_view_screen.dart` | 대본 보기 |
| `lib/ui/view/image_viewer_screen.dart` | 원본 이미지 넘겨보기 |
| `lib/ui/edit/script_edit_screen.dart` | 추가·편집 폼 |
| `lib/ui/edit/tag_input.dart` | 태그 입력(자동완성) |
| `lib/ui/capture/capture_flow.dart` | 사진 선택 → 정렬 → 인식 |
| `lib/ui/settings/settings_screen.dart` | 백업·복원·방침·버전 |
| `test/...` | 각 단위·위젯 테스트 |

---

### Task 1: 도구 준비 + 프로젝트 생성 + 네이티브 설정

**Files:** Create: Flutter 프로젝트 전체(`flutter create`), Modify: `pubspec.yaml`, `ios/Podfile`, `ios/Runner/Info.plist`, `android/app/build.gradle.kts`, `android/app/src/main/AndroidManifest.xml`, `analysis_options.yaml`

- [ ] **Step 1: 도구 확인** — `flutter --version`이 3.47.3, `flutter doctor`에서 Android toolchain·Xcode 체크.
- [ ] **Step 2: 생성**

```bash
cd ~/monologue
flutter create --org com.tacowasabii --project-name monologue --platforms ios,android --empty .
```

- [ ] **Step 3: 의존성**

```bash
flutter pub add drift drift_flutter sqlite3 path_provider path google_mlkit_text_recognition image_picker archive share_plus file_picker shared_preferences url_launcher package_info_plus intl 'flutter_localizations:{"sdk":"flutter"}'
flutter pub add dev:drift_dev dev:build_runner dev:flutter_launcher_icons
```

- [ ] **Step 4: API 시그니처 확인** — pub-cache에서 `archive`(ArchiveFile.bytes/string, ZipEncoder.encodeBytes, ZipDecoder.decodeBytes, findFile, readBytes), `file_picker`(pickFiles 호출 형태), ML Kit 한글 pod·gradle 좌표 버전을 읽고 Task 4·6·1 코드와 다르면 그 코드를 맞춘다.

```bash
P=~/.pub-cache/hosted/pub.dev
grep -nE 'factory ArchiveFile\.|ArchiveFile\.(bytes|string)|Uint8List\? readBytes|encodeBytes|decodeBytes' $P/archive-4.*/lib/src/archive/archive_file.dart $P/archive-4.*/lib/src/codecs/zip_encoder.dart $P/archive-4.*/lib/src/codecs/zip_decoder.dart
grep -rnE 'Future<FilePickerResult\?> pickFiles' $P/file_picker-12.*/lib | head
grep -rnE "TextRecognition(Korean)?|text-recognition" $P/google_mlkit_text_recognition-*/ios/*.podspec $P/google_mlkit_text_recognition-*/android/build.gradle*
```

- [ ] **Step 5: iOS 설정**
  - `ios/Podfile`: `platform :ios, '15.5'`, target Runner 안에 `pod 'GoogleMLKit/TextRecognitionKorean', '<podspec의 GoogleMLKit 버전과 동일>'`, post_install에서 모든 pod의 `IPHONEOS_DEPLOYMENT_TARGET`을 15.5 이상으로.
  - `ios/Runner.xcodeproj`: 최소 배포 버전 15.5, Excluded Architectures(Any SDK) `armv7`.
  - `Info.plist`: `CFBundleDisplayName`=`모노로그`, `NSCameraUsageDescription`=`대본을 촬영해 글자를 인식하려면 카메라 접근이 필요해요.`, `NSPhotoLibraryUsageDescription`=`캡처해 둔 대본 사진을 불러오려면 사진 접근이 필요해요.`
- [ ] **Step 6: Android 설정**
  - `android/app/build.gradle.kts`: `applicationId = "com.tacowasabii.monologue"`, `minSdk = maxOf(flutter.minSdkVersion, 21)`, `dependencies { implementation("com.google.mlkit:text-recognition-korean:<확인한 버전>") }`.
  - `AndroidManifest.xml`: `android:label="모노로그"`, `<queries>`에 https VIEW intent(url_launcher).
- [ ] **Step 7: 확인** — `flutter analyze` 0 issues, `flutter test`(기본 테스트 없음이면 통과), `flutter build apk --debug` 성공, `flutter build ios --simulator --debug` 성공(실패 시 원인 기록: ML Kit arm64 시뮬레이터 미지원이면 Task 7에서 실기기/에뮬레이터로 대체).
- [ ] **Step 8: Commit** `chore: scaffold Flutter app with ML Kit Korean and platform config`

---

### Task 2: 순수 로직 — enum, 텍스트 조립, 기본 제목, 필터 값

**Files:** Create `lib/domain/enums.dart`, `lib/domain/script_draft.dart`, `lib/domain/script_filter.dart`, `lib/ocr/assemble_text.dart`; Test `test/ocr/assemble_text_test.dart`, `test/domain/script_draft_test.dart`

**Interfaces (Produces):**
- `enum Gender/AgeRange/PracticeStatus { ...; final String label; }`
- `class OcrBlock { const OcrBlock({required double top, required double left, required List<String> lines}); }`
- `String joinLines(List<String> lines)`, `String assembleText(List<List<OcrBlock>> pages)`
- `String defaultTitle(String body)` — 첫 비어있지 않은 줄 trim 후 앞 20자, 없으면 `'제목 없음'`
- `class ScriptDraft { title, work?, character?, gender, ageRange, status, favorite, body, tags; ScriptDraft withResolvedTitle() }`
- `class ScriptFilter { query, gender?, ageRange?, status?, tag?, favoritesOnly; copyWith(...) ; bool get isActive }`

- [ ] **Step 1: 실패 테스트** — `test/ocr/assemble_text_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:monologue/ocr/assemble_text.dart';

OcrBlock b(double top, List<String> lines, {double left = 0}) => OcrBlock(top: top, left: left, lines: lines);

void main() {
  group('joinLines', () {
    test('블록 안의 줄은 공백 하나로 잇는다', () {
      expect(joinLines(['나는 늘 괜찮다고', '말했어.']), '나는 늘 괜찮다고 말했어.');
    });
    test('하이픈으로 끝난 줄은 공백 없이 잇는다', () {
      expect(joinLines(['self-', 'tape']), 'self-tape');
    });
    test('줄 안의 연속 공백을 정리하고 빈 줄은 건너뛴다', () {
      expect(joinLines(['  괜찮지   않아 ', '', ' 하나도 ']), '괜찮지 않아 하나도');
    });
  });

  group('assembleText', () {
    test('블록을 위에서 아래로 정렬하고 빈 줄로 나눈다', () {
      final page = [b(200, ['둘째 문단']), b(10, ['첫 문단'])];
      expect(assembleText([page]), '첫 문단\n\n둘째 문단');
    });
    test('같은 높이면 왼쪽 블록이 먼저', () {
      final page = [b(10, ['오른쪽'], left: 300), b(10, ['왼쪽'], left: 5)];
      expect(assembleText([page]), '왼쪽\n\n오른쪽');
    });
    test('이미지 사이는 빈 줄 하나로 잇는다', () {
      expect(assembleText([[b(0, ['첫 장'])], [b(0, ['둘째 장'])]]), '첫 장\n\n둘째 장');
    });
    test('글자가 없는 블록과 이미지는 건너뛴다', () {
      expect(assembleText([[b(0, ['  '])], [], [b(0, ['본문'])]]), '본문');
    });
  });
}
```

`test/domain/script_draft_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:monologue/domain/enums.dart';
import 'package:monologue/domain/script_draft.dart';

void main() {
  test('defaultTitle은 첫 비어있지 않은 줄의 앞 20자', () {
    expect(defaultTitle('\n\n  괜찮다는 말은 참 편리하더라. 그 한마디면\n다음 줄'), '괜찮다는 말은 참 편리하더라. 그 ');
    expect(defaultTitle('짧은 줄\n다음'), '짧은 줄');
    expect(defaultTitle('   \n  '), '제목 없음');
  });

  test('withResolvedTitle은 제목이 비었을 때만 채우고 태그를 정리한다', () {
    const d = ScriptDraft(title: '  ', body: '첫 줄\n둘째 줄', tags: [' 슬픔', '슬픔', '', '분노 ']);
    final r = d.withResolvedTitle();
    expect(r.title, '첫 줄');
    expect(r.tags, ['분노', '슬픔']);
    expect(const ScriptDraft(title: '햄릿', body: 'x').withResolvedTitle().title, '햄릿');
  });

  test('enum 라벨', () {
    expect(Gender.values.map((g) => g.label), ['무관', '남', '여']);
    expect(AgeRange.fiftiesPlus.label, '50대 이상');
    expect(PracticeStatus.memorized.label, '다 외움');
  });
}
```

- [ ] **Step 2: 실패 확인** — `flutter test test/ocr test/domain` → import 실패.
- [ ] **Step 3: 구현**

`lib/domain/enums.dart`
```dart
enum Gender {
  any('무관'),
  male('남'),
  female('여');

  const Gender(this.label);
  final String label;
}

enum AgeRange {
  any('무관'),
  teens('10대'),
  twenties('20대'),
  thirties('30대'),
  forties('40대'),
  fiftiesPlus('50대 이상');

  const AgeRange(this.label);
  final String label;
}

enum PracticeStatus {
  notStarted('연습 전'),
  practicing('연습 중'),
  memorized('다 외움');

  const PracticeStatus(this.label);
  final String label;
}
```

`lib/domain/script_draft.dart`
```dart
import 'enums.dart';

const _titleLength = 20;

String defaultTitle(String body) {
  for (final line in body.split('\n')) {
    final t = line.trim();
    if (t.isNotEmpty) return t.length <= _titleLength ? t : t.substring(0, _titleLength);
  }
  return '제목 없음';
}

class ScriptDraft {
  const ScriptDraft({
    required this.title,
    required this.body,
    this.work,
    this.character,
    this.gender = Gender.any,
    this.ageRange = AgeRange.any,
    this.status = PracticeStatus.notStarted,
    this.favorite = false,
    this.tags = const [],
  });

  final String title;
  final String body;
  final String? work;
  final String? character;
  final Gender gender;
  final AgeRange ageRange;
  final PracticeStatus status;
  final bool favorite;
  final List<String> tags;

  /// 제목이 비면 본문으로 채우고, 빈 문자열을 null로, 태그는 trim·중복 제거·정렬.
  ScriptDraft withResolvedTitle() {
    String? blankToNull(String? s) => (s == null || s.trim().isEmpty) ? null : s.trim();
    final cleanTags = {for (final t in tags) t.trim()}..remove('');
    return ScriptDraft(
      title: title.trim().isEmpty ? defaultTitle(body) : title.trim(),
      body: body.trim(),
      work: blankToNull(work),
      character: blankToNull(character),
      gender: gender,
      ageRange: ageRange,
      status: status,
      favorite: favorite,
      tags: cleanTags.toList()..sort(),
    );
  }
}
```

`lib/domain/script_filter.dart`
```dart
import 'enums.dart';

class ScriptFilter {
  const ScriptFilter({
    this.query = '',
    this.gender,
    this.ageRange,
    this.status,
    this.tag,
    this.favoritesOnly = false,
  });

  final String query;
  final Gender? gender;
  final AgeRange? ageRange;
  final PracticeStatus? status;
  final String? tag;
  final bool favoritesOnly;

  bool get isActive =>
      query.trim().isNotEmpty || gender != null || ageRange != null || status != null || tag != null || favoritesOnly;

  // nullable 필드는 함수로 받아 null로 되돌릴 수 있게 한다: copyWith(gender: () => null)
  ScriptFilter copyWith({
    String? query,
    Gender? Function()? gender,
    AgeRange? Function()? ageRange,
    PracticeStatus? Function()? status,
    String? Function()? tag,
    bool? favoritesOnly,
  }) =>
      ScriptFilter(
        query: query ?? this.query,
        gender: gender != null ? gender() : this.gender,
        ageRange: ageRange != null ? ageRange() : this.ageRange,
        status: status != null ? status() : this.status,
        tag: tag != null ? tag() : this.tag,
        favoritesOnly: favoritesOnly ?? this.favoritesOnly,
      );
}
```

`lib/ocr/assemble_text.dart`
```dart
class OcrBlock {
  const OcrBlock({required this.top, required this.left, required this.lines});
  final double top;
  final double left;
  final List<String> lines;
}

final _spaces = RegExp(r'\s+');

/// 화면 폭 때문에 생긴 줄바꿈을 이어붙인다.
String joinLines(List<String> lines) {
  final buf = StringBuffer();
  for (final raw in lines) {
    final line = raw.replaceAll(_spaces, ' ').trim();
    if (line.isEmpty) continue;
    if (buf.isNotEmpty && !buf.toString().endsWith('-')) buf.write(' ');
    buf.write(line);
  }
  return buf.toString();
}

/// 이미지별 인식 블록을 읽는 순서대로 본문 하나로 만든다.
String assembleText(List<List<OcrBlock>> pages) {
  final pageTexts = <String>[];
  for (final blocks in pages) {
    final sorted = [...blocks]
      ..sort((a, b) {
        final byTop = a.top.compareTo(b.top);
        return byTop != 0 ? byTop : a.left.compareTo(b.left);
      });
    final text = sorted.map((b) => joinLines(b.lines)).where((t) => t.isNotEmpty).join('\n\n');
    if (text.isNotEmpty) pageTexts.add(text);
  }
  return pageTexts.join('\n\n');
}
```

- [ ] **Step 4: 통과 확인** — `flutter test test/ocr test/domain` PASS.
- [ ] **Step 5: Commit** `feat: add domain enums, draft/filter models, and OCR text assembly`

---

### Task 3: 데이터 계층 — DB, 이미지 저장소, 저장소(Repository)

**Files:** Create `lib/data/database.dart`, `lib/data/image_store.dart`, `lib/data/script_repository.dart`; Test `test/data/script_repository_test.dart`

**Interfaces:**
- Consumes: Task 2 enums, `ScriptDraft`, `ScriptFilter`.
- Produces:
  - `AppDatabase([QueryExecutor?])` with tables `scripts`, `scriptTags`, `scriptImages`; data classes `Script`, `ScriptTag`, `ScriptImage`.
  - `class ImageStore { ImageStore(Directory dir); static Future<ImageStore> open(); String pathOf(String fileName); Future<String> importFile(String sourcePath); Future<String> importBytes(List<int> bytes, String extension); Future<void> delete(String fileName); }`
  - `class ScriptSummary { Script script; List<String> tags; }`, `class ScriptDetail { Script script; List<String> tags; List<ScriptImage> images; }`
  - `class ScriptRepository { ScriptRepository(AppDatabase db, ImageStore images); Stream<List<ScriptSummary>> watchScripts(ScriptFilter f); Stream<ScriptDetail?> watchScript(int id); Future<int> create(ScriptDraft d, {List<String> imagePaths}); Future<void> update(int id, ScriptDraft d, {List<String> newImagePaths}); Future<void> setFavorite(int id, bool v); Future<void> setStatus(int id, PracticeStatus s); Future<void> delete(int id); Future<List<String>> allTags(); Future<int> insertRestored(ScriptDraft d, {required DateTime createdAt, required DateTime updatedAt, required List<String> storedImageFileNames}); }`

- [ ] **Step 1: 실패 테스트** — `test/data/script_repository_test.dart`

```dart
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
```

- [ ] **Step 2: 실패 확인** — `flutter test test/data` → import 실패.
- [ ] **Step 3: 구현**

`lib/data/database.dart`
```dart
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
```

`lib/data/image_store.dart`
```dart
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ImageStore {
  ImageStore(this.dir);

  final Directory dir;
  int _seq = 0;

  static Future<ImageStore> open() async {
    final base = await getApplicationSupportDirectory();
    return ImageStore(await Directory(p.join(base.path, 'images')).create(recursive: true));
  }

  String pathOf(String fileName) => p.join(dir.path, fileName);

  String _newName(String extension) {
    final ext = extension.isEmpty ? '.jpg' : extension.toLowerCase();
    return '${DateTime.now().microsecondsSinceEpoch}_${_seq++}$ext';
  }

  Future<String> importFile(String sourcePath) async {
    final name = _newName(p.extension(sourcePath));
    await File(sourcePath).copy(pathOf(name));
    return name;
  }

  Future<String> importBytes(List<int> bytes, String extension) async {
    final name = _newName(extension);
    await File(pathOf(name)).writeAsBytes(bytes, flush: true);
    return name;
  }

  Future<void> delete(String fileName) async {
    final f = File(pathOf(fileName));
    if (await f.exists()) await f.delete();
  }
}
```

`lib/data/script_repository.dart`
```dart
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
  const ScriptDetail(this.script, this.tags, this.images);
  final Script script;
  final List<String> tags;
  final List<ScriptImage> images;
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
          e = e & (s.title.like(pattern) | s.work.like(pattern) | s.character.like(pattern) | s.body.like(pattern));
        }
        if (f.gender != null) e = e & s.gender.isIn([f.gender!.name, Gender.any.name]);
        if (f.ageRange != null) e = e & s.ageRange.isIn([f.ageRange!.name, AgeRange.any.name]);
        if (f.status != null) e = e & s.status.equals(f.status!.name);
        if (f.favoritesOnly) e = e & s.favorite.equals(true);
        if (f.tag != null) {
          e = e &
              existsQuery(db.select(db.scriptTags)
                ..where((t) => t.scriptId.equalsExp(s.id) & t.tag.equals(f.tag!)));
        }
        return e;
      })
      ..orderBy([(s) => OrderingTerm.desc(s.updatedAt), (s) => OrderingTerm.desc(s.id)]);
    return q.watch().asyncMap(_withTags);
  }

  Future<List<ScriptSummary>> _withTags(List<Script> rows) async {
    if (rows.isEmpty) return const [];
    final tagRows = await (db.select(db.scriptTags)..where((t) => t.scriptId.isIn(rows.map((r) => r.id)))).get();
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
      return ScriptDetail(script, tags.map((t) => t.tag).toList()..sort(), imgs);
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
      for (final name in stored) {
        await images.delete(name);
      }
      rethrow;
    }
  }

  Future<int> create(ScriptDraft draft, {List<String> imagePaths = const []}) async {
    final stored = await _importAll(imagePaths);
    final now = DateTime.now();
    try {
      return await insertRestored(draft, createdAt: now, updatedAt: now, storedImageFileNames: stored);
    } catch (_) {
      for (final name in stored) {
        await images.delete(name);
      }
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
    final d = draft.withResolvedTitle();
    return db.transaction(() async {
      final id = await db.into(db.scripts).insert(ScriptsCompanion.insert(
            title: d.title,
            work: Value(d.work),
            character: Value(d.character),
            gender: d.gender,
            ageRange: d.ageRange,
            status: d.status,
            favorite: d.favorite,
            body: d.body,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ));
      await _replaceTags(id, d.tags);
      await _appendImages(id, storedImageFileNames);
      return id;
    });
  }

  Future<void> update(int id, ScriptDraft draft, {List<String> newImagePaths = const []}) async {
    final stored = await _importAll(newImagePaths);
    final d = draft.withResolvedTitle();
    try {
      await db.transaction(() async {
        await (db.update(db.scripts)..where((s) => s.id.equals(id))).write(ScriptsCompanion(
              title: Value(d.title),
              work: Value(d.work),
              character: Value(d.character),
              gender: Value(d.gender),
              ageRange: Value(d.ageRange),
              status: Value(d.status),
              favorite: Value(d.favorite),
              body: Value(d.body),
              updatedAt: Value(DateTime.now()),
            ));
        await _replaceTags(id, d.tags);
        await _appendImages(id, stored);
      });
    } catch (_) {
      for (final name in stored) {
        await images.delete(name);
      }
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

  Future<void> setStatus(int id, PracticeStatus status) =>
      (db.update(db.scripts)..where((s) => s.id.equals(id))).write(ScriptsCompanion(status: Value(status)));

  Future<void> delete(int id) async {
    final imgs = await (db.select(db.scriptImages)..where((i) => i.scriptId.equals(id))).get();
    await db.transaction(() async {
      await (db.delete(db.scriptTags)..where((t) => t.scriptId.equals(id))).go();
      await (db.delete(db.scriptImages)..where((i) => i.scriptId.equals(id))).go();
      await (db.delete(db.scripts)..where((s) => s.id.equals(id))).go();
    });
    for (final img in imgs) {
      await images.delete(img.fileName);
    }
  }

  Future<List<String>> allTags() async {
    final q = db.selectOnly(db.scriptTags, distinct: true)..addColumns([db.scriptTags.tag]);
    final rows = await q.get();
    return rows.map((r) => r.read(db.scriptTags.tag)!).toList()..sort();
  }
}
```

- [ ] **Step 4: 코드 생성 + 통과 확인** — `dart run build_runner build --delete-conflicting-outputs && flutter test test/data` PASS (8 tests). `database.g.dart`는 커밋한다.
- [ ] **Step 5: Commit** `feat: add drift database, image store, and script repository`

---

### Task 4: 백업·복원

**Files:** Create `lib/backup/backup_service.dart`; Test `test/backup/backup_service_test.dart`

**Interfaces:**
- Consumes: `AppDatabase`, `ImageStore`, `ScriptRepository.insertRestored`.
- Produces: `class BackupFormatException implements Exception`; `class BackupService { BackupService(AppDatabase db, ScriptRepository repo, ImageStore images); Future<File> export(Directory outDir, {DateTime? now}); Future<int> restore(List<int> zipBytes); }`

- [ ] **Step 1: 실패 테스트** — `test/backup/backup_service_test.dart`

```dart
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
      const ScriptDraft(title: '갈매기', work: '갈매기', character: '니나', body: '나는 갈매기...', gender: Gender.female,
          ageRange: AgeRange.twenties, status: PracticeStatus.practicing, favorite: true, tags: ['슬픔']),
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
```

- [ ] **Step 2: 실패 확인** — `flutter test test/backup` → import 실패.
- [ ] **Step 3: 구현** (Task 1 Step 4에서 확인한 archive 시그니처에 맞춘다)

`lib/backup/backup_service.dart`
```dart
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import '../data/database.dart';
import '../data/image_store.dart';
import '../data/script_repository.dart';
import '../domain/enums.dart';
import '../domain/script_draft.dart';

class BackupFormatException implements Exception {
  const BackupFormatException(this.message);
  final String message;
  @override
  String toString() => 'BackupFormatException: $message';
}

class BackupService {
  BackupService(this.db, this.repo, this.images);

  static const format = 'monologue-backup';
  static const version = 1;
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
        'title': s.title,
        'work': s.work,
        'character': s.character,
        'gender': s.gender.name,
        'ageRange': s.ageRange.name,
        'status': s.status.name,
        'favorite': s.favorite,
        'body': s.body,
        'createdAt': s.createdAt.toIso8601String(),
        'updatedAt': s.updatedAt.toIso8601String(),
        'tags': tags.where((t) => t.scriptId == s.id).map((t) => t.tag).toList(),
        'images': myImages,
      });
    }
    final manifest = {'format': format, 'version': version, 'scripts': entries};
    archive.addFile(ArchiveFile.string(_manifest, jsonEncode(manifest)));

    final stamp = DateFormat('yyyyMMdd').format(now ?? DateTime.now());
    final file = File(p.join(outDir.path, 'monologue-backup-$stamp.zip'));
    await file.writeAsBytes(ZipEncoder().encodeBytes(archive), flush: true);
    return file;
  }

  /// 백업의 대본을 현재 데이터에 추가하고 추가한 개수를 돌려준다.
  Future<int> restore(List<int> zipBytes) async {
    final (archive, entries) = _parse(zipBytes);
    final stored = <String>[];
    try {
      final plans = <(ScriptDraft, DateTime, DateTime, List<String>)>[];
      for (final e in entries) {
        final names = <String>[];
        for (final name in (e['images'] as List).cast<String>()) {
          final file = archive.findFile('images/$name');
          final bytes = file?.readBytes();
          if (bytes == null) throw BackupFormatException('missing image $name');
          final storedName = await images.importBytes(bytes, p.extension(name));
          stored.add(storedName);
          names.add(storedName);
        }
        plans.add((_draftOf(e), DateTime.parse(e['createdAt'] as String), DateTime.parse(e['updatedAt'] as String), names));
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
      entries.forEach(_draftOf); // 쓰기 전에 전체 검증
      return (archive, entries);
    } on BackupFormatException {
      rethrow;
    } catch (e) {
      throw BackupFormatException('$e');
    }
  }

  ScriptDraft _draftOf(Map<String, Object?> e) => ScriptDraft(
        title: e['title'] as String,
        body: e['body'] as String,
        work: e['work'] as String?,
        character: e['character'] as String?,
        gender: Gender.values.byName(e['gender'] as String),
        ageRange: AgeRange.values.byName(e['ageRange'] as String),
        status: PracticeStatus.values.byName(e['status'] as String),
        favorite: e['favorite'] as bool,
        tags: (e['tags'] as List).cast<String>(),
      );

  @visibleForTesting
  static List<int> debugRewriteManifest(List<int> zipBytes, Map<String, Object?> Function(Map<String, Object?>) edit) {
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
```

- [ ] **Step 4: 통과 확인** — `flutter test test/backup` PASS (3 tests).
- [ ] **Step 5: Commit** `feat: add zip backup export and restore`

---

### Task 5: 앱 셸 · 인식 서비스 · 설정값

**Files:** Create `lib/ocr/text_recognizer.dart`, `lib/settings/reading_settings.dart`, `lib/app_scope.dart`, `lib/app.dart`; Modify `lib/main.dart`

**Interfaces (Produces):**
- `abstract interface class TextRecognizing { Future<List<OcrBlock>> recognize(String imagePath); }`, `class MlKitTextRecognizer implements TextRecognizing`
- `class ReadingSettings extends ChangeNotifier { static Future<ReadingSettings> load(); double get fontSize; Future<void> setFontSize(double v); static const min = 14.0, max = 32.0; }`
- `class AppServices { repo, images, ocr, backup, settings }`, `AppScope.of(context) → AppServices`
- `class MonologueApp extends StatelessWidget`

`lib/ocr/text_recognizer.dart`
```dart
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'assemble_text.dart';

abstract interface class TextRecognizing {
  Future<List<OcrBlock>> recognize(String imagePath);
}

class MlKitTextRecognizer implements TextRecognizing {
  final _recognizer = TextRecognizer(script: TextRecognitionScript.korean);

  @override
  Future<List<OcrBlock>> recognize(String imagePath) async {
    final result = await _recognizer.processImage(InputImage.fromFilePath(imagePath));
    return [
      for (final block in result.blocks)
        OcrBlock(
          top: block.boundingBox.top,
          left: block.boundingBox.left,
          lines: [for (final line in block.lines) line.text],
        ),
    ];
  }
}
```

`lib/settings/reading_settings.dart`
```dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReadingSettings extends ChangeNotifier {
  ReadingSettings._(this._prefs, this._fontSize);

  static const min = 14.0;
  static const max = 32.0;
  static const _key = 'reading.fontSize';

  final SharedPreferencesAsync _prefs;
  double _fontSize;

  static Future<ReadingSettings> load() async {
    final prefs = SharedPreferencesAsync();
    return ReadingSettings._(prefs, (await prefs.getDouble(_key)) ?? 20);
  }

  double get fontSize => _fontSize;

  Future<void> setFontSize(double value) async {
    _fontSize = value.clamp(min, max);
    notifyListeners();
    await _prefs.setDouble(_key, _fontSize);
  }
}
```

`lib/app_scope.dart`
```dart
import 'package:flutter/widgets.dart';

import 'backup/backup_service.dart';
import 'data/image_store.dart';
import 'data/script_repository.dart';
import 'ocr/text_recognizer.dart';
import 'settings/reading_settings.dart';

class AppServices {
  const AppServices({required this.repo, required this.images, required this.ocr, required this.backup, required this.settings});
  final ScriptRepository repo;
  final ImageStore images;
  final TextRecognizing ocr;
  final BackupService backup;
  final ReadingSettings settings;
}

class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.services, required super.child});
  final AppServices services;

  static AppServices of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!.services;

  @override
  bool updateShouldNotify(AppScope oldWidget) => services != oldWidget.services;
}
```

`lib/app.dart`
```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'ui/list/script_list_screen.dart';

const _seed = Color(0xFF7A4B5C);

class MonologueApp extends StatelessWidget {
  const MonologueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '모노로그',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: _seed, brightness: Brightness.light),
      darkTheme: ThemeData(colorSchemeSeed: _seed, brightness: Brightness.dark),
      locale: const Locale('ko'),
      supportedLocales: const [Locale('ko')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const ScriptListScreen(),
    );
  }
}
```

`lib/main.dart`
```dart
import 'package:flutter/material.dart';

import 'app.dart';
import 'app_scope.dart';
import 'backup/backup_service.dart';
import 'data/database.dart';
import 'data/image_store.dart';
import 'data/script_repository.dart';
import 'ocr/text_recognizer.dart';
import 'settings/reading_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase();
  final images = await ImageStore.open();
  final repo = ScriptRepository(db, images);
  runApp(AppScope(
    services: AppServices(
      repo: repo,
      images: images,
      ocr: MlKitTextRecognizer(),
      backup: BackupService(db, repo, images),
      settings: await ReadingSettings.load(),
    ),
    child: const MonologueApp(),
  ));
}
```

- [ ] **Step 1:** 위 파일 작성 (Task 6의 `ScriptListScreen`이 아직 없으므로 이 태스크는 Task 6과 함께 컴파일 확인).
- [ ] **Step 2: Commit**은 Task 6 끝에서 함께.

---

### Task 6: 화면 — 목록, 보기, 편집, 캡처, 설정

**Files:** Create `lib/ui/**` (File Structure 표 참고); Test `test/ui/script_list_screen_test.dart`, `test/ui/script_edit_screen_test.dart`, `test/ui/test_harness.dart`

**Interfaces:**
- Consumes: `AppScope.of(context)`, Task 2~5의 모든 공개 API.
- Produces:
  - `ScriptListScreen()`, `ScriptViewScreen(scriptId: int)`, `ImageViewerScreen(paths: List<String>, initialIndex: int)`
  - `ScriptEditScreen({ScriptDetail? existing, String initialBody = '', List<String> newImagePaths = const [], int failedImages = 0})` — 저장 후 `Navigator.pop(context, id)`
  - `class CaptureResult { String text; List<String> imagePaths; int failedCount; }`, `Future<CaptureResult?> runCapture(BuildContext context)`
  - `TagInput({required List<String> tags, required List<String> suggestions, required ValueChanged<List<String>> onChanged})`
  - `FilterBar({required ScriptFilter filter, required List<String> tags, required ValueChanged<ScriptFilter> onChanged})`
  - `SettingsScreen()`

화면 동작(스펙 "화면" 절 그대로):
- **목록**: AppBar(제목 "모노로그", 설정 아이콘) · SearchBar(hint "제목, 작품, 인물, 본문 검색") · FilterBar(즐겨찾기 FilterChip, 성별/나이대/상태/태그 선택 칩 — 탭하면 바텀시트에서 `전체` 또는 값 선택, 선택 시 칩 라벨이 값으로 바뀜) · StreamBuilder 목록(ListTile: 제목 / `작품 · 인물` / 태그 칩 / 상태 라벨 / 별 아이콘 탭으로 즐겨찾기 토글) · 비었을 때 문구 두 가지(전체 비어있음: "아직 대본이 없어요\n사진을 올려 첫 대본을 추가해 보세요", 필터 결과 없음: "조건에 맞는 대본이 없어요") · FAB.extended "대본 추가" → `runCapture` → 결과가 있으면 `ScriptEditScreen(initialBody, newImagePaths, failedImages)` push. 스트림은 filter가 바뀔 때만 새로 만든다(State에 보관).
- **보기**: `watchScript` StreamBuilder. AppBar: 즐겨찾기 토글, 글자 크기(바텀시트 Slider 14~32), 편집, 메뉴(원본 보기 — 이미지 있을 때, 삭제 — 확인 대화상자 "이 대본을 삭제할까요? 원본 사진도 함께 지워져요." 후 pop). 본문: 메타 줄(작품 · 인물 · 성별 · 나이대, 무관/빈 값 생략), 태그 Wrap, `SegmentedButton<PracticeStatus>`(→ setStatus), `SelectableText(body)` 글자 크기는 `ListenableBuilder(settings)`.
- **편집**: Form — 제목(hint "비워두면 본문 첫 줄로"), 작품명, 인물, 성별 `SegmentedButton<Gender>`, 나이대 `DropdownButtonFormField<AgeRange>`, 상태 `SegmentedButton<PracticeStatus>`, 즐겨찾기 SwitchListTile, TagInput(제안: `repo.allTags()`), 본문(minLines 10, validator "본문을 입력해 주세요"). AppBar "저장" → validate → create/update → pop(id). 기존 대본이면 "사진 추가로 이어쓰기" 버튼 → `runCapture` → 본문 끝에 `\n\n`+텍스트, 이미지 경로 누적. `failedImages > 0`이면 첫 프레임에 SnackBar "사진 N장은 글자를 찾지 못했어요". 변경이 있으면 PopScope로 "저장하지 않고 나갈까요?" 확인.
- **캡처(`runCapture`)**: 바텀시트 "사진첩에서 선택"/"카메라로 촬영" → 선택 결과로 `_ArrangeScreen` push(ReorderableListView 썸네일, 항목 삭제, 하단 "사진첩"/"카메라" 추가 버튼, "글자 인식" FilledButton) → 인식: 진행 대화상자("인식 중 k/n"), 이미지별 try/catch, `assembleText` → `CaptureResult` pop. 사진 선택은 `ImagePicker().pickMultiImage(maxWidth: 2400, imageQuality: 90)`, 촬영은 `pickImage(source: ImageSource.camera, maxWidth: 2400, imageQuality: 90)`. `PlatformException` 코드에 `access_denied`가 들어 있으면 SnackBar "사진/카메라 권한이 필요해요. 설정 앱에서 허용해 주세요." 인식 결과가 전부 비면 SnackBar "글자를 찾지 못했어요. 직접 입력할 수 있어요."로 빈 본문 편집 화면을 연다.
- **설정**: "백업 내보내기"(`backup.export(getTemporaryDirectory())` → `SharePlus.instance.share(ShareParams(files: [XFile(path)]))`), "백업에서 복원"(file_picker로 .zip 1개 → 확인 대화상자 "백업의 대본 N개를 지금 목록에 추가할까요?"는 개수 모름 → "백업의 대본을 지금 목록에 추가할까요? 기존 대본은 그대로 남아요." → `restore` → SnackBar "대본 N개를 가져왔어요" / 실패 "백업 파일이 아니거나 손상됐어요"), "개인정보처리방침"(url_launcher externalApplication), "버전"(package_info_plus `version (buildNumber)`).

- [ ] **Step 1: 테스트 하네스** — `test/ui/test_harness.dart`

```dart
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:monologue/app_scope.dart';
import 'package:monologue/backup/backup_service.dart';
import 'package:monologue/data/database.dart';
import 'package:monologue/data/image_store.dart';
import 'package:monologue/data/script_repository.dart';
import 'package:monologue/ocr/assemble_text.dart';
import 'package:monologue/ocr/text_recognizer.dart';
import 'package:monologue/settings/reading_settings.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class FakeRecognizer implements TextRecognizing {
  @override
  Future<List<OcrBlock>> recognize(String imagePath) async => const [];
}

class Harness {
  Harness._(this.db, this.services);
  final AppDatabase db;
  final AppServices services;

  static Future<Harness> create() async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final db = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    final images = ImageStore(Directory.systemTemp.createTempSync('monologue_ui'));
    final repo = ScriptRepository(db, images);
    return Harness._(
      db,
      AppServices(repo: repo, images: images, ocr: FakeRecognizer(), backup: BackupService(db, repo, images), settings: await ReadingSettings.load()),
    );
  }

  Widget wrap(Widget child) => AppScope(
        services: services,
        child: MaterialApp(
          locale: const Locale('ko'),
          supportedLocales: const [Locale('ko')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: child,
        ),
      );
}
```

(`shared_preferences_platform_interface`는 dev_dependency로 추가: `flutter pub add dev:shared_preferences_platform_interface`.)

- [ ] **Step 2: 실패 위젯 테스트**

`test/ui/script_list_screen_test.dart`
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monologue/domain/enums.dart';
import 'package:monologue/domain/script_draft.dart';
import 'package:monologue/ui/list/script_list_screen.dart';

import 'test_harness.dart';

void main() {
  testWidgets('대본이 없으면 안내 문구를 보여준다', (tester) async {
    final h = await tester.runAsync(Harness.create);
    await tester.pumpWidget(h!.wrap(const ScriptListScreen()));
    await tester.pumpAndSettle();
    expect(find.textContaining('아직 대본이 없어요'), findsOneWidget);
    await h.db.close();
  });

  testWidgets('검색어로 목록을 거른다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    await tester.runAsync(() async {
      await h.services.repo.create(const ScriptDraft(title: '햄릿', body: '사느냐 죽느냐'));
      await h.services.repo.create(const ScriptDraft(title: '갈매기', body: '나는 갈매기', gender: Gender.female));
    });
    await tester.pumpWidget(h.wrap(const ScriptListScreen()));
    await tester.pumpAndSettle();
    expect(find.text('햄릿'), findsOneWidget);
    expect(find.text('갈매기'), findsOneWidget);

    await tester.enterText(find.byType(SearchBar), '죽느냐');
    await tester.pumpAndSettle();
    expect(find.text('햄릿'), findsOneWidget);
    expect(find.text('갈매기'), findsNothing);
    await h.db.close();
  });
}
```

`test/ui/script_edit_screen_test.dart`
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monologue/domain/script_filter.dart';
import 'package:monologue/ui/edit/script_edit_screen.dart';

import 'test_harness.dart';

void main() {
  testWidgets('본문이 비면 저장하지 않는다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    await tester.pumpWidget(h.wrap(const ScriptEditScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(find.text('본문을 입력해 주세요'), findsOneWidget);
    await h.db.close();
  });

  testWidgets('인식된 본문으로 저장하면 제목이 첫 줄로 채워진다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    await tester.pumpWidget(h.wrap(const ScriptEditScreen(initialBody: '괜찮다는 말은\n참 편리하더라')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    final list = await tester.runAsync(() => h.services.repo.watchScripts(const ScriptFilter()).first);
    expect(list!.single.script.title, '괜찮다는 말은');
    await h.db.close();
  });
}
```

- [ ] **Step 3: 실패 확인** — `flutter test test/ui` → import 실패.
- [ ] **Step 4: 구현** — Task 5 파일 + `lib/ui/**`를 위 "화면 동작"대로 작성. 공통 규칙: 모든 비동기 후 `if (!context.mounted) return;`, 스트림은 State 필드로 보관, 문자열은 한국어.
- [ ] **Step 5: 통과 확인** — `flutter analyze` 0 issues, `flutter test` 전체 PASS.
- [ ] **Step 6: Commit** `feat: add app shell, capture flow, and list/view/edit/settings screens`

---

### Task 7: 실제 기기 환경에서 인식 확인

**Files:** 없음(문제 발견 시 해당 파일 수정)

- [ ] **Step 1: 샘플 이미지** — 한글 대본 캡처 샘플 2장(스크래치패드에서 생성, 1장은 상태바 포함).
- [ ] **Step 2: Android 에뮬레이터** — AVD 기동 → `adb push` 샘플을 `/sdcard/Pictures/` + 미디어 스캔 → `flutter run -d <emulator>` → 사진첩에서 2장 선택 → 인식 → 편집 화면 본문이 샘플 문장과 일치하는지(오탈자 수 기록) 스크린샷으로 확인 → 저장 → 목록·검색·보기 확인.
- [ ] **Step 3: iOS 시뮬레이터** — `xcrun simctl addmedia` 샘플 → `flutter run -d <sim>` → 같은 흐름. 시뮬레이터 빌드가 ML Kit 아키텍처 문제로 불가하면 그 사실과 오류를 기록하고 `flutter build ios --release --no-codesign` 성공으로 iOS 빌드만 검증.
- [ ] **Step 4:** 발견한 문제 수정 → `flutter test` → Commit `fix: ...`

---

### Task 8: 출시 준비

**Files:** Create `assets/icon/icon.png`, `flutter_launcher_icons.yaml`(또는 pubspec 섹션), `docs/store-listing.md`, `docs/release.md`; Modify `android/app/build.gradle.kts`(release signing), website 저장소 `src/pages/monologue/privacy.astro`

- [ ] **Step 1: 아이콘** — 1024×1024 PNG(단색 배경 + 흰 글자 "모"), `flutter_launcher_icons`로 iOS·Android(적응형 배경색 `_seed`) 생성.
- [ ] **Step 2: Android 릴리스 서명** — `keytool`로 `~/.monologue-keys/upload-keystore.jks` 생성(저장소 밖), `android/key.properties`(gitignore) 읽어 release signingConfig. `flutter build appbundle --release` 성공.
- [ ] **Step 3: iOS 릴리스 빌드** — `flutter build ios --release --no-codesign` 성공. (서명·업로드는 Apple 계정 생성 후 `docs/release.md` 절차로.)
- [ ] **Step 4: 개인정보처리방침** — `~/website/src/pages/monologue/privacy.astro`(수집 데이터 없음, 기기 내 저장·처리, 문의 이메일 없이 GitHub 없이 — 연락처는 사용자 확인 후 기입하도록 release.md에 체크 항목), website `npm test` 후 배포, URL 200 확인.
- [ ] **Step 5: 문서** — `docs/store-listing.md`(앱 이름, 부제, 설명, 키워드, 카테고리 "생산성", 연령 등급 4+, 개인정보 "데이터 수집 안 함"), `docs/release.md`(Apple/Google 계정 가입, 번들 ID 등록, TestFlight·Play 비공개 테스트, 제출 체크리스트).
- [ ] **Step 6: Commit** `chore: add icons, release signing config, and store docs`
