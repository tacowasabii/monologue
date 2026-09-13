import 'package:flutter/services.dart';

import 'assemble_text.dart';

abstract interface class TextRecognizing {
  Future<List<OcrBlock>> recognize(String imagePath);
}

/// 기기 안에서 인식한다. Android: ML Kit 한글 모델(MainActivity.kt), iOS: Apple Vision(AppDelegate.swift).
/// 두 플랫폼 모두 줄 목록만 주고, 문단 묶기는 [groupLines]가 같은 규칙으로 한다.
class PlatformTextRecognizer implements TextRecognizing {
  static const _channel = MethodChannel('monologue/ocr');

  @override
  Future<List<OcrBlock>> recognize(String imagePath) async {
    final raw = await _channel.invokeListMethod<Map<Object?, Object?>>('recognize', {'path': imagePath}) ?? const [];
    return groupLines([
      for (final m in raw)
        OcrLine(
          text: m['text']! as String,
          top: (m['top']! as num).toDouble(),
          left: (m['left']! as num).toDouble(),
          height: (m['height']! as num).toDouble(),
          confidence: (m['confidence'] as num?)?.toDouble(),
        ),
    ]);
  }
}
