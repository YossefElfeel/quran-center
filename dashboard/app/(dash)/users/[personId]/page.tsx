import Link from "next/link";
import { notFound } from "next/navigation";
import { createSupabaseServerClient } from "@/lib/supabase/server";
import { formatDateTime } from "@/lib/format";
export default async function PersonPage({params}:{params:Promise<{personId:string}>}){
  const {personId}=await params;
  if(!/^[0-9a-f-]{36}$/i.test(personId))notFound();
  const client=await createSupabaseServerClient();
  const [{data:person,error},{data:enrollments,error:enrollmentError},{data:members,error:memberError},{data:roles,error:roleError}]=await Promise.all([
    client.from('person').select('id,full_name,phone,lifecycle_status').eq('id',personId).maybeSingle(),
    client.from('enrollment').select('id,status,enrolled_at,circle:circle_id(id,name)').eq('student_person_id',personId).order('enrolled_at',{ascending:false}).limit(50),
    client.from('household_member').select('role,household:household_id(id,name)').eq('person_id',personId),
    client.from('role_assignment').select('role').eq('person_id',personId),
  ]);
  if(error||enrollmentError||memberError||roleError)throw new Error('person_load_failed');
  if(!person)notFound();
  return <div className="max-w-3xl space-y-6"><Link href="/users" className="text-primary underline">→ المستخدمون</Link><h1 className="text-2xl font-bold">{person.full_name}</h1>{person.phone&&<a dir="ltr" href={`tel:${person.phone}`} className="block underline">{person.phone}</a>}<p>الحالة: {person.lifecycle_status==='active'?'نشط':person.lifecycle_status==='blocked'?'محظور':'موقوف'}</p><p>الأدوار: {(roles??[]).map(role=>role.role).join('، ')||'طالب / شخص بدون دور دخول'}</p>
    <section className="space-y-3"><h2 className="text-xl font-semibold">التسجيلات</h2>{!enrollments?.length&&<p>مفيش تسجيلات — استخدم تسجيل الطلاب لإضافة الطالب لحلقة.</p>}{(enrollments??[]).map(row=>{const circle=row.circle as unknown as {id:string;name:string}|null;return <p key={row.id}>{circle&&<Link href={`/circles/${circle.id}`} className="text-primary underline">{circle.name}</Link>} — {formatDateTime(row.enrolled_at)}</p>})}</section>
    <section className="space-y-3"><h2 className="text-xl font-semibold">الأسرة</h2>{!members?.length&&<p>الشخص مش مرتبط بأسرة — افتح الاشتراكات لإضافة عضوية.</p>}{(members??[]).map((row,index)=>{const household=row.household as unknown as {id:string;name:string}|null;return household&&<Link key={index} href={`/subscriptions/${household.id}`} className="block text-primary underline">{household.name}</Link>})}</section>
  </div>;
}
