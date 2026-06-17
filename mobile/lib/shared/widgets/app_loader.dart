import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// لودر قياسي واحد للتطبيق = [CircularProgressIndicator] (الـ framework بيديره).
/// **مفيش حركة decorative لانهائية** خلاف ده.
class AppLoader extends StatelessWidget {
  const AppLoader({this.message, super.key});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final String? message = this.message;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const CircularProgressIndicator(),
          if (message != null) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            Text(message, style: const TextStyle(fontSize: 16)),
          ],
        ],
      ),
    );
  }
}
