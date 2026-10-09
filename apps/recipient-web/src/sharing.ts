export const TOKEN_PATTERN = /^[A-Za-z0-9_-]{43}$/;
export function captureLink(location: Pick<Location, 'pathname' | 'hash'>): {kind: 's' | 'e'; token: string} | null {
  const kind = location.pathname.replace(/\/$/, '');
  const token = location.hash.slice(1);
  if ((kind === '/s' || kind === '/e') && TOKEN_PATTERN.test(token)) return {kind: kind.slice(1) as 's' | 'e', token};
  return null;
}
export async function hashToken(token: string): Promise<string> {
  if (!TOKEN_PATTERN.test(token)) throw new Error('Invalid link');
  const result = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(token));
  return Array.from(new Uint8Array(result), byte => byte.toString(16).padStart(2, '0')).join('');
}
export function isExpired(value: unknown, now = Date.now()): boolean {
  return typeof value !== 'string' || !Number.isFinite(Date.parse(value)) || Date.parse(value) <= now;
}
export type Medicine = {name: string; dosage: string | null; frequency: string | null; duration: string | null;
  taking_status: 'unknown' | 'taking' | 'stopped'; prescription_date: string | null; reviewed_at: string};
export type Summary = {display_name: string; allergies: string[]; medicines: Medicine[]; notes: string; updated_at: string; expires_at: string};
export type ContactCard = {display_name: string; contacts: {name: string; relationship: string; phone: string}[]; updated_at: string};
