import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// هل المستخدم شاف شاشة الترحيب؟ (افتراضي true عشان ما يومضش للراجعين، ثم القراءة
/// من القرص بتضبطه؛ مفيش قيمة محفوظة = أول تشغيل = false → نعرض الترحيب).
class OnboardingNotifier extends Notifier<bool> {
  static const String _key = 'onboarding_seen';

  @override
  bool build() {
    _load();
    return true;
  }

  void _load() {
    SharedPreferences.getInstance().then((SharedPreferences prefs) {
      state = prefs.getBool(_key) ?? false;
    });
  }

  Future<void> markSeen() async {
    state = true;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }
}

final NotifierProvider<OnboardingNotifier, bool> onboardingSeenProvider =
    NotifierProvider<OnboardingNotifier, bool>(OnboardingNotifier.new);
