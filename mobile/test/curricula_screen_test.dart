import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_center/features/admin_setup/data/curriculum_repository.dart';
import 'package:quran_center/features/admin_setup/domain/curriculum.dart';
import 'package:quran_center/features/admin_setup/presentation/screens/curricula_screen.dart';

class _MockCurriculumRepository extends Mock implements CurriculumRepository {}

void main() {
  testWidgets('شاشة المناهج بتعرض القايمة', (WidgetTester tester) async {
    final _MockCurriculumRepository repo = _MockCurriculumRepository();
    when(() => repo.fetchAll()).thenAnswer(
      (_) async => const <Curriculum>[
        Curriculum(id: '1', name: 'جزء عمّ', type: CurriculumType.quran),
        Curriculum(
          id: '2',
          name: 'تأسيس',
          type: CurriculumType.arabicFoundation,
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [curriculumRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: CurriculaScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('جزء عمّ'), findsOneWidget);
    expect(find.text('تأسيس'), findsOneWidget);
  });
}
