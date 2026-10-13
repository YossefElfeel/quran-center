import { OperatorScopeNote } from "@/components/operator-scope-note";
import { RowActions } from "@/components/ui/row-actions";
import { Button } from "@/components/ui/button";
import { FieldSelect } from "@/components/ui/fields";
import Link from "next/link";
import { formatPhone, pluralAr, shortRef } from "@/lib/format";
import { ROLE_LABEL, roleLabel } from "@/lib/action-labels";
import { Pager, SearchForm } from "@/components/list-controls";
import { getSuperAdmin } from "@/lib/auth";
import { createSupabaseServerClient } from "@/lib/supabase/server";

import { InviteForm } from "./invite-form";
import { UserActions } from "./user-actions";

type Status = "active" | "blocked" | "deactivated";

type PersonRow = {
  id: string;
  full_name: string;
  phone: string | null;
  lifecycle_status: Status;
  blocked_reason: string | null;
  deactivated_reason: string | null;
  role_assignment: { role: string }[] | null;
};

const STATUS_BADGE: Record<Status, { label: string; cls: string }> = {
  active: { label: "نشط", cls: "bg-green-100 text-green-700" },
  blocked: { label: "محظور", cls: "bg-amber-100 text-amber-700" },
  deactivated: { label: "موقوف", cls: "bg-gray-200 text-gray-600" },
};

const PAGE_SIZE = 25;
const USER_COUNT = { zero: "مفيش مستخدمين", one: "مستخدم واحد", two: "مستخدمين اتنين", few: "{n} مستخدمين", many: "{n} مستخدم" };

// سطر صغير تحت الاسم يفرّق بين الأسماء المتكررة: الموبايل لو موجود، وإلا "#XXXX".
function PersonTagLine({ id, phone }: { id: string; phone: string | null }) {
  const formatted = formatPhone(phone);
  return (
    <span className="block text-xs text-foreground/50">
      {formatted ? <bdi dir="ltr">{formatted}</bdi> : <bdi dir="ltr" title="معرّف مختصر">{shortRef(id)}</bdi>}
    </span>
  );
}

