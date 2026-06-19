import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../shared/theme/theme_mode_provider.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_list_card.dart';
import '../../../../shared/widgets/app_list_skeleton.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/app_section_header.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../favorites_provider.dart';
import '../../feature_catalog.dart';

/// مركز "المزيد" — كل الميزات مجمّعة حسب التصنيف + بحث + تثبيت في المفضّلة.
class MoreHubScreen extends ConsumerStatefulWidget {
  const MoreHubScreen({super.key});

  @override
  ConsumerState<MoreHubScreen> createState() => _MoreHubScreenState();
}

class _MoreHubScreenState extends ConsumerState<MoreHubScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
    final AsyncValue<List<String>> rolesAsync = ref.watch(currentRolesProvider);

    return AppScaffold(
      title: l.moreTitle,
      actions: <Widget>[_ThemeMenu()],
      body: rolesAsync.when(
        loading: () => const AppListSkeleton(),
        error: (Object e, StackTrace _) => AppErrorView(
          message: l.genericError,
          onRetry: () => ref.invalidate(currentRolesProvider),
        ),
        data: (List<String> roles) => _buildBody(context, l, roles),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppL10n l, List<String> roles) {
    final List<String> favorites = ref.watch(favoritesProvider);
    final List<FeatureItem> visible = featuresFor(roles);
    final String q = _query.trim();
    final List<FeatureItem> filtered = q.isEmpty
        ? visible
        : visible.where((FeatureItem f) => f.label(l).contains(q)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: AppTextField(
            hint: l.moreSearchHint,
            prefixIcon: Icons.search,
            onChanged: (String v) => setState(() => _query = v),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? EmptyState(message: l.moreNoResults, icon: Icons.search_off)
              : ListView(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                  children: <Widget>[
                    for (final FeatureCategory cat in FeatureCategory.values)
                      ..._categorySection(context, l, cat, filtered, favorites),
                  ],
                ),
        ),
      ],
    );
  }

  List<Widget> _categorySection(
    BuildContext context,
    AppL10n l,
    FeatureCategory cat,
    List<FeatureItem> items,
    List<String> favorites,
  ) {
    final List<FeatureItem> inCat = items
        .where((FeatureItem f) => f.category == cat)
        .toList();
    if (inCat.isEmpty) return const <Widget>[];
    return <Widget>[
      AppSectionHeader(title: categoryLabel(l, cat)),
      for (final FeatureItem f in inCat)
        AppListCard(
          title: f.label(l),
          leadingIcon: f.icon,
          onTap: () => context.push(f.route),
          trailing: IconButton(
            tooltip: favorites.contains(f.route)
                ? l.removeFavorite
                : l.addFavorite,
            icon: Icon(
              favorites.contains(f.route) ? Icons.star : Icons.star_border,
              color: favorites.contains(f.route)
                  ? context.palette.accent
                  : null,
            ),
            onPressed: () =>
                ref.read(favoritesProvider.notifier).toggle(f.route),
          ),
        ),
    ];
  }
}

/// قائمة اختيار المظهر (system/light/dark/amoled).
class _ThemeMenu extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    final AppThemeChoice current = ref.watch(themeChoiceProvider);
    return PopupMenuButton<AppThemeChoice>(
      icon: const Icon(Icons.brightness_6_outlined),
      tooltip: l.settingsTheme,
      initialValue: current,
      onSelected: (AppThemeChoice c) =>
          ref.read(themeChoiceProvider.notifier).set(c),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<AppThemeChoice>>[
        PopupMenuItem<AppThemeChoice>(
          value: AppThemeChoice.system,
          child: Text(l.themeSystem),
        ),
        PopupMenuItem<AppThemeChoice>(
          value: AppThemeChoice.light,
          child: Text(l.themeLight),
        ),
        PopupMenuItem<AppThemeChoice>(
          value: AppThemeChoice.dark,
          child: Text(l.themeDark),
        ),
        PopupMenuItem<AppThemeChoice>(
          value: AppThemeChoice.amoled,
          child: Text(l.themeAmoled),
        ),
      ],
    );
  }
}
