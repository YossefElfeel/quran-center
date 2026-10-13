"use client";
import { Button } from "@/components/ui/button";
export default function ErrorPage({ reset }: { reset: () => void }) { return <div role="alert" className="space-y-4"><h1 className="text-2xl font-bold">تعذّر تحميل البيانات</h1><p>راجع اتصالك وصلاحيات الحساب، وبعدها جرّب تاني.</p><Button onClick={reset}>إعادة المحاولة</Button></div>; }
