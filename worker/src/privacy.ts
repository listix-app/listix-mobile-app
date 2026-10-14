import { sanitizePlayStoreUrl } from './security.ts';

export interface PrivacyPageOptions {
  playStoreUrl?: string;
  supportEmail?: string;
  lang?: string;
  pure?: boolean;
}

export function renderPrivacyPage(options: PrivacyPageOptions = {}): string {
  const playStore = sanitizePlayStoreUrl(options.playStoreUrl);
  const supportEmail = options.supportEmail || 'support@listix.app';
  const initialLang = options.lang === 'es' ? 'es' : 'en';
  const pure = options.pure ?? false;

  const englishBody = `
      <div class="doc-meta">
        Effective Date: October 2026 • Version 1.0
      </div>

      <h1>Privacy Policy for Listix</h1>

      <div class="summary-box">
        <strong>Privacy Summary at a Glance</strong>
        <p>
          Listix is built on an offline-first architecture. We do not require an account or your email address to use the app. Your personal checklists and grocery items are stored locally in an SQLite database on your device. We never sell your personal information.
        </p>
      </div>

      <h2>1. Overview and Core Philosophy</h2>
      <p>
        This Privacy Policy explains how <strong>Listix</strong> ("we", "our", or "the App") handles information when you use our mobile application and related web services. Listix is designed as an ultra-fast, offline-first grocery and checklist utility. Our core engineering principle is minimal data collection and user autonomy.
      </p>

      <h2>2. Data We Do Not Collect</h2>
      <p>Unlike conventional cloud applications, Listix does not request, store, or sell:</p>
      <ul>
        <li>Personal identity records (name, physical address, phone number).</li>
        <li>Forced account credentials (passwords, social media logins).</li>
        <li>Contact lists, phonebooks, or message history.</li>
        <li>Precise GPS geographic location.</li>
        <li>Biometric identifiers or camera/microphone recordings.</li>
      </ul>

      <h2>3. Information Stored Locally on Your Device</h2>
      <p>
        All lists, categories, item descriptions, quantities, and completion statuses created for your personal use are saved exclusively inside your device's private sandboxed SQLite database.
      </p>
      <ul>
        <li><strong>Local Persistence:</strong> This data never leaves your device unless you explicitly use a sharing feature.</li>
        <li><strong>Data Purge:</strong> When you delete an item or a list, it is permanently erased from your local database. Uninstalling the app removes all local database records immediately.</li>
      </ul>

      <h2>4. Collaborative Lists and Cloud Synchronization</h2>
      <p>
        Listix provides an optional feature allowing users to share lists with family members, partners, or roommates in real time:
      </p>
      <ul>
        <li><strong>Supabase Backend:</strong> Shared lists are synchronized using Supabase, an industry-standard database and backend service. Communication is strictly encrypted in transit via TLS 1.3.</li>
        <li><strong>Anonymous Authentication:</strong> To protect your identity, collaboration relies on anonymous, randomly generated tokens. You are never asked to provide an email or identity to join or create a shared list.</li>
        <li><strong>Invites &amp; Tokens:</strong> When you generate an invite link, a cryptographically secure token hash is stored to validate invitees. Once an invite is revoked, access is immediately terminated.</li>
      </ul>

      <h2>5. Advertising and Third-Party SDK Disclosures</h2>
      <p>
        To maintain Listix as a free utility, the application displays banner and interstitial advertisements provided by <strong>Google Mobile Ads (AdMob)</strong>.
      </p>
      <ul>
        <li><strong>Google AdMob SDK:</strong> Google AdMob may collect and process pseudonymous identifiers (such as the Android Advertising ID or iOS IDFA), app interaction data, and coarse diagnostics to serve advertisements and measure ad performance in accordance with Google's Advertising Policies.</li>
        <li><strong>Opt-Out:</strong> You can manage or reset your advertising identifier at any time through your device operating system settings (Android: Settings &gt; Google &gt; Ads; iOS: Settings &gt; Privacy &gt; Tracking).</li>
      </ul>

      <h2>6. Third-Party Sharing Integrations (WhatsApp, Gmail, System Share)</h2>
      <p>
        Listix offers quick-export capabilities to format your shopping list with pending and completed checkboxes:
      </p>
      <ul>
        <li>When you tap the WhatsApp or Gmail share button, Listix generates a plain text string and opens the native operating system share sheet.</li>
        <li>Listix does not read, intercept, or store messages sent through these third-party platforms. Your use of WhatsApp and Gmail is governed by Meta's and Google's respective terms and privacy policies.</li>
      </ul>

      <h2>7. Device Permissions</h2>
      <p>Listix requests only the minimum permissions necessary to function:</p>
      <ul>
        <li><strong>Network Access (INTERNET):</strong> Required for Google AdMob advertisement delivery and for real-time synchronization of shared collaborative lists. Not required for offline list management.</li>
        <li><strong>Notifications:</strong> Required only if you opt to schedule reminders for specific items or tasks. Notifications are scheduled strictly on your local device.</li>
      </ul>

      <h2>8. Data Retention and Deletion Rights</h2>
      <p>
        You have full control over your data:
      </p>
      <ul>
        <li><strong>Local Data:</strong> Can be deleted at any moment by swiping to delete lists or items, or by clearing the application storage via device settings.</li>
        <li><strong>Shared Cloud Lists:</strong> Shared lists can be deleted by the list creator. You may also contact us to request the deletion of any collaborative list data associated with your invite token.</li>
      </ul>

      <h2>9. Children's Privacy</h2>
      <p>
        Listix is not directed toward children under the age of 13. We do not knowingly collect personal information from children. If you believe a child has provided data through our collaborative features, please contact us immediately for prompt deletion.
      </p>

      <h2>10. Changes to This Privacy Policy</h2>
      <p>
        We may update our Privacy Policy periodically to reflect app updates or legal requirements. Any modifications will be posted to this URL with a revised effective date. Continued use of Listix after changes constitutes acceptance.
      </p>

      <h2>11. Contact Information</h2>
      <p>
        If you have questions, feedback, or requests regarding this Privacy Policy or your data, please contact:
      </p>
      <p>
        <strong>Listix Support</strong><br>
        Email: <a href="mailto:${supportEmail}">${supportEmail}</a><br>
        Google Play Listing: <a href="${playStore}" target="_blank" rel="noopener noreferrer">Listix on Google Play</a>
      </p>
  `;

  const spanishBody = `
      <div class="doc-meta">
        Fecha de Vigencia: Octubre 2026 • Versión 1.0
      </div>

      <h1>Política de Privacidad de Listix</h1>

      <div class="summary-box">
        <strong>Resumen de Privacidad en un Vistazo</strong>
        <p>
          Listix está construido sobre una arquitectura offline-first. No requerimos cuentas ni correo electrónico para usar la aplicación. Tus listas y tareas se almacenan de manera local en SQLite dentro de tu dispositivo. Jamás vendemos tu información personal.
        </p>
      </div>

      <h2>1. Descripción General y Filosofía de Privacidad</h2>
      <p>
        Esta Política de Privacidad describe cómo <strong>Listix</strong> ("nosotros", "nuestro" o "la Aplicación") gestiona la información cuando utilizas nuestra aplicación móvil y los servicios web asociados. Listix está diseñada como una herramienta de listas de compras y tareas ultra rápida y 100% offline. Nuestro principio fundamental es la mínima recolección de datos y la autonomía del usuario.
      </p>

      <h2>2. Información que NO Recopilamos</h2>
      <p>A diferencia de las aplicaciones convencionales en la nube, Listix no solicita, almacena ni comercializa:</p>
      <ul>
        <li>Registros de identidad personal (nombre, dirección física, número de teléfono).</li>
        <li>Cuentas o contraseñas forzadas ni accesos por redes sociales.</li>
        <li>Contactos de la libreta telefónica ni registro de mensajes.</li>
        <li>Ubicación geográfica por GPS en tiempo real.</li>
        <li>Identificadores biométricos ni grabaciones de cámara o micrófono.</li>
      </ul>

      <h2>3. Datos Almacenados Localmente en tu Dispositivo</h2>
      <p>
        Todas las listas, categorías, nombres de artículos, cantidades y estados de completado creados para uso personal se guardan exclusivamente dentro de la base de datos local SQLite de tu dispositivo.
      </p>
      <ul>
        <li><strong>Persistencia Local:</strong> Estos datos nunca salen de tu teléfono a menos que decidas compartirlos explícitamente.</li>
        <li><strong>Eliminación Definitiva:</strong> Al borrar un item o lista, se destruye permanentemente de la base de datos local. Desinstalar la app elimina todos los datos locales de inmediato.</li>
      </ul>

      <h2>4. Listas Compartidas y Sincronización en la Nube</h2>
      <p>
        Listix ofrece una función opcional para compartir listas con familiares, pareja o compañeros en tiempo real:
      </p>
      <ul>
        <li><strong>Infraestructura Supabase:</strong> Las listas compartidas se sincronizan mediante Supabase, con cifrado estricto en tránsito a través de TLS 1.3.</li>
        <li><strong>Autenticación Anónima:</strong> Para proteger tu identidad, la colaboración se basa en identificadores anónimos generados al azar. Nunca se te solicitará correo electrónico ni credenciales para unirte a una lista compartida.</li>
        <li><strong>Enlaces e Invitaciones:</strong> Al crear un enlace de invitación, se almacena un hash criptográfico seguro del token para validar a los participantes. Al revocar la invitación, el acceso se interrumpe de inmediato.</li>
      </ul>

      <h2>5. Publicidad y Servicios de Terceros (Google AdMob)</h2>
      <p>
        Para mantener Listix como una herramienta gratuita, la aplicación muestra anuncios en formato banner e intersticial a través de <strong>Google Mobile Ads (AdMob)</strong>.
      </p>
      <ul>
        <li><strong>SDK de Google AdMob:</strong> Google AdMob puede procesar identificadores seudónimos (como el ID de publicidad de Android o IDFA en iOS), información técnica del dispositivo y diagnósticos para el servicio y medición de anuncios de acuerdo con las políticas de Google.</li>
        <li><strong>Control del Usuario:</strong> Puedes restablecer o deshabilitar tu ID de publicidad en cualquier momento desde los ajustes del sistema operativo de tu teléfono (Android: Ajustes &gt; Google &gt; Anuncios).</li>
      </ul>

      <h2>6. Compartir por WhatsApp y Gmail</h2>
      <p>
        Listix incluye la opción de exportar tu lista con formato limpio y casillas de verificación:
      </p>
      <ul>
        <li>Al presionar el botón de WhatsApp o Gmail, Listix genera texto plano y delega el envío a la aplicación oficial mediante el menú del sistema.</li>
        <li>Listix no tiene acceso a tus conversaciones, lista de contactos ni correos enviados.</li>
      </ul>

      <h2>7. Permisos del Dispositivo</h2>
      <p>Listix únicamente requiere los permisos esenciales para su funcionamiento:</p>
      <ul>
        <li><strong>Acceso a Internet (INTERNET):</strong> Necesario para la entrega de anuncios y la sincronización opcional de listas compartidas. La app opera 100% offline para listas locales.</li>
        <li><strong>Notificaciones:</strong> Solicitado únicamente si configuras recordatorios de compras o tareas. Los recordatorios se ejecutan de manera local.</li>
      </ul>

      <h2>8. Retención y Derechos de Eliminación de Datos</h2>
      <p>
        Tienes control absoluto sobre tu información:
      </p>
      <ul>
        <li><strong>Datos Locales:</strong> Puedes eliminarlos deslizando cualquier item o borrando los datos de la app en los ajustes del dispositivo.</li>
        <li><strong>Listas en la Nube:</strong> El creador de la lista puede borrarla en cualquier momento. También puedes escribirnos para solicitar la eliminación de datos de listas vinculadas a un código de invitación.</li>
      </ul>

      <h2>9. Privacidad de Menores</h2>
      <p>
        Listix no está dirigida a menores de 13 años. No recopilamos conscientemente información de menores de edad. Si consideras que un menor ha interactuado con una lista compartida, contáctanos para proceder con su eliminación inmediata.
      </p>

      <h2>10. Modificaciones a esta Política</h2>
      <p>
        Podemos actualizar esta Política de Privacidad de forma periódica. Cualquier actualización se publicará en esta misma dirección web indicando la fecha de entrada en vigencia.
      </p>

      <h2>11. Contacto</h2>
      <p>
        Para consultas, aclaraciones o solicitudes sobre tu privacidad, puedes comunicarte a:
      </p>
      <p>
        <strong>Soporte de Listix</strong><br>
        Correo: <a href="mailto:${supportEmail}">${supportEmail}</a><br>
        Ficha en Google Play: <a href="${playStore}" target="_blank" rel="noopener noreferrer">Listix en Google Play</a>
      </p>
  `;

  return `<!DOCTYPE html>
<html lang="${initialLang}" id="html-root">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${initialLang === 'es' ? 'Política de Privacidad — Listix' : 'Privacy Policy — Listix'}</title>
  <meta name="description" content="Privacy Policy for Listix: Fast, offline-first, private shopping and checklist app. Transparent disclosures regarding local storage, advertising, and data safety.">
  <meta property="og:title" content="Listix Privacy Policy">
  <meta property="og:description" content="Transparent, user-first privacy policy for Listix. Learn how your data is stored locally and securely.">
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
    .summary-box {
      background-color: var(--primary-light);
      border: 1px solid var(--primary-border);
      border-radius: 14px;
      padding: 20px;
      margin-bottom: 32px;
      font-size: 15px;
    }
    .summary-box strong {
      color: var(--primary);
      display: block;
      font-size: 16px;
      margin-bottom: 8px;
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
        <a href="${pure ? (initialLang === 'es' ? '/es/terms' : '/en/terms') : '/terms'}" class="nav-link">${initialLang === 'es' ? 'Términos' : 'Terms'}</a>
        ${
          pure
            ? `<a href="${initialLang === 'es' ? '/en/privacy' : '/es/privacy'}" class="lang-btn">${initialLang === 'es' ? '🌐 English' : '🌐 Español'}</a>`
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
