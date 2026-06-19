# المتبقّي من الخطة — دليل تنفيذ لـ session جديد

> آخر تحقّق فعلي: **2026-06-19** (مقابل الريبو + الـ DB الحيّة + خدمات Edge).
> النواة كلها خلصت واتحقّق منها (`flutter analyze` نضيف، CI أخضر، RLS/engine OK).
> الملف ده بيوثّق **اللي لسه** بالظبط عشان تبدأ منه على طول.

## 0) إزاي تبدأ الـ session الجديد (Onboarding سريع)

1. **اقرا الأول:** [الخطة الأصلية](../../.claude/plans/we-will-work-on-moonlit-rabin.md) (الـ ACTIVE BACKLOG) + [`VERIFICATION_PLAN.md`](VERIFICATION_PLAN.md) + الملف ده.
2. **الفرع:** اشتغل على `dev` (مفيش merge لـ `main` غير بأمر صريح "ادمج").
3. **خط الأساس (baseline) قبل أي شغل** — لازم يعدّوا نضاف:
   ```bash
   cd mobile && flutter analyze            # متوقّع: No issues
   cd mobile && flutter test --exclude-tags golden   # متوقّع: كلها تنجح
   ```
   + RLS/engine smoke عبر Supabase MCP (نمط `do $$ ... raise exception 'OK' $$`).
4. **MCP:** `project_id = quzqenavfoqsjupbtiix`. بعد أي DDL شغّل `get_advisors` (الـ baseline: 1 INFO + RPCs + leaked-pw المؤجّل — متفيش جديد).

## 1) الاتفاقيات الملزمة (تلخيص — التفاصيل في الخطة الأصلية)

- **شاشة رفيعة** تركّب widgets صغيرة const؛ مفيش build عملاق؛ قوائم `ListView.builder` + `ValueKey`.
- **طبقية**: Supabase في الـ repository بس → controller (`@riverpod`) → screen؛ منطق نقي في `domain/`.
- **بوابة سيرفر-سايد**: trigger/function `security definer, set search_path=''` + `revoke all ... from public, anon, authenticated`؛ كل كرون **idempotent** + يسجّل في `audit_log` بـ `system` actor.
- **i18n**: كل نص UI من `AppL10n` (مفيش hardcode عربي في `presentation/`).
- **تحقق لكل مهمة**: `dart format` → `flutter analyze` (صفر) → `flutter test` → DB smoke (rollback) → `get_advisors` → commit + push لـ `dev`. مراجعة ذاتية قبل اللي بعدها.
- بعد أي `@riverpod` جديد: `dart run build_runner build` (`.g.dart` متجاهلة في git؛ CI بيولّدها).

---

## 2) الشغل المتبقّي (مرتّب بالأولوية)

### 🔴 P1 — M4: الكرونات الناقصة (٤ وظائف) — أكبر فجوة فعلية

**الموجود فعلاً (متحقّق من `cron.job`):** `escalate-overdue-complaints` (كل ساعة) + `notify-overdue-subscriptions` (يومي ٦ص).
**النمط المرجعي:** [`supabase/migrations/20260618240002_cron_escalate_overdue_complaints.sql`](../supabase/migrations/20260618240002_cron_escalate_overdue_complaints.sql) و[`..240003_cron_overdue_subscriptions.sql`](../supabase/migrations/20260618240003_cron_overdue_subscriptions.sql) — كل وظيفة = SQL function `security definer, search_path=''` + `select cron.schedule('name', '<cron>', $$ select fn() $$)`.

**نمط التحقق لكل كرون (DB smoke):**
```sql
do $$ begin
  -- seed throwaway data, call the function, assert effect
  perform <the_function>();
  if <expected_condition> then raise exception 'CRON OK'; else raise exception 'CRON FAIL'; end if;
end $$;   -- الـ exception بيعمل rollback تلقائي
```

| # | الكرون | إيه/الأفضل | جدولة مقترحة | تحقق |
|---|---|---|---|---|
| **4.1** | **`monthly-close`** (قفل الشهر) | function تولّد مسوّدات `monthly_student_evaluation` (`draft`/`auto_finalized`) لكل enrollment نشط من (تسميع + حضور + سلوك الشهر الماضي)؛ تولّد تقرير الحلقة + بطاقات تقدّم (إشعار/manifest)؛ تدوّر دورة الاشتراك للشهر الجديد؛ تصعّد الـ `missed` (المعلّم ما سلّمش). **idempotent** على `(student, month)`. | `0 2 1 * *` (أول كل شهر ٢ص) | seed طالب + تسميعات شهر → run → اتأكد اتعملت مسوّدة evaluation واحدة بس (re-run مايكرّرش). |
| **4.2** | **`purge-public-registrations`** (TTL) | تحذف `public_registration` المنتهية/المرفوضة بعد TTL (مثلاً ٩٠ يوم) + `competition_application` المعلّقة المرتبطة؛ manifest عدد المحذوف في `audit_log` (system). | `0 3 * * *` (يومي) | seed صف قديم (created_at > TTL) + صف جديد → run → القديم اتحذف، الجديد فضل. |
| **4.3** | **`media-retention`** (أول+آخر) | عند `enrollment` منتهي/متخرّج → احتفظ بأول وآخر `media` (video) لكل طالب، علّم الباقي `retained=false` (manifest + نافذة استرجاع، مش حذف فوري)؛ **استبعد** وسائط مرتبطة بمسابقة/شكوى مفتوحة. بـ `system` actor. **ملاحظة:** مربوط بـ M3.2 (الوسائط لسه مش بتترفع) — اكتب المنطق دلوقتي، أثره يظهر مع أول رفع. | `0 4 * * 0` (أسبوعي) | seed طالب dropped + ٣ فيديوهات → run → الأوسط بس `retained=false`. |
| **4.4** | **`nominate-certificate-candidates`** | function تستخدم `is_certificate_eligible` (موجودة) لترشيح المؤهّلين (zero-debt + كل المقاطع `passed`) → إشعار/طابور للمشرف (مش إصدار تلقائي — المشرف يعتمد الامتحان النهائي). | `0 5 * * 1` (أسبوعي إثنين) | seed طالب مؤهّل + طالب عليه دين → run → الأول بس اترشّح. |

