import { formatDateTime } from "@/lib/format";
import { createSupabaseServerClient } from "@/lib/supabase/server";

import { retractNotification } from "./actions";
import { BroadcastForm, DeleteButton } from "./forms";

type Row = {
  id: string;
  type: string;
  title: string;
  created_at: string;
  recipient: { full_name: string } | null;
};

export default async function NotificationsPage() {
  const supabase = await createSupabaseServerClient();
  const { data } = await supabase
    .from("notification")
    .select("id, type, title, created_at, recipient:recipient_person_id(full_name)")
    .order("created_at", { ascending: false })
    .limit(50);
  const rows = (data ?? []) as unknown as Row[];

  return (
    <div className="flex flex-col gap-6">
      <div>
        <h1 className="text-2xl font-bold">الإشعارات والبثّ</h1>
        <p className="text-sm text-foreground/60">
          ابعت إشعار لجمهور، أو اسحب إشعار مُرسَل.
        </p>
      </div>

      <BroadcastForm />

      <div className="flex flex-col gap-3">
        <h2 className="text-lg font-bold">آخر الإشعارات</h2>
        <div className="overflow-x-auto rounded-xl border border-border bg-white">
          <table className="w-full text-right text-sm">
            <thead className="border-b border-border bg-background/50 text-foreground/60">
              <tr>
                <th className="px-4 py-2 font-medium">العنوان</th>
                <th className="px-4 py-2 font-medium">المستلِم</th>
                <th className="px-4 py-2 font-medium">الوقت</th>
                <th className="px-4 py-2 font-medium">إجراء</th>
              </tr>
            </thead>
            <tbody>
              {rows.length === 0 ? (
                <tr>
                  <td colSpan={4} className="px-4 py-6 text-center text-foreground/50">
                    مفيش إشعارات.
                  </td>
                </tr>
              ) : (
                rows.map((n) => (
                  <tr key={n.id} className="border-b border-border/60">
                    <td className="px-4 py-2">{n.title}</td>
                    <td className="px-4 py-2 text-foreground/60">
                      {n.recipient?.full_name ?? "—"}
                    </td>
                    <td className="px-4 py-2 text-foreground/50">
                      {formatDateTime(n.created_at)}
                    </td>
                    <td className="px-4 py-2">
                      <DeleteButton
                        action={retractNotification}
                        hidden={{ id: n.id }}
                        label="سحب"
                        confirmMessage="سحب الإشعار ده؟"
                      />
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
