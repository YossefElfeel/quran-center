import { Pager, SearchForm } from "@/components/list-controls";
import { getSuperAdmin } from "@/lib/auth";
import { createSupabaseServerClient } from "@/lib/supabase/server";

import { InviteForm } from "./invite-form";
import { UserActions } from "./user-actions";

const ROLE_LABEL: Record<string, string> = {
  super_admin: "سوبر أدمن",
  admin: "أدمن",
  supervisor: "مشرف",
  teacher: "معلّم",
  parent: "ولي أمر",
};

type Status = "active" | "blocked" | "deactivated";

type PersonRow = {
  id: string;
  full_name: string;
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

export default async function UsersPage({
  searchParams,
}: {
  searchParams: Promise<{ q?: string; page?: string }>;
}) {
  const { q, page: pageRaw } = await searchParams;
  const page = Math.max(1, Number(pageRaw) || 1);
  const from = (page - 1) * PAGE_SIZE;

  const supabase = await createSupabaseServerClient();
  const admin = await getSuperAdmin();
  let query = supabase
    .from("person")
    .select(
      "id, full_name, lifecycle_status, blocked_reason, deactivated_reason, role_assignment!inner(role)",
      { count: "exact" },
    )
    .order("full_name")
    .range(from, from + PAGE_SIZE - 1);
  if (q) query = query.ilike("full_name", `%${q}%`);
  const { data, count } = await query;
  const rows = (data ?? []) as unknown as PersonRow[];
  const totalPages = Math.ceil((count ?? 0) / PAGE_SIZE);

  return (
    <div className="flex flex-col gap-8">
      <section className="flex flex-col gap-3">
        <h1 className="text-2xl font-bold">المستخدمون والأدوار</h1>
        <p className="text-sm text-foreground/60">
          تحكّم كامل: منح/سحب الأدوار، الحظر/فك الحظر، الإيقاف والحذف. كل عملية
          بتتسجّل في سجل التدقيق. ({count ?? 0} مستخدم)
        </p>
        <SearchForm q={q} placeholder="ابحث بالاسم…" />
        <div className="overflow-x-auto rounded-xl border border-border bg-white">
          <table className="w-full min-w-[640px] text-right text-sm">
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
                      <td className="px-4 py-2">{r.full_name}</td>
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
                                {ROLE_LABEL[role] ?? role}
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
                      <td className="px-4 py-2">
                        <UserActions
                          personId={r.id}
                          fullName={r.full_name}
                          status={r.lifecycle_status}
                          roles={roles}
                          isSelf={r.id === admin?.personId}
                        />
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
        <Pager page={page} totalPages={totalPages} params={q ? { q } : {}} />
      </section>

      <section className="flex flex-col gap-3">
        <h2 className="text-xl font-bold">دعوة مستخدم جديد</h2>
        <p className="text-sm text-foreground/60">
          بيتعمل Person + دور + رابط دعوة (المستخدم بيحطّ باسورده باللينك).
        </p>
        <InviteForm />
      </section>
    </div>
  );
}
