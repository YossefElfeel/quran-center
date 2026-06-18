import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase/supabase_providers.dart';
import 'app_settings.dart';

export 'app_settings.dart';

part 'settings_repository.g.dart';

/// يقرا system_settings (key→value jsonb) ويحوّلها لـ AppSettings.
class SettingsRepository {
  SettingsRepository(this._client);

  final SupabaseClient _client;

  Future<AppSettings> fetch() async {
    final List<Map<String, dynamic>> rows = await _client
        .from('system_settings')
        .select('key, value');
    final Map<String, Object?> m = <String, Object?>{
      for (final Map<String, dynamic> r in rows) r['key'] as String: r['value'],
    };
    return AppSettings.fromMap(m);
  }
}

@riverpod
SettingsRepository settingsRepository(Ref ref) =>
    SettingsRepository(ref.watch(supabaseClientProvider));

/// إعدادات النظام (keepAlive — بتتقري مرة وتفضل) اللي التطبيق بيستهلكها.
@Riverpod(keepAlive: true)
Future<AppSettings> appSettings(Ref ref) =>
    ref.watch(settingsRepositoryProvider).fetch();
