import 'package:shared_preferences/shared_preferences.dart';

/// 한 번만 보여 주는 안내를 이미 봤는지 기억한다.
class AppTips {
  AppTips._(this._prefs, this._photoKeptSeen, this._onboardingSeen);

  static const _photoKeptKey = 'tips.photoKept';
  static const _onboardingKey = 'tips.onboarding';

  final SharedPreferencesAsync _prefs;
  bool _photoKeptSeen;
  bool _onboardingSeen;

  static Future<AppTips> load() async {
    final prefs = SharedPreferencesAsync();
    return AppTips._(
      prefs,
      (await prefs.getBool(_photoKeptKey)) ?? false,
      (await prefs.getBool(_onboardingKey)) ?? false,
    );
  }

  /// 앱을 처음 켰을 때 보여 주는 사용 방법 슬라이드를 이미 넘겼는지.
  bool get onboardingSeen => _onboardingSeen;

  /// 사용 방법 슬라이드를 끝까지 보거나 건너뛰면 부른다.
  /// 기록에 실패해도 첫 화면을 막지 않도록 오류는 삼킨다(이번 실행 동안은 다시 보여 주지 않는다).
  Future<void> markOnboardingSeen() async {
    _onboardingSeen = true;
    try {
      await _prefs.setBool(_onboardingKey, true);
    } catch (_) {}
  }

  /// 사진 보관 안내를 아직 안 봤으면 본 것으로 기록하고 true를 준다.
  /// 기록에 실패해도 대본 저장 흐름을 막지 않도록 오류는 삼킨다(이번 실행 동안은 다시 보여 주지 않는다).
  Future<bool> takePhotoKept() async {
    if (_photoKeptSeen) return false;
    _photoKeptSeen = true;
    try {
      await _prefs.setBool(_photoKeptKey, true);
    } catch (_) {}
    return true;
  }
}