> **مهم:** كل function تتكتب في migration جديدة مؤرّخة، و`cron.schedule` بيعمل upsert بالاسم (إعادة التطبيق آمنة). بعد التطبيق: `select jobname, schedule, active from cron.job;` لازم تبقى **٦ وظائف**.

---

### 🟡 P2 — M1.9: تقرير الحلقة الشهري PDF (سريع)

- **الموجود:** [`attendance_sheet_pdf.dart`](../mobile/lib/features/documents/domain/attendance_sheet_pdf.dart) + [`progress_card_pdf.dart`](../mobile/lib/features/documents/domain/progress_card_pdf.dart) + `certificate_pdf.dart`.
- **الناقص:** `monthly_circle_report_pdf.dart`.
- **الأفضل:** دالة نقية `buildMonthlyCircleReportPdf({required data, required ByteData cairoFont, ...}) → Uint8List` بنفس نمط الموجود (Cairo + `pw.Directionality.rtl` + أرقام عربية). البيانات: متوسّط الحضور، نسبة النجاح للحلقة، المتفوّق، ملخّص تقدّم المقاطع للشهر.
- **ملفات:** `mobile/lib/features/documents/domain/monthly_circle_report_pdf.dart` + شاشة `*_preview`/إضافة لـ `print_report_screen` + repo method للبيانات.
- **تحقق:** unit test (`bytes` غير فاضية + تبدأ بـ `%PDF`) — زي `certificate_test.dart`؛ معاينة فعلية على الجهاز.

---

### 🟡 P3 — M3.2: upload-media (نشر + علامة مائية + ضغط + المعرض)

- **الحالة:** [`supabase/functions/upload-media/index.ts`](../supabase/functions/upload-media/index.ts) **مكتوبة بس مش منشورة**، والعلامة المائية/الضغط لسه `TODO` (سطور 6/53/73). (`invite-user` و`submit-public-application` منشورين ACTIVE — متحقّق.)
- **التحدّي التقني (محتاج قرار):** `ffmpeg` مش متاح مباشرة في Deno Edge runtime. البدائل:
  1. **علامة مائية على الصور فقط** (في الـ Edge، مكتبة صور خفيفة) + تأجيل ضغط الفيديو.
  2. **خدمة معالجة خارجية** (worker/Cloud Run بـ ffmpeg) يندهها الـ Edge.
  3. **معالجة على الجهاز** قبل الرفع (watermark/ضغط في Flutter) ثم رفع جاهز.
- **بعد ما يتحسم القرار:**
  - نفّذ العلامة المائية/الضغط، خلّي `watermarked: true`.
  - `supabase functions deploy upload-media`.
  - **معرض الوسائط (موبايل):** signed URLs من Edge + `log_media_access` + `cached_network_image` + `RepaintBoundary` + thumbnails (مفيش autoplay). جزء الموافقة موجود ([`child_consent_section.dart`](../mobile/lib/features/parent_portal/presentation/widgets/child_consent_section.dart)) — المعرض الكامل + مشغّل الفيديو يتراجعوا.
- **تحقق:** e2e رفع → معاينة؛ **وسائط البنت محجوبة بدون `consent_record` نشط** (RLS موجود — أكّد بـ smoke).

---

## 3) مؤجّل بقرار/خارجي (مش كود — قرارك أو ترقية)

| البند | اللي محتاجه | ملاحظة |
|---|---|---|
| **M2.2** حماية الباسوردات المسرّبة | ترقية Supabase **Pro** + toggle في Auth | advisor WARN متوقّع على Free — مش bug. |
| **M6 D4** التقمّص الكامل (JWT-`act`) | مراجعة أمنية + إصدار JWT قصير بـ claim `act` | النسخة الحالية **قراءة-فقط مدقّقة** (الخطة طلبت "read-biased") — شغّالة وآمنة. |
| **M9** الإطلاق | keystore + AAB + رفع Play | دليل كامل: [`RELEASE_ANDROID.md`](RELEASE_ANDROID.md). جرّب `--release` على جهاز (R8 شال حاجة؟). |
| **Vercel** | قفل **Deployment Protection** للمشروعين + (لو لزم) redeploy `invite-user` | اللوحة + الويب اتنشروا production؛ الـ 401 = الحماية الافتراضية. |
| **نشر prod / أول مستخدم حقيقي** | **تأكيدك الصريح** | قيد أمان قائم. |

---

## 4) التحقق النهائي end-to-end (بعد P1–P3)

بعد إقفال P1–P3، شغّل مسار الأدوار الكامل (من الخطة الأصلية، قسم Global Verification):
أدمن → معلّم (حصة كاملة + قطع نت) → مشرف (اعتماد + شهادة) → ولي أمر (كارت + وسائط بموافقة + شكوى) → عام (كورس + مسابقة) → سوبر أدمن (لوحة + audit). + أكّد الكرونات الـ ٦ شغّالة، و`get_advisors` نضيف، وعزل RLS بالاختبارات السلبية.

**"خلصت" =** الكرونات الـ ٦ كلها live، تقرير الحلقة الشهري بيتطبع، الوسائط بترفع بعلامة مائية ومحكومة بالموافقة، و`flutter analyze`/الاختبارات/CI كلها خضرا.
