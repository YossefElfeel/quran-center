import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// حارس التعريب: كل نص ظاهر للمستخدم لازم ييجي من AppL10n (app_ar.arb).
/// الاختبار ده بيمسح طبقات العرض ويفشل لو لقى حروف عربي جوّه string literal.
///
/// - التعليقات (`//`, `///`, `/* */`) متجاهلة.
/// - سطر فيه `// l10n-ignore: <السبب>` متجاهل (لعلامات ترقيم/جداول أرقام مثلاً).
/// - [_allowList] لملفات بعينها لازم تفضل كده — كل عنصر بسبب واضح.
const List<String> _scannedRoots = <String>[
  'lib/app',
  'lib/shared/widgets',
  'lib/shared/presentation',
];

/// ملفات مسموح فيها نصوص عربي ثابتة (المسار نسبةً لـ mobile/) → السبب.
const Map<String, String> _allowList = <String, String>{};

final RegExp _arabic = RegExp('[؀-ۿ]');

void main() {
  test('no hardcoded Arabic string literals in presentation code', () {
    final List<File> files = _dartFiles();
    expect(files, isNotEmpty, reason: 'لازم يتشغّل من مجلد mobile/');

    final List<String> offenders = <String>[];
    for (final File file in files) {
      final String path = file.path.replaceAll(r'\', '/');
      if (_allowList.containsKey(path)) continue;
      final List<String> lines = file.readAsLinesSync();
      for (final int lineNo in _arabicLiteralLines(lines)) {
        final String line = lines[lineNo];
        if (line.contains('// l10n-ignore')) continue;
        offenders.add('$path:${lineNo + 1}: ${line.trim()}');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Hardcoded Arabic in presentation code — move it to '
          'lib/l10n/app_ar.arb and use AppL10n (or mark the line with '
          '`// l10n-ignore: <reason>` if it is not user-facing copy):\n'
          '${offenders.join('\n')}',
    );
  });

  test('scanner detects literals and ignores comments', () {
    expect(_arabicLiteralLines(<String>["final a = 'نص';"]), <int>[0]);
    expect(
      _arabicLiteralLines(<String>['final a = "x \${b ? \'نص\' : c}";']),
      <int>[0],
    );
    expect(
      _arabicLiteralLines(<String>["foo(); // تعليق 'فيه' quote"]),
      isEmpty,
    );
    expect(_arabicLiteralLines(<String>['/// "توثيق"']), isEmpty);
    expect(_arabicLiteralLines(<String>['/* "a', 'نص" */ x();']), isEmpty);
    expect(_arabicLiteralLines(<String>["final a = '''", 'سطر', "''';"]), <int>[
      1,
    ]);
  });
}

List<File> _dartFiles() {
  final List<Directory> roots = <Directory>[
    ..._scannedRoots.map(Directory.new),
    ...Directory('lib/features').listSync().whereType<Directory>().map(
      (Directory d) => Directory('${d.path}/presentation'),
    ),
  ].where((Directory d) => d.existsSync()).toList();
  return <File>[
    for (final Directory root in roots)
      ...root
          .listSync(recursive: true)
          .whereType<File>()
          .where(
            (File f) =>
                f.path.endsWith('.dart') &&
                !f.path.endsWith('.g.dart') &&
                !f.path.endsWith('.freezed.dart'),
          ),
  ]..sort((File a, File b) => a.path.compareTo(b.path));
}

/// يرجّع أرقام الأسطر (من صفر) اللي فيها حرف عربي جوّه string literal.
/// tokenizer مبسّط: بيفهم التعليقات، الـ strings بأنواعها (single/double،
/// triple، raw) والـ interpolation المتداخل `${...}`.
List<int> _arabicLiteralLines(List<String> lines) {
  final String src = lines.join('\n');
  final Set<int> hits = <int>{};
  // كل عنصر في الستاك: إمّا string مفتوح (quote) أو كود جوّه interpolation
  // (null) مع عدّاد أقواس.
  final List<_Frame> stack = <_Frame>[_Frame.code()];
  int line = 0;
  int i = 0;
  while (i < src.length) {
    final String c = src[i];
    final _Frame top = stack.last;
    if (c == '\n') line++;

    if (top.quote == null) {
      // كود.
      if (src.startsWith('//', i)) {
        while (i < src.length && src[i] != '\n') {
          i++;
        }
        continue;
      }
      if (src.startsWith('/*', i)) {
        final int end = src.indexOf('*/', i + 2);
        final int stop = end == -1 ? src.length : end + 2;
        line += '\n'.allMatches(src.substring(i, stop)).length;
        i = stop;
        continue;
      }
      if (c == '{') {
        top.braces++;
      } else if (c == '}') {
        if (top.braces == 0 && stack.length > 1) {
          stack.removeLast(); // نهاية ${...} → رجوع للـ string
          i++;
          continue;
        }
        top.braces--;
      } else if (c == "'" || c == '"') {
        final bool raw = i > 0 && src[i - 1] == 'r';
        final String triple = c * 3;
        final String quote = src.startsWith(triple, i) ? triple : c;
        stack.add(_Frame.string(quote, raw: raw));
        i += quote.length;
        continue;
      }
      i++;
      continue;
    }

    // جوّه string.
    if (!top.raw && c == r'\') {
      if (i + 1 < src.length && src[i + 1] == '\n') line++;
      i += 2;
      continue;
    }
    if (src.startsWith(top.quote!, i)) {
      stack.removeLast();
      i += top.quote!.length;
      continue;
    }
    if (!top.raw && src.startsWith(r'${', i)) {
      stack.add(_Frame.code());
      i += 2;
      continue;
    }
    if (top.quote!.length == 1 && c == '\n') {
      // string سطر واحد مقفلش (كود غلط) — اقفله عشان مانبوظش الباقي.
      stack.removeLast();
      i++;
      continue;
    }
    if (_arabic.hasMatch(c)) hits.add(line);
    i++;
  }
  return hits.toList()..sort();
}

class _Frame {
  _Frame.code() : quote = null, raw = false;
  _Frame.string(this.quote, {required this.raw});

  final String? quote;
  final bool raw;
  int braces = 0;
}
