import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/theme/motion.dart';
import '../../../shared/theme/tokens.dart';
import '../../../shared/widgets/app_button.dart';
import '../onboarding_provider.dart';

class _Slide {
  const _Slide(this.icon, this.title, this.body);
  final IconData icon;
  final String title;
  final String body;
}

/// شاشة ترحيب أول تشغيل — ٣ شرائح + تخطّي/بدء. تظهر فوق الداشبورد مرة واحدة.
class OnboardingView extends ConsumerStatefulWidget {
  const OnboardingView({super.key});

  @override
  ConsumerState<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends ConsumerState<OnboardingView> {
  final PageController _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() => ref.read(onboardingSeenProvider.notifier).markSeen();

  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
    final AppPalette p = context.palette;
    final List<String> roles =
        ref.watch(currentRolesProvider).asData?.value ?? <String>[];
    final bool teacher = roles.contains('teacher'),
        parent = roles.contains('parent');
    final List<_Slide> slides = teacher
        ? <_Slide>[
            _Slide(Icons.menu_book, l.onbTeacherTitle1, l.onbTeacherBody1),
            _Slide(Icons.cloud_off, l.onbTeacherTitle2, l.onbTeacherBody2),
            _Slide(Icons.trending_up, l.onbTeacherTitle3, l.onbTeacherBody3),
          ]
        : parent
        ? <_Slide>[
            _Slide(Icons.child_care, l.onbParentTitle1, l.onbParentBody1),
            _Slide(Icons.message, l.onbParentTitle2, l.onbParentBody2),
            _Slide(Icons.payments, l.onbParentTitle3, l.onbParentBody3),
          ]
        : <_Slide>[
            _Slide(Icons.groups, l.onbAdminTitle1, l.onbAdminBody1),
            _Slide(Icons.fact_check, l.onbAdminTitle2, l.onbAdminBody2),
            _Slide(Icons.notifications, l.onbAdminTitle3, l.onbAdminBody3),
          ];
    final bool last = _page == slides.length - 1;

    return Material(
      color: p.background,
      child: SafeArea(
        child: Column(
          children: <Widget>[
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(onPressed: _finish, child: Text(l.onbSkip)),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: slides.length,
                onPageChanged: (int i) => setState(() => _page = i),
                itemBuilder: (BuildContext context, int i) {
                  final _Slide s = slides[i];
                  return Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: p.heroGradient),
                              shape: BoxShape.circle,
                              boxShadow: AppElevation.shadowMd(p.shadowColor),
                            ),
                            child: Icon(s.icon, size: 56, color: p.onHero),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          Text(
                            s.title,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.headlineMd.copyWith(
                              color: p.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            s.body,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyLg.copyWith(
                              color: p.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                for (int i = 0; i < slides.length; i++)
                  Semantics(
                    label: l.onbPageIndicator('${i + 1}', '${slides.length}'),
                    selected: i == _page,
                    child: AnimatedContainer(
                      duration: reduceMotion(context)
                          ? Duration.zero
                          : AppDurations.fast,
                      margin: const EdgeInsets.all(4),
                      width: i == _page ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _page
                            ? p.primary
                            : p.primary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(AppRadii.full),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: AppButton(
                label: last
                    ? (teacher
                          ? l.onbTeacherFinish
                          : parent
                          ? l.onbParentFinish
                          : l.onbAdminFinish)
                    : l.onbNext,
                icon: last ? Icons.check : Icons.arrow_forward,
                onPressed: () {
                  if (last) {
                    _finish();
                    if (teacher || parent) context.go('/me');
                  } else {
                    if (reduceMotion(context)) {
                      _controller.jumpToPage(_page + 1);
                      return;
                    }
                    _controller.nextPage(
                      duration: AppDurations.base,
                      curve: AppCurves.emphasized,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
