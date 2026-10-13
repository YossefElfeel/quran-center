import { RowActions } from "@/components/ui/row-actions";
import Link from "next/link";

import { getDataClient } from "@/lib/supabase/data-client";

import { deleteCompetition, deleteCourse } from "./actions";
import {
  CompetitionForm,
  CompetitionStatus,
  CourseForm,
  DeleteButton,
} from "./forms";

const COMP_STATUS_LABEL: Record<string, string> = {
  draft: "مسودّة",
  open: "مفتوحة",
  judging: "تحكيم",
  closed: "مقفولة",
};

type Course = { id: string; title: string; is_free: boolean;description:string|null;video_url:string };
type Competition = {
  id: string;
  name: string;
  year: number | null;
  status: string;
};

export default async function ContentPage() {
  const supabase = await getDataClient();
  const [coursesRes, competitionsRes] = await Promise.all([
    supabase
      .from("course")
      .select("id, title, is_free, description, video_url")
      .order("created_at", { ascending: false }),
    supabase
      .from("competition")
      .select("id, name, year, status")
      .order("created_at", { ascending: false }),
  ]);

  if (coursesRes.error || competitionsRes.error) throw new Error("content_load_failed");
  const courses = (coursesRes.data ?? []) as Course[];
  const competitions = (competitionsRes.data ?? []) as Competition[];

  return (
    <div className="flex flex-col gap-8">
      <section className="flex flex-col gap-3">
        <h1 className="text-2xl font-bold">الكورسات</h1>
        <CourseForm />
        <div className="overflow-x-auto rounded-xl border border-border bg-white">
          <table className="w-full text-start text-sm">
            <thead className="border-b border-border bg-background/50 text-foreground/60">
              <tr>
                <th className="px-4 py-2 font-medium">العنوان</th>
                <th className="px-4 py-2 font-medium">مجاني</th>
                <th className="px-4 py-2 font-medium">إجراء</th>
              </tr>
            </thead>
            <tbody>
              {courses.length === 0 ? (
                <tr>
                  <td colSpan={3} className="px-4 py-6 text-center text-foreground/50">
                    مفيش كورسات لسه.
                  </td>
                </tr>
              ) : (
                courses.map((c) => (
                  <tr key={c.id} className="border-b border-border/60">
                    <td className="px-4 py-2"><details><summary className="cursor-pointer font-medium text-primary">{c.title} — تعديل</summary><CourseForm course={c}/></details></td>
                    <td className="px-4 py-2">{c.is_free ? "نعم" : "لا"}</td>
                    <td className="px-4 py-2"><RowActions>
                      <DeleteButton
                        action={deleteCourse}
                        hidden={{ id: c.id }}
                        label="حذف"
                        confirmMessage={`حذف كورس «${c.title}»؟`}
                      />
                    </RowActions></td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </section>

      <section className="flex flex-col gap-3">
        <h2 className="text-xl font-bold">المسابقات</h2>
        <CompetitionForm />
        <div className="flex flex-col gap-2">
          {competitions.length === 0 ? (
            <p className="rounded-xl border border-border bg-white p-6 text-center text-foreground/50">
              مفيش مسابقات لسه.
            </p>
          ) : (
            competitions.map((c) => (
              <div
                key={c.id}
                className="flex flex-wrap items-center justify-between gap-3 rounded-xl border border-border bg-white px-4 py-3"
              >
                <div className="flex flex-col gap-0.5">
                  <Link
                    href={`/content/${c.id}`}
                    className="font-medium text-primary hover:underline"
                  >
                    {c.name}
                  </Link>
                  <span className="text-xs text-foreground/50">
                    {c.year ?? "—"} · {COMP_STATUS_LABEL[c.status] ?? c.status}
                  </span>
                </div>
                <div className="flex flex-wrap items-center gap-2">
                  <CompetitionStatus id={c.id} current={c.status} />
                  <DeleteButton
                    action={deleteCompetition}
                    hidden={{ id: c.id }}
                    label="حذف"
                    confirmMessage={`حذف مسابقة «${c.name}» وكل طلباتها؟`}
                  />
                </div>
              </div>
            ))
          )}
        </div>
      </section>
    </div>
  );
}
