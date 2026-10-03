import 'package:shared_preferences/shared_preferences.dart';

class OnboardingStore {
  static const _key = 'onboarding_done';

  bool done = false;

  Future<void> load() async {
    done = (await SharedPreferences.getInstance()).getBool(_key) ?? false;
  }

  Future<void> complete() async {
    await (await SharedPreferences.getInstance()).setBool(_key, true);
    done = true;
  }
}
