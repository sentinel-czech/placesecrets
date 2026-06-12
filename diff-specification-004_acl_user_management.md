# DIFF-004 – ACL systém & sjednocená správa uživatelů

**Verze:** 004-r1
**Datum:** 2026-03-09
**Týká se:** spec-placesecrets-web.md (Web portal) + backend
**Claude Code:** Implementuj sekce v pořadí: 1–4 (DB) → 5–7 (Edge Functions) → 8–16 (Web)

---

## PŘEHLED ZMĚN

### Sjednocený přihlašovací tok
Všechny role (superadmin, editor, viewer, contributor) sdílí jedinou přihlašovací cestu: email → admin PIN → admin shell. Contributor již nemá separátní `/contributor/*` routy ani vlastní shell.

### Výchozí PIN a povinná změna
Nově vytvořený uživatel (ať už přes „Add New User" v admin UI nebo přes self-registraci contributora) obdrží výchozí PIN `123456` (uložen jako bcrypt hash). Při prvním přihlášení je vynucena změna PINu — bez jejího dokončení nelze pokračovat do admin shellu.

### ACL systém
Oprávnění jsou řízena tabulkou `acl_permissions(role, resource, can_read, can_write, can_delete)`. Superadmin má veškerá práva natvrdo (nelze odebrat). Pro ostatní role lze oprávnění měnit z UI stránky `/admin/acl`.

---

## MATICE OPRÁVNĚNÍ (výchozí stav po migraci)

| Resource | superadmin | editor | contributor | user | viewer |
|---|---|---|---|---|---|
| cities | R/W/D | R | R | R | R |
| pois | R/W/D | R/W | — | R | R |
| own_pois | R/W/D | R/W/D | R/W | — | — |
| poi_types | R/W/D | R | R | R | R |
| users | R/W/D | — | — | — | — |
| payments | R/W/D | — | — | — | — |
| settings | R/W | — | — | — | — |
| acl | R/W | — | — | — | — |
| hall_of_fame | R | R | R | R | R |
| contributors | R/W/D | — | — | — | — |
| own_profile | R/W | R/W | R/W | R/W | — |
| audio | R/W/D | R/W | R/W | R | — |
| dashboard | R | R | R | R | R |

> *📌 Legenda: R = can_read, W = can_write, D = can_delete. Superadmin řádek je immutable — nelze změnit z UI ani z API.*

---

## SEKCE 1 – DB: tabulka `acl_permissions`

**Identifikátor:** D4-001
**Typ:** NOVÉ

### 1.1 Migrace `024_acl_permissions.sql`

```sql
-- ================================================================
-- ACL PERMISSIONS TABLE
-- ================================================================

CREATE TABLE IF NOT EXISTS acl_permissions (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  role        TEXT NOT NULL CHECK (role IN ('superadmin', 'editor', 'viewer', 'contributor', 'user')),
  resource    TEXT NOT NULL CHECK (resource IN (
    'cities', 'pois', 'own_pois', 'poi_types', 'users', 'payments',
    'settings', 'acl', 'hall_of_fame', 'contributors', 'own_profile',
    'audio', 'dashboard'
  )),
  can_read    BOOLEAN NOT NULL DEFAULT FALSE,
  can_write   BOOLEAN NOT NULL DEFAULT FALSE,
  can_delete  BOOLEAN NOT NULL DEFAULT FALSE,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(role, resource)
);

-- updated_at trigger
CREATE TRIGGER acl_permissions_updated_at
  BEFORE UPDATE ON acl_permissions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- RLS
ALTER TABLE acl_permissions ENABLE ROW LEVEL SECURITY;

-- Superadmin can read/write, editor/viewer can read
CREATE POLICY acl_permissions_select ON acl_permissions
  FOR SELECT USING (true);

CREATE POLICY acl_permissions_modify ON acl_permissions
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM admin_users
      WHERE user_id = auth.uid() AND role = 'superadmin'
    )
  );

-- Index
CREATE INDEX idx_acl_permissions_role ON acl_permissions(role);
```

### 1.2 Seed data

Migrace obsahuje `INSERT INTO acl_permissions` pro všechny kombinace z matice oprávnění výše. Celkem 5 rolí × 13 zdrojů = 65 řádků.

```sql
-- Seed: superadmin — full access everywhere
INSERT INTO acl_permissions (role, resource, can_read, can_write, can_delete) VALUES
  ('superadmin', 'cities',       TRUE, TRUE, TRUE),
  ('superadmin', 'pois',         TRUE, TRUE, TRUE),
  ('superadmin', 'own_pois',     TRUE, TRUE, TRUE),
  ('superadmin', 'poi_types',    TRUE, TRUE, TRUE),
  ('superadmin', 'users',        TRUE, TRUE, TRUE),
  ('superadmin', 'payments',     TRUE, TRUE, TRUE),
  ('superadmin', 'settings',     TRUE, TRUE, TRUE),
  ('superadmin', 'acl',          TRUE, TRUE, FALSE),
  ('superadmin', 'hall_of_fame', TRUE, FALSE, FALSE),
  ('superadmin', 'contributors', TRUE, TRUE, TRUE),
  ('superadmin', 'own_profile',  TRUE, TRUE, FALSE),
  ('superadmin', 'audio',        TRUE, TRUE, TRUE),
  ('superadmin', 'dashboard',    TRUE, FALSE, FALSE)
ON CONFLICT (role, resource) DO NOTHING;

-- Seed: editor — can edit all POIs + audio, but NOT users/payments/settings/ACL/contributors
INSERT INTO acl_permissions (role, resource, can_read, can_write, can_delete) VALUES
  ('editor', 'cities',       TRUE, FALSE, FALSE),
  ('editor', 'pois',         TRUE, TRUE, FALSE),
  ('editor', 'own_pois',     TRUE, TRUE, TRUE),
  ('editor', 'poi_types',    TRUE, FALSE, FALSE),
  ('editor', 'users',        FALSE, FALSE, FALSE),
  ('editor', 'payments',     FALSE, FALSE, FALSE),
  ('editor', 'settings',     FALSE, FALSE, FALSE),
  ('editor', 'acl',          FALSE, FALSE, FALSE),
  ('editor', 'hall_of_fame', TRUE, FALSE, FALSE),
  ('editor', 'contributors', FALSE, FALSE, FALSE),
  ('editor', 'own_profile',  TRUE, TRUE, FALSE),
  ('editor', 'audio',        TRUE, TRUE, FALSE),
  ('editor', 'dashboard',    TRUE, FALSE, FALSE)
ON CONFLICT (role, resource) DO NOTHING;

-- Seed: viewer — anonymous browsing: can read public content, NO audio, NO own_profile
INSERT INTO acl_permissions (role, resource, can_read, can_write, can_delete) VALUES
  ('viewer', 'cities',       TRUE, FALSE, FALSE),
  ('viewer', 'pois',         TRUE, FALSE, FALSE),
  ('viewer', 'own_pois',     FALSE, FALSE, FALSE),
  ('viewer', 'poi_types',    TRUE, FALSE, FALSE),
  ('viewer', 'users',        FALSE, FALSE, FALSE),
  ('viewer', 'payments',     FALSE, FALSE, FALSE),
  ('viewer', 'settings',     FALSE, FALSE, FALSE),
  ('viewer', 'acl',          FALSE, FALSE, FALSE),
  ('viewer', 'hall_of_fame', TRUE, FALSE, FALSE),
  ('viewer', 'contributors', FALSE, FALSE, FALSE),
  ('viewer', 'own_profile',  FALSE, FALSE, FALSE),
  ('viewer', 'audio',        FALSE, FALSE, FALSE),
  ('viewer', 'dashboard',    TRUE, FALSE, FALSE)
ON CONFLICT (role, resource) DO NOTHING;

-- Seed: contributor
INSERT INTO acl_permissions (role, resource, can_read, can_write, can_delete) VALUES
  ('contributor', 'cities',       TRUE, FALSE, FALSE),
  ('contributor', 'pois',         FALSE, FALSE, FALSE),
  ('contributor', 'own_pois',     TRUE, TRUE, FALSE),
  ('contributor', 'poi_types',    TRUE, FALSE, FALSE),
  ('contributor', 'users',        FALSE, FALSE, FALSE),
  ('contributor', 'payments',     FALSE, FALSE, FALSE),
  ('contributor', 'settings',     FALSE, FALSE, FALSE),
  ('contributor', 'acl',          FALSE, FALSE, FALSE),
  ('contributor', 'hall_of_fame', TRUE, FALSE, FALSE),
  ('contributor', 'contributors', FALSE, FALSE, FALSE),
  ('contributor', 'own_profile',  TRUE, TRUE, FALSE),
  ('contributor', 'audio',        TRUE, TRUE, FALSE),
  ('contributor', 'dashboard',    TRUE, FALSE, FALSE)
ON CONFLICT (role, resource) DO NOTHING;

-- Seed: user — logged in, can read content + audio (R only), own_profile R/W
INSERT INTO acl_permissions (role, resource, can_read, can_write, can_delete) VALUES
  ('user', 'cities',       TRUE, FALSE, FALSE),
  ('user', 'pois',         TRUE, FALSE, FALSE),
  ('user', 'own_pois',     FALSE, FALSE, FALSE),
  ('user', 'poi_types',    TRUE, FALSE, FALSE),
  ('user', 'users',        FALSE, FALSE, FALSE),
  ('user', 'payments',     FALSE, FALSE, FALSE),
  ('user', 'settings',     FALSE, FALSE, FALSE),
  ('user', 'acl',          FALSE, FALSE, FALSE),
  ('user', 'hall_of_fame', TRUE, FALSE, FALSE),
  ('user', 'contributors', FALSE, FALSE, FALSE),
  ('user', 'own_profile',  TRUE, TRUE, FALSE),
  ('user', 'audio',        TRUE, FALSE, FALSE),
  ('user', 'dashboard',    TRUE, FALSE, FALSE)
ON CONFLICT (role, resource) DO NOTHING;
```

---

## SEKCE 2 – DB: `admin_users.must_change_pin` + výchozí PIN hash

**Identifikátor:** D4-002
**Typ:** ZMĚNA

### 2.1 Migrace `025_must_change_pin.sql`

```sql
-- ================================================================
-- MUST CHANGE PIN FLAG + DEFAULT PIN
-- ================================================================

-- New column: forces PIN change on first login
ALTER TABLE admin_users
  ADD COLUMN IF NOT EXISTS must_change_pin BOOLEAN NOT NULL DEFAULT TRUE;

-- Existing admin users already have their own PINs — mark as changed
UPDATE admin_users SET must_change_pin = FALSE
  WHERE pin_hash IS NOT NULL AND pin_hash != '';
```

### 2.2 Výchozí PIN

  --------------------- -------------------------------------------------
  **Hodnota**           `123456`

  **Uložení**           Bcrypt hash (generován serverově při vytvoření
                        uživatele)

  **Flag**              `must_change_pin = TRUE`

  **Chování**           Po úspěšné verifikaci PINu — pokud
                        `must_change_pin = TRUE` — klient je přesměrován
                        na `ForceChangePinPage` místo admin shellu
  --------------------- -------------------------------------------------

> *📌 Výchozí PIN se NIKDY neposílá e-mailem. Zobrazí se jednorázově v success stránce po registraci nebo v admin UI při vytvoření uživatele.*

---

## SEKCE 3 – DB: trigger `create_admin_user_for_contributor`

**Identifikátor:** D4-003
**Typ:** NOVÉ

### 3.1 Migrace `026_contributor_admin_trigger.sql`

Při self-registraci contributora (INSERT do `contributor_profiles`) se automaticky vytvoří odpovídající řádek v `admin_users` s rolí `contributor`, výchozím PIN hashem a `must_change_pin = TRUE`.

```sql
-- ================================================================
-- AUTO-CREATE admin_users ROW FOR NEW CONTRIBUTORS
-- ================================================================

CREATE OR REPLACE FUNCTION create_admin_user_for_contributor()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  default_pin_hash TEXT;
BEGIN
  -- Bcrypt hash of '123456' (cost factor 10)
  default_pin_hash := crypt('123456', gen_salt('bf', 10));

  INSERT INTO admin_users (user_id, email, role, pin_hash, must_change_pin)
  VALUES (
    NEW.user_id,
    (SELECT email FROM auth.users WHERE id = NEW.user_id),
    'contributor',
    default_pin_hash,
    TRUE
  )
  ON CONFLICT (user_id) DO NOTHING;

  RETURN NEW;
END;
$$;

CREATE TRIGGER contributor_auto_admin_user
  AFTER INSERT ON contributor_profiles
  FOR EACH ROW EXECUTE FUNCTION create_admin_user_for_contributor();

-- Backfill: create admin_users rows for existing contributors without one
INSERT INTO admin_users (user_id, email, role, pin_hash, must_change_pin)
SELECT
  cp.user_id,
  au.email,
  'contributor',
  crypt('123456', gen_salt('bf', 10)),
  TRUE
FROM contributor_profiles cp
JOIN auth.users au ON au.id = cp.user_id
WHERE NOT EXISTS (
  SELECT 1 FROM admin_users adm WHERE adm.user_id = cp.user_id
)
ON CONFLICT (user_id) DO NOTHING;
```

### 3.2 Self-registrace — success screen

Po úspěšné registraci contributora (`/register/contributor`) se zobrazí:

- Potvrzení „Registrace proběhla úspěšně"
- Info box: **„Váš počáteční admin PIN je `123456`. Po prvním přihlášení do admin sekce budete vyzváni k jeho změně."**
- Tlačítko „Přihlásit se do administrace" → `/login` → `/admin-pin`

---

## SEKCE 4 – DB: RPC `get_role_permissions`, `get_all_permissions`

**Identifikátor:** D4-004
**Typ:** NOVÉ

### 4.1 Migrace `027_acl_rpcs.sql`

```sql
-- ================================================================
-- ACL RPCs
-- ================================================================

-- Get permissions for a single role
CREATE OR REPLACE FUNCTION get_role_permissions(target_role TEXT)
RETURNS TABLE (
  resource TEXT,
  can_read BOOLEAN,
  can_write BOOLEAN,
  can_delete BOOLEAN
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT resource, can_read, can_write, can_delete
  FROM acl_permissions
  WHERE role = target_role
  ORDER BY resource;
$$;

-- Get all permissions (for ACL management page)
CREATE OR REPLACE FUNCTION get_all_permissions()
RETURNS TABLE (
  id UUID,
  role TEXT,
  resource TEXT,
  can_read BOOLEAN,
  can_write BOOLEAN,
  can_delete BOOLEAN
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT id, role, resource, can_read, can_write, can_delete
  FROM acl_permissions
  ORDER BY role, resource;
$$;
```

### 4.2 Použití v admin-api

Edge Function `admin-api` volá `get_role_permissions(role)` při každém požadavku a ověřuje, zda má daná role oprávnění pro požadovanou operaci nad daným zdrojem.

---

## SEKCE 5 – Edge Function `verify-admin-pin`: podpora contributor + `must_change_pin`

**Identifikátor:** D4-005
**Typ:** ZMĚNA

### 5.1 Změny

  --------------------- -------------------------------------------------
  **Nový response**     Přidáno pole `must_change_pin: boolean` do
  **field**             úspěšné odpovědi

  **Contributor**       Funkce akceptuje i uživatele s rolí `contributor`
  **role**              (dosud akceptovala pouze `superadmin`, `editor`,
                        `viewer`)

  **Flow**              1. Ověřit PIN (bcrypt compare)
                        2. Pokud OK → vrátit `{ success: true, role,
                        must_change_pin }`
                        3. Klient zkontroluje `must_change_pin` a
                        případně přesměruje na force-change stránku
  --------------------- -------------------------------------------------

### 5.2 Response schema

```json
// Úspěch
{
  "success": true,
  "role": "contributor",
  "must_change_pin": true
}

// Chyba (PIN špatný / locked)
{
  "error": "Invalid PIN",
  "attempts_remaining": 3
}
```

---

## SEKCE 6 – Edge Function `change-admin-pin`: force-change mode

**Identifikátor:** D4-006
**Typ:** ZMĚNA

### 6.1 Nový mode: force-change

  --------------------- -------------------------------------------------
  **Podmínka**          `must_change_pin = TRUE` v `admin_users`

  **Request body**      `{ new_pin: "...", confirm_pin: "..." }`
                        (BEZ `current_pin`)

  **Validace**          `new_pin === confirm_pin`, délka ≥ 6 číslic,
                        nesmí být `123456`

  **Po úspěchu**        1. Uloží nový bcrypt hash
                        2. Nastaví `must_change_pin = FALSE`
                        3. Vrátí `{ success: true }`

  **Bezpečnost**        Funkce ověří, že volající user má skutečně
                        `must_change_pin = TRUE` v DB; jinak vyžaduje
                        `current_pin` jako dosud
  --------------------- -------------------------------------------------

### 6.2 Validační pravidla nového PINu

- Minimální délka: 6 číslic
- Nesmí být `123456` (výchozí)
- Nesmí být sekvence (`123456`, `654321`, `111111`, `000000`)
- `new_pin` musí odpovídat `confirm_pin`

---

## SEKCE 7 – Edge Function `admin-api`: ACL enforcement

**Identifikátor:** D4-007
**Typ:** ZMĚNA

### 7.1 Současný stav

`admin-api` aktuálně kontroluje roli hardcoded — např. `if (role !== 'superadmin') return 403`. Toto bude nahrazeno dynamickým ověřením oprávnění z tabulky `acl_permissions`.

### 7.2 Nový flow

1. Autentizovat uživatele (JWT → `admin_users.role`)
2. Mapovat požadovanou operaci na `(resource, action)`:
   - `SELECT` / `GET` → `can_read`
   - `INSERT` / `UPDATE` / `PATCH` → `can_write`
   - `DELETE` → `can_delete`
3. Zavolat `get_role_permissions(role)` (nebo cachovat per-request)
4. Najít řádek pro odpovídající `resource`
5. Pokud požadovaná akce není povolena → `403 Forbidden`

### 7.3 Mapování tabulek na resources

  --------------------- -------------------------------------------------
  **cities**            `cities`

  **pois**              Pokud `contributor` a operace nad vlastním
                        POI → `own_pois`; jinak `pois`

  **poi_types**         `poi_types`

  **admin_users**,      `users`
  **user_profiles**

  **payment_receipts**, `payments`
  **payment_config**

  **acl_permissions**   `acl`

  **contributor_       `contributors`
  profiles**

  **audio-guides**      `audio` (Storage bucket)
  (Storage)

  **poi_ratings**       `hall_of_fame`
  --------------------- -------------------------------------------------

### 7.4 Superadmin bypass

Superadmin role se v `admin-api` NEKONTROLUJE přes ACL tabulku — má vždy plný přístup. To zajišťuje, že i pokud jsou data v `acl_permissions` poškozena, superadmin může vše opravit.

### 7.5 Ochrana superadmin řádků v ACL

Edge Function odmítne jakýkoliv UPDATE/DELETE na `acl_permissions` kde `role = 'superadmin'`:

```
403 Forbidden: "Superadmin permissions cannot be modified"
```

---

## SEKCE 8 – Web: `AdminGuard` rozšířen o contributor role

**Identifikátor:** D4-008
**Typ:** ZMĚNA

### 8.1 Současný stav

`AdminGuard` propouští pouze role `superadmin`, `editor`, `viewer`. Contributor je směrován do `ContributorShell`.

### 8.2 Změny

- `AdminGuard` akceptuje i roli `contributor`
- Po úspěšné PIN verifikaci zkontroluje `must_change_pin`:
  - `true` → redirect na `/admin/force-change-pin`
  - `false` → propustí do admin shellu
- Odstraněna logika pro redirect na `/contributor/*`

---

## SEKCE 9 – Web: `ForceChangePinPage`

**Identifikátor:** D4-009
**Typ:** NOVÉ

### 9.1 Route

`/admin/force-change-pin`

### 9.2 UI komponenty

  --------------------- -------------------------------------------------
  **Nadpis**            „Změna výchozího PINu"

  **Popis**             „Z bezpečnostních důvodů je nutné změnit výchozí
                        PIN před prvním použitím administrace."

  **Pole 1**            Nový PIN (6+ číslic, input type=password,
                        inputMode=numeric)

  **Pole 2**            Potvrzení PINu (musí souhlasit)

  **Tlačítko**          „Uložit nový PIN"

  **Validace**          Real-time: délka ≥ 6, shoda obou polí, ne
                        `123456`

  **Chybový stav**      Toast / inline error z Edge Function

  **Po úspěchu**        Toast „PIN úspěšně změněn" → redirect na
                        `/admin` (dashboard)
  --------------------- -------------------------------------------------

### 9.3 Ochrana

- Stránka je přístupná POUZE pokud `must_change_pin = TRUE`
- Pokud uživatel nemá `must_change_pin`, redirect na `/admin`
- Nelze stránku obejít — `AdminGuard` vynucuje redirect

---

## SEKCE 10 – Web: `Sidebar` role-aware navigace

**Identifikátor:** D4-010
**Typ:** ZMĚNA

### 10.1 Současný stav

Sidebar zobrazuje všechny admin sekce bez ohledu na roli.

### 10.2 Nové chování

Sidebar načte oprávnění aktuální role (přes `get_role_permissions` nebo z auth store) a zobrazí pouze položky, ke kterým má uživatel `can_read = TRUE`.

### 10.3 Mapování menu → resource

| Menu item | Resource | Viditelnost |
|---|---|---|
| Dashboard | `dashboard` | superadmin, editor, contributor, user |
| Cities | `cities` | superadmin, editor, contributor, user, viewer |
| Places | `pois` nebo `own_pois` | superadmin, editor → `pois`; contributor → `own_pois` |
| Place Types | `poi_types` | superadmin, editor, contributor, user, viewer |
| Users | `users` | superadmin |
| Payments | `payments` | superadmin |
| Contributors | `contributors` | superadmin |
| Hall of Fame | `hall_of_fame` | superadmin, editor, contributor, user, viewer |
| ACL Management | `acl` | superadmin |
| Settings | `settings` | superadmin |
| My Profile | `own_profile` | superadmin, editor, contributor, user |

### 10.4 Contributor menu

Contributor v sidebaru vidí:

- **Dashboard** — svůj přehled (počet POI, návštěvy)
- **My Places** → `/admin/my-pois` — seznam vlastních POI
- **Cities** → `/admin/cities` — read-only seznam měst (pro autocomplete a orientaci)
- **Place Types** → `/admin/poi-types` — read-only
- **Hall of Fame** → `/admin/hall-of-fame`
- **My Profile** → `/admin/profile`
- **← Back to website**

---

## SEKCE 11 – Web: `AdminPinPage` podpora contributor + `must_change_pin` redirect

**Identifikátor:** D4-011
**Typ:** ZMĚNA

### 11.1 Změny

- PIN page akceptuje contributor roli (dosud odmítala)
- Po úspěšné PIN verifikaci zkontroluje response field `must_change_pin`:
  - `true` → `navigate('/admin/force-change-pin')`
  - `false` → `navigate('/admin')` (jako dosud)
- Chybové hlášky zůstávají generické („Invalid PIN" / „Account locked")

---

## SEKCE 12 – Web: rozšířený `InviteAdminForm` → „Add New User"

**Identifikátor:** D4-012
**Typ:** ZMĚNA

### 12.1 Současný stav

Formulář pro pozvánku admina (superadmin-only) umožňuje zadat email a roli (`editor`, `viewer`).

### 12.2 Změny

  --------------------- -------------------------------------------------
  **Název akce**        Přejmenováno z „Invite Admin" na „Add New User"

  **Role dropdown**     Přidána možnost `contributor` (vedle `editor`,
                        `viewer`)

  **Default PIN info**  Pod formulářem info box: „Uživatel obdrží
                        výchozí PIN 123456 a bude vyzván k jeho změně
                        při prvním přihlášení."

  **Volitelné pole**    Jméno (display_name) — vyplní se do
                        `admin_users.display_name` (pokud sloupec
                        existuje)

  **Serverová akce**    Vytvoří `admin_users` řádek s:
                        - email
                        - role
                        - `pin_hash = bcrypt('123456')`
                        - `must_change_pin = TRUE`

  **Success toast**     „Uživatel {email} vytvořen s rolí {role}.
                        Výchozí PIN: 123456"
  --------------------- -------------------------------------------------

### 12.3 Validace

- Email musí být unikátní v `admin_users`
- Role je povinná
- Superadmin nemůže vytvořit dalšího superadmina (role `superadmin` není v dropdown)

---

## SEKCE 13 – Web: ACL Management stránka `/admin/acl`

**Identifikátor:** D4-013
**Typ:** NOVÉ

### 13.1 Route

`/admin/acl` — přístupná pro superadmin (R/W), editor a viewer (R — read-only).

### 13.2 Layout

Tabulková matice (grid) zobrazující role jako sloupce a resources jako řádky. Každá buňka obsahuje 3 checkboxy: Read / Write / Delete.

### 13.3 UI komponenty

  --------------------- -------------------------------------------------
  **Nadpis**            „Access Control Management"

  **Hlavní**            Grid / tabulka:
  **komponenta**        - Řádky: resources (cities, pois, own_pois, …)
                        - Sloupce: role (superadmin, editor, viewer,
                        contributor, user)
                        - Buňka: 3 checkboxy (R/W/D) nebo 3 toggle
                        switche

  **Superadmin**        Sloupec `superadmin` je vizuálně odlišen (šedé
  **sloupec**           pozadí), všechny checkboxy disabled + checked,
                        tooltip: „Superadmin permissions cannot be
                        changed"

  **Uložení**           Tlačítko „Save Changes" — batch UPDATE přes
                        `admin-api`

  **Reset**             Tlačítko „Reset to Defaults" — obnoví výchozí
                        matici z migrace (s confirm dialogem)

  **Indikace změn**     Buňky se změnou oproti uloženému stavu mají
                        žlutý highlight

  **Loading**           Skeleton / spinner při načítání z DB
  --------------------- -------------------------------------------------

### 13.4 Logická pravidla UI

- `can_write = TRUE` automaticky zapne `can_read = TRUE` (nelze zapisovat bez čtení)
- `can_delete = TRUE` automaticky zapne `can_write = TRUE` a `can_read = TRUE`
- Odškrtnutí `can_read` automaticky odškrtne `can_write` i `can_delete`

### 13.5 API flow

1. Načtení: `admin-api` → RPC `get_all_permissions()`
2. Uložení: `admin-api` → batch `UPDATE acl_permissions SET can_read=..., can_write=..., can_delete=... WHERE id=...`
3. Reset: `admin-api` → RPC nebo batch DELETE + re-INSERT z výchozích hodnot

---

## SEKCE 14 – Web: Contributor views v admin shellu

**Identifikátor:** D4-014
**Typ:** ZMĚNA

### 14.1 Nové routy (v rámci admin shellu)

| Route | Komponenta | Popis |
|---|---|---|
| `/admin/my-pois` | `MyPoisPage` | Seznam POI patřících přihlášenému contributorovi |
| `/admin/my-pois/:id` | `MyPoiEditPage` | Edit formulář vlastního POI |
| `/admin/my-pois/new` | `MyPoiNewPage` | Vytvoření nového POI |
| `/admin/profile` | `AdminProfilePage` | Profil přihlášeného admin uživatele |

### 14.2 `MyPoisPage`

  --------------------- -------------------------------------------------
  **Filtr**             Pouze POI kde `contributor_id = currentUser.id`

  **Sloupce**           Název, město, typ, stav, poslední úprava

  **Akce**              Edit, „Add Audio" (otevře audio upload modal)

  **Přidat POI**        Tlačítko „+ New Place" → `/admin/my-pois/new`
  --------------------- -------------------------------------------------

### 14.3 `MyPoiNewPage` — formulář pro nové POI

  --------------------- -------------------------------------------------
  **Město**             Autocomplete / combobox z existujících měst
                        (SELECT z `cities` — contributor NEMŮŽE vytvářet
                        nová města)

  **Typ**               Dropdown z `poi_types`

  **Název**             Vícejazyčný input (JSONB)

  **Popis**             Vícejazyčný textarea (JSONB)

  **GPS**               Lat/lon inputy + „Pick on map" (klik na Leaflet
                        mapu)

  **Fotky**             Upload do `poi-photos` bucketu

  **Audio**             Volitelné — upload do `audio-guides` bucketu

  **Access level**      Výchozí `city_access`, contributor může nastavit
                        `public` nebo `city_access` (ne `premium_poi` —
                        to nastaví pouze superadmin/editor)
  --------------------- -------------------------------------------------

