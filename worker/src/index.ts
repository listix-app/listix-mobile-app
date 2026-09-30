import type { Env, InviteValidationResult } from './types.ts';
import {
  isValidTokenFormat,
  maskToken,
  applySecurityHeaders,
  sanitizePlayStoreUrl,
} from './security.ts';
import { validateInviteToken } from './supabase.ts';
import { renderLandingPage } from './html.ts';

export default {
  async fetch(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
    const url = new URL(request.url);
    const path = url.pathname;

    if (request.method === 'OPTIONS') {
      const headers = applySecurityHeaders(new Headers());
      headers.set('Access-Control-Allow-Origin', '*');
      headers.set('Access-Control-Allow-Methods', 'GET, OPTIONS');
      headers.set('Access-Control-Allow-Headers', 'Content-Type, Accept');
      return new Response(null, { status: 204, headers });
    }

    if (request.method !== 'GET') {
      const headers = applySecurityHeaders(new Headers());
      return new Response('Method Not Allowed', { status: 405, headers });
    }

    if (path === '/' || path === '/health') {
      const headers = applySecurityHeaders(
        new Headers({ 'Content-Type': 'application/json; charset=utf-8' }),
      );
      return new Response(
        JSON.stringify({
          status: 'ok',
          service: 'listix-invite-worker',
          timestamp: new Date().toISOString(),
        }),
        { status: 200, headers },
      );
    }

    if (path === '/.well-known/assetlinks.json') {
      return handleAssetLinks(env);
    }

    if (path.startsWith('/join/')) {
      return handleJoin(request, url, env);
    }

    const headers = applySecurityHeaders(new Headers());
    return new Response('Not Found', { status: 404, headers });
  },
};

async function handleAssetLinks(env: Env): Promise<Response> {
  const packageName = env.ANDROID_PACKAGE_NAME || 'com.nmenag.listix';
  const rawFingerprint =
    env.ANDROID_SHA256_FINGERPRINT ||
    'FA:C6:17:45:DC:09:03:78:6F:B9:ED:E6:2A:96:2B:39:9F:73:48:F0:BB:6F:89:9B:83:32:66:75:91:03:3B:9C';

  const fingerprints = rawFingerprint
    .split(',')
    .map((s) => s.trim())
    .filter((s) => s.length > 0);

  const assetLinks = [
    {
      relation: ['delegate_permission/common.handle_all_urls'],
      target: {
        namespace: 'android_app',
        package_name: packageName,
        sha256_cert_fingerprints: fingerprints,
      },
    },
  ];

  const headers = applySecurityHeaders(
    new Headers({
      'Content-Type': 'application/json; charset=utf-8',
      'Cache-Control': 'public, max-age=3600',
    }),
  );

  return new Response(JSON.stringify(assetLinks, null, 2), {
    status: 200,
    headers,
  });
}

async function handleJoin(
  request: Request,
  url: URL,
  env: Env,
): Promise<Response> {
  const rawToken = url.pathname.replace(/^\/join\//, '').split('/')[0].trim();
  const acceptHeader = request.headers.get('Accept') || '';
  const wantsJson =
    acceptHeader.includes('application/json') || url.searchParams.get('format') === 'json';

  const playStoreUrl = sanitizePlayStoreUrl(env.PLAY_STORE_URL);
  const appScheme = env.APP_SCHEME || 'listix';
  const packageName = env.ANDROID_PACKAGE_NAME || 'com.nmenag.listix';

  if (!isValidTokenFormat(rawToken)) {
    console.warn(`Invalid token format attempted: ${maskToken(rawToken)}`);
    const result: InviteValidationResult = {
      valid: false,
      errorCode: 'INVALID_TOKEN_FORMAT',
      message: 'El código de invitación proporcionado tiene un formato no válido.',
    };

    if (wantsJson) {
      return jsonResponse(result, 400);
    }

    const html = renderLandingPage({
      token: rawToken,
      result,
      playStoreUrl,
      appScheme,
      packageName,
    });
    return htmlResponse(html, 400);
  }

  const result = await validateInviteToken(rawToken, env);

  if (wantsJson) {
    const statusCode = result.valid
      ? 200
      : result.errorCode === 'MEMBER_LIMIT_REACHED'
        ? 409
        : result.errorCode === 'INVITE_EXPIRED'
          ? 410
          : result.errorCode === 'INVITE_NOT_FOUND' || result.errorCode === 'LIST_NOT_FOUND'
            ? 404
            : 400;
    return jsonResponse(result, statusCode);
  }

  const statusCode = result.valid
    ? 200
    : result.errorCode === 'MEMBER_LIMIT_REACHED'
      ? 409
      : result.errorCode === 'INVITE_EXPIRED'
        ? 410
        : result.errorCode === 'INVITE_NOT_FOUND' || result.errorCode === 'LIST_NOT_FOUND'
          ? 404
          : 400;

  const html = renderLandingPage({
    token: rawToken,
    result,
    playStoreUrl,
    appScheme,
    packageName,
  });

  return htmlResponse(html, statusCode);
}

function jsonResponse(data: unknown, status: number): Response {
  const headers = applySecurityHeaders(
    new Headers({
      'Content-Type': 'application/json; charset=utf-8',
      'Cache-Control': 'no-store, max-age=0',
    }),
  );
  return new Response(JSON.stringify(data), { status, headers });
}

function htmlResponse(html: string, status: number): Response {
  const headers = applySecurityHeaders(
    new Headers({
      'Content-Type': 'text/html; charset=utf-8',
      'Cache-Control': 'no-store, max-age=0',
    }),
  );
  return new Response(html, { status, headers });
}
