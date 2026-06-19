import { createSupabaseServerClient } from "@/lib/supabase/server";

import { InviteForm } from "./invite-form";

const ROLE_LABEL: Record<string, string> = {
  super_admin: "سوبر أدمن",
  admin: "أدمن",
  supervisor: "مشرف",
  teacher: "معلّم",
  parent: "ولي أمر",
};

type RoleRow = {
  role: string;
  person: { id: string; full_name: string } | null;
};

export default async function UsersPage() {
  const supabase = await createSupabaseServerClient();
  const { data } = await supabase
    .from("role_assignment")
    .select("role, person:person_id(id, full_name)");

  // تجميع الأدوار حسب الشخص (الشخص ممكن يكون له أكتر من دور).
  // ملاحظة: PostgREST بيرجّع person كـ object (علاقة to-one)، بس type inference
  // بيستنتجها array — فبنعدّي عبر unknown.
  const byPerson = new Map<string, { name: string; roles: string[] }>();
  for (const row of (data ?? []) as unknown as RoleRow[]) {
    const person = row.person;
    if (!person) continue;
    const entry = byPerson.get(person.id) ?? {
      name: person.full_name,
      roles: [],
    };
    entry.roles.push(row.role);
    byPerson.set(person.id, entry);
  }
  const rows = [...byPerson.values()].sort((a, b) =>
    a.name.localeCompare(b.name, "ar"),
  );

  return (
    <div className="flex flex-col gap-8">
      <section className="flex flex-col gap-3">
        <h1 className="text-2xl font-bold">المستخدمون والأدوار</h1>
        <div className="overflow-hidden rounded-xl border border-border bg-white">
          <table className="w-full text-right text-sm">
            <thead className="border-b border-border bg-background/50 text-foreground/60">
              <tr>
                <th className="px-4 py-2 font-medium">الاسم</th>
                <th className="px-4 py-2 font-medium">الأدوار</th>
              </tr>
            </thead>
            <tbody>
              {rows.length === 0 ? (
                <tr>
                  <td
                    colSpan={2}
                    className="px-4 py-6 text-center text-foreground/50"
                  >
                    مفيش مستخدمين بأدوار لسه.
                  </td>
                </tr>
              ) : (
                rows.map((r) => (
                  <tr key={r.name} className="border-b border-border/60">
                    <td className="px-4 py-2">{r.name}</td>
                    <td className="px-4 py-2">
                      <div className="flex flex-wrap gap-1">
                        {r.roles.map((role) => (
                          <span
                            key={role}
                            className="rounded-full bg-primary/10 px-2 py-0.5 text-xs text-primary"
                          >
                            {ROLE_LABEL[role] ?? role}
                          </span>
                        ))}
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
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
