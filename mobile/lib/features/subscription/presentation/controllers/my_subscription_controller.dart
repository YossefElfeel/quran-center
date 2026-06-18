import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/subscription_repository.dart';

part 'my_subscription_controller.g.dart';

/// هل اشتراك ولي الأمر الحالي نشط؟ (لبوابة الوصول).
@riverpod
Future<bool> mySubscriptionActive(Ref ref) =>
    ref.watch(subscriptionRepositoryProvider).mySubscriptionActive();
