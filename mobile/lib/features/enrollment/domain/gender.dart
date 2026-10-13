/// نوع الطالب (بيان فقط — مفيش فصل بسببه؛ بيهمّ لاحقًا في موافقة وسائط البنات).
enum Gender {
  male,
  female;

  String get dbValue => this == Gender.male ? 'male' : 'female';

  static Gender? fromDb(String? value) =>
      value == null ? null : (value == 'female' ? Gender.female : Gender.male);
}
