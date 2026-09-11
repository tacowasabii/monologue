import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'assemble_text.dart';

abstract interface class TextRecognizing {
  Future<List<OcrBlock>> recognize(String imagePath);
}

/// ML Kit 한글 모델로 기기 안에서 인식한다(한글 모델은 라틴 문자도 인식).
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
