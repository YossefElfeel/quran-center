import Link from "next/link";

import { createSupabaseServerClient } from "@/lib/supabase/server";

import { deleteLevel } from "../actions";
import { DeleteButton, LevelForm } from "../forms";

type Row = { id: string; name: string; ord: number };

export default async function LevelsPage({
  params,
}: {
  params: Promise<{ curriculumId: string }>;
}) {
  const { curriculumId } = await params;
  const supabase = await createSupabaseServerClient();
  const { data: curriculum } = await supabase
    .from("curriculum")
    .select("name")
    .eq("id", curriculumId)
    .maybeSingle();
  const { data } = await supabase
    .from("level")
    .select("id, name, ord")
    .eq("curriculum_id", curriculumId)
    .order("ord");
  const rows = (data ?? []) as Row[];

  return (
    <div className="flex flex-col gap-6">
      <div className="flex flex-col gap-1">
        <Link href="/academics" className="text-sm text-primary hover:underline">
          ← المناهج
        </Link>
        <h1 className="text-2xl font-bold">
          مستويات «{(curriculum?.name as string) ?? "المنهج"}»
        </h1>
        <p className="text-sm text-foreground/60">
          اضغط على مستوى علشان تدير حلقاته.
        </p>
      </div>

      <LevelForm curriculumId={curriculumId} />

      <div className="overflow-hidden rounded-xl border border-border bg-white">
        <table className="w-full text-right text-sm">
          <thead className="border-b border-border bg-background/50 text-foreground/60">
            <tr>
              <th className="px-4 py-2 font-medium">#</th>
              <th className="px-4 py-2 font-medium">المستوى</th>
              <th className="px-4 py-2 font-medium">إجراءات</th>
            </tr>
          </thead>
          <tbody>
            {rows.length === 0 ? (
              <tr>
                <td colSpan={3} className="px-4 py-6 text-center text-foreground/50">
                  مفيش مستويات لسه.
                </td>
              </tr>
            ) : (
              rows.map((l) => (
                <tr key={l.id} className="border-b border-border/60">
                  <td className="px-4 py-2 text-foreground/50">{l.ord}</td>
                  <td className="px-4 py-2">
                    <Link
                      href={`/academics/${curriculumId}/${l.id}`}
                      className="font-medium text-primary hover:underline"
                    >
                      {l.name}
                    </Link>
                  </td>
                  <td className="px-4 py-2">
                    <DeleteButton
                      action={deleteLevel}
                      hidden={{ id: l.id, curriculum_id: curriculumId }}
                      label="حذف"
                      confirmMessage={`حذف مستوى «${l.name}»؟`}
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
