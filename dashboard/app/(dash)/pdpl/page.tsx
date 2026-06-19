import { formatDateTime } from "@/lib/format";
import { createSupabaseServerClient } from "@/lib/supabase/server";

const SCOPE: Record<string, string> = {
  id: "الرقم القومي",
  photo: "صور",
  video: "فيديو",
};

type Consent = {
  id: string;
  scope: string;
  granted_at: string;
  revoked_at: string | null;
  student: { full_name: string } | null;
};

export default async function PdplPage() {
  const supabase = await createSupabaseServerClient();
  const { data } = await supabase
    .from("consent_record")
    .select("id, scope, granted_at, revoked_at, student:student_person_id(full_name)")
    .order("granted_at", { ascending: false })
    .limit(200);

  const rows = (data ?? []) as unknown as Consent[];

  return (
    <div className="flex flex-col gap-4">
      <div>
        <h1 className="text-2xl font-bold">الخصوصية (PDPL)</h1>
        <p className="mt-1 text-sm text-foreground/60">
          سجل الموافقات (وسائط/رقم قومي). الحذف وسحب الموافقة بيتمّوا من التطبيق
          (ولي الأمر) أو يدويًا بقرار موثّق.
        </p>
      </div>

      <div className="overflow-x-auto rounded-xl border border-border bg-white">
        <table className="w-full text-right text-sm">
          <thead className="border-b border-border bg-background/50 text-foreground/60">
            <tr>
              <th className="px-4 py-2 font-medium">الطالب</th>
              <th className="px-4 py-2 font-medium">النطاق</th>
              <th className="px-4 py-2 font-medium">تاريخ الموافقة</th>
              <th className="px-4 py-2 font-medium">الحالة</th>
            </tr>
          </thead>
          <tbody>
            {rows.length === 0 ? (
              <tr>
                <td
                  colSpan={4}
                  className="px-4 py-6 text-center text-foreground/50"
                >
                  مفيش موافقات مسجّلة.
                </td>
              </tr>
            ) : (
              rows.map((r) => (
                <tr key={r.id} className="border-b border-border/60">
                  <td className="px-4 py-2">{r.student?.full_name ?? "—"}</td>
                  <td className="px-4 py-2">{SCOPE[r.scope] ?? r.scope}</td>
                  <td className="px-4 py-2 text-foreground/60">
                    {formatDateTime(r.granted_at)}
                  </td>
                  <td className="px-4 py-2">
                    {r.revoked_at ? (
                      <span className="rounded-full bg-red-100 px-2 py-0.5 text-xs text-red-600">
                        مسحوبة
                      </span>
                    ) : (
                      <span className="rounded-full bg-primary/10 px-2 py-0.5 text-xs text-primary">
                        فعّالة
                      </span>
                    )}
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
