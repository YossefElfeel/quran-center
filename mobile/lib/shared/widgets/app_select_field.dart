import 'package:flutter/material.dart';

class AppSelectField<T> extends StatelessWidget {
  const AppSelectField({
    required this.label,
    required this.items,
    required this.onChanged,
    this.value,
    this.validator,
    super.key,
  });
  final String label;
  final List<DropdownMenuItem<T>> items;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final String? Function(T?)? validator;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text(label, style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: 8),
      Semantics(
        label: label,
        child: DropdownButtonFormField<T>(
          initialValue: value,
          isExpanded: true,
          decoration: const InputDecoration(),
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
