import Link from "next/link";

// A person's name that opens their profile; falls back to plain text when the id is unknown.
export function PersonLink({ person, fallback = "—", className = "text-primary hover:underline" }: { person: { id?: string | null; full_name: string } | null | undefined; fallback?: string; className?: string }) {
  if (!person) return <>{fallback}</>;
  if (!person.id) return <>{person.full_name}</>;
  return <Link href={`/users/${person.id}`} className={className}>{person.full_name}</Link>;
}
