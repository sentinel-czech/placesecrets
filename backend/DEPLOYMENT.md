# Backend deployment (Supabase)

How to deploy the PlaceSecrets backend (Postgres migrations + 15 Edge Functions)
to a Supabase cloud project. Local dev is in `LOCAL_DEV.md`.

## 0. Prerequisites
- Supabase CLI (`npx supabase`), logged in: `npx supabase login`
- A Supabase project (its ref id, e.g. `abcdxyz`)
- Link the repo to the project (run in `backend/`):
  ```bash
  npx supabase link --project-ref <PROJECT_REF>
  ```

## 1. Apply database migrations
Migrations live in `backend/supabase/migrations/` (forward-only, numbered).
```bash
npx supabase db push          # applies all pending migrations to the linked project
```
Verify a couple of recent objects exist (Supabase SQL editor or psql), e.g.
`user_profiles.fcm_token` (0454), the `payment_receipts_owner_read` storage policy
(0455), and the new `landing_config` section columns (0456).

## 2. Set Edge Function secrets
These are **required** for the corresponding features; a missing secret makes the
function return **503** (configured) or fail. Set them once per environment:
```bash
npx supabase secrets set \
  STRIPE_SECRET_KEY=sk_live_xxx \
  STRIPE_POI_WEBHOOK_SECRET=whsec_xxx \
  COMGATE_MERCHANT=xxxxxx \
  COMGATE_SECRET=xxxxxxxx \
  WEBHOOK_SECRET=$(openssl rand -hex 32) \
  RESEND_API_KEY=re_xxx \
  APP_URL=https://placesecrets.app
npx supabase secrets list      # verify
```
`SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` are injected automatically.

| Secret | Used by | Required for |
|---|---|---|
| `STRIPE_SECRET_KEY` | create-payment-intent, create-poi-checkout, confirm-poi-payment, stripe-refund | Stripe checkout/refunds |
| `STRIPE_POI_WEBHOOK_SECRET` | confirm-poi-payment | Stripe webhook signature |
| `COMGATE_MERCHANT`, `COMGATE_SECRET` | comgate-create, comgate-webhook | Comgate payments (web Buy) |
| `WEBHOOK_SECRET` | payment-webhook | generic payment webhook auth |
| `RESEND_API_KEY` | confirm-payment, generate-receipt, confirm-poi-payment, invite-contributor | transactional email (best-effort) |
| `APP_URL` | comgate-create, create-poi-checkout | success/cancel redirect base |

## 3. Deploy Edge Functions
```bash
for fn in confirm-payment generate-receipt delete-user-data stripe-refund \
  create-payment-intent payment-webhook create-poi-checkout confirm-poi-payment \
  comgate-create comgate-webhook verify-admin-pin change-admin-pin \
  invite-contributor admin-api migrate-anonymous-data; do
  npx supabase functions deploy "$fn"
done
```

## 4. Configure Auth (dashboard)
- **Redirect URLs** (Authentication → URL Configuration): add
  `placesecrets://login-callback` (mobile OAuth) and the web origin(s).
- **Providers**: enable Google / Apple with their client ids/secrets (mobile + web OAuth).
- **Email templates**: confirm signup / reset password (branding optional).

## 5. Production data
See `PRODUCTION_SETUP.md` (countries, initial admin, `payment_config` prices, free quota).

## 6. Webhook endpoints (payment providers)
Point the provider dashboards at the deployed functions:
- Stripe → `https://<ref>.functions.supabase.co/confirm-poi-payment`
- Comgate → `https://<ref>.functions.supabase.co/comgate-webhook`

## Verification
- `npx supabase secrets list` shows all required keys.
- A test purchase in the provider's **test mode** grants an entitlement and produces a receipt.
- `delete-user-data` removes a throwaway test account and writes a `gdpr_account_deletion` audit row.
