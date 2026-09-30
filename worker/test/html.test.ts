import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { renderLandingPage } from '../src/html.ts';
import type { InviteValidationResult } from '../src/types.ts';

describe('HTML Landing Page Renderer', () => {
  it('renders active invite landing page with details, deep link, and play store button', () => {
    const validResult: InviteValidationResult = {
      valid: true,
      listId: 'list-123',
      listName: 'Mercado Semanal',
      memberCount: 2,
      maxMembers: 5,
      expiresAt: new Date(Date.now() + 86400000).toISOString(),
    };

    const html = renderLandingPage({
      token: 'INVITE123',
      result: validResult,
      playStoreUrl: 'https://play.google.com/store/apps/details?id=com.nmenag.listix',
      appScheme: 'listix',
      packageName: 'com.nmenag.listix',
    });

    assert.ok(html.includes('Mercado Semanal'));
    assert.ok(html.includes('Invitación activa'));
    assert.ok(html.includes('listix://join/INVITE123'));
    assert.ok(html.includes('intent://join/INVITE123#Intent;scheme=listix;package=com.nmenag.listix;end'));
    assert.ok(html.includes('https://play.google.com/store/apps/details?id=com.nmenag.listix'));
    assert.ok(html.includes('INVITE123'));
    assert.ok(html.includes('Colaboradores: 2 de 5'));
  });

  it('escapes user input in list name and token to prevent XSS', () => {
    const maliciousResult: InviteValidationResult = {
      valid: true,
      listName: '<script>alert("xss")</script>',
    };

    const html = renderLandingPage({
      token: 'XSS"&<>',
      result: maliciousResult,
      playStoreUrl: 'https://play.google.com/store/apps/details?id=com.nmenag.listix',
    });

    assert.ok(!html.includes('<script>alert("xss")</script>'));
    assert.ok(html.includes('&lt;script&gt;alert(&quot;xss&quot;)&lt;/script&gt;'));
  });

  it('renders expired / revoked / error landing page politely with reason', () => {
    const errorResult: InviteValidationResult = {
      valid: false,
      errorCode: 'INVITE_EXPIRED',
      message: 'El enlace de invitación ha caducado.',
    };

    const html = renderLandingPage({
      token: 'EXPIRED123',
      result: errorResult,
      playStoreUrl: 'https://play.google.com/store/apps/details?id=com.nmenag.listix',
    });

    assert.ok(html.includes('No disponible'));
    assert.ok(html.includes('El enlace de invitación ha caducado.'));
    assert.ok(html.includes('Conoce Listix en Google Play'));
    assert.ok(!html.includes('Abrir en Listix'));
  });
});
