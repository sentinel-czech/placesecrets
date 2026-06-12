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

## Web env

Copy `web/.env.example` → `web/.env.local` and fill in `VITE_SUPABASE_URL` /
`VITE_SUPABASE_ANON_KEY` (the local stack prints these on `supabase start`).
