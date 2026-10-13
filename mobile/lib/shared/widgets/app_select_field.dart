import 'package:flutter/material.dart';

/// قائمة اختيار موحّدة (عنوان فوق + dropdown) — متحكَّم فيها من [value]:
/// أي تغيير برمجي في [value] (مسح/اختيار تلقائي) بيظهر فورًا، لأن الحقل
/// بيتبني من جديد بمفتاح القيمة بدل ما يفضل على `initialValue` القديمة.
class AppSelectField<T> extends StatelessWidget {
  const AppSelectField({
    required this.label,
    required this.items,
    required this.onChanged,
    this.value,
    this.validator,
    this.hint,
    super.key,
  });
  final String label;
  final List<DropdownMenuItem<T>> items;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final String? Function(T?)? validator;

  /// نص يظهر لما مفيش اختيار (مثلاً "اختار الحلقة").
  final String? hint;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text(label, style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: 8),
      Semantics(
        label: label,
        child: DropdownButtonFormField<T>(
          // مفتاح بالقيمة = الحقل يعكس القيمة البرمجية الحالية دايمًا.
          key: ValueKey<T?>(value),
          initialValue: value,
          isExpanded: true,
          decoration: const InputDecoration(),
          hint: hint == null ? null : Text(hint!),
          itemHeight: null,
          isDense: false,
          items: items,
          onChanged: onChanged,
          validator: validator,
        ),
      ),
    ],
  );
}
