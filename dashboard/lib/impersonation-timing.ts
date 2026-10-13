// Shared impersonation timing (no server-only imports, so proxy.ts can use it too).
export const IMPERSONATION_TIMEBOX_MS = 30 * 60 * 1000; // ٣٠ دقيقة
// Treat a session as over a few seconds early, so the client countdown reaching zero and the
// server deciding "still active" can never disagree (no stuck banner / refresh loop).
export const IMPERSONATION_GRACE_MS = 5000;

export function impersonationOver(startedAt: string | number, now = Date.now()): boolean {
  return now - new Date(startedAt).getTime() >= IMPERSONATION_TIMEBOX_MS - IMPERSONATION_GRACE_MS;
}

export function impersonationTokenExpired(exp: unknown, now = Date.now()): boolean {
  return typeof exp !== "number" || exp * 1000 - IMPERSONATION_GRACE_MS <= now;
}

export type ImpersonationClaims = { sub?: string; exp?: number; act?: { sub?: string; sid?: string } };

export function readImpersonationClaims(token: string): ImpersonationClaims | null {
  try {
    const claims: unknown = JSON.parse(Buffer.from(token.split(".")[1] ?? "", "base64url").toString());
    return claims && typeof claims === "object" ? (claims as ImpersonationClaims) : null;
  } catch {
    return null;
  }
}
