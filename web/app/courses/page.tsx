import { CourseCard, type Course } from "@/components/course-card";
import { supabaseAnon } from "@/lib/supabase-server";

export const dynamic = "force-dynamic";

export default async function CoursesPage() {
  const supabase = supabaseAnon();
  const { data } = await supabase
    .from("course")
    .select("id, title, description, video_url")
    .eq("is_free", true)
    .order("created_at", { ascending: false });
  const courses = (data ?? []) as Course[];

  return (
    <main className="mx-auto w-full max-w-3xl px-6 py-12">
      <h1 className="mb-6 text-3xl font-bold text-[var(--brand)]">
        الكورسات المجانية
      </h1>
      {courses.length === 0 ? (
        <p className="text-gray-500">لسه مفيش كورسات متاحة — تابعنا قريب.</p>
      ) : (
        <div className="flex flex-col gap-5">
          {courses.map((c) => (
            <CourseCard key={c.id} course={c} />
          ))}
        </div>
      )}
    </main>
  );
}