### 14.4 Audio přidání k existujícímu POI

Contributor může přidat audio k POI, které patří jinému contributorovi nebo bylo vytvořeno adminem, pokud má `can_write = TRUE` na resource `audio`:

- Tlačítko „Add Audio" na stránce `/admin/my-pois/:id` nebo v seznamu POI
- Modal s upload zónou (drag & drop nebo file picker)
- Akceptované formáty: MP3, OGG, WAV (max 50 MB)
- Po uploadu se URL uloží do `pois.audio_url` (nebo `poi_premium_content.audio_url` pokud premium)
- Metadata: jazyk audia (dropdown), délka (auto-detect)

> *📌 Contributor nemůže smazat cizí audio — může pouze přidat nové. Přepis existujícího audia vyžaduje `can_delete` na `audio` resource.*

---

## SEKCE 15 – Web: odstranění `ContributorShell` + `/contributor/*` rout

**Identifikátor:** D4-015
**Typ:** ZMĚNA

### 15.1 Co se odstraní

- Komponenta `ContributorShell` (celý soubor)
- Všechny routy pod `/contributor/*`:
  - `/contributor/dashboard`
  - `/contributor/my-pois`
  - `/contributor/my-pois/:id`
  - `/contributor/profile`
- `ContributorGuard` (nahrazen `AdminGuard` s ACL kontrolou)

