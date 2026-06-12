# todo-plan.md — cesta k releasovatelnosti place-secrets

Stav po bezpečnostním průchodu (2026-06-12). Blokery (Critical/High) jsou **hotové**
a zacommitnuté (viz `git log`); shrnutí dole. Tento dokument je prioritizovaný seznam
**zbývajících** věcí. Priority: **P1** = před releasem, **P2** = krátce po, **P3** = nice-to-have.

---

## ✅ Hotovo v tomto průchodu (blokery)
- npm zranitelnosti: **19 → 0** (`npm audit fix`; vitest 4.0.18→4.1.8 critical RCE, vite, react-router, dompurify…).
- `git init` + kořenový `.gitignore` + sjednocení monorepa (web mělo vlastní scaffold `.git`).
- `change-admin-pin`: PIN sjednocen na přesně 6 číslic (sdílené `PIN_RE`) — opraven i latentní bug (delší PIN nešel ověřit → lockout).
- migrace `0444` (ověřena `supabase db reset` na lokálním PG): `acl_permissions` SELECT jen pro `authenticated`; dropnut mrtvý sloupec `payment_config.stripe_secret_key`.
- `ForceChangePinPage`: `!user` → `/login` (defense-in-depth).
- `generate_docs.py`: opravena natvrdo zadaná stará cesta `…/HeroDots/…`; PDF přegenerováno.
- testy: web 280 / edge 70 / tsc čistý; přidány regresní testy.

> **Pozn. k verifikaci:** řada „critical" nálezů z automatického review byla po ověření
> u zdroje **false-positive** (storage RLS, stripe-refund fail-open, admin-api auth,
> force-pin guard) — viz `memory/security-audit.md`, Round 3. Nebyly „opraveny", protože
> už byly v pořádku.

---

## P1 — před releasem

1. **Úklid mrtvého top-level `supabase/`** — má prázdné `migrations/` i `functions/`, kanonický je `backend/supabase/`. Ověřit, že nic nereferencuje top-level (`config.toml`), pak smazat. (Riziko záměny při deployi.)
2. **`reset-db.sh` je destruktivní bez potvrzení** — přidat `read -p "type 'yes'…"` před `supabase db reset`. Hrozí omylem wipe. Zároveň přesunout dev creds (`vtm999` / PIN `123456`) z `echo` skriptů do `README`/`.env.example` (nelogovat creds).
3. **Povinné env v dodávaných artefaktech** — ověřit, že produkční build/deploy má reálně k dispozici `VITE_SUPABASE_URL` a `VITE_SUPABASE_ANON_KEY` (viz `web/.env.example`) a že Edge Functions mají v prostředí `STRIPE_SECRET_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, webhook secret. Nasadit a ověřit start z artefaktů, ne jen z lokálu.
4. **Edge funkce — live ověření** — `change-admin-pin` a `ForceChangePinPage` byly ověřeny jen unit/typově. Před releasem projet reálný flow přes `supabase functions serve`: refund bez práv → 403, admin-api bez/neplatný token → 401, force-pin bez session → /login, PIN 6 vs 7 číslic.

## P2 — krátce po releasu

5. **Dependency majory (vite 8 / TS 6 / eslint 10)** — teď **odloženo**: ekosystém není připraven (`i18next` peer `typescript:^5`; `@tailwindcss/vite@4.2.1` drží vite `^7`; eslint 10 nepodporuje `typescript-eslint@8`). Vynucení by vyžadovalo `legacy-peer-deps` → rozbije čistý `npm install`/CI. **Revidovat**, až tailwind/shadcn/i18next vydají kompatibilní peer ranges; pak koordinovaný upgrade + `npm ci` test.
6. **Web bundle 2.5 MB v jednom chunku** — code-splitting (dynamic `import()` pro stránky, `manualChunks` pro `html2canvas`/`jspdf`/mapy). Zrychlí první načtení adminu.
7. **Lint dluh (~21 errors, 10 warnings)** — mimo build/test gate, ale: `react-hooks/set-state-in-effect` (`PoiTypesPage`), `exhaustive-deps`, `vitest.config.ts` triple-slash, shadcn UI komponenty. Projít a opravit nebo cíleně zkonfigurovat pravidla. Zvážit zařazení `npm run lint` do `test.sh`/CI.
8. **Edge-fn hardening (Medium):**
   - `confirm-poi-payment`: UUID validace `user_id`/`poi_id`/`city_id` z Stripe metadat.
   - `invite-contributor`: max délka emailu (254, RFC 5321).
   - `payment-webhook`: striktní `content-type` (přesná shoda, ne `includes`).
   - Sjednotit privilegované zápisy přes `admin-api` — dnes některé `pois` insert/update jdou přímo přes supabase klienta (spoléhá jen na RLS, bez audit logu).
9. **DB RLS (Medium):** `backup_email` (PII) — RLS jen vlastník/service_role; `payment_receipts` service_role → omezit na čtení (audit trail); anon přístup k vlastním device-id ratingům (mig 009); moderační flag u komentářů (mig 042).

## P3 — nice-to-have / proces

10. **CI pipeline** — na PR spouštět `./test.sh` + `npm audit --audit-level=high` (gate na 0 high/critical). Pre-commit hook na secret-scanning (`sk_live`, `BEGIN PRIVATE KEY`).
11. **Generovaný PDF v gitu** — `project-documentation.pdf` je build artefakt; zvážit generování v CI místo commitování binárky.
12. **Konvence migrací** — nepřečíslovávat (riziko u nasazené DB); zavést sekvenční forward-migrace + krátký zápis pořadí do README. Nestandardní názvy (`0400`, `0165`…) ponechat.
13. **CORS** — `create-poi-checkout`/`confirm-poi-payment` mají wildcard `*`; CORS není auth hranice (chrání je JWT/Stripe podpis), ale vyhodnotit allowlist, který zahrne legitimní nákupní origins bez rozbití mobil/web nákupu. Odstranit zastaralý `admin.herodots.app` z allowlistů.
14. **Branding HeroDots → place-secrets** (produkt = `placesecrets`): zbytkové reference v kódu — balíček `cz.tuma.herodots`, `app/herodots.iml`, `operator_name` default v `generate_docs.py:327` a případně v DB. Rozhodnout, zda přejmenovat (balíček je breaking pro store listing) nebo ponechat.
15. **Flutter závislosti** — review napříč majory (mobil), v tomto průchodu needitováno (žádné kriticky zastaralé balíčky nenalezeny).

---

### Jak ověřit (end-to-end)
- Web/testy: `cd web && npm ci && npm run build && npm run lint` + `./test.sh` (cíl: zeleno, `npm audit` 0 high/critical).
- DB: `./reset-db.sh` (po přidání promptu spustit neinteraktivně) → migrace projdou v pořadí; `storage.objects` RLS a privátnost `payment-receipts` ověřit anonymním GETem (musí selhat).
- Deploy: nasadit z artefaktů a ověřit start s reálnými env (ne jen lokál).
