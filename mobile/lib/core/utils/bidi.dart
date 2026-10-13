/// يعزل نص لاتيني/كود (زي "#A183") كاتجاه LTR جوّه سطر عربي (Unicode
/// LRI U+2066 … PDI U+2069)، عشان ميكسرش ترتيب السطر ولا يشدّ علامات الترقيم
/// جنبه.
final String _lri = String.fromCharCode(0x2066);
final String _pdi = String.fromCharCode(0x2069);

String ltrIsolate(String text) => '$_lri$text$_pdi';