### 15.2 Redirecty

Pro zpětnou kompatibilitu (bookmarky, sdílené linky):

| Stará route | Nová route |
|---|---|
| `/contributor/dashboard` | `/admin` (dashboard) |
| `/contributor/my-pois` | `/admin/my-pois` |
| `/contributor/my-pois/:id` | `/admin/my-pois/:id` |
| `/contributor/profile` | `/admin/profile` |

Redirecty implementovány jako React Router `<Navigate>` komponenty v route definici.

### 15.3 Soubory ke smazání

- `src/components/ContributorShell.tsx`
- `src/components/ContributorGuard.tsx` (pokud existuje jako separátní soubor)
- `src/pages/contributor/*` (celý adresář)

---

## SEKCE 16 – Web: i18n klíče

**Identifikátor:** D4-016
**Typ:** ZMĚNA

### 16.1 Nové klíče (přidat do všech 11 locale souborů)

```json
{
  "admin": {
    "acl": {
      "title": "Access Control",
      "resource": "Resource",
      "read": "Read",
      "write": "Write",
      "delete": "Delete",
      "saveChanges": "Save Changes",
      "resetDefaults": "Reset to Defaults",
      "resetConfirm": "Reset all permissions to defaults? This cannot be undone.",
      "superadminLocked": "Superadmin permissions cannot be changed",
      "saved": "Permissions saved successfully",
      "noChanges": "No changes to save"
    },
    "users": {
      "addUser": "Add New User",
      "addUserDesc": "Create a new admin panel user",
      "defaultPinInfo": "User will receive default PIN 123456 and will be asked to change it on first login.",
      "userCreated": "User {email} created with role {role}. Default PIN: 123456",
      "roleSuperadmin": "Superadmin",
      "roleEditor": "Editor",
      "roleViewer": "Viewer",
      "roleContributor": "Contributor"
    },
    "forceChangePin": {
      "title": "Change Default PIN",
      "description": "For security reasons, you must change the default PIN before accessing the admin panel.",
      "newPin": "New PIN",
      "confirmPin": "Confirm PIN",
      "submit": "Save New PIN",
      "success": "PIN changed successfully",
      "mismatch": "PINs do not match",
      "tooShort": "PIN must be at least 6 digits",
      "notDefault": "New PIN cannot be the default PIN (123456)",
      "weakPin": "PIN is too simple (sequential or repeated digits)"
    },
    "myPois": {
      "title": "My Places",
      "addNew": "New Place",
      "addAudio": "Add Audio",
      "audioUpload": "Upload Audio Guide",
      "audioFormats": "Accepted formats: MP3, OGG, WAV (max 50 MB)",
      "audioLanguage": "Audio Language",
      "noPois": "You haven't created any places yet.",
      "citySelect": "Select City",
      "citySearchPlaceholder": "Search cities...",
      "cannotCreateCity": "New cities can only be created by administrators."
    }
  },
  "nav": {
    "myPlaces": "My Places",
    "aclManagement": "Access Control"
  }
}
```

