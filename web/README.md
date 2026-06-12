# place-secrets — Admin Web

Vite + React 18 + TypeScript + Tailwind admin panel for the place-secrets POI
AudioGuide platform. Talks to the shared Supabase backend (`../backend/supabase`).

## Setup

```bash
npm install
cp .env.example .env.local   # then fill in VITE_SUPABASE_URL / VITE_SUPABASE_ANON_KEY
npm run dev                  # Vite dev server on http://localhost:5173
```

Environment variables (see `.env.example`):

| Variable | Purpose |
|----------|---------|
| `VITE_SUPABASE_URL` | Supabase project URL |
| `VITE_SUPABASE_ANON_KEY` | Supabase **anon** (public) key — safe in the browser bundle |

> The `service_role` key and Stripe secret key are **never** used in the client.
> All privileged operations go through the `admin-api` Edge Function, which
> validates the caller's JWT and admin role server-side. The Stripe secret is read
> only from the `STRIPE_SECRET_KEY` env var inside Edge Functions.

## Scripts

```bash
npm run dev       # dev server
npm run build     # type-check (tsc -b) + production build
npm run preview   # preview the production build
npm run lint      # eslint
npm test          # vitest (run once)
```

Run the whole project test suite (web + types + edge functions) from the repo root:

```bash
./test.sh
```

## Security notes

- Auth/role gating is enforced server-side in Edge Functions; client guards
  (`AdminGuard`) are UX only. `/admin/force-change-pin` deliberately sits outside
  `AdminGuard` (AdminGuard redirects `mustChangePin` users to it, so nesting it
  would loop) and instead checks for a live session itself.
- Admin PINs are exactly 6 digits, bcrypt-hashed, with brute-force lockout.
- Keep dependencies clean: `npm audit` should report 0 vulnerabilities.
