import 'package:flutter/material.dart';

/// Scaffold قياسي رفيع — كل شاشة بتركّبه وتحط الـ body بتاعها.
/// (التطبيق RTL على مستوى MaterialApp، فمفيش داعي لضبط الاتجاه هنا.)
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    super.key,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      body: SafeArea(child: body),
      floatingActionButton: floatingActionButton,
    );
  }
}
