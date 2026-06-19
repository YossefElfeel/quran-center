import { createSupabaseServerClient } from "@/lib/supabase/server";

import { updateSettings } from "./actions";
import { SETTINGS } from "./meta";

export default async function SettingsPage({
  searchParams,
}: {
  searchParams: Promise<{ saved?: string }>;
}) {
  const { saved } = await searchParams;

  const supabase = await createSupabaseServerClient();
  const { data } = await supabase.from("system_settings").select("key, value");
  const map = new Map(
    (data ?? []).map((r) => [r.key as string, r.value as number]),
  );

  return (
    <div className="flex max-w-xl flex-col gap-6">
      <div>
        <h1 className="text-2xl font-bold">إعدادات النظام</h1>
        <p className="mt-1 text-sm text-foreground/60">
          العتبات دي بيقراها التطبيق مباشرة (التسميع، التعثّر، الاشتراك، الحلقة).
        </p>
      </div>

      {saved ? (
        <p className="rounded-lg bg-primary/10 px-3 py-2 text-sm font-bold text-primary">
          اتحفظت الإعدادات ✅
        </p>
      ) : null}

      <form action={updateSettings} className="flex flex-col gap-4">
        {SETTINGS.map((s) => (
          <label key={s.key} className="flex flex-col gap-1 text-sm">
            {s.label}
            <input
              name={s.key}
              type="number"
              min={s.min}
              max={s.max}
              defaultValue={Number(map.get(s.key) ?? s.min)}
              required
              className="rounded-lg border border-border bg-white px-3 py-2 outline-none focus:border-primary"
            />
          </label>
        ))}
        <button
          type="submit"
          className="self-start rounded-lg bg-primary px-5 py-2 font-bold text-white transition-opacity hover:opacity-90"
        >
          حفظ
        </button>
      </form>
    </div>
  );
}
