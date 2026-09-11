import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 원본 캡처를 앱 지원 디렉터리에 복사해 보관한다(사진첩 원본이 지워져도 유지).
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
