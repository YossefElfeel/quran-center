import 'package:flutter/widgets.dart';

/// يربط عمر controllers (مثلاً [TextEditingController]) اتعملت برّه الشيت
/// بعمر محتوى الشيت نفسه: بتتعمل لها dispose لما الـ subtree يتشال فعلًا —
/// يعني بعد أنيميشن القفل، مش لحظة ما `await showAppModalSheet` يرجع
/// (الحقول لسه بتترسم وقت الأنيميشن، والـ dispose بدري بيرمي استثناء).
///
/// ```dart
/// final name = TextEditingController();
/// await showAppModalSheet<void>(
///   context: context,
///   builder: (_) => DisposeWith(notifiers: [name], child: MyForm(name)),
/// );
/// // ممنوع name.dispose() هنا.
/// ```
class DisposeWith extends StatefulWidget {
  const DisposeWith({required this.notifiers, required this.child, super.key});

  final List<ChangeNotifier> notifiers;
  final Widget child;

  @override
  State<DisposeWith> createState() => _DisposeWithState();
}

class _DisposeWithState extends State<DisposeWith> {
  @override
  void dispose() {
    // العناصر الأبناء (الحقول) بتتشال قبل الأب، فالـ listeners اتفكّت خلاص.
    for (final ChangeNotifier n in widget.notifiers) {
      n.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
