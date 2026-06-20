import 'package:flutter/material.dart';

/// غلاف رفيع موحّد فوق [SegmentedButton] — بيرث ستايل الثيم تلقائيًا.
///
/// كل قطعة سجلّ `(value, label)`؛ الاختيار مفرد ([selected]) و[onChanged]
/// بترجّع القيمة المختارة.
class AppSegmentedControl<T> extends StatelessWidget {
  const AppSegmentedControl({
    required this.segments,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final List<({T value, String label})> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<T>(
      showSelectedIcon: false,
      segments: <ButtonSegment<T>>[
        for (final ({T value, String label}) s in segments)
          ButtonSegment<T>(value: s.value, label: Text(s.label)),
      ],
      selected: <T>{selected},
      onSelectionChanged: (Set<T> set) => onChanged(set.first),
    );
  }
}
