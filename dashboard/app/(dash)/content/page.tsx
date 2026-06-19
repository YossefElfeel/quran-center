import { formatNumber } from "@/lib/format";
import { createSupabaseServerClient } from "@/lib/supabase/server";

type Course = {
  id: string;
  title: string;
  video_url: string;
  is_free: boolean;
};
type Competition = { id: string; name: string; year: number | null };

export default async function ContentPage() {
  const supabase = await createSupabaseServerClient();
  const [coursesRes, competitionsRes, appsRes] = await Promise.all([
    supabase
      .from("course")
      .select("id, title, video_url, is_free")
      .order("created_at", { ascending: false }),
    supabase
      .from("competition")
      .select("id, name, year")
      .order("created_at", { ascending: false }),
    supabase
      .from("competition_application")
      .select("*", { count: "exact", head: true }),
  ]);

  const courses = (coursesRes.data ?? []) as Course[];
  const competitions = (competitionsRes.data ?? []) as Competition[];
  const totalApps = appsRes.count ?? 0;

  return (
    <div className="flex flex-col gap-8">
      <section className="flex flex-col gap-3">
        <h1 className="text-2xl font-bold">الكورسات</h1>
        <div className="overflow-hidden rounded-xl border border-border bg-white">
          <table className="w-full text-right text-sm">
            <thead className="border-b border-border bg-background/50 text-foreground/60">
              <tr>
                <th className="px-4 py-2 font-medium">العنوان</th>
                <th className="px-4 py-2 font-medium">مجاني</th>
              </tr>
            </thead>
            <tbody>
              {courses.length === 0 ? (
                <tr>
                  <td
                    colSpan={2}
                    className="px-4 py-6 text-center text-foreground/50"
                  >
                    مفيش كورسات لسه.
                  </td>
                </tr>
              ) : (
                courses.map((c) => (
                  <tr key={c.id} className="border-b border-border/60">
                    <td className="px-4 py-2">{c.title}</td>
                    <td className="px-4 py-2">{c.is_free ? "نعم" : "لا"}</td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </section>

      <section className="flex flex-col gap-3">
        <div className="flex items-center justify-between">
          <h2 className="text-xl font-bold">المسابقات</h2>
          <span className="text-sm text-foreground/60">
            إجمالي المتقدّمين: {formatNumber(totalApps)}
          </span>
        </div>
        <div className="flex flex-col gap-2">
          {competitions.length === 0 ? (
            <p className="rounded-xl border border-border bg-white p-6 text-center text-foreground/50">
              مفيش مسابقات لسه.
            </p>
          ) : (
            competitions.map((c) => (
              <div
                key={c.id}
                className="flex items-center justify-between rounded-xl border border-border bg-white px-4 py-3"
              >
                <span className="font-medium">{c.name}</span>
                <span className="text-sm text-foreground/60">
                  {c.year ?? "—"}
                </span>
              </div>
            ))
          )}
        </div>
      </section>
    </div>
  );
}
