import Link from "next/link";

import { createSupabaseServerClient } from "@/lib/supabase/server";

import { deleteCurriculum } from "./actions";
import { CurriculumForm, DeleteButton } from "./forms";

const TYPE_LABEL: Record<string, string> = {
  quran: "قرآن",
  arabic_foundation: "تأسيس عربي",
};

type Row = { id: string; name: string; type: string };

export default async function AcademicsPage() {
  const supabase = await createSupabaseServerClient();
  const { data } = await supabase
    .from("curriculum")
    .select("id, name, type")
    .order("created_at");
  const rows = (data ?? []) as Row[];

  return (
    <div className="flex flex-col gap-6">
      <div>
        <h1 className="text-2xl font-bold">المناهج والحلقات</h1>
        <p className="text-sm text-foreground/60">
          منهج ← مستويات ← حلقات. اضغط على منهج علشان تدير مستوياته.
        </p>
      </div>

      <CurriculumForm />

      <div className="overflow-hidden rounded-xl border border-border bg-white">
        <table className="w-full text-right text-sm">
          <thead className="border-b border-border bg-background/50 text-foreground/60">
            <tr>
              <th className="px-4 py-2 font-medium">المنهج</th>
              <th className="px-4 py-2 font-medium">النوع</th>
              <th className="px-4 py-2 font-medium">إجراءات</th>
            </tr>
          </thead>
          <tbody>
            {rows.length === 0 ? (
              <tr>
                <td colSpan={3} className="px-4 py-6 text-center text-foreground/50">
                  مفيش مناهج لسه.
                </td>
              </tr>
            ) : (
              rows.map((c) => (
                <tr key={c.id} className="border-b border-border/60">
                  <td className="px-4 py-2">
                    <Link
                      href={`/academics/${c.id}`}
                      className="font-medium text-primary hover:underline"
                    >
                      {c.name}
                    </Link>
                  </td>
                  <td className="px-4 py-2">{TYPE_LABEL[c.type] ?? c.type}</td>
                  <td className="px-4 py-2">
                    <DeleteButton
                      action={deleteCurriculum}
                      hidden={{ id: c.id }}
                      label="حذف"
                      confirmMessage={`حذف منهج «${c.name}» وكل مستوياته؟`}
                    />
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
