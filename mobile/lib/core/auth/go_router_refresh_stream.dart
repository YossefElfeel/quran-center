import 'dart:async';

import 'package:flutter/foundation.dart';

/// يحوّل Stream لـ Listenable عشان go_router يعيد تقييم الـ redirect عند تغيّر الجلسة.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
