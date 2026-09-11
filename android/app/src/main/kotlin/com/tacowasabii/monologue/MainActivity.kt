package com.tacowasabii.monologue

import android.net.Uri
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * 기기 안에서 글자를 인식한다(ML Kit 한글 모델, 라틴 문자도 인식).
 * Dart의 PlatformTextRecognizer와 짝을 이루며, 줄 목록(text, top, left, height — 픽셀)을 돌려준다.
 */
class MainActivity : FlutterActivity() {
    private val recognizerDelegate = lazy { TextRecognition.getClient(KoreanTextRecognizerOptions.Builder().build()) }
    private val recognizer by recognizerDelegate

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "monologue/ocr").setMethodCallHandler { call, result ->
            if (call.method != "recognize") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val path = call.argument<String>("path")
            if (path == null) {
                result.error("bad_args", "path is required", null)
                return@setMethodCallHandler
            }
            val image = try {
                InputImage.fromFilePath(this, Uri.fromFile(File(path)))
            } catch (e: Exception) {
                result.error("ocr_failed", e.message, null)
                return@setMethodCallHandler
            }
            recognizer.process(image)
                .addOnSuccessListener { text ->
                    val lines = text.textBlocks.flatMap { it.lines }.mapNotNull { line ->
                        val box = line.boundingBox ?: return@mapNotNull null
                        mapOf(
                            "text" to line.text,
                            "top" to box.top.toDouble(),
                            "left" to box.left.toDouble(),
                            "height" to box.height().toDouble(),
                        )
                    }
                    result.success(lines)
                }
                .addOnFailureListener { e -> result.error("ocr_failed", e.message, null) }
        }
    }

    override fun onDestroy() {
        if (recognizerDelegate.isInitialized()) recognizer.close()
        super.onDestroy()
    }
}
