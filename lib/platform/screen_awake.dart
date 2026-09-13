import 'package:flutter/services.dart';

abstract interface class ScreenAwake {
  Future<void> keepOn(bool on);
}

/// iOS: `isIdleTimerDisabled`(AppDelegate.swift), Android: `FLAG_KEEP_SCREEN_ON`(MainActivity.kt).
class PlatformScreenAwake implements ScreenAwake {
  static const _channel = MethodChannel('monologue/screen');

  @override
  Future<void> keepOn(bool on) => _channel.invokeMethod<void>('keepOn', {'on': on});
}
