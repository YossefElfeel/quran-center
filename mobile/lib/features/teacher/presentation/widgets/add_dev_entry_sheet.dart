import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../controllers/teacher_controllers.dart';

/// شيت إضافة قيد تطوّر شهري للمعلّم.
///
/// بديل الـ AlertDialog القديم اللي كان بيعمل [TextEditingController] جوّه ميثود
/// async ويتعامل معاه بإيد: هنا الويدجت بتملك دورة حياة الكنترولر، بتتحقّق من
/// الإدخال قبل الإرسال، بتعرض حالة تحميل على الزرّ، وبترجّع رسالة نجاح/خطأ
/// (من غير ما تبلع الأخطاء). بتتفتح عبر [showAppModalSheet].
class AddDevEntrySheet extends ConsumerStatefulWidget {
  const AddDevEntrySheet({super.key});

  @override
  ConsumerState<AddDevEntrySheet> createState() => _AddDevEntrySheetState();
}

class _AddDevEntrySheetState extends ConsumerState<AddDevEntrySheet> {
  final TextEditingController _controller = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final AppL10n l = AppL10n.of(context);
    final NavigatorState navigator = Navigator.of(context);
    setState(() => _saving = true);
    try {
      await ref.read(myDevelopmentProvider.notifier).add(_controller.text);
      if (!mounted) return;
      navigator.pop();
      AppSnackbar.success(context, l.tchDevAddedSuccess);
    } catch (e) {
      if (!mounted) return;
      // الإدخال محفوظ في الحقل — بنسيب الشيت مفتوح عشان يعيد المحاولة.
      setState(() => _saving = false);
      AppSnackbar.error(
        context,
        e is AppException ? e.message : l.tchDevAddFailed,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppTextField(
            controller: _controller,
            autofocus: true,
            maxLines: 4,
            enabled: !_saving,
            label: l.tchDevEntryHint,
            validator: (String? v) =>
                (v == null || v.trim().isEmpty) ? l.tchDevEntryRequired : null,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: _saving ? l.tchSending : l.tchSend,
            icon: Icons.send,
            isLoading: _saving,
            onPressed: _saving ? null : _submit,
          ),
        ],
      ),
    );
  }
}
