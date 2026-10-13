import 'package:flutter/material.dart';

/// Shared content for form sheets that used to use AlertDialog.
class AppActionSheet extends StatelessWidget {
  const AppActionSheet({
    this.title,
    this.content,
    this.actions = const <Widget>[],
    super.key,
  });
  final Widget? title;
  final Widget? content;
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      if (title != null)
        DefaultTextStyle.merge(
          style: Theme.of(context).textTheme.titleLarge,
          child: title!,
        ),
      const SizedBox(height: 16),
      ?content,
      const SizedBox(height: 16),
      Wrap(spacing: 8, alignment: WrapAlignment.end, children: actions),
    ],
  );
}

class AppChoiceSheet extends StatelessWidget {
  const AppChoiceSheet({this.title, required this.children, super.key});
  final Widget? title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[?title, ...children],
  );
}
