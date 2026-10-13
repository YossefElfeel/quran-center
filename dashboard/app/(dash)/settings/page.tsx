import { OperatorScopeNote } from "@/components/operator-scope-note";
import { createSupabaseServerClient } from "@/lib/supabase/server";
import { SettingsForm } from "./forms";
export default async function SettingsPage() {
  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase.from("system_settings").select("key, value");
  if (error) throw new Error("settings_load_failed");
  return <div className="max-w-xl space-y-6"><h1 className="text-2xl font-bold">إعدادات النظام</h1><OperatorScopeNote /><SettingsForm values={Object.fromEntries((data ?? []).map((row) => [row.key, row.value]))} /></div>;
}
