import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/core/auth/auth_providers.dart';
import 'package:quran_center/features/excuse/domain/pending_excuse.dart';
import 'package:quran_center/features/excuse/presentation/controllers/pending_excuses_controller.dart';
import 'package:quran_center/features/excuse/presentation/screens/excuse_queue_screen.dart';
import 'package:quran_center/features/feedback/domain/complaint.dart';
import 'package:quran_center/features/feedback/presentation/controllers/feedback_controllers.dart';
import 'package:quran_center/features/feedback/presentation/screens/complaint_inbox_screen.dart';
import 'package:quran_center/features/notifications/domain/app_notification.dart';
import 'package:quran_center/features/notifications/presentation/controllers/notifications_controller.dart';
import 'package:quran_center/features/notifications/presentation/screens/notification_list_screen.dart';
import 'package:quran_center/features/supervisor_eval/domain/eval_criterion.dart';
import 'package:quran_center/features/supervisor_eval/domain/eval_student.dart';
import 'package:quran_center/features/supervisor_eval/presentation/widgets/eval_student_tile.dart';
import 'package:quran_center/features/teacher/domain/teacher_dev_entry.dart';
import 'package:quran_center/features/teacher/presentation/controllers/teacher_controllers.dart';
import 'package:quran_center/features/teacher/presentation/screens/teacher_development_screen.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';
import 'package:quran_center/shared/theme/app_theme.dart';
import 'package:quran_center/shared/widgets/app_scaffold.dart';

void main() {
  runApp(
    ProviderScope(
      overrides: [
        complaintInboxProvider.overrideWith(_FakeComplaintInbox.new),
        pendingExcusesControllerProvider.overrideWith(
          _FakePendingExcuses.new,
        ),
        notificationsControllerProvider.overrideWith(_FakeNotifications.new),
        currentRolesProvider.overrideWith((Ref ref) async => <String>[]),
        myDevelopmentProvider.overrideWith(_FakeMyDevelopment.new),
        myPassRateProvider.overrideWith((Ref ref) async => 0.89),
      ],
      child: const _VisualQaApp(),
    ),
  );
}

class _VisualQaApp extends StatelessWidget {
  const _VisualQaApp();

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: const Locale('ar'),
    supportedLocales: AppL10n.supportedLocales,
    localizationsDelegates: AppL10n.localizationsDelegates,
    theme: AppTheme.light(),
    home: const Directionality(
      textDirection: TextDirection.rtl,
      child: _QaMenu(),
    ),
  );
}

class _QaMenu extends StatelessWidget {
  const _QaMenu();

  void _open(BuildContext context, Widget child) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (BuildContext _) => child),
    );
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
    title: 'مراجعة الإصلاحات',
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        _QaButton(
          label: 'الشكاوى — فتح التفاصيل والرقم والتاريخ',
          icon: Icons.support_agent,
          onTap: () => _open(context, const ComplaintInboxScreen()),
        ),
        _QaButton(
          label: 'الأعذار — فتح الطلب واعتماد الحالة',
          icon: Icons.event_available,
          onTap: () => _open(context, const ExcuseQueueScreen()),
        ),
        _QaButton(
          label: 'التقييم — الدرجة والمستوى والتفاصيل',
          icon: Icons.grading,
          onTap: () => _open(context, const _EvaluationQaScreen()),
        ),
        _QaButton(
          label: 'التطوير — ظهور حالة الاعتماد',
          icon: Icons.verified,
          onTap: () => _open(context, const TeacherDevelopmentScreen()),
        ),
        _QaButton(
          label: 'الإشعارات — فتح إشعار بلا مسار',
          icon: Icons.notifications,
          onTap: () => _open(context, const NotificationListScreen()),
        ),
      ],
    ),
  );
}

class _QaButton extends StatelessWidget {
  const _QaButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: FilledButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Text(label, textAlign: TextAlign.center),
      ),
    ),
  );
}

class _EvaluationQaScreen extends StatelessWidget {
  const _EvaluationQaScreen();

  static const EvalStudent _student = EvalStudent(
    studentPersonId: 'student-1',
    fullName: 'طالب تجريبي',
    selected: true,
    scores: <EvalCriterion, int>{
      EvalCriterion.memorization: 9,
      EvalCriterion.recitation: 8,
      EvalCriterion.mushafReading: 7,
    },
  );

