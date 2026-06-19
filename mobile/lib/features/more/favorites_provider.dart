import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// مفضّلة المستخدم = قائمة مسارات الميزات المثبّتة (محفوظة محليًا).
class FavoritesNotifier extends Notifier<List<String>> {
  static const String _key = 'feature_favorites';

  @override
  List<String> build() {
    _load();
    return const <String>[];
  }

  void _load() {
    SharedPreferences.getInstance().then((SharedPreferences prefs) {
      state = prefs.getStringList(_key) ?? const <String>[];
    });
  }

  Future<void> toggle(String route) async {
    final List<String> next = List<String>.of(state);
    if (next.contains(route)) {
      next.remove(route);
    } else {
      next.add(route);
    }
    state = next;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, next);
  }

  bool isFavorite(String route) => state.contains(route);
}

final NotifierProvider<FavoritesNotifier, List<String>> favoritesProvider =
    NotifierProvider<FavoritesNotifier, List<String>>(FavoritesNotifier.new);
