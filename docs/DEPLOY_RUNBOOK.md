# دليل التشغيل والنشر (Deploy Runbook)

> خطوات **عمليّة** للبنود الخارجية/الحسّاسة اللي الكود فيها جاهز بس محتاجة إجراء منك
> (تدوير مفاتيح، نشر، توجلات لوحة، مراجعة أمنية). مرتّبة بالأولوية. آخر تحديث: 2026-06-19.
>
> اتعمل في الـ session ده: P1 (٦ كرونات) + P2 (تقرير الحلقة) + P3 (وسائط على الجهاز —
> كود) + حسابات تجربة لكل دور + كود M6 D4 (تقمّص). الباقي تحت ⏬.

---

## 0) حسابات التجربة (جاهزة — على DB التطوير)

اتعملت ٥ حسابات، واحد لكل دور، كلها **مؤكّدة** وبنفس الباسورد المشترك، مع سيناريو مربوط
(حلقة "حلقة تجريبية" بيدرّسها `teacher@`، طالب مسجّل، `parent@` وليّه، أسرة مدفوعة الشهر).

> **الباسورد المشترك اتبلّغ في المحادثة — مش متخزّن في الريبو** (تفادي تسريب أسرار).

| الدور | الإيميل |
|---|---|
| super_admin | `superadmin@qurancenter.app` |
| admin | `admin@qurancenter.app` |
| supervisor | `supervisor@qurancenter.app` |
| teacher | `teacher@qurancenter.app` |
| parent | `parent@qurancenter.app` |

> دي بيانات تطوير على مشروع `quzqenavfoqsjupbtiix`. **قبل أول مستخدم حقيقي/برود:** غيّر
> الباسوردات أو امسح الحسابات دي، وفعّل حماية الباسوردات المسرّبة (البند ٤).

---

## 1) نشر وسائط M3.2 (upload-media + media-signed-url)

الكود جاهز ومتصمّم على معالجة الجهاز (علامة مائية/ضغط للصور في Flutter). الـ Edge بتخزّن
+ تطبّق الموافقة عبر RLS. **محظور النشر لحد ما يتدوّر مفتاح الـ service-role المكشوف.**

```bash
# (أ) دوّر مفتاح service-role المكشوف:
#     Supabase Dashboard → Project Settings → API → "service_role" → Rotate.
#     (الـ Edge functions بتاخد المفتاح الجديد تلقائيًا من البيئة عند إعادة النشر.)

# (ب) انشر الاتنين (من جذر الريبو، الـ CLI متربط بالمشروع):
supabase functions deploy upload-media
supabase functions deploy media-signed-url

# (ج) أكّد إنهم ACTIVE:
supabase functions list
```

**تحقق e2e (بعد النشر):**
1. ادخل بحساب `teacher@` (أو `admin@`) من الموبايل → كارت الطفل "طالب تجريبي" → زر إضافة صورة
   → اختار صورة → المفروض ترفع (علامة مائية + مضغوطة) وتظهر في المعرض.
2. **بوابة الموافقة:** اعمل طالبة (بنت) + صورة لها بدون موافقة → لازم **تتحجب** عن ولي أمرها؛
   فعّل الموافقة من قسم موافقة الوسائط → تظهر. (الـ RLS اتأكّد منها بـ `rls_isolation.sql` =
   "RLS OK".)
3. أكّد تسجيل الوصول في `audit_log` (action = `media_access`).

> **متبقّي اختياري:** رفع/ضغط الفيديو على الجهاز (محتاج ffmpeg/native) · علامة مائية عربية
> محروقة (خط الحزمة لاتيني) · `cached_network_image` · مشغّل فيديو داخلي.

---

## 2) M6 D4 — التقمّص الكامل المدقّق (full impersonation)

الحالي: **معاينة قراءة-فقط مدقّقة** في اللوحة (بتسجّل `impersonation_session`، مفيش تبديل
هوية فعلي). الكود الجديد بيضيف التبديل الفعلي عبر JWT بـ claim `act` للمساءلة.

**⚠️ بند أمني — لازم مراجعة قبل التفعيل في برود.** التقمّص الخاطئ = تصعيد صلاحيات.

### المتطلّبات
1. تدوير مفتاح service-role (نفس البند ١-أ).
2. **سرّ JWT للتوقيع:** الدالة بتوقّع HS256 بـ `SUPABASE_JWT_SECRET`.
   - تأكّد إن المشروع لسه بيستخدم **السرّ المشترك (legacy HS256)**: Dashboard → Settings →
     API → "JWT Settings". لو متحوّل لـ **مفاتيح غير متماثلة (asymmetric signing keys)**،
     النمط ده **مش هيتقبل** — لازم توقّع بالمفتاح الخاص النشط (راجع توثيق Supabase) وتعدّل
     `signHs256` في [`impersonate/index.ts`](../supabase/functions/impersonate/index.ts).
   - اضبط السرّ: `supabase secrets set SUPABASE_JWT_SECRET=<من Settings → API → JWT Secret>`

