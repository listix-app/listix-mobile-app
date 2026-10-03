import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import worker from '../src/index.ts';
import type { Env } from '../src/types.ts';
import { renderLandingPage } from '../src/landing.ts';
import { renderPrivacyPage } from '../src/privacy.ts';
import { renderTermsPage } from '../src/terms.ts';
import { renderLandingPage as renderInviteLandingPage } from '../src/html.ts';

const mockEnv: Env = {
  PLAY_STORE_URL: 'https://play.google.com/store/apps/details?id=com.nmenag.listix',
  ANDROID_PACKAGE_NAME: 'com.nmenag.listix',
  ANDROID_SHA256_FINGERPRINT: 'AA:BB:CC:DD',
  SUPPORT_EMAIL: 'support@listix.app',
};

const mockCtx = {
  waitUntil: () => {},
  passThroughOnException: () => {},
} as unknown as ExecutionContext;

describe('Landing Page Renderer & ASO Strategy', () => {
  it('renders landing page with core ASO keywords, title, and Play Store link', () => {
    const html = renderLandingPage({
      playStoreUrl: 'https://play.google.com/store/apps/details?id=com.nmenag.listix',
      lang: 'en',
    });

    assert.ok(html.includes('Listix — Offline Shopping &amp; Todo Lists'));
    assert.ok(html.includes('100% Offline'));
    assert.ok(html.includes('WhatsApp'));
    assert.ok(html.includes('Gmail'));
    assert.ok(html.includes('shopping list'));
    assert.ok(html.includes('grocery list'));
    assert.ok(html.includes('todo list'));
    assert.ok(html.includes('https://play.google.com/store/apps/details?id=com.nmenag.listix'));
    assert.ok(html.includes('SQLite'));
    assert.ok(html.includes('href="/privacy"'));
    assert.ok(html.includes('href="/terms"'));
  });

  it('renders pure standalone English landing page without Spanish content', () => {
    const html = renderLandingPage({
      playStoreUrl: 'https://play.google.com/store/apps/details?id=com.nmenag.listix',
      lang: 'en',
      pure: true,
    });

    assert.ok(html.includes('lang="en"'));
    assert.ok(html.includes('The Fastest, <span>100% Offline</span> Shopping &amp; Checklist App'));
    assert.ok(html.includes('Get on Google Play'));
    assert.ok(html.includes('Weekly Groceries'));
    assert.ok(!html.includes('Supermercado Semanal'));
    assert.ok(html.includes('href="/en/privacy"'));
    assert.ok(html.includes('href="/en/terms"'));
    assert.ok(html.includes('href="/es"'));
  });

  it('renders landing page in Spanish when requested', () => {
    const html = renderLandingPage({
      playStoreUrl: 'https://play.google.com/store/apps/details?id=com.nmenag.listix',
      lang: 'es',
    });

    assert.ok(html.includes('lang="es"'));
    assert.ok(html.includes('class="is-es"'));
    assert.ok(html.includes('Supermercado'));
    assert.ok(html.includes('lista de compras'));
    assert.ok(html.includes('Descargar en Google Play'));
  });
});

describe('Privacy Policy Renderer', () => {
  it('renders Privacy Policy with required disclosures', () => {
    const html = renderPrivacyPage({
      playStoreUrl: 'https://play.google.com/store/apps/details?id=com.nmenag.listix',
      supportEmail: 'support@listix.app',
      lang: 'en',
    });

    assert.ok(html.includes('Privacy Policy for Listix'));
    assert.ok(html.includes('SQLite'));
    assert.ok(html.includes('Supabase'));
    assert.ok(html.includes('Google Mobile Ads'));
    assert.ok(html.includes('AdMob'));
    assert.ok(html.includes('WhatsApp'));
    assert.ok(html.includes('support@listix.app'));
    assert.ok(html.includes('Children&#039;s Privacy') || html.includes("Children's Privacy"));
    assert.ok(html.includes('Data Retention and Deletion Rights'));
  });

  it('renders pure standalone English Privacy Policy without Spanish text', () => {
    const html = renderPrivacyPage({
      playStoreUrl: 'https://play.google.com/store/apps/details?id=com.nmenag.listix',
      supportEmail: 'support@listix.app',
      lang: 'en',
      pure: true,
    });

    assert.ok(html.includes('lang="en"'));
    assert.ok(html.includes('Privacy Policy for Listix'));
    assert.ok(html.includes('Privacy Summary at a Glance'));
    assert.ok(html.includes('href="/en/terms"'));
    assert.ok(html.includes('href="/es/privacy"'));
    assert.ok(!html.includes('Política de Privacidad de Listix'));
  });

  it('renders Spanish Privacy Policy when requested', () => {
    const html = renderPrivacyPage({
      supportEmail: 'ayuda@listix.app',
      lang: 'es',
    });

    assert.ok(html.includes('Política de Privacidad de Listix'));
    assert.ok(html.includes('lang="es"'));
    assert.ok(html.includes('class="is-es"'));
    assert.ok(html.includes('ayuda@listix.app'));
    assert.ok(html.includes('Almacenados Localmente en tu Dispositivo'));
  });
});

