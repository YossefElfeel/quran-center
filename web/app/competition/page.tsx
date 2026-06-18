import { ApplicationForm } from "@/components/application-form";
import { supabaseAnon } from "@/lib/supabase-server";

export const dynamic = "force-dynamic";

interface Competition {
  id: string;
  name: string;
  year: number | null;
}

export default async function CompetitionPage() {
  const supabase = supabaseAnon();
  const { data } = await supabase
    .from("competition")
    .select("id, name, year")
    .eq("status", "open")
    .order("year", { ascending: false })
    .limit(1)
    .maybeSingle();
  const comp = data as Competition | null;

  return (
    <main className="mx-auto w-full max-w-2xl px-6 py-12">
      <h1 className="mb-2 text-3xl font-bold text-[var(--brand)]">
        مسابقة دار التحفيظ
      </h1>
      {!comp ? (
        <p className="text-gray-500">
          مفيش مسابقة مفتوحة للتقديم دلوقتي — تابعنا قريب.
        </p>
      ) : (
        <>
          <p className="mb-6 text-gray-600">
            {comp.name}
            {comp.year ? ` — ${comp.year}` : ""}
          </p>
          <ApplicationForm competitionId={comp.id} />
        </>
      )}
    </main>
  );
}
