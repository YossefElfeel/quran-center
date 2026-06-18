/// نتيجة متقدّم بعد تجميع درجات المحكّمين.
class ApplicantResult {
  const ApplicantResult({
    required this.applicationId,
    required this.average,
    required this.maxScore,
    required this.judgeCount,
  });

  final String applicationId;
  final double average;
  final double maxScore;
  final int judgeCount;
}

/// متوسّط درجات المحكّمين (فاضي → صفر).
double averageScore(List<double> scores) => scores.isEmpty
    ? 0
    : scores.reduce((double a, double b) => a + b) / scores.length;

/// ترتيب المتقدّمين: بالمتوسّط تنازليًا، وكسر التعادل بأعلى درجة مفردة،
/// ثم بمعرّف المتقدّم (ثبات الترتيب). قابل للضبط لاحقًا.
List<ApplicantResult> rankApplicants(Map<String, List<double>> scoresByApp) {
  final List<ApplicantResult> results = scoresByApp.entries.map((
    MapEntry<String, List<double>> e,
  ) {
    final List<double> scores = e.value;
    final double maxScore = scores.isEmpty
        ? 0
        : scores.reduce((double a, double b) => a > b ? a : b);
    return ApplicantResult(
      applicationId: e.key,
      average: averageScore(scores),
      maxScore: maxScore,
      judgeCount: scores.length,
    );
  }).toList();
  results.sort((ApplicantResult a, ApplicantResult b) {
    final int byAvg = b.average.compareTo(a.average);
    if (byAvg != 0) return byAvg;
    final int byMax = b.maxScore.compareTo(a.maxScore);
    if (byMax != 0) return byMax;
    return a.applicationId.compareTo(b.applicationId);
  });
  return results;
}