export default async function UsersPage({
  searchParams,
}: {
  searchParams: Promise<{ q?: string; page?: string; role?: string }>;
}) {
  const { q, page: pageRaw, role: roleRaw } = await searchParams;
  // Only known roles reach the query; anything else means "everyone".
  const role = roleRaw === "student" || (roleRaw && Object.hasOwn(ROLE_LABEL, roleRaw)) ? roleRaw : undefined;
  const page = Math.max(1, Number(pageRaw) || 1);
  const from = (page - 1) * PAGE_SIZE;

  const supabase = await createSupabaseServerClient();
  const admin = await getSuperAdmin();
  let query = supabase
    .from("person")
    .select(
      role === "student" ? "id, full_name, phone, lifecycle_status, blocked_reason, deactivated_reason, role_assignment(role),enrollment!inner(id,status)" : role ? "id, full_name, phone, lifecycle_status, blocked_reason, deactivated_reason, role_assignment!inner(role)" : "id, full_name, phone, lifecycle_status, blocked_reason, deactivated_reason, role_assignment(role)",
      { count: "exact" },
    )
    .order("full_name")
    .range(from, from + PAGE_SIZE - 1);
  if(role === "student") query=query.eq("enrollment.status","active");
  else if(role) query=query.eq("role_assignment.role",role);
  // رقم (أو جزء منه) → بحث بالموبايل؛ غير كده بالاسم.
  const phoneQuery = q && /^[+\d\s٠-٩-]{3,}$/.test(q.trim()) ? formatPhone(q.trim()) : null;
  if (phoneQuery) query = query.ilike("phone", `%${phoneQuery.replace(/^(\+|00)20/, "")}%`);
  else if (q) query = query.ilike("full_name", `%${q}%`);
  const { data, count, error: loadError1 } = await query;
  if (loadError1) throw new Error('data_load_failed');
  const rows = (data ?? []) as unknown as PersonRow[];
  const totalPages = Math.ceil((count ?? 0) / PAGE_SIZE);

  return (
    <div className="flex flex-col gap-8">
      <section className="flex flex-col gap-3">
        <h1 className="text-2xl font-bold">المستخدمون والأدوار</h1><OperatorScopeNote />
        <p className="text-sm text-foreground/60">
          تحكّم كامل: منح/سحب الأدوار، الحظر/فك الحظر، الإيقاف والحذف. كل عملية
          بتتسجّل في سجل التدقيق. ({pluralAr(count, USER_COUNT)})
        </p>
        <SearchForm q={q} placeholder="ابحث بالاسم أو الموبايل…" hidden={role ? { role } : undefined} /><form className="flex flex-wrap items-end gap-3"><input type="hidden" name="q" value={q??""}/><label className="flex items-center gap-3">الدور<FieldSelect name="role" defaultValue={role??""} className="w-auto"><option value="">كل الناس</option><option value="student">الطلاب</option>{Object.entries(ROLE_LABEL).map(([key,label])=><option key={key} value={key}>{label}</option>)}</FieldSelect></label><Button type="submit" variant="secondary">تصفية</Button></form>
        <div className="overflow-x-auto rounded-xl border border-border bg-white">
          <table className="w-full min-w-[640px] text-start text-sm">
            <thead className="border-b border-border bg-background/50 text-foreground/60">
              <tr>
                <th className="px-4 py-2 font-medium">الاسم</th>
                <th className="px-4 py-2 font-medium">الأدوار</th>
                <th className="px-4 py-2 font-medium">الحالة</th>
                <th className="px-4 py-2 font-medium">إجراءات</th>
              </tr>
            </thead>
            <tbody>
              {rows.length === 0 ? (
                <tr>
                  <td colSpan={4} className="px-4 py-6 text-center text-foreground/50">
                    مفيش نتائج.
                  </td>
                </tr>
              ) : (
                rows.map((r) => {
                  const badge = STATUS_BADGE[r.lifecycle_status];
                  const reason =
                    r.lifecycle_status === "blocked"
                      ? r.blocked_reason
                      : r.lifecycle_status === "deactivated"
                        ? r.deactivated_reason
                        : null;
                  const roles = (r.role_assignment ?? []).map((x) => x.role);
                  return (
                    <tr key={r.id} className="border-b border-border/60">
                      <td className="px-4 py-2"><Link href={`/users/${r.id}`} className="text-primary underline">{r.full_name}</Link><PersonTagLine id={r.id} phone={r.phone} /></td>
                      <td className="px-4 py-2">
                        <div className="flex flex-wrap gap-1">
                          {roles.length === 0 ? (
                            <span className="text-xs text-foreground/40">—</span>
                          ) : (
                            roles.map((role) => (
                              <span
                                key={role}
                                className="rounded-full bg-primary/10 px-2 py-0.5 text-xs text-primary"
                              >
                                {roleLabel(role)}
                              </span>
                            ))
                          )}
                        </div>
                      </td>
                      <td className="px-4 py-2">
                        <span
                          title={reason ?? undefined}
                          className={`rounded-full px-2 py-0.5 text-xs ${badge.cls}`}
                        >
                          {badge.label}
                        </span>
                      </td>
                      <td className="px-4 py-2"><RowActions>
                        <UserActions
                          personId={r.id}
                          fullName={r.full_name}
                          tag={formatPhone(r.phone) ?? shortRef(r.id)}
                          status={r.lifecycle_status}
                          roles={roles}
                          isSelf={r.id === admin?.personId}
                        />
                      </RowActions></td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
        <Pager page={page} totalPages={totalPages} params={{ ...(q ? { q } : {}), ...(role ? { role } : {}) }} />
      </section>

      <section className="flex flex-col gap-3">
        <h2 className="text-xl font-bold">دعوة مستخدم جديد</h2>
        <p className="text-sm text-foreground/60">
          بيتعمل حساب + دور + رابط دعوة (المستخدم بيحط كلمة السر من اللينك).
        </p>
        <InviteForm />
      </section>
    </div>
  );
}
