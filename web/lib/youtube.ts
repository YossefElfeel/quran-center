// بياخد رابط يوتيوب ويطلّع الـ video id (أو null لو مش يوتيوب).
export function youtubeId(url: string | null): string | null {
  if (!url) return null;
  const m = url.match(
    /(?:youtube\.com\/(?:watch\?v=|embed\/|shorts\/)|youtu\.be\/)([A-Za-z0-9_-]{11})/,
  );
  return m ? m[1] : null;
}
