import type { MetadataRoute } from "next";
export default function sitemap(): MetadataRoute.Sitemap { const base=process.env.NEXT_PUBLIC_SITE_URL??'https://quran-web-sage.vercel.app';return ['/','/courses','/competition'].map(path=>({url:base+path,changeFrequency:'weekly',priority:path==='/'?1:.8})); }