  @override
  Widget build(BuildContext context) => AppScaffold(
    title: 'حلقة تجريبية',
    body: ListView(
      children: <Widget>[
        EvalStudentTile(
          student: _student,
          onEvaluate: () => showModalBottomSheet<void>(
            context: context,
            showDragHandle: true,
            builder: (BuildContext context) => const Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'درجات طالب تجريبي',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  Text('الحفظ: ٩/١٠'),
                  Text('التلاوة: ٨/١٠'),
                  Text('القراءة من المصحف: ٧/١٠'),
                  SizedBox(height: 12),
                  Text(
                    'المتوسط: ٨٫٠ — جيد جدًا',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _FakeComplaintInbox extends ComplaintInbox {
  @override
  Future<List<Complaint>> build() async => <Complaint>[
    Complaint(
      id: 'A1B2C3D4-0000-4000-8000-000000000000',
      category: 'academic',
      body: 'ابني محتاج متابعة أكتر في الحفظ وأريد معرفة خطة المراجعة.',
      status: 'open',
      createdAt: DateTime(2026, 9, 18, 10, 30),
      authorName: 'ولي أمر تجريبي',
    ),
  ];

  @override
  Future<void> respond(String id, String response) async {
    final List<Complaint> current = state.value ?? <Complaint>[];
    state = AsyncData<List<Complaint>>(<Complaint>[
      for (final Complaint item in current)
        Complaint(
          id: item.id,
          category: item.category,
          body: item.body,
          status: 'answered',
          createdAt: item.createdAt,
          authorName: item.authorName,
          managerResponse: response,
          respondedAt: DateTime.now(),
        ),
    ]);
  }
}

class _FakePendingExcuses extends PendingExcusesController {
  @override
  Future<List<PendingExcuse>> build() async => <PendingExcuse>[
    PendingExcuse(
      id: 'excuse-1',
      enrollmentId: 'enrollment-1',
      sessionId: 'session-1',
      studentName: 'طالب تجريبي',
      circleName: 'حلقة تجريبية',
      reason: 'سفر مع العائلة',
      status: 'pending',
      createdAt: DateTime(2026, 9, 19, 17, 15),
    ),
  ];

  @override
  Future<void> decide(PendingExcuse excuse, {required bool approve}) async {
    final List<PendingExcuse> current = state.value ?? <PendingExcuse>[];
    state = AsyncData<List<PendingExcuse>>(<PendingExcuse>[
      for (final PendingExcuse item in current)
        if (item.id == excuse.id)
          item.copyWith(
            status: approve ? 'approved' : 'rejected',
            decidedAt: DateTime.now(),
          )
        else
          item,
    ]);
  }
}

class _FakeNotifications extends NotificationsController {
  @override
  Future<List<AppNotification>> build() async => <AppNotification>[
    AppNotification(
      id: 'notification-1',
      type: 'general',
      title: 'تذكير مهم',
      body: 'هذا إشعار عام بلا صفحة مصدر، ويجب أن يفتح كاملًا بدل أن يكون طريقًا مسدودًا.',
      createdAt: DateTime(2026, 9, 20, 9),
    ),
  ];

  @override
  Future<void> markRead(String id) async {
    final List<AppNotification> current = state.value ?? <AppNotification>[];
    state = AsyncData<List<AppNotification>>(<AppNotification>[
      for (final AppNotification item in current)
        if (item.id == id) item.copyWith(readAt: DateTime.now()) else item,
    ]);
  }

  @override
  Future<void> markAllRead() async {
    final List<AppNotification> current = state.value ?? <AppNotification>[];
    state = AsyncData<List<AppNotification>>(<AppNotification>[
      for (final AppNotification item in current)
        item.copyWith(readAt: DateTime.now()),
    ]);
  }
}

class _FakeMyDevelopment extends MyDevelopment {
  @override
  Future<List<TeacherDevEntry>> build() async => <TeacherDevEntry>[
    TeacherDevEntry(
      id: 'development-1',
      month: DateTime(2026, 9),
      status: 'approved',
      progress: 'تمت مراجعة جزء عمّ',
      approvedAt: DateTime(2026, 9, 20, 11, 30),
    ),
  ];
}
