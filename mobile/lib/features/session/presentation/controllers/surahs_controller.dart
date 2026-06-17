import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/session_repository.dart';
import '../../data/surah_option.dart';

part 'surahs_controller.g.dart';

/// قائمة السور المرجعية (لاختيار نطاق المقطع) — keepAlive لأنها ثابتة.
@Riverpod(keepAlive: true)
Future<List<SurahOption>> surahs(Ref ref) =>
    ref.watch(sessionRepositoryProvider).fetchSurahs();
