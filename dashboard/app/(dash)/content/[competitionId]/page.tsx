import { PersonLink } from "@/components/person-link";
import Link from "next/link";
import { notFound } from "next/navigation";

import { formatDateTime, formatNumber } from "@/lib/format";
import { getDataClient } from "@/lib/supabase/data-client";

import { ApplicationDecision, CompetitionEditForm } from "../forms";

const STATUS_LABEL: Record<string, string> = {
  pending: "قيد المراجعة",
  accepted: "مقبول",
  rejected: "مرفوض",
};
const COMP_STATUS_LABEL: Record<string, string> = {
  draft: "مسودّة",
  open: "مفتوحة",
  judging: "تحكيم",
  closed: "مقفولة",
};

// datetime-local value in center time (Africa/Cairo); empty when no deadline.
function cairoLocalInput(iso: string | null): string {
  if (!iso) return "";
  const date = new Date(iso);
  if (Number.isNaN(date.getTime())) return "";
  const parts = Object.fromEntries(
    new Intl.DateTimeFormat("sv-SE", { timeZone: "Africa/Cairo", year: "numeric", month: "2-digit", day: "2-digit", hour: "2-digit", minute: "2-digit", hourCycle: "h23" })
      .formatToParts(date)
      .map((p) => [p.type, p.value]),
  );
  return `${parts.year}-${parts.month}-${parts.day}T${parts.hour}:${parts.minute}`;
}

type App = {
  id: string;
  origin: string;
  status: string;
  youtube_url: string | null;
  student: { id: string; full_name: string } | null;
  reg: { name: string; phone: string } | null;
};

export default async function CompetitionDetailPage({
  params,
}: {
  params: Promise<{ competitionId: string }>;
}) {
  const { competitionId } = await params;
  const supabase = await getDataClient();

  const { data: comp, error: compError } = await supabase
    .from("competition")
    .select("name, status, rules, deadline, prize")
    .eq("id", competitionId)
    .maybeSingle();

  if (compError) throw new Error("competition_load_failed");
  if (!comp) notFound();

  const { data: appData, error: appError } = await supabase
    .from("competition_application")
    .select(
      "id, origin, status, youtube_url, student:student_person_id(id, full_name), reg:public_registration_id(name, phone)",
    )
    .eq("competition_id", competitionId)
    .order("created_at", { ascending: true });
  if (appError) throw new Error("applicants_load_failed");
  const apps = (appData ?? []) as unknown as App[];

  const scoreAvg = new Map<string, { sum: number; n: number }>();
  if (apps.length) {
    const { data: scores, error: loadError1 } = await supabase
      .from("competition_score")
      .select("application_id, score")
      .in(
        "application_id",
        apps.map((a) => a.id),
      );
  if (loadError1) throw new Error('data_load_failed');
    for (const s of (scores ?? []) as {
      application_id: string;
      score: number;
    }[]) {
      const cur = scoreAvg.get(s.application_id) ?? { sum: 0, n: 0 };
      cur.sum += Number(s.score);
      cur.n += 1;
      scoreAvg.set(s.application_id, cur);
    }
  }
  const avgOf = (id: string) => {
    const a = scoreAvg.get(id);
    return a && a.n ? formatNumber(Math.round((a.sum / a.n) * 10) / 10) : "—";
  };
  const applicantName = (a: App) =>
    a.student?.full_name ?? a.reg?.name ?? "—";

  return (
    <div className="flex flex-col gap-6">
      <div className="flex flex-col gap-1">
        <Link href="/content" className="text-sm text-primary hover:underline">
          → المحتوى
        </Link>
        <h1 className="text-2xl font-bold">{(comp?.name as string) ?? "المسابقة"}</h1>
        <p className="text-sm text-foreground/50">
          الحالة: {COMP_STATUS_LABEL[comp?.status as string] ?? comp?.status}
          {" • "}آخر موعد: {formatDateTime(comp.deadline as string | null)}
        </p>
      </div>

      <section className="flex flex-col gap-2">
        <h2 className="text-lg font-bold">تعديل المسابقة</h2>
        <CompetitionEditForm
          competition={{
            id: competitionId,
            name: comp.name as string,
            rules: (comp.rules as string | null) ?? null,
            prize: (comp.prize as string | null) ?? null,
            deadlineLocal: cairoLocalInput(comp.deadline as string | null),
          }}
        />
      </section>

      <div className="overflow-x-auto rounded-xl border border-border bg-white">
        <table className="w-full min-w-[640px] text-start text-sm">
          <thead className="border-b border-border bg-background/50 text-foreground/60">
            <tr>
              <th className="px-4 py-2 font-medium">المتقدّم</th>
              <th className="px-4 py-2 font-medium">المصدر</th>
              <th className="px-4 py-2 font-medium">الحالة</th>
              <th className="px-4 py-2 font-medium">متوسّط الدرجات</th>
              <th className="px-4 py-2 font-medium">قرار</th>
            </tr>
          </thead>
          <tbody>
            {apps.length === 0 ? (
              <tr>
                <td colSpan={5} className="px-4 py-6 text-center text-foreground/50">
                  مفيش متقدّمين لسه.
                </td>
              </tr>
            ) : (
              apps.map((a) => (
                <tr key={a.id} className="border-b border-border/60">
                  <td className="px-4 py-2">
                    {a.youtube_url ? (
                      <a
                        href={a.youtube_url}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="text-primary hover:underline"
                      >
                        {applicantName(a)}
                      </a>
                    ) : a.student ? (
                      <PersonLink person={a.student} />
                    ) : (
                      applicantName(a)
                    )}
                    {a.youtube_url && a.student ? <> · <PersonLink person={a.student} fallback="" className="text-xs text-foreground/60 hover:underline" /></> : null}
                    {a.reg?.phone && <div className="mt-2 flex flex-wrap gap-3"><a href={`tel:${a.reg.phone}`} dir="ltr" className="text-primary underline">{a.reg.phone}</a><a href={`https://wa.me/${a.reg.phone.replace(/[^0-9]/g, '')}`} target="_blank" rel="noopener noreferrer" className="text-primary underline">واتساب</a></div>}
                  </td>
                  <td className="px-4 py-2 text-foreground/60">
                    {a.origin === "public" ? "عام" : "طالب"}
                  </td>
                  <td className="px-4 py-2">
                    {STATUS_LABEL[a.status] ?? a.status}
                  </td>
                  <td className="px-4 py-2">{avgOf(a.id)}</td>
                  <td className="px-4 py-2">
                    {a.status === "pending" ? (
                      <ApplicationDecision
                        id={a.id}
                        competitionId={competitionId}
                      />
                    ) : (
                      <span className="text-xs text-foreground/40">تمّ</span>
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
