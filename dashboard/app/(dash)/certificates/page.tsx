import { PersonLink } from "@/components/person-link";
import { RowActions } from "@/components/ui/row-actions";
import Link from "next/link";
import { formatDate } from "@/lib/format";
import { getDataClient } from "@/lib/supabase/data-client";

import { revokeCertificate } from "./actions";
import { DeleteButton, IssueForm, type Student } from "./forms";

const KIND_LABEL: Record<string, string> = {
  juz_amma: "جزء عمّ",
  half: "النصف",
  full: "كامل",
  honor: "تكريم",
};

type EnrRow = { student: { id: string; full_name: string } | null };
type Eligible = { id: string; full_name: string };
type Cert = {
  id: string;
  kind: string;
  issued_at: string;
  student: { id: string; full_name: string } | null;
};

export default async function CertificatesPage({searchParams}:{searchParams:Promise<{student?:string}>}) {
  const {student}=await searchParams;
  const supabase = await getDataClient();

  const { data: enrData, error: loadError1 } = await supabase
    .from("enrollment")
    .select("student:student_person_id(id, full_name)")
    .eq("status", "active");
  if (loadError1) throw new Error('data_load_failed');
  const seen = new Set<string>();
  const students: Student[] = [];
  for (const e of (enrData ?? []) as unknown as EnrRow[]) {
    if (e.student && !seen.has(e.student.id)) {
      seen.add(e.student.id);
      students.push({ id: e.student.id, name: e.student.full_name });
    }
  }
  students.sort((a, b) => a.name.localeCompare(b.name, "ar"));

  const { data: eligibleData, error: loadError2 } = await supabase.rpc(
    "eligible_certificate_students",
  );
  if (loadError2) throw new Error('data_load_failed');
  const eligible = (eligibleData ?? []) as Eligible[];

  const { data: certData, error: loadError3 } = await supabase
    .from("certificate")
    .select("id, kind, issued_at, student:student_person_id(id, full_name)")
    .order("issued_at", { ascending: false })
    .limit(50);
  if (loadError3) throw new Error('data_load_failed');
  const certs = (certData ?? []) as unknown as Cert[];

  return (
    <div className="flex flex-col gap-6">
      <div>
        <h1 className="text-2xl font-bold">الشهادات</h1>
        <p className="text-sm text-foreground/60">
          أصدر شهادة إتمام للمؤهّلين، أو تكريم لأي طالب، أو اسحب شهادة.
        </p>
      </div>

      <IssueForm key={student??"new"} students={students} selectedStudent={student} />

      {eligible.length > 0 ? (
        <p className="rounded-xl border border-border bg-primary/5 px-4 py-3 text-sm">
          <span className="font-bold text-primary">مؤهّلون للإتمام:</span>{" "}
          {eligible.map((e) => <Link key={e.id} href={`/certificates?student=${e.id}`} className="mx-2 underline">{e.full_name} · إصدار شهادة</Link>)}
        </p>
      ) : null}

      <div className="flex flex-col gap-3">
        <h2 className="text-lg font-bold">الشهادات المُصدَرة</h2>
        <div className="overflow-x-auto rounded-xl border border-border bg-white">
          <table className="w-full text-start text-sm">
            <thead className="border-b border-border bg-background/50 text-foreground/60">
              <tr>
                <th className="px-4 py-2 font-medium">الطالب</th>
                <th className="px-4 py-2 font-medium">النوع</th>
                <th className="px-4 py-2 font-medium">التاريخ</th>
                <th className="px-4 py-2 font-medium">إجراء</th>
              </tr>
            </thead>
            <tbody>
              {certs.length === 0 ? (
                <tr>
                  <td colSpan={4} className="px-4 py-6 text-center text-foreground/50">
                    مفيش شهادات لسه.
                  </td>
                </tr>
              ) : (
                certs.map((c) => (
                  <tr key={c.id} className="border-b border-border/60">
                    <td className="px-4 py-2"><PersonLink person={c.student} /></td>
                    <td className="px-4 py-2">{KIND_LABEL[c.kind] ?? c.kind}</td>
                    <td className="px-4 py-2 text-foreground/50">
                      {formatDate(c.issued_at)}
                    </td>
                    <td className="px-4 py-2"><RowActions>
                      <Link href={`/certificates/${c.id}`} className="me-4 text-primary underline">عرض PDF</Link>
                      <DeleteButton
                        action={revokeCertificate}
                        hidden={{ id: c.id }}
                        label="سحب"
                        confirmMessage="سحب الشهادة دي؟"
                      />
                    </RowActions></td>
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
