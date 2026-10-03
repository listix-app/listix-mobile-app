import { sanitizePlayStoreUrl } from './security.ts';

export interface TermsPageOptions {
  playStoreUrl?: string;
  supportEmail?: string;
  lang?: string;
  pure?: boolean;
}

export function renderTermsPage(options: TermsPageOptions = {}): string {
  const playStore = sanitizePlayStoreUrl(options.playStoreUrl);
  const supportEmail = options.supportEmail || 'support@listix.app';
  const initialLang = options.lang === 'es' ? 'es' : 'en';
  const pure = options.pure ?? false;

  const englishBody = `
      <div class="doc-meta">
        Effective Date: October 2026 • Version 1.0
      </div>

      <h1>Terms of Service for Listix</h1>

      <h2>1. Acceptance of Terms</h2>
      <p>
        By downloading, installing, accessing, or using the <strong>Listix</strong> mobile application or related services, you agree to be bound by these Terms of Service ("Terms"). If you do not agree to these Terms, please do not use the application.
      </p>

      <h2>2. License Grant &amp; Permitted Use</h2>
      <p>
        Subject to your compliance with these Terms, Listix grants you a limited, non-exclusive, non-transferable, revocable license to download, install, and use the application on personal devices solely for your personal, non-commercial productivity and organization needs.
      </p>

      <h2>3. Offline Architecture &amp; Data Responsibility</h2>
      <p>
        Listix is built primarily as an offline-first tool. Personal shopping lists, task records, and checklist modifications are recorded in local device storage (SQLite).
      </p>
      <ul>
        <li><strong>Local Integrity:</strong> You acknowledge that you are responsible for maintaining the security of your device and managing backups. Deleting the application or clearing device storage will permanently erase your un-synced local data.</li>
        <li><strong>Zero Warranty on Device Storage:</strong> We are not liable for data loss caused by hardware malfunction, operating system updates, or user deletion.</li>
      </ul>

      <h2>4. Collaborative Lists &amp; Acceptable Use</h2>
      <p>
        When you participate in collaborative lists via invite links, you agree to use the service responsibly. You agree NOT to:
      </p>
      <ul>
        <li>Post or transmit unlawful, harassing, defamatory, abusive, threatening, or infringing text in shared list names or item entries.</li>
        <li>Attempt to breach or bypass rate limits, server security, or cryptographic tokens protecting invite URLs.</li>
        <li>Transmit malicious code, scripts, automated web scrapers, or bot requests against our synchronization infrastructure.</li>
      </ul>
      <p>
        We reserve the right to revoke invite links, invalidate tokens, or restrict access to collaborative features for users who violate these conduct rules.
      </p>

      <h2>5. Advertising &amp; Third-Party Services</h2>
      <p>
        Listix integrates third-party services to deliver free functionality:
      </p>
      <ul>
        <li><strong>Google AdMob:</strong> The application displays third-party advertisements provided by Google Mobile Ads. Your interaction with ad content is governed by Google's advertising policies.</li>
        <li><strong>WhatsApp &amp; Gmail Export:</strong> Our formatted export feature interacts with third-party messaging clients installed on your device. We have no control over and assume no liability for the services, privacy policies, or delivery mechanisms of WhatsApp or Google.</li>
        <li><strong>Supabase:</strong> Real-time synchronization is operated on secure cloud servers. We endeavor to maintain high service availability but do not guarantee uninterrupted connectivity.</li>
      </ul>

      <h2>6. Intellectual Property Rights</h2>
      <p>
        All copyrights, trademarks, logos, visual designs, source code, and app assets associated with Listix are the exclusive property of Listix and its creators. You may not reverse engineer, decompile, copy, or distribute any part of the application without express prior written consent.
      </p>

      <h2>7. Disclaimer of Warranties</h2>
      <p>
        THE APPLICATION AND RELATED SERVICES ARE PROVIDED ON AN "AS IS" AND "AS AVAILABLE" BASIS WITHOUT WARRANTIES OF ANY KIND, WHETHER EXPRESS, IMPLIED, STATUTORY, OR OTHERWISE, INCLUDING BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT. WE DO NOT WARRANT THAT THE APPLICATION WILL OPERATE ERROR-FREE OR THAT CLOUD SYNCHRONIZATION WILL BE CONTINUOUSLY AVAILABLE.
      </p>

      <h2>8. Limitation of Liability</h2>
      <p>
        TO THE MAXIMUM EXTENT PERMITTED UNDER APPLICABLE LAW, IN NO EVENT SHALL LISTIX, ITS DEVELOPERS, OR AFFILIATES BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES, INCLUDING BUT NOT LIMITED TO LOSS OF DATA, DEVICE DAMAGE, OR INTERRUPTION OF SERVICE ARISING OUT OF OR IN CONNECTION WITH YOUR USE OR INABILITY TO USE THE APPLICATION.
      </p>

      <h2>9. Modifications to the Service and Terms</h2>
      <p>
        We reserve the right to update, modify, or discontinue features of Listix at any time. We may also revise these Terms periodically. Any revised terms will be published on this website. Your continued use of Listix following the posting of updated Terms constitutes your binding agreement.
      </p>

      <h2>10. Governing Law</h2>
      <p>
        These Terms shall be governed by and construed in accordance with the laws applicable to consumer mobile software, without giving effect to any principles of conflicts of law.
      </p>

      <h2>11. Contact Us</h2>
      <p>
        If you have any questions or feedback regarding these Terms of Service, please reach out to us:
      </p>
      <p>
        <strong>Listix Support</strong><br>
        Email: <a href="mailto:${supportEmail}">${supportEmail}</a><br>
        Google Play: <a href="${playStore}" target="_blank" rel="noopener noreferrer">Listix on Google Play</a>
      </p>
  `;

  const spanishBody = `
      <div class="doc-meta">
        Fecha de Vigencia: Octubre 2026 • Versión 1.0
      </div>

      <h1>Términos del Servicio de Listix</h1>

      <h2>1. Aceptación de los Términos</h2>
      <p>
        Al descargar, instalar o utilizar la aplicación móvil <strong>Listix</strong> o sus servicios vinculados, aceptas cumplir y quedar vinculado por estos Términos del Servicio ("Términos"). Si no estás de acuerdo con estos Términos, no debes utilizar la aplicación.
      </p>

      <h2>2. Licencia de Uso</h2>
      <p>
        Sujeto al cumplimiento de estos Términos, Listix te otorga una licencia limitada, revocable, no exclusiva e intransferible para instalar y utilizar la aplicación en tus dispositivos personales, con fines exclusivamente personales y no comerciales.
      </p>

      <h2>3. Arquitectura Offline y Responsabilidad de los Datos</h2>
      <p>
        Listix está diseñada como una herramienta primordialmente offline. Tus listas, tareas y compras se guardan localmente en la base de datos de tu teléfono (SQLite).
      </p>
      <ul>
        <li><strong>Integridad Local:</strong> Eres responsable de la seguridad de tu dispositivo y de tus copias de respaldo. Al desinstalar la aplicación o restablecer los datos del sistema, tus datos locales no sincronizados se borrarán de manera definitiva.</li>
        <li><strong>Sin Garantía sobre Almacenamiento Local:</strong> No nos hacemos responsables por pérdidas de datos ocasionadas por fallos de hardware, actualizaciones del sistema operativo o eliminación accidental por parte del usuario.</li>
      </ul>

      <h2>4. Listas Compartidas y Uso Aceptable</h2>
      <p>
        Al interactuar en listas colaborativas mediante enlaces de invitación, te comprometes a usar el servicio de forma lícita y respetuosa. Queda estrictamente prohibido:
      </p>
      <ul>
        <li>Publicar contenido ilegal, ofensivo, calumnioso o difamatorio en los títulos o artículos de las listas compartidas.</li>
        <li>Intentar vulnerar los mecanismos de seguridad, cifrado o límites de peticiones de los servidores de sincronización.</li>
        <li>Enviar código malicioso, scripts automatizados o herramientas de raspado masivo contra la infraestructura de Listix.</li>
      </ul>
      <p>
        Nos reservamos el derecho de revocar enlaces de invitación y restringir el acceso a usuarios que infrinjan estas normas.
      </p>

      <h2>5. Publicidad y Servicios de Terceros</h2>
      <p>
        Listix se apoya en servicios externos para brindar funciones gratuitas:
      </p>
      <ul>
        <li><strong>Google AdMob:</strong> Se muestran anuncios a través de Google Mobile Ads. La interacción con los anuncios se rige por las políticas de publicidad de Google.</li>
        <li><strong>Exportación por WhatsApp y Gmail:</strong> La función de envío directo utiliza las apps instaladas en tu teléfono mediante los menús del sistema. No controlamos ni asumimos responsabilidad por la disponibilidad o políticas de WhatsApp o Google.</li>
        <li><strong>Supabase:</strong> La sincronización en tiempo real opera en infraestructura en la nube. Procuramos alta disponibilidad pero no garantizamos operación ininterrumpida.</li>
      </ul>

      <h2>6. Propiedad Intelectual</h2>
      <p>
        Todos los derechos de autor, logotipos, marcas comerciales, código fuente, interfaz visual y activos gráficos de Listix son propiedad exclusiva de sus creadores. Queda prohibida su reproducción, ingeniería inversa o redistribución no autorizada.
      </p>

      <h2>7. Exclusión de Garantías</h2>
      <p>
        LA APLICACIÓN SE OFRECE "TAL CUAL" Y "SEGÚN DISPONIBILIDAD", SIN GARANTÍAS DE NINGÚN TIPO, YA SEAN EXPRESAS O IMPLÍCITAS. NO GARANTIZAMOS QUE LA APLICACIÓN OPERE LIBRE DE ERRORES O QUE LA SINCRONIZACIÓN EN LA NUBE ESTÉ DISPONIBLE DE MANERA ININTERRUMPIDA.
      </p>

      <h2>8. Limitación de Responsabilidad</h2>
      <p>
        EN LA MEDIDA MÁXIMA PERMITIDA POR LA LEY APLICABLE, LISTIX Y SUS DESARROLLADORES NO SERÁN RESPONSABLES POR DAÑOS INDIRECTOS, INCIDENTALES, ESPECIALES O PUNITIVOS, INCLUYENDO PÉRDIDA DE DATOS O DAÑOS AL DISPOSITIVO RESULTANTES DEL USO O DE LA IMPOSIBILIDAD DE USO DE LA APLICACIÓN.
      </p>

      <h2>9. Modificaciones al Servicio y a los Términos</h2>
      <p>
        Podemos actualizar, suspender o modificar funcionalidades de Listix en cualquier momento. Cualquier cambio en estos Términos será publicado en este sitio web. El uso continuo de la aplicación tras dichos cambios constituye tu aceptación plena.
      </p>

      <h2>10. Ley Aplicable</h2>
      <p>
        Estos Términos se rigen e interpretan según las leyes aplicables al software de consumo móvil, sin perjuicio de los principios de conflicto de leyes.
      </p>

      <h2>11. Contacto</h2>
      <p>
        Si tienes dudas o inquietudes sobre estos Términos, puedes contactarnos en:
      </p>
      <p>
        <strong>Soporte de Listix</strong><br>
        Correo: <a href="mailto:${supportEmail}">${supportEmail}</a><br>
        Google Play: <a href="${playStore}" target="_blank" rel="noopener noreferrer">Listix en Google Play</a>
      </p>
  `;

  return `<!DOCTYPE html>
<html lang="${initialLang}" id="html-root">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${initialLang === 'es' ? 'Términos del Servicio — Listix' : 'Terms of Service — Listix'}</title>
  <meta name="description" content="Terms of Service for Listix: Fast, offline-first, private shopping and checklist mobile application. User rights, acceptable use, and license agreement.">
  <meta property="og:title" content="Listix Terms of Service">
  <meta property="og:description" content="Terms of Service and End User License Agreement for Listix.">
  <meta property="og:type" content="article">
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
      --shadow: 0 10px 30px -5px rgba(0, 0, 0, 0.05), 0 8px 10px -6px rgba(0, 0, 0, 0.03);
    }
    @media (prefers-color-scheme: dark) {
      :root {
        --primary: #10b981;
        --primary-hover: #059669;
        --primary-light: #064e3b;
        --primary-border: #065f46;
        --bg: #090d16;
        --card-bg: #111827;
        --text: #f8fafc;
        --text-muted: #94a3b8;
        --border: #334155;
        --shadow: 0 10px 30px -5px rgba(0, 0, 0, 0.3);
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
      line-height: 1.7;
      -webkit-font-smoothing: antialiased;
    }
    a {
      color: var(--primary);
      text-decoration: none;
    }
    a:hover {
      text-decoration: underline;
    }
    header {
      position: sticky;
      top: 0;
      background-color: var(--card-bg);
      border-bottom: 1px solid var(--border);
      z-index: 50;
      backdrop-filter: blur(12px);
    }
    .nav-container {
      max-width: 900px;
      margin: 0 auto;
      padding: 14px 20px;
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 16px;
    }
    .brand {
      display: flex;
      align-items: center;
      gap: 10px;
      font-size: 20px;
      font-weight: 800;
      color: var(--text);
      text-decoration: none;
    }
    .brand-icon {
      width: 36px;
      height: 36px;
      background: linear-gradient(135deg, #10b981, #059669);
      border-radius: 10px;
      display: flex;
      align-items: center;
      justify-content: center;
      color: #ffffff;
    }
    .nav-links {
      display: flex;
      align-items: center;
      gap: 16px;
    }
    .nav-link {
      font-size: 14px;
      font-weight: 600;
      color: var(--text-muted);
      text-decoration: none;
    }
    .nav-link:hover {
      color: var(--text);
    }
    .lang-btn {
      background: transparent;
      border: 1px solid var(--border);
      border-radius: 8px;
      padding: 6px 12px;
      font-size: 13px;
      font-weight: 600;
      color: var(--text);
      cursor: pointer;
    }
    .content-wrap {
      max-width: 900px;
      margin: 0 auto;
      padding: 40px 20px 80px;
    }
    .legal-card {
      background-color: var(--card-bg);
      border: 1px solid var(--border);
      border-radius: 20px;
      padding: 40px;
      box-shadow: var(--shadow);
    }
    .doc-meta {
      display: flex;
      align-items: center;
      gap: 12px;
      font-size: 13px;
      color: var(--text-muted);
      margin-bottom: 16px;
      text-transform: uppercase;
      letter-spacing: 0.5px;
      font-weight: 700;
    }
    h1 {
      font-size: 34px;
      font-weight: 800;
      letter-spacing: -0.5px;
      margin-bottom: 24px;
      line-height: 1.25;
    }
    h2 {
      font-size: 22px;
      font-weight: 700;
      margin: 32px 0 14px;
      padding-bottom: 8px;
      border-bottom: 1px solid var(--border);
    }
    p {
      margin-bottom: 16px;
      font-size: 15px;
      color: var(--text);
    }
    ul, ol {
      margin-bottom: 18px;
      padding-left: 24px;
      font-size: 15px;
    }
    li {
      margin-bottom: 8px;
    }
    footer {
      border-top: 1px solid var(--border);
      background-color: var(--card-bg);
      padding: 32px 20px;
      font-size: 14px;
      color: var(--text-muted);
      text-align: center;
    }
    ${
      pure
        ? ''
        : `
    .lang-es { display: none; }
    .lang-en { display: block; }
    span.lang-es, a.lang-es, button.lang-es, div.lang-es { display: none; }
    span.lang-en, a.lang-en, button.lang-en, div.lang-en { display: inline-block; }
    div.lang-en, p.lang-en, h1.lang-en, h2.lang-en, h3.lang-en, ul.lang-en, ol.lang-en { display: block; }
    div.lang-es, p.lang-es, h2.lang-es, h3.lang-es, ul.lang-es, ol.lang-es { display: none; }
    body.is-es .lang-en { display: none !important; }
    body.is-es .lang-es { display: block !important; }
    body.is-es span.lang-es, body.is-es a.lang-es, body.is-es button.lang-es { display: inline-block !important; }
    body.is-es ul.lang-es, body.is-es ol.lang-es { display: block !important; }
    `
    }
    @media (max-width: 640px) {
      .legal-card { padding: 24px 18px; }
      h1 { font-size: 26px; }
      h2 { font-size: 19px; }
    }
  </style>
</head>
<body class="${initialLang === 'es' ? 'is-es' : ''}">
  <header>
    <div class="nav-container">
      <a href="${pure ? (initialLang === 'es' ? '/es' : '/en') : '/'}" class="brand">
        <div class="brand-icon">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>
        </div>
        <span>Listix</span>
      </a>

      <nav class="nav-links">
        <a href="${pure ? (initialLang === 'es' ? '/es' : '/en') : '/'}" class="nav-link">${initialLang === 'es' ? 'Inicio' : 'Home'}</a>
        <a href="${pure ? (initialLang === 'es' ? '/es/privacy' : '/en/privacy') : '/privacy'}" class="nav-link">${initialLang === 'es' ? 'Privacidad' : 'Privacy'}</a>
        ${
          pure
            ? `<a href="${initialLang === 'es' ? '/en/terms' : '/es/terms'}" class="lang-btn">${initialLang === 'es' ? '🌐 English' : '🌐 Español'}</a>`
            : `<button id="lang-toggle-btn" class="lang-btn" type="button" aria-label="Switch Language">
                <span class="lang-en">🌐 Español</span>
                <span class="lang-es">🌐 English</span>
              </button>`
        }
      </nav>
    </div>
  </header>

  <div class="content-wrap">
    <div class="legal-card">
      ${
        pure
          ? initialLang === 'es'
            ? spanishBody
            : englishBody
          : `
        <div class="lang-en">${englishBody}</div>
        <div class="lang-es">${spanishBody}</div>
      `
      }
    </div>
  </div>

  <footer>
    <div>&copy; ${new Date().getFullYear()} Listix. Fast, Private &amp; Offline Shopping Lists.</div>
  </footer>

  ${
    pure
      ? ''
      : `
  <script>
    (function() {
      var btn = document.getElementById('lang-toggle-btn');
      var body = document.body;
      var html = document.getElementById('html-root');

      function setLang(isEs) {
        if (isEs) {
          body.classList.add('is-es');
          html.setAttribute('lang', 'es');
          localStorage.setItem('listix_lang', 'es');
        } else {
          body.classList.remove('is-es');
          html.setAttribute('lang', 'en');
          localStorage.setItem('listix_lang', 'en');
        }
      }

      var saved = localStorage.getItem('listix_lang');
      if (saved) {
        setLang(saved === 'es');
      }

      if (btn) {
        btn.addEventListener('click', function() {
          var isCurrentlyEs = body.classList.contains('is-es');
          setLang(!isCurrentlyEs);
        });
      }
    })();
  </script>
  `
  }
</body>
</html>`;
}
