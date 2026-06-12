# Local development

Local-only helpers and seed data. **None of these are production credentials** — the
seed values exist only in your local Supabase stack created by `./reset-db.sh`.

## Stack

- Canonical backend lives in `backend/supabase/` (migrations + edge functions + `config.toml`).
- Web admin/app in `web/` (see `web/README.md`).

## Scripts

| Script | What it does |
|--------|--------------|
| `./dev.sh` | Start backend + frontend for local dev |
| `./start_backend.sh` | Start local Supabase stack |
| `./start_frontend.sh` | Start the Vite dev server |
| `./reset-db.sh` | **Destructive** — drops, re-applies all migrations and reseeds. Prompts for confirmation; set `FORCE_RESET=1` (or pass `-y`) to skip the prompt in CI. |
| `./test.sh` | Web tests + `tsc --noEmit` + edge-function tests |

## Local seed credentials (local DB only)

After `./reset-db.sh`:

- Superadmin: `vtm@placesecrets.cz` / `vtm999` — admin PIN `123456` (forced change on first admin login)
- Supabase Studio: http://127.0.0.1:54323

## Secret-scan pre-commit hook

Enable once per clone to block commits that contain obvious secrets
(`sk_live…`, private keys, service-role JWTs):

```bash
git config core.hooksPath .githooks
```

CI (`.github/workflows/ci.yml`) runs lint + `tsc` + build + tests + `npm audit --audit-level=high`
on every push/PR.

## Web env

Copy `web/.env.example` → `web/.env.local` and fill in `VITE_SUPABASE_URL` /
`VITE_SUPABASE_ANON_KEY` (the local stack prints these on `supabase start`).

## Production env (must exist before deploy)

Deploying from the built artifacts requires these to be set, or the app/functions
fail at runtime:

**Web build** (`web/`): `VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY` (anon key only —
never the service-role key).

**Edge functions** (Supabase project secrets, `supabase secrets set …`):

| Var | Notes |
|-----|-------|
| `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` | auto-injected by the Supabase Edge runtime |
| `STRIPE_SECRET_KEY` | Stripe API key |
| `STRIPE_POI_WEBHOOK_SECRET` | signing secret for `confirm-poi-payment` |
| `WEBHOOK_SECRET` | signing secret for `payment-webhook` |
| `RESEND_API_KEY` | transactional email (best-effort) |
| `APP_URL` | base URL used in emails/links |

Password reset also needs Supabase **Auth → Email templates / SMTP** configured.
