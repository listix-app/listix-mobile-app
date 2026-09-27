import type { InviteValidationResult } from './types.ts';
import { sanitizePlayStoreUrl } from './security.ts';

interface RenderOptions {
  token: string;
  result: InviteValidationResult;
  playStoreUrl: string;
  appScheme?: string;
  packageName?: string;
}

export function renderLandingPage(options: RenderOptions): string {
  const { token, result, appScheme = 'listix', packageName = 'com.example.listix' } = options;
  const playStore = sanitizePlayStoreUrl(options.playStoreUrl);
  const isValid = result.valid;

  const title = isValid
    ? `Únete a "${escapeHtml(result.listName ?? 'Lista')}" en Listix`
    : 'Invitación a Listix';

  const description = isValid
    ? `Colabora en tiempo real en la lista "${escapeHtml(result.listName ?? '')}" con Listix.`
    : (result.message ?? 'Enlace de invitación de Listix.');

  const deepLink = `${appScheme}://join/${encodeURIComponent(token)}`;
  const androidIntent = `intent://join/${encodeURIComponent(token)}#Intent;scheme=${appScheme};package=${packageName};end`;

  return `<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${title}</title>
  <meta name="description" content="${description}">
  <meta property="og:title" content="${title}">
  <meta property="og:description" content="${description}">
  <meta property="og:type" content="website">
  <meta name="theme-color" content="#059669">
  <style>
    :root {
      --primary: #059669;
      --primary-hover: #047857;
      --primary-light: #ecfdf5;
      --primary-border: #a7f3d0;
      --bg: #f8fafc;
      --card-bg: #ffffff;
      --text: #0f172a;
      --text-muted: #64748b;
      --border: #e2e8f0;
      --error-bg: #fef2f2;
      --error-text: #b91c1c;
      --error-border: #fecaca;
    }
    @media (prefers-color-scheme: dark) {
      :root {
        --bg: #0f172a;
        --card-bg: #1e293b;
        --text: #f8fafc;
        --text-muted: #94a3b8;
        --border: #334155;
        --primary-light: #064e3b;
        --primary-border: #065f46;
        --error-bg: #450a0a;
        --error-text: #fca5a5;
        --error-border: #7f1d1d;
      }
    }
    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
    }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      background-color: var(--bg);
      color: var(--text);
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      padding: 24px 16px;
      line-height: 1.5;
    }
    .container {
      width: 100%;
      max-width: 440px;
      display: flex;
      flex-direction: column;
      gap: 20px;
    }
    .brand {
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 10px;
      text-decoration: none;
      color: var(--text);
    }
    .brand-icon {
      width: 44px;
      height: 44px;
      background: linear-gradient(135deg, #10b981, #059669);
      border-radius: 12px;
      display: flex;
      align-items: center;
      justify-content: center;
      color: #ffffff;
      box-shadow: 0 4px 12px rgba(5, 150, 105, 0.25);
    }
    .brand-name {
      font-size: 26px;
      font-weight: 800;
      letter-spacing: -0.5px;
    }
    .card {
      background-color: var(--card-bg);
      border: 1px solid var(--border);
      border-radius: 20px;
      padding: 28px 24px;
      box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.05), 0 8px 10px -6px rgba(0, 0, 0, 0.02);
      text-align: center;
    }
    .status-badge {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      padding: 6px 14px;
      border-radius: 9999px;
      font-size: 13px;
      font-weight: 600;
      margin-bottom: 16px;
    }
    .status-badge.success {
      background-color: var(--primary-light);
      color: var(--primary);
      border: 1px solid var(--primary-border);
    }
    .status-badge.error {
      background-color: var(--error-bg);
      color: var(--error-text);
      border: 1px solid var(--error-border);
    }
    h1 {
      font-size: 22px;
      font-weight: 700;
      line-height: 1.3;
      margin-bottom: 8px;
    }
    .subtitle {
      color: var(--text-muted);
      font-size: 15px;
      margin-bottom: 24px;
    }
    .list-preview {
      background-color: var(--bg);
      border: 1px solid var(--border);
      border-radius: 14px;
      padding: 16px;
      margin-bottom: 24px;
      display: flex;
      flex-direction: column;
      gap: 6px;
      text-align: left;
    }
    .list-preview-label {
      font-size: 12px;
      text-transform: uppercase;
      letter-spacing: 0.5px;
      color: var(--text-muted);
      font-weight: 600;
    }
    .list-preview-name {
      font-size: 18px;
      font-weight: 700;
      color: var(--text);
    }
    .list-preview-meta {
      font-size: 13px;
      color: var(--text-muted);
    }
    .actions {
      display: flex;
      flex-direction: column;
      gap: 12px;
    }
    .btn {
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 8px;
      padding: 14px 20px;
      border-radius: 14px;
      font-size: 16px;
      font-weight: 600;
      text-decoration: none;
      transition: all 0.15s ease;
      cursor: pointer;
      border: none;
      width: 100%;
    }
    .btn-primary {
      background-color: var(--primary);
      color: #ffffff;
      box-shadow: 0 4px 12px rgba(5, 150, 105, 0.25);
    }
    .btn-primary:hover {
      background-color: var(--primary-hover);
      transform: translateY(-1px);
    }
    .btn-secondary {
      background-color: transparent;
      color: var(--text);
      border: 1px solid var(--border);
    }
    .btn-secondary:hover {
      background-color: var(--bg);
    }
    .token-box {
      margin-top: 20px;
      padding-top: 20px;
      border-top: 1px dashed var(--border);
      display: flex;
      flex-direction: column;
      gap: 8px;
    }
    .token-code {
      font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
      font-size: 13px;
      background-color: var(--bg);
      padding: 8px 12px;
      border-radius: 8px;
      border: 1px solid var(--border);
      color: var(--text);
      word-break: break-all;
      user-select: all;
    }
    .copy-btn {
      background: none;
      border: none;
      color: var(--primary);
      font-size: 13px;
      font-weight: 600;
      cursor: pointer;
      padding: 4px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      gap: 4px;
    }
    .copy-btn:hover {
      text-decoration: underline;
    }
    .footer {
      text-align: center;
      font-size: 13px;
      color: var(--text-muted);
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="brand">
      <div class="brand-icon">
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
          <path d="m9 11 3 3L22 4"/>
          <path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"/>
        </svg>
      </div>
      <span class="brand-name">Listix</span>
    </div>

    <div class="card">
      ${
        isValid
          ? `
        <div class="status-badge success">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>
          Invitación activa
        </div>
        <h1>Únete a la lista</h1>
        <p class="subtitle">Te han invitado a colaborar y sincronizar en tiempo real.</p>

        <div class="list-preview">
          <span class="list-preview-label">Lista compartida</span>
          <span class="list-preview-name">${escapeHtml(result.listName ?? 'Lista')}</span>
          <span class="list-preview-meta">Colaboradores: ${result.memberCount ?? 1} de ${result.maxMembers ?? 5}</span>
        </div>

        <div class="actions">
          <a id="open-app-btn" href="${deepLink}" class="btn btn-primary">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"/><polyline points="15 3 21 3 21 9"/><line x1="10" y1="14" x2="21" y2="3"/></svg>
            Abrir en Listix
          </a>
          <a href="${playStore}" target="_blank" rel="noopener noreferrer" class="btn btn-secondary">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M3.609 1.814L13.793 12 3.61 22.186c-.198-.184-.31-.448-.31-.734V2.548c0-.286.112-.55.31-.734zm11.242 11.244l2.42 2.42-12.022 6.94 9.602-9.36zm2.42-2.42l-2.42-2.42 9.602-9.36-9.602 9.36 2.42 2.42zm1.058-1.058l3.195 1.844c.638.368.638.97 0 1.338l-3.195 1.844-2.127-2.513 2.127-2.513z"/></svg>
            Instalar desde Google Play
          </a>
        </div>

        <div class="token-box">
          <span class="list-preview-label">Código de invitación</span>
          <div class="token-code">${escapeHtml(token)}</div>
          <button id="copy-btn" class="copy-btn" type="button">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect width="14" height="14" x="8" y="8" rx="2" ry="2"/><path d="M4 16c-1.1 0-2-.9-2-2V4c0-1.1.9-2 2-2h10c1.1 0 2 .9 2 2"/></svg>
            <span id="copy-text">Copiar código</span>
          </button>
        </div>
      `
          : `
        <div class="status-badge error">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
          No disponible
        </div>
        <h1>Invitación no válida</h1>
        <p class="subtitle">${escapeHtml(result.message ?? 'No se pudo procesar la invitación.')}</p>

        <div class="actions">
          <a href="${playStore}" target="_blank" rel="noopener noreferrer" class="btn btn-primary">
            Conoce Listix en Google Play
          </a>
        </div>
      `
      }
    </div>

    <div class="footer">
      Listix &bull; Listas compartidas sincronizadas
    </div>
  </div>

  ${
    isValid
      ? `
  <script>
    (function() {
      var token = ${JSON.stringify(token)};
      var deepLink = ${JSON.stringify(deepLink)};
      var androidIntent = ${JSON.stringify(androidIntent)};

      var copyBtn = document.getElementById('copy-btn');
      var copyText = document.getElementById('copy-text');
      if (copyBtn) {
        copyBtn.addEventListener('click', function() {
          navigator.clipboard.writeText(token).then(function() {
            copyText.textContent = '¡Copiado!';
            setTimeout(function() { copyText.textContent = 'Copiar código'; }, 2000);
          }).catch(function() {
            copyText.textContent = 'Error al copiar';
          });
        });
      }

      var openBtn = document.getElementById('open-app-btn');
      if (openBtn) {
        openBtn.addEventListener('click', function(e) {
          if (/Android/i.test(navigator.userAgent)) {
            window.location.href = androidIntent;
          } else {
            window.location.href = deepLink;
          }
        });
      }

      if (/Android|iPhone|iPad|iPod/i.test(navigator.userAgent)) {
        setTimeout(function() {
          window.location.href = /Android/i.test(navigator.userAgent) ? androidIntent : deepLink;
        }, 150);
      }
    })();
  </script>
  `
      : ''
  }
</body>
</html>`;
}

function escapeHtml(str: string): string {
  return str
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}
