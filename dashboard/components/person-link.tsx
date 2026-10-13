import Link from "next/link";

import { personTag } from "@/lib/format";

type LinkedPerson = { id?: string | null; full_name: string; phone?: string | null };

// A person's name that opens their profile; falls back to plain text when the id is unknown.
// showTag adds a small LTR-isolated disambiguator (phone, else "#XXXX") so repeated names can be told apart.
export function PersonLink({ person, fallback = "—", className = "text-primary hover:underline", showTag = false }: { person: LinkedPerson | null | undefined; fallback?: string; className?: string; showTag?: boolean }) {
  if (!person) return <>{fallback}</>;
  if (!person.id) return <>{person.full_name}</>;
  const link = <Link href={`/users/${person.id}`} className={className}>{person.full_name}</Link>;
  if (!showTag) return link;
  return <>{link} <bdi dir="ltr" className="text-xs text-foreground/50">{personTag({ id: person.id, phone: person.phone })}</bdi></>;
}
