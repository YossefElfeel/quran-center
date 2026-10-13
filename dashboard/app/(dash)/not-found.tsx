import Link from "next/link";
export default function NotFound() { return <div className="space-y-4"><h1 className="text-2xl font-bold">العنصر مش موجود</h1><p>الرابط قديم أو العنصر اتحذف.</p><Link href="/" className="text-primary underline">الرجوع للرئيسية</Link></div>; }
