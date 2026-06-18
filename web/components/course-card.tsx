import { youtubeId } from "@/lib/youtube";

export interface Course {
  id: string;
  title: string;
  description: string | null;
  video_url: string | null;
}

export function CourseCard({ course }: { course: Course }) {
  const vid = youtubeId(course.video_url);
  return (
    <article className="rounded-2xl border border-gray-200 bg-white p-5 shadow-sm">
      <h2 className="text-xl font-semibold">{course.title}</h2>
      {course.description ? (
        <p className="mt-2 text-gray-600">{course.description}</p>
      ) : null}
      {vid ? (
        <div className="mt-4 aspect-video overflow-hidden rounded-xl">
          <iframe
            className="h-full w-full"
            src={`https://www.youtube-nocookie.com/embed/${vid}`}
            title={course.title}
            allow="accelerometer; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
            allowFullScreen
          />
        </div>
      ) : course.video_url ? (
        <a
          href={course.video_url}
          target="_blank"
          rel="noopener noreferrer"
          className="mt-4 inline-block font-semibold text-[var(--brand)]"
        >
          ▶ اتفرّج على الفيديو
        </a>
      ) : null}
    </article>
  );
}
