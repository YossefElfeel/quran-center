import { formatDateTime } from "@/lib/format";
import { createSupabaseServerClient } from "@/lib/supabase/server";

import { respondToComplaint } from "./actions";

const CATEGORY: Record<string, string> = {
  academic: "أكاديمي",
  financial: "مالي",
  behavioral: "سلوكي",
  privacy: "خصوصية",
  other: "أخرى",
};
const STATUS: Record<string, string> = {
  open: "مفتوحة",
  answered: "اترد عليها",
  reopened: "اتفتحت تاني",
  closed: "مقفولة",
};

type Complaint = {
  id: string;
  category: string;
  body: string;
  status: string;
  manager_response: string | null;
  responded_at: string | null;
  created_at: string;
};

export default async function ComplaintsPage() {
  const supabase = await createSupabaseServerClient();
  const { data } = await supabase
    .from("complaint")
    .select("id, category, body, status, manager_response, responded_at, created_at")
    .order("status", { ascending: true })
    .order("created_at", { ascending: false })
    .limit(100);

  const rows = (data ?? []) as Complaint[];

  return (
    <div className="flex flex-col gap-4">
      <div>
        <h1 className="text-2xl font-bold">صندوق الشكاوى</h1>
        <p className="mt-1 text-sm text-foreground/60">
          الرد خلال ٤٨ ساعة (SLA). الكاتب مخفي — الشكوى للمدير بس.
        </p>
      </div>

      {rows.length === 0 ? (
        <p className="rounded-xl border border-border bg-white p-6 text-center text-foreground/50">
          مفيش شكاوى.
        </p>
      ) : (
        <div className="flex flex-col gap-3">
          {rows.map((c) => {
            const answered = c.status === "answered" || c.status === "closed";
            return (
              <div
                key={c.id}
                className="flex flex-col gap-3 rounded-xl border border-border bg-white p-4"
              >
                <div className="flex flex-wrap items-center gap-2 text-xs text-foreground/60">
                  <span className="rounded-full bg-accent/10 px-2 py-0.5 text-accent">
                    {CATEGORY[c.category] ?? c.category}
                  </span>
                  <span
                    className={`rounded-full px-2 py-0.5 ${
                      answered
                        ? "bg-primary/10 text-primary"
                        : "bg-red-100 text-red-600"
                    }`}
                  >
                    {STATUS[c.status] ?? c.status}
                  </span>
                  <span>{formatDateTime(c.created_at)}</span>
                </div>

                <p className="whitespace-pre-wrap text-sm">{c.body}</p>

                <form
                  action={respondToComplaint}
                  className="flex flex-col gap-2 border-t border-border pt-3"
                >
                  <input type="hidden" name="id" value={c.id} />
                  <textarea
                    name="response"
                    rows={2}
                    defaultValue={c.manager_response ?? ""}
                    placeholder="رد المدير…"
                    className="rounded-lg border border-border px-3 py-2 text-sm outline-none focus:border-primary"
                  />
                  <button
                    type="submit"
                    className="self-start rounded-lg bg-primary px-4 py-1.5 text-sm font-bold text-white hover:opacity-90"
                  >
                    {answered ? "تحديث الرد" : "رد"}
                  </button>
                </form>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
