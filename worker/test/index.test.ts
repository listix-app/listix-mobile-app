import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import worker from '../src/index.ts';
import type { Env } from '../src/types.ts';

const mockEnv: Env = {
  PLAY_STORE_URL: 'https://play.google.com/store/apps/details?id=com.nmenag.listix',
  ANDROID_PACKAGE_NAME: 'com.nmenag.listix',
  ANDROID_SHA256_FINGERPRINT: 'AA:BB:CC:DD',
};

const mockCtx = {
  waitUntil: () => {},
  passThroughOnException: () => {},
} as unknown as ExecutionContext;

describe('Cloudflare Worker Endpoint Router', () => {
  it('responds with 200 OK on / and /health', async () => {
    const reqHealth = new Request('https://worker.test/health');
    const resHealth = await worker.fetch(reqHealth, mockEnv, mockCtx);
    assert.equal(resHealth.status, 200);
    const dataHealth = (await resHealth.json()) as { status: string };
    assert.equal(dataHealth.status, 'ok');

    const reqRoot = new Request('https://worker.test/');
    const resRoot = await worker.fetch(reqRoot, mockEnv, mockCtx);
    assert.equal(resRoot.status, 200);
  });

  it('serves /.well-known/assetlinks.json for Android App Links verification', async () => {
    const req = new Request('https://worker.test/.well-known/assetlinks.json');
    const res = await worker.fetch(req, mockEnv, mockCtx);
    assert.equal(res.status, 200);
    assert.equal(res.headers.get('Content-Type'), 'application/json; charset=utf-8');

    const assetLinks = (await res.json()) as Array<{
      relation: string[];
      target: { namespace: string; package_name: string; sha256_cert_fingerprints: string[] };
    }>;
    assert.equal(assetLinks.length, 1);
    assert.equal(assetLinks[0].target.package_name, 'com.nmenag.listix');
    assert.deepEqual(assetLinks[0].target.sha256_cert_fingerprints, ['AA:BB:CC:DD']);
  });

  it('rejects invalid token format with 400 Bad Request on /join/:token', async () => {
    const req = new Request('https://worker.test/join/invalid%20token%20with%20spaces?format=json');
    const res = await worker.fetch(req, mockEnv, mockCtx);
    assert.equal(res.status, 400);
    const data = (await res.json()) as { valid: boolean; errorCode: string };
    assert.equal(data.valid, false);
    assert.equal(data.errorCode, 'INVALID_TOKEN_FORMAT');
  });

  it('returns missing configuration error when Supabase secrets are not set', async () => {
    const req = new Request('https://worker.test/join/ABC12345?format=json');
    const res = await worker.fetch(req, mockEnv, mockCtx);
    assert.equal(res.status, 400);
    const data = (await res.json()) as { valid: boolean; errorCode: string };
    assert.equal(data.valid, false);
    assert.equal(data.errorCode, 'MISSING_CONFIGURATION');
  });

  it('returns 204 for OPTIONS preflight request', async () => {
    const req = new Request('https://worker.test/join/ABC12345', { method: 'OPTIONS' });
    const res = await worker.fetch(req, mockEnv, mockCtx);
    assert.equal(res.status, 204);
    assert.equal(res.headers.get('Access-Control-Allow-Origin'), '*');
  });

  it('returns 405 Method Not Allowed for POST requests', async () => {
    const req = new Request('https://worker.test/join/ABC12345', { method: 'POST' });
    const res = await worker.fetch(req, mockEnv, mockCtx);
    assert.equal(res.status, 405);
  });

  it('returns 404 Not Found for unknown routes', async () => {
    const req = new Request('https://worker.test/unknown-endpoint');
    const res = await worker.fetch(req, mockEnv, mockCtx);
    assert.equal(res.status, 404);
  });
});