### 16.2 Překlady

Všechny nové klíče musí být přeloženy do všech 11 jazyků: EN, CS, SK, DE, ES, FR, PT, RU, VI, ZH, KO.

> *📌 Claude Code přeloží klíče přímo v implementaci — ne strojovým překladačem ale s ohledem na kontext UI.*

---

## IMPLEMENTAČNÍ POKYNY PRO CLAUDE CODE

### Pořadí implementace

1. **Sekce 1–4** (DB migrace) — `024`, `025`, `026`, `027`
2. **Sekce 5–6** (Edge Functions) — `verify-admin-pin`, `change-admin-pin`
3. **Sekce 7** (Edge Function) — `admin-api` ACL enforcement
4. **Sekce 15** (Web) — odstranění ContributorShell + redirecty (nejdříve, aby se předešlo konfliktům)
5. **Sekce 8, 11** (Web) — AdminGuard + AdminPinPage úpravy
6. **Sekce 9** (Web) — ForceChangePinPage
7. **Sekce 10** (Web) — Sidebar role-aware navigace
8. **Sekce 12** (Web) — Add New User formulář
9. **Sekce 14** (Web) — Contributor views v admin shellu
10. **Sekce 13** (Web) — ACL Management stránka
11. **Sekce 16** (Web) — i18n klíče

### Technické závislosti

  --------------------- -------------------------------------------------
  **bcrypt**            Použít existující `bcryptjs` v Edge Functions
                        pro hash výchozího PINu

  **ACL cache**         `admin-api` může cachovat `get_role_permissions`
                        výsledek v rámci jednoho requestu (ne globálně)

  **React Router**      `<Navigate>` pro contributor → admin redirecty

  **Leaflet**           Již nainstalován (z diff-003)

  **i18next**           Již nainstalován (z diff-003)
  --------------------- -------------------------------------------------

### Verifikace

Po implementaci:

- `npm run build` + `tsc --noEmit` — čistý výstup
- Nové migrace se aplikují čistě na lokální Supabase
- Contributor login → PIN → force change → vidí pouze vlastní POI
- Superadmin → ACL stránka → může přepínat oprávnění
- „Add New User" → vytvoří uživatele s default PINem
- Staré `/contributor/*` URL redirectují na `/admin/*`
- Sidebar se dynamicky přizpůsobuje roli přihlášeného uživatele

*--- Konec specifikace Diff #4 ---*
