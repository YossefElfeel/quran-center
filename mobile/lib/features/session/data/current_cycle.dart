import '../domain/portion.dart';

/// الدورة المفتوحة للحلقة: المقطع الحالي + المقام المجمّد (النشطون وقت الفتح).
class CurrentCycle {
  const CurrentCycle({
    required this.cycleId,
    required this.activeAtOpen,
    required this.portion,
  });

  factory CurrentCycle.fromMap(Map<String, dynamic> row) => CurrentCycle(
    cycleId: row['id'] as String,
    activeAtOpen: (row['active_at_open'] as num?)?.toInt() ?? 0,
    portion: Portion.fromMap(row['portion'] as Map<String, dynamic>),
  );

  final String cycleId;
  final int activeAtOpen;
  final Portion portion;
}
