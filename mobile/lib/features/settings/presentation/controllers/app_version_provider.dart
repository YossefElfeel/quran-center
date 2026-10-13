import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_version_provider.g.dart';

/// نسخة التطبيق — بتتقري مرة واحدة وتفضل في الكاش (مش مع كل rebuild).
@Riverpod(keepAlive: true)
Future<String> appVersion(Ref ref) async {
  final PackageInfo info = await PackageInfo.fromPlatform();
  return info.buildNumber.isEmpty
      ? info.version
      : '${info.version} (${info.buildNumber})';
}
