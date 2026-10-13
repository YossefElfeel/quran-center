import Link from "next/link";
import { notFound } from "next/navigation";
import { PersonLink } from "@/components/person-link";
import { createSupabaseServerClient } from "@/lib/supabase/server";
import { roleLabel } from "@/lib/action-labels";
import { formatDateTime, formatPhone, shortRef } from "@/lib/format";

const ENROLLMENT_STATUS: Record<string, string> = {
  active: "نشط",
  paused: "موقوف مؤقتًا",
  graduated: "متخرّج",
  dropped: "منسحب",
  transferred: "منقول",
};

// guardian_link.relation = صلة ولي الأمر بالطالب.
const RELATION: Record<string, string> = { father: "الأب", mother: "الأم", other: "ولي أمر" };
const relationLabel = (relation: string | null) => (relation ? (RELATION[relation] ?? relation) : null);

type LinkedPerson = { id: string; full_name: string; phone: string | null };
type Circle = { id: string; name: string };

export default async function PersonPage({params}:{params:Promise<{personId:string}>}){
  const {personId}=await params;
  if(!/^[0-9a-f-]{36}$/i.test(personId))notFound();
  const client=await createSupabaseServerClient();
  const [{data:person,error},{data:enrollments,error:enrollmentError},{data:members,error:memberError},{data:roles,error:roleError},{data:childLinks,error:childError},{data:guardianLinks,error:guardianError}]=await Promise.all([
    client.from('person').select('id,full_name,phone,lifecycle_status').eq('id',personId).maybeSingle(),
    client.from('enrollment').select('id,status,enrolled_at,circle:circle_id(id,name)').eq('student_person_id',personId).order('enrolled_at',{ascending:false}).limit(50),
    client.from('household_member').select('role,household:household_id(id,name)').eq('person_id',personId),
    client.from('role_assignment').select('role').eq('person_id',personId),
    client.from('guardian_link').select('relation,student:student_person_id(id,full_name,phone)').eq('guardian_person_id',personId),
    client.from('guardian_link').select('relation,guardian:guardian_person_id(id,full_name,phone)').eq('student_person_id',personId),
  ]);
  if(error||enrollmentError||memberError||roleError||childError||guardianError)throw new Error('person_load_failed');
  if(!person)notFound();

  const roleCodes=(roles??[]).map(row=>row.role as string);
  const householdRoles=(members??[]).map(row=>row.role as string);
  const children=((childLinks??[]) as unknown as {relation:string|null;student:LinkedPerson|null}[]).filter(row=>row.student);
  const guardians=((guardianLinks??[]) as unknown as {relation:string|null;guardian:LinkedPerson|null}[]).filter(row=>row.guardian);
  // الصفحة بتتكيّف مع نوع الشخص: ولي أمر (أبناء) و/أو طالب (تسجيلات).
  const isGuardian=roleCodes.includes('parent')||children.length>0||householdRoles.includes('guardian');
  const isStudent=(enrollments?.length??0)>0||guardians.length>0||householdRoles.includes('student')||(!isGuardian&&roleCodes.length===0);

  // الحلقة النشطة لكل ابن (نداء واحد للأبناء كلهم).
  const activeCircle=new Map<string,Circle>();
  if(children.length){
    const {data:childEnrollments,error:childEnrollmentError}=await client.from('enrollment').select('student_person_id,circle:circle_id(id,name)').in('student_person_id',children.map(row=>row.student!.id)).eq('status','active');
    if(childEnrollmentError)throw new Error('person_load_failed');
    for(const row of (childEnrollments??[]) as unknown as {student_person_id:string;circle:Circle|null}[])if(row.circle&&!activeCircle.has(row.student_person_id))activeCircle.set(row.student_person_id,row.circle);
  }

  const phone=formatPhone(person.phone);
  const roleChips=[...roleCodes.map(roleLabel),...(isStudent?['طالب']:[])];
  return <div className="max-w-3xl space-y-6"><Link href="/users" className="text-primary underline">→ المستخدمون</Link>
    <div className="space-y-1"><h1 className="text-2xl font-bold">{person.full_name} <bdi dir="ltr" className="text-sm font-normal text-foreground/50" title="معرّف مختصر">{shortRef(person.id)}</bdi></h1>
      <p>الموبايل: {phone?<a dir="ltr" href={`tel:${phone}`} className="underline">{phone}</a>:<span className="text-foreground/50">مش متسجّل</span>}</p>
      <p>الحالة: {person.lifecycle_status==='active'?'نشط':person.lifecycle_status==='blocked'?'محظور':'موقوف'}</p>
      <div className="flex flex-wrap items-center gap-1">الأدوار: {roleChips.length?roleChips.map(label=><span key={label} className="rounded-full bg-primary/10 px-2 py-0.5 text-xs text-primary">{label}</span>):<span className="text-foreground/50">بدون دور دخول</span>}</div>
    </div>
    {isGuardian&&<section className="space-y-3"><h2 className="text-xl font-semibold">الأبناء</h2>
      {!children.length&&<p>مفيش أبناء مربوطين بولي الأمر ده — الربط بيتعمل من «إضافة ولي أمر» في بطاقة الطالب في التطبيق.</p>}
      {children.length>0&&<ul className="space-y-2">{children.map(({student})=>{const circle=activeCircle.get(student!.id);return <li key={student!.id} className="rounded-lg border border-border bg-white px-3 py-2"><PersonLink person={student} showTag /><span className="block text-sm text-foreground/70">{circle?<>الحلقة: <Link href={`/circles/${circle.id}`} className="text-primary underline">{circle.name}</Link></>:'مش متسجّل في حلقة دلوقتي'}</span></li>})}</ul>}
    </section>}
    {isStudent&&<section className="space-y-3"><h2 className="text-xl font-semibold">التسجيلات</h2>{!enrollments?.length&&<p>مفيش تسجيلات — استخدم تسجيل الطلاب لإضافة الطالب لحلقة.</p>}{(enrollments??[]).map(row=>{const circle=row.circle as unknown as Circle|null;return <p key={row.id}>{circle&&<Link href={`/circles/${circle.id}`} className="text-primary underline">{circle.name}</Link>} — {ENROLLMENT_STATUS[row.status as string]??row.status} — {formatDateTime(row.enrolled_at)}</p>})}</section>}
    {isStudent&&guardians.length>0&&<section className="space-y-3"><h2 className="text-xl font-semibold">أولياء الأمر</h2><ul className="space-y-1">{guardians.map(({guardian,relation})=><li key={guardian!.id}><PersonLink person={guardian} showTag />{relation&&<span className="text-sm text-foreground/50"> · {relationLabel(relation)}</span>}</li>)}</ul></section>}
    <section className="space-y-3"><h2 className="text-xl font-semibold">الأسرة</h2>{!members?.length&&<p>الشخص مش مرتبط بأسرة — افتح الاشتراكات لإضافة عضوية.</p>}{(members??[]).map((row,index)=>{const household=row.household as unknown as {id:string;name:string}|null;return household&&<Link key={index} href={`/subscriptions/${household.id}`} className="block text-primary underline">{household.name}</Link>})}</section>
  </div>;
}
