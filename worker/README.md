# Listix Invite Worker (Cloudflare Workers)

Cloudflare Worker implemented in **TypeScript** to handle Listix list invitation links and native **Android App Links** verification.

---

## 🎯 Features

- **ASO Landing Page & Static Website**: `GET /`
  - High-converting landing page optimized following **App Store Optimization (ASO)** strategy and keywords (`shopping list`, `grocery list`, `offline checklist`, `lista de compras`, etc.).
  - Showcases core value pillars: 100% Offline SQLite speed, 1-tap WhatsApp and Gmail sharing, real-time collaboration, and zero forced account signups.
  - Interactive feature showcase, competitor comparison matrix, and direct Google Play download CTA.
  - Interactive English / Spanish language switcher.
  - Content negotiation: serves JSON (`{"status":"ok", ...}`) when requested with `Accept: application/json` or `?format=json`.
- **Privacy Policy**: `GET /privacy` (aliases: `/privacy-policy`)
  - Complete, Google Play Data Safety and App Store compliant Privacy Policy.
  - Transparent disclosures on local SQLite persistence, anonymous Supabase sync, Google Mobile Ads (AdMob) advertising identifiers, and user data deletion rights.
  - Bilingual (English and Spanish) with instant UI toggle and `?lang=` query support.
- **Terms of Service**: `GET /terms` (aliases: `/terms-of-service`, `/terms-and-conditions`)
  - Comprehensive Terms of Service covering acceptable use, offline architecture disclaimer, third-party services, and intellectual property.
  - Bilingual (English and Spanish) with instant UI toggle and `?lang=` query support.
- **Static Website Assets**: Located in `worker/public/` (`index.html`, `privacy.html`, `terms.html`, `styles.css`) for static hosting or Cloudflare Pages deployment.
- **Invite Endpoint**: `GET /join/:token`
  - Validates token format (sanitizes against injections and illegal characters).
  - Calculates SHA-256 cryptographic hash identically to the Flutter mobile client.
  - Validates invite status atomically in **Supabase**:
    - Existing token hash.
    - Active invite (not revoked).
    - Unexpired invite (`expires_at > now()`).
    - Valid, non-deleted list (`deleted_at IS NULL`).
    - Active member limit enforcement (< 5 members) protected against race conditions via `pg_advisory_xact_lock`.
  - For valid invites:
    - Prepares deep link app handover (`listix://join/:token` and Android Intent).
    - Serves a clean, responsive landing page with list name, member counts, and one-tap invite code copy button.
    - Provides a direct installation button configured via `PLAY_STORE_URL`.
  - For invalid, expired, or full lists (5/5 members):
    - Displays an informative, branded error card with fallback actions.
  - Supports structured JSON responses for API clients (`Accept: application/json` or `?format=json`).
- **Android App Links**: `GET /.well-known/assetlinks.json`
  - Serves Digital Asset Links with package name and SHA-256 certificate fingerprints for seamless OS-level link handling without browser prompts.
- **Healthcheck**: `GET /health` and `GET /`

---

## 🔐 Cloudflare Secrets Configuration

In production, configure required secrets using Wrangler:

```bash
# Supabase project URL
npx wrangler secret put SUPABASE_URL

# Supabase Service Role Key (Privileged, NEVER expose to the mobile app)
npx wrangler secret put SUPABASE_SERVICE_ROLE_KEY

# Google Play Store URL (Optional if using default in wrangler.jsonc)
npx wrangler secret put PLAY_STORE_URL
```

---

## 💻 Local Development

1. Install dependencies:

```bash
cd worker
npm install
```

2. Configure local variables by creating `.dev.vars` from the example template:

```bash
cp .dev.vars.example .dev.vars
```

Edit `.dev.vars` with your Supabase credentials:

```env
SUPABASE_URL="https://your-project-ref.supabase.co"
SUPABASE_SERVICE_ROLE_KEY="eyJhbGciOi..."
PLAY_STORE_URL="https://play.google.com/store/apps/details?id=com.nmenag.listix"
```

3. Start the local development server:

```bash
# From worker directory:
npx wrangler dev

# Or from repository root:
npx wrangler dev
```

The worker runs locally at `http://localhost:8787`.

---

## 🧪 Unit Tests & Type Checking

```bash
# Run TypeScript type check
npm run typecheck

# Run unit tests (Node.js native test runner)
npm test
```

---

## 🚀 Deployment

To deploy to Cloudflare Workers:

```bash
npx wrangler deploy
```

---

## 🔍 Testing `/join/:token`

### 1. Healthcheck verification

```bash
curl -i http://localhost:8787/health
```

### 2. Android Asset Links verification

```bash
curl -i http://localhost:8787/.well-known/assetlinks.json
```

### 3. Invalid token format test

```bash
curl -i http://localhost:8787/join/bad?format=json
```

Response (HTTP 400):
```json
{
  "valid": false,
  "errorCode": "INVALID_TOKEN_FORMAT",
  "message": "El código de invitación proporcionado tiene un formato no válido."
}
```

### 4. Real invite test via browser or curl

Open in your browser:
```text
http://localhost:8787/join/<your-token>
```
Or via curl:
```bash
curl -i http://localhost:8787/join/<your-token>?format=json
```