describe('Terms of Service Renderer', () => {
  it('renders Terms of Service with required legal protections', () => {
    const html = renderTermsPage({
      playStoreUrl: 'https://play.google.com/store/apps/details?id=com.nmenag.listix',
      supportEmail: 'support@listix.app',
      lang: 'en',
    });

    assert.ok(html.includes('Terms of Service for Listix'));
    assert.ok(html.includes('Acceptance of Terms'));
    assert.ok(html.includes('License Grant'));
    assert.ok(html.includes('Disclaimer of Warranties'));
    assert.ok(html.includes('Limitation of Liability'));
    assert.ok(html.includes('support@listix.app'));
  });

  it('renders pure standalone English Terms of Service without Spanish text', () => {
    const html = renderTermsPage({
      playStoreUrl: 'https://play.google.com/store/apps/details?id=com.nmenag.listix',
      supportEmail: 'support@listix.app',
      lang: 'en',
      pure: true,
    });

    assert.ok(html.includes('lang="en"'));
    assert.ok(html.includes('Terms of Service for Listix'));
    assert.ok(html.includes('Acceptance of Terms'));
    assert.ok(html.includes('href="/en/privacy"'));
    assert.ok(html.includes('href="/es/terms"'));
    assert.ok(!html.includes('Términos del Servicio de Listix'));
  });

  it('renders Spanish Terms of Service when requested', () => {
    const html = renderTermsPage({
      supportEmail: 'soporte@listix.app',
      lang: 'es',
    });

    assert.ok(html.includes('Términos del Servicio de Listix'));
    assert.ok(html.includes('lang="es"'));
    assert.ok(html.includes('class="is-es"'));
    assert.ok(html.includes('soporte@listix.app'));
    assert.ok(html.includes('Aceptación de los Términos'));
  });
});

describe('Invite Landing Page English Support', () => {
  it('renders invite page in English when lang is set to en', () => {
    const html = renderInviteLandingPage({
      token: 'INVITE99',
      result: {
        valid: true,
        listName: 'Groceries',
        memberCount: 1,
        maxMembers: 5,
      },
      lang: 'en',
    });

    assert.ok(html.includes('lang="en"'));
    assert.ok(html.includes('Join "Groceries" on Listix'));
    assert.ok(html.includes('Active invite'));
    assert.ok(html.includes('Join the list'));
    assert.ok(html.includes('Shared list'));
    assert.ok(html.includes('Collaborators: 1 of 5'));
    assert.ok(html.includes('Open in Listix'));
    assert.ok(html.includes('Install from Google Play'));
    assert.ok(html.includes('Invite code'));
  });

  it('renders invalid invite page in English when invalid and lang is en', () => {
    const html = renderInviteLandingPage({
      token: 'BAD99',
      result: {
        valid: false,
        message: 'This invitation has expired.',
      },
      lang: 'en',
    });

    assert.ok(html.includes('Unavailable'));
    assert.ok(html.includes('Invalid invitation'));
    assert.ok(html.includes('Explore Listix on Google Play'));
  });
});

