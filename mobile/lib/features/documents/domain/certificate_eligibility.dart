/// أهلية شهادة الإتمام من حالات دفتر الطالب (يطابق is_certificate_eligible في SQL):
/// لازم يكون عدّى مقطع واحد على الأقل، ومفيش أي مقطع لسه مش passed (zero debt).
bool isDebtFreeForCertificate(List<String> ledgerStates) =>
    ledgerStates.isNotEmpty && ledgerStates.every((String s) => s == 'passed');
