import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

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
    final List<_Slide> slides = <_Slide>[
      _Slide(Icons.dashboard_customize_outlined, l.onbTitle1, l.onbBody1),
      _Slide(Icons.touch_app_outlined, l.onbTitle2, l.onbBody2),
      _Slide(Icons.palette_outlined, l.onbTitle3, l.onbBody3),
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
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                for (int i = 0; i < slides.length; i++)
                  AnimatedContainer(
                    duration: AppDurations.fast,
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
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: AppButton(
                label: last ? l.onbStart : l.onbNext,
                icon: last ? Icons.check : Icons.arrow_back,
                onPressed: () {
                  if (last) {
                    _finish();
                  } else {
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
