const TOKEN_REGEX = /^[a-zA-Z0-9_-]{6,128}$/;

export function isValidTokenFormat(token: string): boolean {
  if (!token || typeof token !== 'string') return false;
  return TOKEN_REGEX.test(token.trim());
}

export async function hashToken(token: string): Promise<string> {
  const encoder = new TextEncoder();
  const data = encoder.encode(token.trim());
  const hashBuffer = await crypto.subtle.digest('SHA-256', data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map((b) => b.toString(16).padStart(2, '0')).join('');
}

export function maskToken(token: string): string {
  if (!token) return '[empty]';
  const clean = token.trim();
  if (clean.length <= 8) return '***';
  return `${clean.slice(0, 4)}...${clean.slice(-4)}`;
}

export function sanitizePlayStoreUrl(url?: string): string {
  const defaultUrl =
    'https://play.google.com/store/apps/details?id=com.example.listix';
  if (!url || typeof url !== 'string') return defaultUrl;
  const trimmed = url.trim();
  try {
    const parsed = new URL(trimmed);
    if (parsed.protocol === 'https:' && parsed.hostname.includes('play.google.com')) {
      return trimmed;
    }
  } catch {
    return defaultUrl;
  }
  return defaultUrl;
}

export function applySecurityHeaders(headers: Headers): Headers {
  headers.set('X-Content-Type-Options', 'nosniff');
  headers.set('X-Frame-Options', 'DENY');
  headers.set('Referrer-Policy', 'strict-origin-when-cross-origin');
  headers.set(
    'Content-Security-Policy',
    "default-src 'self'; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src https://fonts.gstatic.com; img-src 'self' data: https:; script-src 'self' 'unsafe-inline';",
  );
  return headers;
}
