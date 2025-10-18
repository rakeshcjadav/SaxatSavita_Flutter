import 'package:shared_preferences/shared_preferences.dart';

class FirstTimeUserService {
  static const String _firstTimeKey = 'is_first_time_user';

  /// Check if this is the first time the user is opening the app
  static Future<bool> isFirstTimeUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_firstTimeKey) ?? true;
  }

  /// Mark that the user has completed the onboarding
  static Future<void> markOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstTimeKey, false);
  }

  /// Reset first time user status (for testing purposes)
  static Future<void> resetFirstTimeUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstTimeKey, true);
  }
}
