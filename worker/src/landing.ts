import { sanitizePlayStoreUrl } from './security.ts';

export interface LandingPageOptions {
  playStoreUrl?: string;
  lang?: string;
  pure?: boolean;
}

export function renderLandingPage(options: LandingPageOptions = {}): string {
  const playStore = sanitizePlayStoreUrl(options.playStoreUrl);
  const initialLang = options.lang === 'es' ? 'es' : 'en';
  const pure = options.pure ?? false;

  const englishHero = `
      <div class="badge">
        ⚡ 100% Offline • Zero Lag • Ultra Private
      </div>
      <h1>The Fastest, <span>100% Offline</span> Shopping &amp; Checklist App</h1>
      <p class="subtitle">
        Never forget an item at the grocery store again. No mandatory account, zero lag, instant WhatsApp and Gmail sharing, and seamless live list collaboration.
      </p>
      <div class="cta-group">
        <a href="${playStore}" target="_blank" rel="noopener noreferrer" class="btn btn-primary">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
            <path d="M3.609 1.814L13.793 12 3.61 22.186c-.198-.184-.31-.448-.31-.734V2.548c0-.286.112-.55.31-.734zm11.242 11.244l2.42 2.42-12.022 6.94 9.602-9.36zm2.42-2.42l-2.42-2.42 9.602-9.36-9.602 9.36 2.42 2.42zm1.058-1.058l3.195 1.844c.638.368.638.97 0 1.338l-3.195 1.844-2.127-2.513 2.127-2.513z"/>
          </svg>
          Get on Google Play
        </a>
        <a href="#features" class="btn btn-secondary">
          Explore Features
        </a>
      </div>
  `;

  const spanishHero = `
      <div class="badge">
        ⚡ 100% Offline • Sin Lag • Máxima Privacidad
      </div>
      <h1>La App de <span>Listas de Compras</span> Más Rápida y 100% Offline</h1>
      <p class="subtitle">
        No vuelvas a olvidar un artículo en el supermercado. Sin registros obligatorios, sin demoras, con envío inmediato por WhatsApp y Gmail y sincronización en tiempo real.
      </p>
      <div class="cta-group">
        <a href="${playStore}" target="_blank" rel="noopener noreferrer" class="btn btn-primary">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
            <path d="M3.609 1.814L13.793 12 3.61 22.186c-.198-.184-.31-.448-.31-.734V2.548c0-.286.112-.55.31-.734zm11.242 11.244l2.42 2.42-12.022 6.94 9.602-9.36zm2.42-2.42l-2.42-2.42 9.602-9.36-9.602 9.36 2.42 2.42zm1.058-1.058l3.195 1.844c.638.368.638.97 0 1.338l-3.195 1.844-2.127-2.513 2.127-2.513z"/>
          </svg>
          Descargar en Google Play
        </a>
        <a href="#features" class="btn btn-secondary">
          Ver Funcionalidades
        </a>
      </div>
  `;

  const englishPreview = `
      <div class="preview-header">
        <span class="preview-title">🛒 Weekly Groceries</span>
        <span class="preview-badge">3 of 5 done</span>
      </div>

      <div class="progress-bar-wrap">
        <div class="progress-bar"></div>
      </div>

      <div class="item-list">
        <div class="item-row completed">
          <div class="check-box checked">
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3"><polyline points="20 6 9 17 4 12"/></svg>
          </div>
          <span>Almond Milk (Unsweetened)</span>
        </div>
        <div class="item-row completed">
          <div class="check-box checked">
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3"><polyline points="20 6 9 17 4 12"/></svg>
          </div>
          <span>Organic Bananas</span>
        </div>
        <div class="item-row completed">
          <div class="check-box checked">
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3"><polyline points="20 6 9 17 4 12"/></svg>
          </div>
          <span>Extra Virgin Olive Oil</span>
        </div>
        <div class="item-row">
          <div class="check-box unchecked"></div>
          <span>Organic Eggs (12-pack)</span>
        </div>
        <div class="item-row">
          <div class="check-box unchecked"></div>
          <span>Whole Wheat Sourdough</span>
        </div>
      </div>

      <div class="preview-share">
        <span>📲 1-Tap Share to WhatsApp</span>
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="9 18 15 12 9 6"/></svg>
      </div>
  `;

  const spanishPreview = `
      <div class="preview-header">
        <span class="preview-title">🛒 Supermercado Semanal</span>
        <span class="preview-badge">3 de 5 listos</span>
      </div>

      <div class="progress-bar-wrap">
        <div class="progress-bar"></div>
      </div>

      <div class="item-list">
        <div class="item-row completed">
          <div class="check-box checked">
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3"><polyline points="20 6 9 17 4 12"/></svg>
          </div>
          <span>Leche de Almendras</span>
        </div>
        <div class="item-row completed">
          <div class="check-box checked">
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3"><polyline points="20 6 9 17 4 12"/></svg>
          </div>
          <span>Plátanos / Bananas</span>
        </div>
        <div class="item-row completed">
          <div class="check-box checked">
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3"><polyline points="20 6 9 17 4 12"/></svg>
          </div>
          <span>Aceite de Oliva Extra Virgen</span>
        </div>
        <div class="item-row">
          <div class="check-box unchecked"></div>
          <span>Huevos del Campo (Docena)</span>
        </div>
        <div class="item-row">
          <div class="check-box unchecked"></div>
          <span>Pan Integral de Masa Madre</span>
        </div>
      </div>

      <div class="preview-share">
        <span>📲 1 Toque para Enviar por WhatsApp</span>
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="9 18 15 12 9 6"/></svg>
      </div>
  `;

  const englishFeatures = `
      <h2 class="section-title">Engineered for Frictionless Shopping</h2>
      <p class="section-subtitle">
        Say goodbye to sluggish cloud checklists. Listix prioritizes lightning-fast local performance, your privacy, and instant sharing.
      </p>

      <div class="features-grid">
        <div class="feature-card">
          <div class="feature-icon">⚡</div>
          <h3>100% Offline &amp; Instant Speed</h3>
          <p>
            Powered by local SQLite persistence. Works with zero lag deep inside supermarket aisles and basements where internet reception drops to zero.
          </p>
        </div>

        <div class="feature-card">
          <div class="feature-icon">📲</div>
          <h3>Instant WhatsApp &amp; Gmail Sharing</h3>
          <p>
            Format pending and completed items with clean checkboxes and export directly to your family, partner, or roommates in a single tap.
          </p>
        </div>

        <div class="feature-card">
          <div class="feature-icon">🔒</div>
          <h3>Private &amp; Secure by Default</h3>
          <p>
            No forced email signups, no mandatory accounts, and no invasive data tracking. Your personal grocery lists stay exclusively on your device.
          </p>
        </div>

        <div class="feature-card">
          <div class="feature-icon">👥</div>
          <h3>Real-Time Collaborative Lists</h3>
          <p>
            Need to coordinate household chores or a party list? Create secure invite links and collaborate in real-time with anonymous sync.
          </p>
        </div>

        <div class="feature-card">
          <div class="feature-icon">🎨</div>
          <h3>Dark Mode &amp; Tactile Gestures</h3>
          <p>
            Clean Material 3 aesthetics with full dark mode support, fluid swipe-to-delete gestures, and satisfying haptic feedback for every item checked.
          </p>
        </div>

        <div class="feature-card">
          <div class="feature-icon">📋</div>
          <h3>Categorized Progress</h3>
          <p>
            Track your shopping route smoothly with collapsible pending and completed groups, dynamic progress bars, and zero screen clutter.
          </p>
        </div>
      </div>
  `;

  const spanishFeatures = `
      <h2 class="section-title">Diseñado para Compras Sin Fricción</h2>
      <p class="section-subtitle">
        Dile adiós a las listas lentas en la nube. Listix prioriza velocidad local instantánea, privacidad absoluta y compartir al instante.
      </p>

      <div class="features-grid">
        <div class="feature-card">
          <div class="feature-icon">⚡</div>
          <h3>100% Offline y Sin Esperas</h3>
          <p>
            Almacenamiento local con SQLite. Funciona con cero lag en pasillos de supermercados y sótanos sin señal móvil ni Wi-Fi.
          </p>
        </div>

        <div class="feature-card">
          <div class="feature-icon">📲</div>
          <h3>Envío Inmediato por WhatsApp y Gmail</h3>
          <p>
            Formatea artículos pendientes y completados con casillas limpias y envíalos directamente a tu familia, pareja o amigos con un solo toque.
          </p>
        </div>

        <div class="feature-card">
          <div class="feature-icon">🔒</div>
          <h3>Privacidad Total Sin Registros</h3>
          <p>
            Sin creación obligatoria de cuentas ni correos forzados. Tus listas personales se guardan únicamente en la memoria de tu dispositivo.
          </p>
        </div>

        <div class="feature-card">
          <div class="feature-icon">👥</div>
          <h3>Listas Compartidas en Vivo</h3>
          <p>
            ¿Necesitas coordinar las compras del hogar? Genera enlaces de invitación seguros y sincroniza en tiempo real sin revelar datos personales.
          </p>
        </div>

        <div class="feature-card">
          <div class="feature-icon">🎨</div>
          <h3>Modo Oscuro y Gestos Táctiles</h3>
          <p>
            Diseño moderno Material 3 con modo oscuro, gestos intuitivos de deslizamiento para eliminar y respuesta háptica al marcar cada item.
          </p>
        </div>

        <div class="feature-card">
          <div class="feature-icon">📋</div>
          <h3>Progreso por Categorías</h3>
          <p>
            Organiza tu recorrido de compra fácilmente con secciones de pendientes y completados, barra de progreso y diseño limpio.
          </p>
        </div>
      </div>
  `;

  const englishComparison = `
      <h2 class="section-title">Why Shoppers Choose Listix</h2>
      <p class="section-subtitle">
        Compare Listix with traditional cloud-only checklist applications.
      </p>

      <div class="comparison-table-wrap">
        <table>
          <thead>
            <tr>
              <th>Feature</th>
              <th>Listix</th>
              <th>Other Cloud Apps</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>Works Inside Supermarkets with No Signal</td>
              <td class="highlight">✅ 100% Offline (SQLite)</td>
              <td>❌ Freezes or spins endlessly</td>
            </tr>
            <tr>
              <td>Mandatory Account Registration</td>
              <td class="highlight">✅ Zero Sign-up Required</td>
              <td>❌ Forced email &amp; passwords</td>
            </tr>
            <tr>
              <td>Direct WhatsApp / Gmail Export</td>
              <td class="highlight">✅ 1-Tap Formatted Share</td>
              <td>❌ Clunky web links or manual copy</td>
            </tr>
            <tr>
              <td>Input Speed &amp; Interaction</td>
              <td class="highlight">✅ Instant (Zero Lag)</td>
              <td>❌ Delayed by remote server calls</td>
            </tr>
            <tr>
              <td>Real-Time Group Sync</td>
              <td class="highlight">✅ Secure Anonymous Invites</td>
              <td>❌ Requires everyone to register</td>
            </tr>
          </tbody>
        </table>
      </div>
  `;

  const spanishComparison = `
      <h2 class="section-title">¿Por Qué Elegir Listix?</h2>
      <p class="section-subtitle">
        Compara Listix frente a las aplicaciones tradicionales que dependen de la nube.
      </p>

      <div class="comparison-table-wrap">
        <table>
          <thead>
            <tr>
              <th>Funcionalidad</th>
              <th>Listix</th>
              <th>Otras Apps en la Nube</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>Funciona en el Supermercado sin Señal</td>
              <td class="highlight">✅ 100% Offline (SQLite)</td>
              <td>❌ Se congela o muestra errores</td>
            </tr>
            <tr>
              <td>Registro Obligatorio de Cuenta</td>
              <td class="highlight">✅ Sin Cuenta ni Contraseña</td>
              <td>❌ Exige correo y datos personales</td>
            </tr>
            <tr>
              <td>Envío Directo por WhatsApp / Gmail</td>
              <td class="highlight">✅ 1 Toque con Formato Limpio</td>
              <td>❌ Enlaces molestos o copiado manual</td>
            </tr>
            <tr>
              <td>Velocidad al Agregar Artículos</td>
              <td class="highlight">✅ Instantáneo (Cero Lag)</td>
              <td>❌ Lento por consultas a servidores</td>
            </tr>
            <tr>
              <td>Sincronización en Grupo</td>
              <td class="highlight">✅ Enlaces de Invitación Anónimos</td>
              <td>❌ Obliga a todos a registrarse</td>
            </tr>
          </tbody>
        </table>
      </div>
  `;

  const englishBanner = `
      <h2>Never Forget a Grocery Item Again</h2>
      <p>Download Listix on Google Play today and experience the fastest, cleanest offline shopping list.</p>
      <a href="${playStore}" target="_blank" rel="noopener noreferrer" class="btn">
        Download Free on Google Play
      </a>
  `;

  const spanishBanner = `
      <h2>No Vuelvas a Olvidar Nada en el Supermercado</h2>
      <p>Descarga Listix en Google Play hoy mismo y disfruta de la lista de compras más rápida y limpia.</p>
      <a href="${playStore}" target="_blank" rel="noopener noreferrer" class="btn">
        Descargar Gratis en Google Play
      </a>
  `;

  return `<!DOCTYPE html>
<html lang="${initialLang}" id="html-root">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${initialLang === 'es' ? 'Listix — Listas de Compras y Tareas Offline | Rápida y Privada' : 'Listix — Offline Shopping &amp; Todo Lists | Fast, Private, Zero Lag'}</title>
  <meta name="description" content="${initialLang === 'es' ? 'Listix es la app de listas de compras y tareas más rápida y 100% offline. Sin registros obligatorios, sin demoras y con envío fácil por WhatsApp y Gmail.' : 'Listix is the fastest, 100% offline shopping and checklist app. No mandatory account, zero lag, instant WhatsApp and Gmail sharing, and real-time list collaboration.'}">
  <meta name="keywords" content="shopping list, grocery list, todo list, offline checklist, share list, pantry tracker, lista de compras, lista supermercado, lista de tareas">
  <meta property="og:title" content="${initialLang === 'es' ? 'Listix — Listas de Compras Rápidas y 100% Offline' : 'Listix — Fast, Private, 100% Offline Shopping Lists'}">
  <meta property="og:description" content="${initialLang === 'es' ? 'No vuelvas a olvidar un artículo en el supermercado. 100% offline y sin demoras.' : 'Never forget an item at the grocery store again. Fast, private, and 100% offline.'}">
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
      --badge-bg: #d1fae5;
      --badge-text: #065f46;
      --accent: #10b981;
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
        --badge-bg: #064e3b;
        --badge-text: #6ee7b7;
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
      line-height: 1.6;
      -webkit-font-smoothing: antialiased;
    }
    a {
      color: var(--primary);
      text-decoration: none;
      transition: color 0.15s ease;
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
      max-width: 1100px;
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
      gap: 12px;
      font-size: 22px;
      font-weight: 800;
      letter-spacing: -0.5px;
      color: var(--text);
      text-decoration: none;
    }
    .brand-icon {
      width: 40px;
      height: 40px;
      background: linear-gradient(135deg, #10b981, #059669);
      border-radius: 12px;
      display: flex;
      align-items: center;
      justify-content: center;
      color: #ffffff;
      box-shadow: 0 4px 12px rgba(5, 150, 105, 0.25);
    }
    .nav-links {
      display: flex;
      align-items: center;
      gap: 20px;
    }
    .nav-link {
      font-size: 14px;
      font-weight: 600;
      color: var(--text-muted);
      text-decoration: none;
    }
    .nav-link:hover {
      color: var(--text);
      text-decoration: none;
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
      display: flex;
      align-items: center;
      gap: 6px;
      transition: background 0.15s ease;
    }
    .lang-btn:hover {
      background: var(--bg);
    }
    .main-wrap {
      max-width: 1100px;
      margin: 0 auto;
      padding: 40px 20px 80px;
    }
    .hero {
      text-align: center;
      padding: 40px 0 60px;
      max-width: 760px;
      margin: 0 auto;
    }
    .badge {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      background-color: var(--badge-bg);
      color: var(--badge-text);
      padding: 6px 14px;
      border-radius: 9999px;
      font-size: 13px;
      font-weight: 700;
      margin-bottom: 20px;
      letter-spacing: 0.3px;
      text-transform: uppercase;
    }
    h1 {
      font-size: 44px;
      font-weight: 800;
      letter-spacing: -1px;
      line-height: 1.15;
      margin-bottom: 20px;
    }
    h1 span {
      background: linear-gradient(135deg, #10b981, #059669);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
    }
    .subtitle {
      font-size: 19px;
      color: var(--text-muted);
      line-height: 1.5;
      margin-bottom: 32px;
    }
    .cta-group {
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 16px;
      flex-wrap: wrap;
      margin-bottom: 40px;
    }
    .btn {
      display: inline-flex;
      align-items: center;
      gap: 10px;
      padding: 14px 26px;
      border-radius: 14px;
      font-size: 16px;
      font-weight: 700;
      text-decoration: none;
      transition: all 0.15s ease;
      cursor: pointer;
      border: none;
    }
    .btn-primary {
      background-color: var(--primary);
      color: #ffffff;
      box-shadow: 0 4px 14px rgba(5, 150, 105, 0.3);
    }
    .btn-primary:hover {
      background-color: var(--primary-hover);
      transform: translateY(-2px);
      text-decoration: none;
    }
    .btn-secondary {
      background-color: var(--card-bg);
      color: var(--text);
      border: 1px solid var(--border);
    }
    .btn-secondary:hover {
      background-color: var(--bg);
      text-decoration: none;
    }
    .app-preview-card {
      background-color: var(--card-bg);
      border: 1px solid var(--border);
      border-radius: 24px;
      box-shadow: var(--shadow);
      max-width: 440px;
      margin: 0 auto 80px;
      padding: 24px;
      text-align: left;
    }
    .preview-header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      margin-bottom: 16px;
    }
    .preview-title {
      font-size: 18px;
      font-weight: 700;
    }
    .preview-badge {
      background: var(--primary-light);
      color: var(--primary);
      padding: 4px 10px;
      border-radius: 9999px;
      font-size: 12px;
      font-weight: 600;
    }
    .progress-bar-wrap {
      background: var(--bg);
      border-radius: 9999px;
      height: 8px;
      overflow: hidden;
      margin-bottom: 16px;
      border: 1px solid var(--border);
    }
    .progress-bar {
      width: 60%;
      height: 100%;
      background: linear-gradient(90deg, #10b981, #059669);
      border-radius: 9999px;
    }
    .item-list {
      display: flex;
      flex-direction: column;
      gap: 10px;
      margin-bottom: 20px;
    }
    .item-row {
      display: flex;
      align-items: center;
      gap: 12px;
      padding: 10px 12px;
      background: var(--bg);
      border: 1px solid var(--border);
      border-radius: 12px;
      font-size: 15px;
    }
    .item-row.completed {
      opacity: 0.6;
      text-decoration: line-through;
    }
    .check-box {
      width: 20px;
      height: 20px;
      border-radius: 6px;
      display: flex;
      align-items: center;
      justify-content: center;
      flex-shrink: 0;
    }
    .check-box.checked {
      background-color: var(--primary);
      color: #ffffff;
    }
    .check-box.unchecked {
      border: 2px solid var(--border);
    }
    .preview-share {
      background: var(--primary-light);
      border: 1px dashed var(--primary-border);
      border-radius: 12px;
      padding: 12px;
      display: flex;
      align-items: center;
      justify-content: space-between;
      font-size: 13px;
      font-weight: 600;
      color: var(--primary);
    }
    .section-title {
      text-align: center;
      font-size: 32px;
      font-weight: 800;
      letter-spacing: -0.5px;
      margin-bottom: 12px;
    }
    .section-subtitle {
      text-align: center;
      font-size: 17px;
      color: var(--text-muted);
      margin-bottom: 48px;
      max-width: 620px;
      margin-left: auto;
      margin-right: auto;
    }
    .features-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
      gap: 24px;
      margin-bottom: 80px;
    }
    .feature-card {
      background-color: var(--card-bg);
      border: 1px solid var(--border);
      border-radius: 20px;
      padding: 28px;
      box-shadow: var(--shadow);
      display: flex;
      flex-direction: column;
      gap: 14px;
    }
    .feature-icon {
      width: 48px;
      height: 48px;
      border-radius: 14px;
      background: var(--primary-light);
      color: var(--primary);
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 22px;
    }
    .feature-card h3 {
      font-size: 19px;
      font-weight: 700;
    }
    .feature-card p {
      font-size: 15px;
      color: var(--text-muted);
      line-height: 1.6;
    }
    .comparison-table-wrap {
      background-color: var(--card-bg);
      border: 1px solid var(--border);
      border-radius: 20px;
      overflow-x: auto;
      box-shadow: var(--shadow);
      margin-bottom: 80px;
    }
    table {
      width: 100%;
      border-collapse: collapse;
      text-align: left;
      font-size: 15px;
    }
    th, td {
      padding: 16px 20px;
      border-bottom: 1px solid var(--border);
    }
    th {
      background-color: var(--bg);
      font-weight: 700;
      font-size: 14px;
      text-transform: uppercase;
      letter-spacing: 0.5px;
      color: var(--text-muted);
    }
    td.highlight {
      font-weight: 700;
      color: var(--primary);
      background-color: var(--primary-light);
    }
    .cta-banner {
      background: linear-gradient(135deg, #10b981, #059669);
      color: #ffffff;
      border-radius: 24px;
      padding: 48px 32px;
      text-align: center;
      margin-bottom: 60px;
      box-shadow: 0 16px 32px rgba(5, 150, 105, 0.25);
    }
    .cta-banner h2 {
      font-size: 32px;
      font-weight: 800;
      margin-bottom: 12px;
    }
    .cta-banner p {
      font-size: 18px;
      opacity: 0.9;
      margin-bottom: 28px;
      max-width: 580px;
      margin-left: auto;
      margin-right: auto;
    }
    .cta-banner .btn {
      background-color: #ffffff;
      color: #059669;
    }
    .cta-banner .btn:hover {
      background-color: #f8fafc;
      color: #047857;
    }
    footer {
      border-top: 1px solid var(--border);
      background-color: var(--card-bg);
      padding: 40px 20px;
      font-size: 14px;
      color: var(--text-muted);
    }
    .footer-container {
      max-width: 1100px;
      margin: 0 auto;
      display: flex;
      flex-direction: column;
      gap: 20px;
    }
    .footer-top {
      display: flex;
      align-items: center;
      justify-content: space-between;
      flex-wrap: wrap;
      gap: 16px;
    }
    .footer-links {
      display: flex;
      gap: 20px;
      flex-wrap: wrap;
    }
    .footer-links a {
      color: var(--text-muted);
      font-weight: 600;
    }
    .footer-links a:hover {
      color: var(--text);
    }
    .footer-bottom {
      display: flex;
      align-items: center;
      justify-content: space-between;
      border-top: 1px solid var(--border);
      padding-top: 20px;
      font-size: 13px;
    }
    ${
      pure
        ? ''
        : `
    .lang-es { display: none; }
    .lang-en { display: block; }
    span.lang-es, a.lang-es, button.lang-es, div.lang-es { display: none; }
    span.lang-en, a.lang-en, button.lang-en, div.lang-en { display: inline-block; }
    div.lang-en, p.lang-en, h1.lang-en, h2.lang-en, h3.lang-en, section.lang-en, table.lang-en { display: block; }
    div.lang-es, p.lang-es, h2.lang-es, h3.lang-es, section.lang-es, table.lang-es { display: none; }
    body.is-es .lang-en { display: none !important; }
    body.is-es .lang-es { display: block !important; }
    body.is-es span.lang-es, body.is-es a.lang-es, body.is-es button.lang-es { display: inline-block !important; }
    body.is-es table.lang-es { display: table !important; }
    `
    }
    @media (max-width: 640px) {
      h1 { font-size: 32px; }
      .subtitle { font-size: 16px; }
      .main-wrap { padding: 20px 16px 60px; }
      .cta-banner { padding: 32px 20px; }
    }
  </style>
</head>
<body class="${initialLang === 'es' ? 'is-es' : ''}">
  <header>
    <div class="nav-container">
      <a href="${pure ? (initialLang === 'es' ? '/es' : '/en') : '/'}" class="brand">
        <div class="brand-icon">
          <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
            <polyline points="20 6 9 17 4 12"/>
          </svg>
        </div>
        <span>Listix</span>
      </a>

      <nav class="nav-links">
        <a href="#features" class="nav-link">${initialLang === 'es' ? 'Funciones' : 'Features'}</a>
        <a href="#comparison" class="nav-link">${initialLang === 'es' ? 'Por qué Listix' : 'Why Listix'}</a>
        <a href="${pure ? (initialLang === 'es' ? '/es/privacy' : '/en/privacy') : '/privacy'}" class="nav-link">${initialLang === 'es' ? 'Privacidad' : 'Privacy'}</a>
        <a href="${pure ? (initialLang === 'es' ? '/es/terms' : '/en/terms') : '/terms'}" class="nav-link">${initialLang === 'es' ? 'Términos' : 'Terms'}</a>
        ${
          pure
            ? `<a href="${initialLang === 'es' ? '/en' : '/es'}" class="lang-btn">${initialLang === 'es' ? '🌐 English' : '🌐 Español'}</a>`
            : `<button id="lang-toggle-btn" class="lang-btn" type="button" aria-label="Switch Language">
                <span class="lang-en">🌐 ES</span>
                <span class="lang-es">🌐 EN</span>
              </button>`
        }
      </nav>
    </div>
  </header>

  <main class="main-wrap">
    <section class="hero">
      ${
        pure
          ? initialLang === 'es'
            ? spanishHero
            : englishHero
          : `
        <div class="lang-en">${englishHero}</div>
        <div class="lang-es">${spanishHero}</div>
      `
      }
    </section>

    <div class="app-preview-card">
      ${
        pure
          ? initialLang === 'es'
            ? spanishPreview
            : englishPreview
          : `
        <div class="lang-en">${englishPreview}</div>
        <div class="lang-es">${spanishPreview}</div>
      `
      }
    </div>

    <section id="features">
      ${
        pure
          ? initialLang === 'es'
            ? spanishFeatures
            : englishFeatures
          : `
        <div class="lang-en">${englishFeatures}</div>
        <div class="lang-es">${spanishFeatures}</div>
      `
      }
    </section>

    <section id="comparison">
      ${
        pure
          ? initialLang === 'es'
            ? spanishComparison
            : englishComparison
          : `
        <div class="lang-en">${englishComparison}</div>
        <div class="lang-es">${spanishComparison}</div>
      `
      }
    </section>

    <div class="cta-banner">
      ${
        pure
          ? initialLang === 'es'
            ? spanishBanner
            : englishBanner
          : `
        <div class="lang-en">${englishBanner}</div>
        <div class="lang-es">${spanishBanner}</div>
      `
      }
    </div>
  </main>

  <footer>
    <div class="footer-container">
      <div class="footer-top">
        <a href="${pure ? (initialLang === 'es' ? '/es' : '/en') : '/'}" class="brand">
          <div class="brand-icon">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>
          </div>
          <span>Listix</span>
        </a>
        <div class="footer-links">
          <a href="${pure ? (initialLang === 'es' ? '/es/privacy' : '/en/privacy') : '/privacy'}">${initialLang === 'es' ? 'Política de Privacidad' : 'Privacy Policy'}</a>
          <a href="${pure ? (initialLang === 'es' ? '/es/terms' : '/en/terms') : '/terms'}">${initialLang === 'es' ? 'Términos del Servicio' : 'Terms of Service'}</a>
          <a href="${playStore}" target="_blank" rel="noopener noreferrer">Google Play</a>
        </div>
      </div>
      <div class="footer-bottom">
        <div>&copy; ${new Date().getFullYear()} Listix. ${initialLang === 'es' ? 'Todos los derechos reservados.' : 'All rights reserved.'}</div>
        <div>${initialLang === 'es' ? 'Listas de compras rápidas, privadas y 100% offline' : 'Fast, Private &amp; Offline Shopping Lists'}</div>
      </div>
    </div>
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
