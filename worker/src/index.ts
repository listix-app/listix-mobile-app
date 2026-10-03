import type { Env, InviteValidationResult } from './types.ts';
import {
  isValidTokenFormat,
  maskToken,
  applySecurityHeaders,
  sanitizePlayStoreUrl,
} from './security.ts';
import { validateInviteToken } from './supabase.ts';
import { renderLandingPage as renderInviteLandingPage } from './html.ts';
import { renderLandingPage } from './landing.ts';
import { renderPrivacyPage } from './privacy.ts';
import { renderTermsPage } from './terms.ts';

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

    if (path === '/health') {
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

    if (path === '/en') {
      const html = renderLandingPage({
        playStoreUrl: env.PLAY_STORE_URL,
        lang: 'en',
        pure: true,
      });
      return htmlResponse(html, 200, 'public, max-age=3600');
    }

    if (path === '/es') {
      const html = renderLandingPage({
        playStoreUrl: env.PLAY_STORE_URL,
        lang: 'es',
        pure: true,
      });
      return htmlResponse(html, 200, 'public, max-age=3600');
    }

    if (path === '/en/privacy') {
      const html = renderPrivacyPage({
        playStoreUrl: env.PLAY_STORE_URL,
        supportEmail: env.SUPPORT_EMAIL,
        lang: 'en',
        pure: true,
      });
      return htmlResponse(html, 200, 'public, max-age=3600');
    }

    if (path === '/es/privacy') {
      const html = renderPrivacyPage({
        playStoreUrl: env.PLAY_STORE_URL,
        supportEmail: env.SUPPORT_EMAIL,
        lang: 'es',
        pure: true,
      });
      return htmlResponse(html, 200, 'public, max-age=3600');
    }

    if (path === '/en/terms') {
      const html = renderTermsPage({
        playStoreUrl: env.PLAY_STORE_URL,
        supportEmail: env.SUPPORT_EMAIL,
        lang: 'en',
        pure: true,
      });
      return htmlResponse(html, 200, 'public, max-age=3600');
    }

    if (path === '/es/terms') {
      const html = renderTermsPage({
        playStoreUrl: env.PLAY_STORE_URL,
        supportEmail: env.SUPPORT_EMAIL,
        lang: 'es',
        pure: true,
      });
      return htmlResponse(html, 200, 'public, max-age=3600');
    }

    if (path === '/') {
      const acceptHeader = request.headers.get('Accept') || '';
      const wantsJson =
        acceptHeader.includes('application/json') || url.searchParams.get('format') === 'json';

      if (wantsJson) {
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

      const langParam = url.searchParams.get('lang');
      const lang =
        langParam === 'es' || langParam === 'en'
          ? langParam
          : request.headers.get('Accept-Language')?.includes('es')
            ? 'es'
            : 'en';

      const html = renderLandingPage({
        playStoreUrl: env.PLAY_STORE_URL,
        lang,
      });
      return htmlResponse(html, 200, 'public, max-age=3600');
    }

    if (path === '/privacy' || path === '/privacy-policy') {
      const langParam = url.searchParams.get('lang');
      const lang =
        langParam === 'es' || langParam === 'en'
          ? langParam
          : request.headers.get('Accept-Language')?.includes('es')
            ? 'es'
            : 'en';

      const html = renderPrivacyPage({
        playStoreUrl: env.PLAY_STORE_URL,
        supportEmail: env.SUPPORT_EMAIL,
        lang,
      });
      return htmlResponse(html, 200, 'public, max-age=3600');
    }

    if (
      path === '/terms' ||
      path === '/terms-of-service' ||
      path === '/terms-and-conditions'
    ) {
      const langParam = url.searchParams.get('lang');
      const lang =
        langParam === 'es' || langParam === 'en'
          ? langParam
          : request.headers.get('Accept-Language')?.includes('es')
            ? 'es'
            : 'en';

      const html = renderTermsPage({
        playStoreUrl: env.PLAY_STORE_URL,
        supportEmail: env.SUPPORT_EMAIL,
        lang,
      });
      return htmlResponse(html, 200, 'public, max-age=3600');
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

  const langParam = url.searchParams.get('lang');
  const lang =
    langParam === 'es' || langParam === 'en'
      ? langParam
      : request.headers.get('Accept-Language')?.includes('es')
        ? 'es'
        : 'en';

  const playStoreUrl = sanitizePlayStoreUrl(env.PLAY_STORE_URL);
  const appScheme = env.APP_SCHEME || 'listix';
  const packageName = env.ANDROID_PACKAGE_NAME || 'com.nmenag.listix';

  if (!isValidTokenFormat(rawToken)) {
    console.warn(`Invalid token format attempted: ${maskToken(rawToken)}`);
    const result: InviteValidationResult = {
      valid: false,
      errorCode: 'INVALID_TOKEN_FORMAT',
      message:
        lang === 'en'
          ? 'The invite code provided has an invalid format.'
          : 'El código de invitación proporcionado tiene un formato no válido.',
    };

    if (wantsJson) {
      return jsonResponse(result, 400);
    }

    const html = renderInviteLandingPage({
      token: rawToken,
      result,
      playStoreUrl,
      appScheme,
      packageName,
      lang,
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

  const html = renderInviteLandingPage({
    token: rawToken,
    result,
    playStoreUrl,
    appScheme,
    packageName,
    lang,
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

function htmlResponse(
  html: string,
  status: number,
  cacheControl = 'no-store, max-age=0',
): Response {
  const headers = applySecurityHeaders(
    new Headers({
      'Content-Type': 'text/html; charset=utf-8',
      'Cache-Control': cacheControl,
    }),
  );
  return new Response(html, { status, headers });
}
