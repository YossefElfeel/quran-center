/// مسابقة (عرض مختصر).
class CompetitionRow {
  const CompetitionRow({
    required this.id,
    required this.name,
    required this.status,
  });

  factory CompetitionRow.fromMap(Map<String, dynamic> map) => CompetitionRow(
    id: map['id'] as String,
    name: map['name'] as String,
    status: map['status'] as String,
  );

  final String id;
  final String name;
  final String status;
}

/// متقدّم في مسابقة (داخلي أو عام).
class CompetitionApplicationRow {
  const CompetitionApplicationRow({
    required this.id,
    required this.applicantName,
    required this.status,
    this.youtubeUrl,
  });

  factory CompetitionApplicationRow.fromMap(Map<String, dynamic> map) {
    final Map<String, dynamic>? student =
        map['student'] as Map<String, dynamic>?;
    final Map<String, dynamic>? pub = map['pub'] as Map<String, dynamic>?;
    return CompetitionApplicationRow(
      id: map['id'] as String,
      applicantName:
          (student?['full_name'] as String?) ??
          (pub?['name'] as String?) ??
          'متقدّم',
      status: map['status'] as String,
      youtubeUrl: map['youtube_url'] as String?,
    );
  }

  final String id;
  final String applicantName;
  final String status;
  final String? youtubeUrl;
}

/// صف نتيجة مرتّب (الاسم + المتوسّط + عدد المحكّمين).
class CompetitionResultRow {
  const CompetitionResultRow({
    required this.applicantName,
    required this.average,
    required this.judgeCount,
  });

  final String applicantName;
  final double average;
  final int judgeCount;
}
