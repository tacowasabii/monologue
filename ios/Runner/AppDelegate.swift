import Flutter
import ImageIO
import UIKit
import Vision

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "MonologueOcrPlugin") {
      OcrPlugin.register(with: registrar)
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "MonologueScreenPlugin") {
      ScreenPlugin.register(with: registrar)
    }
  }
}

/// 기기 안에서 글자를 인식한다(Apple Vision). Dart의 `PlatformTextRecognizer`와 짝을 이룬다.
/// 결과는 줄 목록이며 좌표는 이미지 크기로 정규화한 값(원점 왼쪽 위)이다.
final class OcrPlugin: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "monologue/ocr", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(OcrPlugin(), channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "recognize" else {
      result(FlutterMethodNotImplemented)
      return
    }
    guard let args = call.arguments as? [String: Any], let path = args["path"] as? String else {
      result(FlutterError(code: "bad_args", message: "path is required", details: nil))
      return
    }
    DispatchQueue.global(qos: .userInitiated).async {
      do {
        let lines = try Self.recognize(path: path)
        DispatchQueue.main.async { result(lines) }
      } catch {
        DispatchQueue.main.async {
          result(FlutterError(code: "ocr_failed", message: error.localizedDescription, details: nil))
        }
      }
    }
  }

  private static func recognize(path: String) throws -> [[String: Any]] {
    let url = URL(fileURLWithPath: path)
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
          let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
      throw NSError(domain: "monologue.ocr", code: 1, userInfo: [NSLocalizedDescriptionKey: "cannot read image"])
    }
    let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
    let rawOrientation = properties?[kCGImagePropertyOrientation] as? UInt32 ?? 1
    let orientation = CGImagePropertyOrientation(rawValue: rawOrientation) ?? .up

    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = true
    request.recognitionLanguages = ["ko-KR", "en-US"]
    try VNImageRequestHandler(cgImage: image, orientation: orientation).perform([request])

    return (request.results ?? []).compactMap { observation in
      guard let candidate = observation.topCandidates(1).first else { return nil }
      let box = observation.boundingBox // 정규화 좌표, 원점 왼쪽 아래
      return [
        "text": candidate.string,
        "top": 1 - box.maxY,
        "left": box.minX,
        "height": box.height,
        // 손글씨처럼 인식기가 자신 없어 하는 줄을 가려내는 데 쓴다
        "confidence": candidate.confidence,
      ]
    }
  }
}

/// 몰입 읽기 동안 화면이 꺼지지 않게 한다. Dart의 `PlatformScreenAwake`와 짝을 이룬다.
final class ScreenPlugin: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "monologue/screen", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(ScreenPlugin(), channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "keepOn", let args = call.arguments as? [String: Any], let on = args["on"] as? Bool else {
      result(FlutterMethodNotImplemented)
      return
    }
    UIApplication.shared.isIdleTimerDisabled = on
    result(nil)
  }
}
