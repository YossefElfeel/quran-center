"use client";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { BookOpen, Users, Settings, MessageSquare, CalendarCheck, LayoutDashboard, ClipboardList, Circle, Award, Bell, Image, Wallet, Flag, Activity, Database, Shield, UserRoundCog, ScrollText, BarChart3 } from "lucide-react";
const groups = [
  {name:'التشغيل اليومي',items:[['/','نظرة عامة',LayoutDashboard],['/intake','قائمة الانتظار',ClipboardList],['/enrollment','تسجيل الطلاب',CalendarCheck],['/circles','الحلقات والمتابعة',Circle],['/excuses','أعذار الغياب',CalendarCheck],['/evaluations','التقييمات والاعتمادات',ClipboardList],['/complaints','الشكاوى',MessageSquare]]},
  {name:'الإعداد الأكاديمي',items:[['/academics','المناهج والمستويات',BookOpen],['/certificates','الشهادات',Award],['/content','الكورسات والمسابقات',BookOpen]]},
  {name:'الناس والمالية',items:[['/users','المستخدمون والأدوار',Users],['/subscriptions','الاشتراكات',Wallet],['/analytics','التحليلات',BarChart3]]},
  {name:'التواصل',items:[['/notifications','الإشعارات والبث',Bell],['/media','الوسائط والموافقات',Image]]},
  {name:'النظام',items:[['/settings','إعدادات النظام',Settings],['/flags','المفاتيح والصيانة',Flag],['/automation','الأتمتة والمجدولات',Activity],['/data','التحكّم بالبيانات',Database],['/impersonation','تقمّص الدور',UserRoundCog],['/audit','سجل التدقيق',ScrollText],['/pdpl','الخصوصية',Shield]]},
] as const;
export function Sidebar({collapsed=false,onNavigate}: {collapsed?: boolean;onNavigate?:()=>void}) {
  const pathname=usePathname();
  return <nav aria-label="التنقّل الرئيسي" className="space-y-5 p-3">{groups.map(group=><section key={group.name}><h2 className={collapsed?'sr-only':'mb-2 px-3 text-sm font-semibold text-foreground/70'}>{group.name}</h2><div className="space-y-1">{group.items.map(([href,label,Icon])=>{const active=href==='/'?pathname==='/':pathname.startsWith(href);return <Link key={href} href={href} onClick={onNavigate} aria-current={active?'page':undefined} aria-label={label} title={collapsed?label:undefined} className={`flex min-h-11 items-center gap-3 rounded-lg px-3 py-2 text-sm ${active?'bg-primary font-bold text-white':'hover:bg-border/50'}`}><Icon size={20} aria-hidden="true" />{!collapsed&&<span>{label}</span>}</Link>})}</div></section>)}</nav>;
}
