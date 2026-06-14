# Production data setup

The seed (`supabase/seed.sql`) is **dev-only** (test city Plzeň, test admin). A fresh
production database needs the following real data before launch. Run after
`supabase db push` (see `DEPLOYMENT.md`).

## 1. Countries (referenced by cities)
```sql
INSERT INTO public.countries (code, name) VALUES
  ('CZ', '{"en":"Czech Republic","cs":"Česko"}'),
  ('SK', '{"en":"Slovakia","cs":"Slovensko"}')
ON CONFLICT (code) DO NOTHING;
```
(Add the countries you launch with; `name` is per-language JSONB.)

## 2. Payment / system config (`payment_config`, single row)
```sql
UPDATE public.payment_config SET
  operator_name   = 'PlaceSecrets',            -- real legal operator name
  free_count      = 1,                          -- free places per period
  free_period     = 'day',                      -- 'day' | 'month'
  country_price_eur = 9.99,                      -- price for a country bundle
  revolut_username = '<your-revolut>'            -- optional
WHERE id = 1;
```
Set per-city / per-POI prices in the admin UI (`/admin/cities`, POI editor).

## 3. Initial admin user
1. Create the auth user (dashboard → Authentication → Add user, or have them sign up).
2. Promote to superadmin:
   ```sql
   INSERT INTO public.admin_users (user_id, email, role, pin_hash, must_change_pin)
   VALUES ('<auth-user-uuid>', '<email>', 'superadmin', '<bcrypt-of-temp-pin>', true)
   ON CONFLICT (user_id) DO UPDATE SET role = 'superadmin';
   ```
   (Or use the `invite-contributor` / admin flows once one superadmin exists.)
   `must_change_pin = true` forces a PIN change on first login.

## 4. Cities & POIs
Created via the admin UI (`/admin/cities`, `/admin/pois`) — includes audio upload,
access levels, prices, slugs. No SQL needed.

## 5. Landing page content (optional)
Editable in `/admin/landing` (hero, explore, featured, how-it-works, CTA, footer)
per language. Empty fields fall back to the shipped i18n defaults.

## Checklist before go-live
- [ ] Test city/POIs from `seed.sql` NOT present in prod (only real content).
- [ ] At least one country + one active city with active POIs.
- [ ] `payment_config` prices + free quota set.
- [ ] One superadmin can log in and change PIN.
- [ ] Legal pages show real operator details (see web `legal/` — needs real data + lawyer).