describe('Worker Static Pages Endpoints', () => {
  it('serves landing page on / by default with HTML content-type and cache headers', async () => {
    const req = new Request('https://worker.test/');
    const res = await worker.fetch(req, mockEnv, mockCtx);

    assert.equal(res.status, 200);
    assert.equal(res.headers.get('Content-Type'), 'text/html; charset=utf-8');
    assert.equal(res.headers.get('Cache-Control'), 'public, max-age=3600');
    const text = await res.text();
    assert.ok(text.includes('Listix — Offline Shopping &amp; Todo Lists'));
    assert.ok(text.includes('com.nmenag.listix'));
  });

  it('serves pure English landing page on /en', async () => {
    const req = new Request('https://worker.test/en');
    const res = await worker.fetch(req, mockEnv, mockCtx);

    assert.equal(res.status, 200);
    assert.equal(res.headers.get('Content-Type'), 'text/html; charset=utf-8');
    const text = await res.text();
    assert.ok(text.includes('The Fastest, <span>100% Offline</span> Shopping &amp; Checklist App'));
    assert.ok(!text.includes('Supermercado Semanal'));
  });

  it('serves pure English Privacy Policy on /en/privacy', async () => {
    const req = new Request('https://worker.test/en/privacy');
    const res = await worker.fetch(req, mockEnv, mockCtx);

    assert.equal(res.status, 200);
    const text = await res.text();
    assert.ok(text.includes('Privacy Policy for Listix'));
    assert.ok(!text.includes('Política de Privacidad de Listix'));
  });

  it('serves pure English Terms of Service on /en/terms', async () => {
    const req = new Request('https://worker.test/en/terms');
    const res = await worker.fetch(req, mockEnv, mockCtx);

    assert.equal(res.status, 200);
    const text = await res.text();
    assert.ok(text.includes('Terms of Service for Listix'));
    assert.ok(!text.includes('Términos del Servicio de Listix'));
  });

  it('serves pure Spanish versions on /es, /es/privacy, /es/terms', async () => {
    const resHome = await worker.fetch(new Request('https://worker.test/es'), mockEnv, mockCtx);
    assert.equal(resHome.status, 200);
    assert.ok((await resHome.text()).includes('La App de <span>Listas de Compras</span>'));

    const resPrivacy = await worker.fetch(new Request('https://worker.test/es/privacy'), mockEnv, mockCtx);
    assert.equal(resPrivacy.status, 200);
    assert.ok((await resPrivacy.text()).includes('Política de Privacidad de Listix'));

    const resTerms = await worker.fetch(new Request('https://worker.test/es/terms'), mockEnv, mockCtx);
    assert.equal(resTerms.status, 200);
    assert.ok((await resTerms.text()).includes('Términos del Servicio de Listix'));
  });

  it('serves landing page in Spanish when ?lang=es query is present', async () => {
    const req = new Request('https://worker.test/?lang=es');
    const res = await worker.fetch(req, mockEnv, mockCtx);

    assert.equal(res.status, 200);
    const text = await res.text();
    assert.ok(text.includes('lang="es"'));
    assert.ok(text.includes('is-es'));
  });

  it('serves JSON on / when Accept header specifies application/json', async () => {
    const req = new Request('https://worker.test/', {
      headers: { Accept: 'application/json' },
    });
    const res = await worker.fetch(req, mockEnv, mockCtx);

    assert.equal(res.status, 200);
    assert.equal(res.headers.get('Content-Type'), 'application/json; charset=utf-8');
    const data = (await res.json()) as { status: string; service: string };
    assert.equal(data.status, 'ok');
    assert.equal(data.service, 'listix-invite-worker');
  });

  it('serves JSON on / when ?format=json query param is provided', async () => {
    const req = new Request('https://worker.test/?format=json');
    const res = await worker.fetch(req, mockEnv, mockCtx);

    assert.equal(res.status, 200);
    assert.equal(res.headers.get('Content-Type'), 'application/json; charset=utf-8');
    const data = (await res.json()) as { status: string };
    assert.equal(data.status, 'ok');
  });

  it('serves Privacy Policy on /privacy and /privacy-policy with security headers', async () => {
    const req1 = new Request('https://worker.test/privacy');
    const res1 = await worker.fetch(req1, mockEnv, mockCtx);
    assert.equal(res1.status, 200);
    assert.equal(res1.headers.get('Content-Type'), 'text/html; charset=utf-8');
    assert.equal(res1.headers.get('X-Content-Type-Options'), 'nosniff');
    assert.equal(res1.headers.get('X-Frame-Options'), 'DENY');
    const text1 = await res1.text();
    assert.ok(text1.includes('Privacy Policy for Listix'));

    const req2 = new Request('https://worker.test/privacy-policy?lang=es');
    const res2 = await worker.fetch(req2, mockEnv, mockCtx);
    assert.equal(res2.status, 200);
    const text2 = await res2.text();
    assert.ok(text2.includes('Política de Privacidad de Listix'));
  });

  it('serves Terms of Service on /terms and aliases with security headers', async () => {
    const routes = ['/terms', '/terms-of-service', '/terms-and-conditions'];
    for (const route of routes) {
      const req = new Request(`https://worker.test${route}`);
      const res = await worker.fetch(req, mockEnv, mockCtx);
      assert.equal(res.status, 200);
      assert.equal(res.headers.get('Content-Type'), 'text/html; charset=utf-8');
      assert.equal(res.headers.get('Cache-Control'), 'public, max-age=3600');
      const text = await res.text();
      assert.ok(text.includes('Terms of Service for Listix'));
    }
  });

  it('serves English invite landing page on /join/:token?lang=en for invalid format', async () => {
    const req = new Request('https://worker.test/join/invalid%20token?lang=en');
    const res = await worker.fetch(req, mockEnv, mockCtx);
    assert.equal(res.status, 400);
    const text = await res.text();
    assert.ok(text.includes('The invite code provided has an invalid format.'));
    assert.ok(text.includes('Invalid invitation'));
  });
});