### النشر
```bash
supabase functions deploy impersonate
```

### ربط اللوحة (dashboard) — كود للمراجعة
الدالة بترجّع `access_token` للموضوع. اللوحة لازم تستخدمه **لقراءة/كتابة البيانات** بينما
**إدارة التقمّص + فحص السوبر أدمن يفضلوا على الجلسة الحقيقية** (`getSuperAdmin` بيستخدم
`auth.getUser()` على الكوكي — لو خلّيته ياخد توكن التقمّص هيرجّع الموضوع ويكسر البوابة).

```ts
// dashboard/lib/supabase/impersonated.ts  (جديد)
import { createServerClient } from "@supabase/ssr";
import { cookies } from "next/headers";

// عميل "يتصرّف كـ الموضوع" لو فيه توكن تقمّص صالح؛ غير كده العميل العادي (RLS الحقيقي).
export async function createImpersonatedClient() {
  const jar = await cookies();
  const impToken = jar.get("imp_token")?.value;
  if (!impToken) {
    const { createSupabaseServerClient } = await import("./server");
    return createSupabaseServerClient();
  }
  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: { getAll: () => jar.getAll(), setAll: () => {} },
      global: { headers: { Authorization: `Bearer ${impToken}` } },
      auth: { persistSession: false, autoRefreshToken: false },
    },
  );
}
```

```ts
// في startImpersonation (actions.ts): بدّل insert المباشر بنداء الدالة + خزّن الكوكي.
const { data } = await supabase.functions.invoke("impersonate", {
  body: { subject_person_id: subject, reason: reason || null },
});
const cookieStore = await cookies();
cookieStore.set("imp_token", data.access_token, {
  httpOnly: true, secure: true, sameSite: "lax", maxAge: 1800, path: "/",
});
// stopImpersonation: cookieStore.delete("imp_token") + إنهاء الصف (زي دلوقتي).
```

- **صفحات/مكوّنات البيانات** تستخدم `createImpersonatedClient()`؛ **`getSuperAdmin` وصفحة
  التقمّص** يفضلوا على `createSupabaseServerClient()`.
- حدّث نسخة صفحة التقمّص من "قراءة فقط" لـ "كامل مدقّق".

### قائمة مراجعة أمنية (قبل برود)
- [ ] منع تقمّص super_admin (الدالة بتعمله) + منع التقمّص المتداخل.
- [ ] TTL قصير (٣٠ دقيقة — موجود) + تنظيف الكوكي عند الإيقاف/الانتهاء.
- [ ] الكوكي `httpOnly + secure + sameSite` ومش بيتسرّب للعميل.
- [ ] تدقيق: `impersonation_session` + (اختياري) قراءة `act` من `request.jwt.claims` في
      تريجرات audit عشان كل كتابة تتنسب للموضوع **مع** السوبر أدمن الحقيقي.
- [ ] اختبار: التقمّص يفقد صلاحيات السوبر أدمن فعلًا (RLS تشوف الموضوع).

---

## 3) M2.2 — حماية الباسوردات المسرّبة
- ترقية Supabase **Pro** ثم: Dashboard → Authentication → Policies → فعّل
  "Leaked password protection" (HaveIBeenPwned).
- على Free: تحذير الـ advisor متوقّع ومش bug.

---

## 4) M9 — إصدار أندرويد
- **APK تجربة:** اتبنى في الـ session ده (راجع آخر سطر من تشغيل `flutter build apk --release`
  للمسار، عادةً `mobile/build/app/outputs/flutter-apk/app-release.apk`). للتثبيت المباشر.
- **للنشر على Play:** keystore + AAB + رفع — الدليل الكامل: [`RELEASE_ANDROID.md`](RELEASE_ANDROID.md).
  جرّب `flutter build appbundle --release` بعد ضبط `key.properties`.

---

## 5) Vercel — Deployment Protection
- Dashboard (Vercel) → كل مشروع (اللوحة + الويب) → Settings → Deployment Protection →
  فعّل Vercel Authentication (الـ 401 الحالي = الحماية الافتراضية شغّالة).
- لو لزم: أعد نشر `invite-user` بعد أي تغيير أسرار.

---

## 6) التحقق النهائي (بعد ما تنشر اللي فوق)
شغّل مسار الأدوار الكامل (REMAINING_WORK.md §4) بالحسابات الخمسة، وأكّد:
- الكرونات الـ ٦ شغّالة (`select jobname, schedule, active from cron.job;`).
- `get_advisors` نضيف (بس الـ INFO المقصودة لجداول النظام + تحذيرات Free المتوقّعة).
- `rls_isolation.sql` = "RLS OK" و`engine_flow.sql` = "ENGINE OK".
