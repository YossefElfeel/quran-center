import { formatDateTime } from "@/lib/format";
import { createSupabaseServerClient } from "@/lib/supabase/server";

import { deleteMedia } from "./actions";
import { DeleteButton, RetainToggle } from "./forms";

const TYPE_LABEL: Record<string, string> = { photo: "صورة", video: "فيديو" };

type MediaRow = {
  id: string;
  type: string;
  retained: boolean;
  created_at: string;
  student: { full_name: string } | null;
};
type ConsentRow = {
  id: string;
  scope: string;
  revoked_at: string | null;
  granted_at: string;
  student: { full_name: string } | null;
};

export default async function MediaPage() {
  const supabase = await createSupabaseServerClient();
  const [mediaRes, consentRes] = await Promise.all([
    supabase
      .from("media")
      .select("id, type, retained, created_at, student:student_person_id(full_name)")
      .order("created_at", { ascending: false })
      .limit(100),
    supabase
      .from("consent_record")
      .select("id, scope, revoked_at, granted_at, student:student_person_id(full_name)")
      .order("granted_at", { ascending: false })
      .limit(50),
  ]);
  const media = (mediaRes.data ?? []) as unknown as MediaRow[];
  const consents = (consentRes.data ?? []) as unknown as ConsentRow[];

  return (
    <div className="flex flex-col gap-8">
      <div>
        <h1 className="text-2xl font-bold">الوسائط والموافقات</h1>
        <p className="text-sm text-foreground/60">
          راجع الوسائط، احذفها (ناعم/نهائي)، واطّلع على موافقات أولياء الأمور.
        </p>
      </div>

      <section className="flex flex-col gap-3">
        <h2 className="text-lg font-bold">الوسائط</h2>
        <div className="overflow-x-auto rounded-xl border border-border bg-white">
          <table className="w-full min-w-[640px] text-right text-sm">
            <thead className="border-b border-border bg-background/50 text-foreground/60">
              <tr>
                <th className="px-4 py-2 font-medium">الطالب</th>
                <th className="px-4 py-2 font-medium">النوع</th>
                <th className="px-4 py-2 font-medium">الحالة</th>
                <th className="px-4 py-2 font-medium">الوقت</th>
                <th className="px-4 py-2 font-medium">إجراءات</th>
              </tr>
            </thead>
            <tbody>
              {media.length === 0 ? (
                <tr>
                  <td colSpan={5} className="px-4 py-6 text-center text-foreground/50">
                    مفيش وسائط.
                  </td>
                </tr>
              ) : (
                media.map((m) => (
                  <tr key={m.id} className="border-b border-border/60">
                    <td className="px-4 py-2">{m.student?.full_name ?? "—"}</td>
                    <td className="px-4 py-2">{TYPE_LABEL[m.type] ?? m.type}</td>
                    <td className="px-4 py-2">
                      {m.retained ? (
                        <span className="text-foreground/60">محفوظ</span>
                      ) : (
                        <span className="text-red-600">محذوف ناعم</span>
                      )}
                    </td>
                    <td className="px-4 py-2 text-foreground/50">
                      {formatDateTime(m.created_at)}
                    </td>
                    <td className="px-4 py-2">
                      <div className="flex flex-wrap items-center gap-2">
                        <RetainToggle id={m.id} retained={m.retained} />
                        <DeleteButton
                          action={deleteMedia}
                          hidden={{ id: m.id }}
                          label="حذف نهائي"
                          confirmMessage="حذف الوسيط نهائيًا؟"
                        />
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
        <h2 className="text-lg font-bold">الموافقات</h2>
        <div className="overflow-x-auto rounded-xl border border-border bg-white">
          <table className="w-full text-right text-sm">
            <thead className="border-b border-border bg-background/50 text-foreground/60">
              <tr>
                <th className="px-4 py-2 font-medium">الطالب</th>
                <th className="px-4 py-2 font-medium">النطاق</th>
                <th className="px-4 py-2 font-medium">الحالة</th>
              </tr>
            </thead>
            <tbody>
              {consents.length === 0 ? (
                <tr>
                  <td colSpan={3} className="px-4 py-6 text-center text-foreground/50">
                    مفيش موافقات.
                  </td>
                </tr>
              ) : (
                consents.map((c) => (
                  <tr key={c.id} className="border-b border-border/60">
                    <td className="px-4 py-2">{c.student?.full_name ?? "—"}</td>
                    <td className="px-4 py-2">
                      {TYPE_LABEL[c.scope] ?? c.scope}
                    </td>
                    <td className="px-4 py-2">
                      {c.revoked_at ? (
                        <span className="text-red-600">مسحوبة</span>
                      ) : (
                        <span className="text-primary">نشطة</span>
                      )}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </section>
    </div>
  );
}
