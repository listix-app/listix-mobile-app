import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import {
  isValidTokenFormat,
  hashToken,
  maskToken,
  sanitizePlayStoreUrl,
  applySecurityHeaders,
} from '../src/security.ts';

describe('Security & Validation Utilities', () => {
  describe('isValidTokenFormat', () => {
    it('accepts valid alphanumeric, hex, and hyphenated tokens', () => {
      assert.equal(isValidTokenFormat('ABC123'), true);
      assert.equal(isValidTokenFormat('a1b2c3d4e5f6'), true);
      assert.equal(
        isValidTokenFormat(
          'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
        ),
        true,
      );
      assert.equal(isValidTokenFormat('invite-token_12345'), true);
    });

    it('rejects invalid or dangerous tokens', () => {
      assert.equal(isValidTokenFormat(''), false);
      assert.equal(isValidTokenFormat('123'), false); // too short (< 6)
      assert.equal(isValidTokenFormat('   '), false);
      assert.equal(isValidTokenFormat('ABC 123'), false); // contains space
      assert.equal(isValidTokenFormat('token<script>'), false);
      assert.equal(isValidTokenFormat("token';DROP TABLE lists;--"), false);
      assert.equal(isValidTokenFormat('../join/other'), false);
      assert.equal(isValidTokenFormat('a'.repeat(129)), false); // too long (> 128)
      assert.equal(isValidTokenFormat(null as unknown as string), false);
      assert.equal(isValidTokenFormat(undefined as unknown as string), false);
    });
  });

  describe('hashToken', () => {
    it('calculates expected standard SHA-256 hash matching Dart crypto', async () => {
      const hash = await hashToken('ABC123test');
      assert.equal(
        hash,
        '59eb73c502018c683af8b81c2d3b6e03a9fe34ea31593bf252aaaa8e12f9aff7',
      );
    });

    it('trims whitespace before hashing', async () => {
      const hash1 = await hashToken('ABC123test');
      const hash2 = await hashToken('  ABC123test  ');
      assert.equal(hash1, hash2);
    });
  });

  describe('maskToken', () => {
    it('masks full tokens to prevent secret leakage in logs', () => {
      assert.equal(maskToken(''), '[empty]');
      assert.equal(maskToken('short'), '***');
      assert.equal(maskToken('12345678'), '***');
      assert.equal(maskToken('123456789'), '1234...6789');
      assert.equal(
        maskToken('e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855'),
        'e3b0...b855',
      );
    });
  });

  describe('sanitizePlayStoreUrl', () => {
    const defaultPlayStore =
      'https://play.google.com/store/apps/details?id=com.example.listix';

    it('returns default URL when input is missing or empty', () => {
      assert.equal(sanitizePlayStoreUrl(), defaultPlayStore);
      assert.equal(sanitizePlayStoreUrl(''), defaultPlayStore);
      assert.equal(sanitizePlayStoreUrl('   '), defaultPlayStore);
    });

    it('accepts valid play.google.com URLs', () => {
      const customUrl =
        'https://play.google.com/store/apps/details?id=com.example.listix&referrer=utm_source%3Dinvite';
      assert.equal(sanitizePlayStoreUrl(customUrl), customUrl);
    });

    it('prevents open redirects to untrusted domains', () => {
      assert.equal(sanitizePlayStoreUrl('https://evil-site.com'), defaultPlayStore);
      assert.equal(sanitizePlayStoreUrl('javascript:alert(1)'), defaultPlayStore);
      assert.equal(sanitizePlayStoreUrl('http://play.google.com.attacker.com'), defaultPlayStore);
    });
  });

  describe('applySecurityHeaders', () => {
    it('applies essential hardening headers', () => {
      const headers = applySecurityHeaders(new Headers());
      assert.equal(headers.get('X-Content-Type-Options'), 'nosniff');
      assert.equal(headers.get('X-Frame-Options'), 'DENY');
      assert.equal(headers.get('Referrer-Policy'), 'strict-origin-when-cross-origin');
      assert.ok(headers.get('Content-Security-Policy')?.includes("default-src 'self'"));
    });
  });
});
