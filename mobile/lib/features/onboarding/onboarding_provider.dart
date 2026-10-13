import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/supabase/supabase_providers.dart';

/// هل المستخدم **الحالي** شاف شاشة الترحيب؟ المفتاح لكل حساب
/// (`onboarding_seen_<authUserId>`) عشان حساب تاني على نفس الموبايل يشوف
/// ترحيب دوره.
///
/// الافتراضي true عشان ما يومضش للراجعين، وبعدين القراءة من القرص بتضبطه
/// (مفيش قيمة = أول مرة للحساب ده = false → نعرض الترحيب).
///
/// ترحيل: المفتاح القديم `onboarding_seen` كان للجهاز كله — أول حساب يفتح بعد
/// التحديث بيورثه (ويتمسح القديم) فمحدش من المستخدمين الحاليين يشوفه تاني.
class OnboardingNotifier extends Notifier<bool> {
  static const String legacyKey = 'onboarding_seen';
  static String keyFor(String userId) => 'onboarding_seen_$userId';

  String? _userId;

  @override
  bool build() {
    // إعادة البناء بس لما المستخدم نفسه يتغيّر (مش مع كل تجديد توكن).
    final String? fromStream = ref.watch(
      authStateProvider.select(
        (AsyncValue<AuthState> a) => a.asData?.value.session?.user.id,
      ),
    );
    final String? userId = fromStream ?? _currentUserId();
    _userId = userId;
    if (userId != null) unawaited(_load(userId));
    return true;
  }

  String? _currentUserId() {
    try {
      return ref.read(supabaseClientProvider).auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  Future<void> _load(String userId) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      bool? seen = prefs.getBool(keyFor(userId));
      if (seen == null) {
        if (prefs.getBool(legacyKey) ?? false) {
          await prefs.setBool(keyFor(userId), true);
          await prefs.remove(legacyKey);
          seen = true;
        } else {
          seen = false;
        }
      }
      if (ref.mounted && _userId == userId) state = seen;
    } catch (_) {
      // التخزين مش متاح — نسيبها "متشافة" بدل ما نزعج المستخدم.
    }
  }

  Future<void> markSeen() async {
    state = true;
    final String? userId = _userId;
    if (userId == null) return;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(keyFor(userId), true);
    } catch (_) {}
  }
}

final NotifierProvider<OnboardingNotifier, bool> onboardingSeenProvider =
    NotifierProvider<OnboardingNotifier, bool>(OnboardingNotifier.new);
