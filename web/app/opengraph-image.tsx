import { ImageResponse } from "next/og";

// PNG share card (social platforms ignore SVG). Text-free on purpose: next/og (Satori) does not
// shape Arabic reliably, so the card carries the center's mark and colours only; the Arabic title
// and description come from the page's og:title / og:description.
export const alt = "شعار دار تحفيظ القرآن";
export const size = { width: 1200, height: 630 };
export const contentType = "image/png";

export default function OpengraphImage() {
  return new ImageResponse(
    (
      <div style={{ width: "100%", height: "100%", display: "flex", alignItems: "center", justifyContent: "center", background: "linear-gradient(135deg, #0c7c59 0%, #075c42 100%)" }}>
        <div style={{ display: "flex", alignItems: "center", justifyContent: "center", width: 360, height: 360, borderRadius: 80, background: "#f8faf9", boxShadow: "0 24px 60px rgba(0,0,0,0.25)" }}>
          <svg width="260" height="260" viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg">
            <rect width="64" height="64" rx="14" fill="#0c7c59" />
            <g fill="none" stroke="#fff" strokeWidth="3" strokeLinejoin="round">
              <path d="M32 17c-8-4-15-4-23-1v29c8-3 15-3 23 1 8-4 15-4 23-1V16c-8-3-15-3-23 1Z" />
              <path d="M32 17v29M16 25h9m-9 7h9m14-7h9m-9 7h9" />
            </g>
          </svg>
        </div>
      </div>
    ),
    size,
  );
}
