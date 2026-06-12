# DIFF-002 – Přístupové úrovně POI + Prémiový obsah + Smart URI sdílení
**Verze:** 002-r2 (kompletní přepis po auditu)
**Datum:** 2026-03-07
**Týká se:** spec-placesecrets-web.md + specification-prompts.md (Flutter app)
**Claude Code:** Implementuj sekce v pořadí: 1 (DB) → 2 (Edge Functions) → 3 (Admin panel) → 4 (Flutter) → 5 (Smart URI)

---

## PŘEHLED ZMĚN

### Čtyřúrovňový přístupový model

| Úroveň | Kdo | Co vidí | Cena |
|---|---|---|---|
| `public` | Kdokoliv (anonymní) | Pin + název + perex (2 věty) + foto | zdarma |
| `registered` | Přihlášený uživatel | 1 sample místo per oblast zdarma (základní text + audio) | zdarma |
| `city_access` | Zakoupil oblast | Veškerý základní obsah všech POI v oblasti | nastavitelné adminem (např. 1 EUR) |
| `premium_poi` | Zakoupil POI nebo bundle | Prémiový audio + text + extra fotky + related POI panel | nastavitelné adminem per POI nebo jako bundle |

### Smart URI systém
Každé POI dostane unikátní sdílitelnou URL ve formátu:
`placesecrets.app/place/{city-slug}/{poi-slug}`

---

## SEKCE 1 – DATABÁZE

### 1.1 Migrace `010_access_levels.sql`

```sql
-- ================================================================
-- ACCESS LEVELS + PREMIUM CONTENT + SMART URI
-- ================================================================

-- 1. Slug pro POI (pro smart URI)
ALTER TABLE pois ADD COLUMN IF NOT EXISTS slug TEXT;
ALTER TABLE pois ADD COLUMN IF NOT EXISTS access_level TEXT
  NOT NULL DEFAULT 'city_access'
  CHECK (access_level IN ('public', 'registered', 'city_access', 'premium_poi'));
ALTER TABLE pois ADD COLUMN IF NOT EXISTS perex TEXT;
ALTER TABLE pois ADD COLUMN IF NOT EXISTS premium_price NUMERIC(10,2);

-- Slug pro areas (pokud ještě nemají)
ALTER TABLE areas ADD COLUMN IF NOT EXISTS slug TEXT;

-- Unikátní indexy pro slugy
CREATE UNIQUE INDEX IF NOT EXISTS pois_slug_area_idx ON pois(slug, area_id);
CREATE UNIQUE INDEX IF NOT EXISTS areas_slug_idx ON areas(slug);

-- Funkce pro generování slugu z textu
CREATE OR REPLACE FUNCTION slugify(input TEXT)
RETURNS TEXT
LANGUAGE plpgsql IMMUTABLE
AS $$
BEGIN
  RETURN lower(
    regexp_replace(
      regexp_replace(
        translate(
          input,
          'áäčďéěíľňóöřšťúůüýžÁÄČĎÉĚÍĽŇÓÖŘŠŤÚŮÜÝŽ',
          'aacdeeillnoorstuuuyzAACDEEILLNOORSTUUUYZ'
        ),
        '[^a-zA-Z0-9\s-]', '', 'g'
      ),
      '\s+', '-', 'g'
    )
  );
END;
$$;

-- Trigger: automaticky generuj slug při INSERT pokud není zadán
CREATE OR REPLACE FUNCTION pois_auto_slug()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
  base_slug TEXT;
  final_slug TEXT;
  counter INTEGER := 0;
BEGIN
  IF NEW.slug IS NULL OR NEW.slug = '' THEN
    base_slug := slugify(
      COALESCE(NEW.name->>'cs', NEW.name->>'en', NEW.name::TEXT, 'poi')
    );
    final_slug := base_slug;
    -- Zajistit unikátnost v rámci oblasti
    WHILE EXISTS (
      SELECT 1 FROM pois WHERE slug = final_slug AND area_id = NEW.area_id AND id != NEW.id
    ) LOOP
      counter := counter + 1;
      final_slug := base_slug || '-' || counter;
    END LOOP;
    NEW.slug := final_slug;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER pois_slug_trigger
  BEFORE INSERT OR UPDATE ON pois
  FOR EACH ROW EXECUTE FUNCTION pois_auto_slug();

-- Trigger pro areas
CREATE OR REPLACE FUNCTION areas_auto_slug()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
  base_slug TEXT;
  final_slug TEXT;
  counter INTEGER := 0;
BEGIN
  IF NEW.slug IS NULL OR NEW.slug = '' THEN
    base_slug := slugify(
      COALESCE(NEW.name->>'cs', NEW.name->>'en', NEW.name::TEXT, 'area')
    );
    final_slug := base_slug;
    WHILE EXISTS (SELECT 1 FROM areas WHERE slug = final_slug AND id != NEW.id) LOOP
      counter := counter + 1;
      final_slug := base_slug || '-' || counter;
    END LOOP;
    NEW.slug := final_slug;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER areas_slug_trigger
  BEFORE INSERT OR UPDATE ON areas
  FOR EACH ROW EXECUTE FUNCTION areas_auto_slug();

-- Zpětně vygeneruj slugy pro existující záznamy
UPDATE pois SET slug = NULL WHERE slug IS NULL OR slug = '';
UPDATE areas SET slug = NULL WHERE slug IS NULL OR slug = '';

-- 2. Prémiový obsah POI
CREATE TABLE IF NOT EXISTS poi_premium_content (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  poi_id      UUID NOT NULL REFERENCES pois(id) ON DELETE CASCADE,
  audio_url   TEXT,
  text_content TEXT,
  extra_photos JSONB DEFAULT '[]',
  related_poi_ids UUID[] DEFAULT '{}',
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(poi_id)
);

-- updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$;

CREATE TRIGGER poi_premium_content_updated_at
  BEFORE UPDATE ON poi_premium_content
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- 3. Ceny oblastí
ALTER TABLE areas ADD COLUMN IF NOT EXISTS registered_sample_poi_id UUID
  REFERENCES pois(id) ON DELETE SET NULL;
ALTER TABLE areas ADD COLUMN IF NOT EXISTS premium_bundle_price NUMERIC(10,2);
ALTER TABLE areas ADD COLUMN IF NOT EXISTS city_access_price NUMERIC(10,2);

-- 4. Nákupy POI
CREATE TABLE IF NOT EXISTS user_poi_purchases (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  poi_id       UUID NOT NULL REFERENCES pois(id) ON DELETE CASCADE,
  purchased_at TIMESTAMPTZ DEFAULT NOW(),
  price_paid   NUMERIC(10,2),
  payment_id   TEXT,
  stripe_session_id TEXT,
  UNIQUE(user_id, poi_id)
);

-- Nákupy premium bundle oblasti
CREATE TABLE IF NOT EXISTS user_area_premium_purchases (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  area_id      UUID NOT NULL REFERENCES areas(id) ON DELETE CASCADE,
  purchased_at TIMESTAMPTZ DEFAULT NOW(),
  price_paid   NUMERIC(10,2),
  payment_id   TEXT,
  stripe_session_id TEXT,
  UNIQUE(user_id, area_id)
);

-- 5. Storage bucket pro prémiové audio
-- Spusť v Supabase Dashboard → Storage:
-- Bucket: 'premium-audio', private: true

-- 6. RLS
ALTER TABLE poi_premium_content ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_poi_purchases ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_area_premium_purchases ENABLE ROW LEVEL SECURITY;

-- Prémiový obsah: SELECT jen pro platící nebo admin
CREATE POLICY "premium_content_select" ON poi_premium_content
  FOR SELECT USING (
    auth.uid() IN (
      SELECT user_id FROM user_poi_purchases WHERE poi_id = poi_premium_content.poi_id
    )
    OR auth.uid() IN (
      SELECT uap.user_id FROM user_area_premium_purchases uap
      JOIN pois p ON p.area_id = uap.area_id
      WHERE p.id = poi_premium_content.poi_id
    )
    OR EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid())
  );

-- INSERT/UPDATE/DELETE jen přes Edge Function (service_role) – žádná přímá RLS policy
-- user_poi_purchases: SELECT jen vlastní záznamy
CREATE POLICY "user_poi_purchases_select" ON user_poi_purchases
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "user_area_premium_purchases_select" ON user_area_premium_purchases
  FOR SELECT USING (user_id = auth.uid());

-- Pois: veřejný SELECT (perex + slug vždy dostupné)
-- Existující RLS na pois zůstává, jen přidáme index pro slug lookup
CREATE INDEX IF NOT EXISTS pois_slug_idx ON pois(slug);
CREATE INDEX IF NOT EXISTS areas_slug_idx2 ON areas(slug);
```

### 1.2 RPC funkce `get_poi_access`

```sql
-- Vrátí přístupovou úroveň přihlášeného uživatele k danému POI
CREATE OR REPLACE FUNCTION get_poi_access(p_poi_id UUID)
RETURNS TEXT
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  v_user_id    UUID := auth.uid();
  v_area_id    UUID;
BEGIN
  SELECT area_id INTO v_area_id FROM pois WHERE id = p_poi_id;

  -- Anonymní
  IF v_user_id IS NULL THEN RETURN 'public'; END IF;

  -- Admin → plný přístup
  IF EXISTS (SELECT 1 FROM admin_users WHERE user_id = v_user_id) THEN
    RETURN 'full';
  END IF;

  -- Zakoupil konkrétní POI
  IF EXISTS (
    SELECT 1 FROM user_poi_purchases
    WHERE user_id = v_user_id AND poi_id = p_poi_id
  ) THEN RETURN 'premium_poi'; END IF;

  -- Zakoupil premium bundle oblasti
  IF EXISTS (
    SELECT 1 FROM user_area_premium_purchases
    WHERE user_id = v_user_id AND area_id = v_area_id
  ) THEN RETURN 'premium_poi'; END IF;

  -- Zakoupil city access
  IF EXISTS (
    SELECT 1 FROM user_purchases
    WHERE user_id = v_user_id AND area_id = v_area_id
  ) THEN RETURN 'city_access'; END IF;

  -- Registrovaný – sample POI zdarma
  IF EXISTS (
    SELECT 1 FROM areas
    WHERE id = v_area_id AND registered_sample_poi_id = p_poi_id
  ) THEN RETURN 'registered'; END IF;

  -- Přihlášený, ale nic nekoupil
  RETURN 'registered_limited';
END;
$$;
```

### 1.3 RPC funkce `get_poi_by_slug`

```sql
-- Lookup POI podle slug + area slug (pro smart URI)
CREATE OR REPLACE FUNCTION get_poi_by_slug(p_area_slug TEXT, p_poi_slug TEXT)
RETURNS TABLE(
  poi_id UUID, poi_name JSONB, poi_perex TEXT,
  poi_access_level TEXT, poi_premium_price NUMERIC,
  poi_lat DOUBLE PRECISION, poi_lng DOUBLE PRECISION,
  area_id UUID, area_name JSONB, area_slug TEXT
)
LANGUAGE plpgsql SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT
    p.id, p.name, p.perex,
    p.access_level, p.premium_price,
    p.latitude, p.longitude,
    a.id, a.name, a.slug
  FROM pois p
  JOIN areas a ON a.id = p.area_id
  WHERE a.slug = p_area_slug AND p.slug = p_poi_slug
  LIMIT 1;
END;
$$;
```

### 1.4 Pohled `user_all_purchases` (pro "Moje nákupy")

```sql
CREATE OR REPLACE VIEW user_all_purchases AS
SELECT
  'poi' AS purchase_type,
  upp.user_id,
  upp.purchased_at,
  upp.price_paid,
  upp.payment_id,
  p.id AS item_id,
  p.name AS item_name,
  p.slug AS item_slug,
  a.slug AS area_slug,
  a.name AS area_name
FROM user_poi_purchases upp
JOIN pois p ON p.id = upp.poi_id
JOIN areas a ON a.id = p.area_id

UNION ALL

SELECT
  'area_premium' AS purchase_type,
  uap.user_id,
  uap.purchased_at,
  uap.price_paid,
  uap.payment_id,
  a.id AS item_id,
  a.name AS item_name,
  a.slug AS item_slug,
  a.slug AS area_slug,
  a.name AS area_name
FROM user_area_premium_purchases uap
JOIN areas a ON a.id = uap.area_id

UNION ALL

SELECT
  'city_access' AS purchase_type,
  up.user_id,
  up.created_at AS purchased_at,
  up.amount AS price_paid,
  up.stripe_payment_id AS payment_id,
  a.id AS item_id,
  a.name AS item_name,
  a.slug AS item_slug,
  a.slug AS area_slug,
  a.name AS area_name
FROM user_purchases up
JOIN areas a ON a.id = up.area_id;

-- RLS na pohled
ALTER VIEW user_all_purchases SET (security_invoker = true);
```

### 1.5 Storage bucket – prémiové audio

```sql
-- Spusť v Supabase SQL editoru:
INSERT INTO storage.buckets (id, name, public)
VALUES ('premium-audio', 'premium-audio', false)
ON CONFLICT DO NOTHING;

-- RLS policy: přístup jen pro platící uživatele nebo admin
-- Audio se ukládá pod cestou {poiId}/filename – matchujeme prefix
CREATE POLICY "premium_audio_select" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'premium-audio' AND (
      -- Per-POI nákup: cesta začíná poi_id/
      EXISTS (
        SELECT 1 FROM user_poi_purchases upp
        WHERE upp.user_id = auth.uid()
          AND storage.objects.name LIKE upp.poi_id::TEXT || '/%'
      )
      OR
      -- Area premium bundle: jakékoliv POI z oblasti
      EXISTS (
        SELECT 1 FROM user_area_premium_purchases uap
        JOIN pois p ON p.area_id = uap.area_id
        WHERE uap.user_id = auth.uid()
          AND storage.objects.name LIKE p.id::TEXT || '/%'
      )
      OR EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid())
    )
  );

-- Index pro rychlé vyhledávání v RLS policy
CREATE INDEX IF NOT EXISTS user_poi_purchases_poi_id_idx ON user_poi_purchases(poi_id);
CREATE INDEX IF NOT EXISTS user_area_premium_purchases_area_id_idx ON user_area_premium_purchases(area_id);
```

---

## SEKCE 2 – EDGE FUNCTIONS

### 2.1 Nová Edge Function `confirm-poi-payment`

```typescript
// supabase/functions/confirm-poi-payment/index.ts
// Zpracovává Stripe webhook pro nákup prémiového POI nebo bundle

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import Stripe from 'https://esm.sh/stripe@13.0.0'

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY')!, {
  apiVersion: '2023-10-16',
  httpClient: Stripe.createFetchHttpClient(),
})

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
)

serve(async (req) => {
  const sig = req.headers.get('stripe-signature')!
  const body = await req.text()

  let event: Stripe.Event
  try {
    event = stripe.webhooks.constructEvent(
      body, sig, Deno.env.get('STRIPE_WEBHOOK_SECRET_POI')!
    )
  } catch (err) {
    return new Response(`Webhook Error: ${err.message}`, { status: 400 })
  }

  if (event.type === 'checkout.session.completed') {
    const session = event.data.object as Stripe.Checkout.Session
    const metadata = session.metadata || {}

    const userId = metadata.user_id
    const purchaseType = metadata.purchase_type // 'poi' | 'area_premium'

    if (!userId) {
      return new Response('Missing user_id in metadata', { status: 400 })
    }

    if (purchaseType === 'poi') {
      const poiId = metadata.poi_id
      const { error } = await supabase.from('user_poi_purchases').upsert({
        user_id: userId,
        poi_id: poiId,
        price_paid: session.amount_total ? session.amount_total / 100 : null,
        payment_id: session.payment_intent as string,
        stripe_session_id: session.id,
      }, { onConflict: 'user_id,poi_id' })

      if (error) {
        console.error('Insert error:', error)
        return new Response('DB error', { status: 500 })
      }

      // Odeslat potvrzovací email
      await sendPurchaseConfirmationEmail(userId, 'poi', poiId, session)

    } else if (purchaseType === 'area_premium') {
      const areaId = metadata.area_id
      const { error } = await supabase.from('user_area_premium_purchases').upsert({
        user_id: userId,
        area_id: areaId,
        price_paid: session.amount_total ? session.amount_total / 100 : null,
        payment_id: session.payment_intent as string,
        stripe_session_id: session.id,
      }, { onConflict: 'user_id,area_id' })

      if (error) {
        console.error('Insert error:', error)
        return new Response('DB error', { status: 500 })
      }

      await sendPurchaseConfirmationEmail(userId, 'area_premium', areaId, session)
    }
  }

  return new Response(JSON.stringify({ received: true }), {
    headers: { 'Content-Type': 'application/json' }
  })
})

async function sendPurchaseConfirmationEmail(
  userId: string,
  type: 'poi' | 'area_premium',
  itemId: string,
  session: Stripe.Checkout.Session
) {
  // Načti email uživatele
  const { data: user } = await supabase.auth.admin.getUserById(userId)
  if (!user?.user?.email) return

  let subject = ''
  let itemName = ''

  if (type === 'poi') {
    const { data: poi } = await supabase.from('pois').select('name, areas(name, slug), slug')
      .eq('id', itemId).single()
    itemName = poi?.name?.cs || poi?.name?.en || 'POI'
    subject = `Zakoupeno: ${itemName} – PlaceSecrets`
  } else {
    const { data: area } = await supabase.from('areas').select('name').eq('id', itemId).single()
    itemName = area?.name?.cs || area?.name?.en || 'oblast'
    subject = `Zakoupen Premium Bundle: ${itemName} – PlaceSecrets`
  }

  // Odeslat přes Resend (stejný pattern jako confirm-payment)
  await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${Deno.env.get('RESEND_API_KEY')}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      from: 'noreply@placesecrets.app',
      to: user.user.email,
      subject,
      html: `
        <h2>Děkujeme za nákup!</h2>
        <p>Zakoupili jste přístup k: <strong>${itemName}</strong></p>
        <p>Částka: ${session.amount_total ? (session.amount_total / 100).toFixed(2) : '—'} EUR</p>
        <p>Přístup je okamžitě aktivní v aplikaci PlaceSecrets.</p>
        <p><a href="https://placesecrets.app/account/purchases">Zobrazit moje nákupy</a></p>
      `,
    }),
  })
}
```

### 2.2 Nová Edge Function `create-poi-checkout`

```typescript
// supabase/functions/create-poi-checkout/index.ts
// Vytvoří Stripe Checkout session pro nákup POI nebo premium bundle

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import Stripe from 'https://esm.sh/stripe@13.0.0'

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY')!, {
  apiVersion: '2023-10-16',
  httpClient: Stripe.createFetchHttpClient(),
})

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
)

serve(async (req) => {
  const { purchase_type, poi_id, area_id, success_url, cancel_url } = await req.json()

  // Ověř přihlášeného uživatele z JWT
  const authHeader = req.headers.get('Authorization')
  const token = authHeader?.replace('Bearer ', '')
  const { data: { user }, error: authError } = await supabase.auth.getUser(token)
  if (authError || !user) {
    return new Response('Unauthorized', { status: 401 })
  }

  let lineItem: Stripe.Checkout.SessionCreateParams.LineItem
  let metadata: Record<string, string> = { user_id: user.id, purchase_type }

  if (purchase_type === 'poi' && poi_id) {
    const { data: poi } = await supabase.from('pois')
      .select('name, premium_price, areas(slug)')
      .eq('id', poi_id).single()
    if (!poi?.premium_price) return new Response('POI not found or no price', { status: 404 })

    const name = poi.name?.cs || poi.name?.en || 'Prémiový obsah'
    lineItem = {
      price_data: {
        currency: 'eur',
        product_data: { name: `PlaceSecrets – ${name}` },
        unit_amount: Math.round(poi.premium_price * 100),
      },
      quantity: 1,
    }
    metadata.poi_id = poi_id

  } else if (purchase_type === 'area_premium' && area_id) {
    const { data: area } = await supabase.from('areas')
      .select('name, premium_bundle_price')
      .eq('id', area_id).single()
    if (!area?.premium_bundle_price) return new Response('Area not found or no price', { status: 404 })

    const name = area.name?.cs || area.name?.en || 'Oblast'
    lineItem = {
      price_data: {
        currency: 'eur',
        product_data: { name: `PlaceSecrets Premium Bundle – ${name}` },
        unit_amount: Math.round(area.premium_bundle_price * 100),
      },
      quantity: 1,
    }
    metadata.area_id = area_id
  } else {
    return new Response('Invalid purchase_type', { status: 400 })
  }

  const session = await stripe.checkout.sessions.create({
    payment_method_types: ['card'],
    line_items: [lineItem],
    mode: 'payment',
    metadata,
    success_url: success_url || 'placesecrets://purchase/success?session_id={CHECKOUT_SESSION_ID}',
    cancel_url: cancel_url || 'placesecrets://purchase/cancel',
  })

  return new Response(JSON.stringify({ url: session.url, session_id: session.id }), {
    headers: { 'Content-Type': 'application/json' }
  })
})
```

### 2.3 Aktualizace `supabase/functions/_shared/stripe-webhooks.ts`

```
Přidat do Stripe Dashboard:
- Webhook endpoint: https://api.placesecrets.app/functions/v1/confirm-poi-payment
- Events: checkout.session.completed
- Uložit signing secret do env jako STRIPE_WEBHOOK_SECRET_POI
```

---

## SEKCE 3 – ADMIN PANEL (Vite/React)

### 3.1 Úprava `src/components/poi/PoiForm.tsx`

Nahraď stávající `is_premium` checkbox celým tímto blokem:

```tsx
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'

// Slug field (editovatelný, ale auto-generated)
<div className="space-y-2">
  <Label>Slug (smart URI)</Label>
  <div className="flex gap-2">
    <Input
      value={form.slug || ''}
      onChange={e => setForm(f => ({ ...f, slug: e.target.value.toLowerCase().replace(/[^a-z0-9-]/g, '-') }))}
      placeholder="auto-generováno z názvu..."
    />
    <Button type="button" variant="outline" size="sm"
      onClick={() => setForm(f => ({ ...f, slug: '' }))}>
      Reset
    </Button>
  </div>
  {form.slug && (
    <p className="text-xs text-muted-foreground">
      URL: placesecrets.app/place/{areaSlug}/{form.slug}
      <button className="ml-2 text-primary underline" type="button"
        onClick={() => navigator.clipboard.writeText(`https://placesecrets.app/place/${areaSlug}/${form.slug}`)}>
        Kopírovat
      </button>
    </p>
  )}
</div>

// Access level
<div className="space-y-2">
  <Label>Úroveň přístupu</Label>
  <Select value={form.access_level || 'city_access'}
    onValueChange={(v) => setForm(f => ({ ...f, access_level: v }))}>
    <SelectTrigger><SelectValue /></SelectTrigger>
    <SelectContent>
      <SelectItem value="public">🌐 Public – vidí všichni anonymně</SelectItem>
      <SelectItem value="registered">👤 Registered – jen přihlášení (zdarma)</SelectItem>
      <SelectItem value="city_access">🏙️ City Access – zakoupená oblast</SelectItem>
      <SelectItem value="premium_poi">⭐ Premium POI – prémiový obsah</SelectItem>
    </SelectContent>
  </Select>
</div>

// Perex
<div className="space-y-2">
  <Label>Perex <span className="text-muted-foreground font-normal">(viditelný pro všechny, max 300 znaků)</span></Label>
  <Textarea
    value={form.perex || ''}
    onChange={e => setForm(f => ({ ...f, perex: e.target.value }))}
    placeholder="Stručný popis místa viditelný i bez přihlášení..."
    rows={2}
    maxLength={300}
  />
  <p className="text-xs text-muted-foreground text-right">{(form.perex || '').length}/300</p>
</div>

// Prémiová cena (jen pro premium_poi)
{form.access_level === 'premium_poi' && (
  <div className="space-y-2 border border-yellow-200 bg-yellow-50 rounded-lg p-4">
    <Label>Cena prémiového přístupu (EUR)</Label>
    <Input type="number" step="0.50" min="0"
      value={form.premium_price || ''}
      onChange={e => setForm(f => ({ ...f, premium_price: parseFloat(e.target.value) }))}
      placeholder="např. 5.00" />
    <p className="text-xs text-muted-foreground">
      Jednorázová platba za přístup k prémiovému obsahu tohoto místa.
    </p>
  </div>
)}
```

### 3.2 Nový soubor `src/components/poi/PremiumContentTab.tsx`

```tsx
import { useState, useEffect } from 'react'
import { supabaseAdmin } from '@/lib/supabase'
import { Button } from '@/components/ui/button'
import { Textarea } from '@/components/ui/textarea'
import { Label } from '@/components/ui/label'
import { Input } from '@/components/ui/input'
import { Badge } from '@/components/ui/badge'
import { X, Plus, Upload } from 'lucide-react'

interface Props {
  poiId: string
  areaId: string
}

export function PremiumContentTab({ poiId, areaId }: Props) {
  const [content, setContent] = useState({
    audio_url: '',
    text_content: '',
    extra_photos: [] as string[],
    related_poi_ids: [] as string[],
  })
  const [allPois, setAllPois] = useState<{ id: string; name: string }[]>([])
  const [saving, setSaving] = useState(false)
  const [uploadingAudio, setUploadingAudio] = useState(false)
  const [newPhotoUrl, setNewPhotoUrl] = useState('')
  const [saved, setSaved] = useState(false)

  useEffect(() => {
    // Načti prémiový obsah
    supabaseAdmin.from('poi_premium_content').select('*').eq('poi_id', poiId).single()
      .then(({ data }) => {
        if (data) setContent({
          audio_url: data.audio_url || '',
          text_content: data.text_content || '',
          extra_photos: data.extra_photos || [],
          related_poi_ids: data.related_poi_ids || [],
        })
      })
    // Načti všechna POI oblasti pro výběr related
    supabaseAdmin.from('pois').select('id, name').eq('area_id', areaId)
      .then(({ data }) => setAllPois(
        (data || []).map(p => ({ id: p.id, name: p.name?.cs || p.name?.en || p.id }))
      ))
  }, [poiId, areaId])

  const save = async () => {
    setSaving(true)
    await supabaseAdmin.from('poi_premium_content')
      .upsert({ poi_id: poiId, ...content }, { onConflict: 'poi_id' })
    setSaving(false)
    setSaved(true)
    setTimeout(() => setSaved(false), 2000)
  }

  const uploadAudio = async (file: File) => {
    setUploadingAudio(true)
    const path = `${poiId}/${file.name}`
    const { data, error } = await supabaseAdmin.storage
      .from('premium-audio')
      .upload(path, file, { upsert: true })
    if (data) {
      const { data: urlData } = supabaseAdmin.storage.from('premium-audio').getPublicUrl(path)
      setContent(c => ({ ...c, audio_url: urlData.publicUrl }))
    }
    setUploadingAudio(false)
  }

  return (
    <div className="space-y-6 p-4">
      <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-3 text-sm">
        ⭐ Prémiový obsah vidí jen uživatelé kteří zakoupili přístup k tomuto POI nebo
        premium bundle oblasti.
      </div>

      {/* Audio */}
      <div className="space-y-2">
        <Label>Prémiový audioprůvodce</Label>
        <div className="flex gap-2">
          <Input value={content.audio_url}
            onChange={e => setContent(c => ({ ...c, audio_url: e.target.value }))}
            placeholder="URL nebo nahrajte soubor..." />
          <label className="cursor-pointer">
            <input type="file" accept="audio/*" className="hidden"
              onChange={e => e.target.files?.[0] && uploadAudio(e.target.files[0])} />
            <Button type="button" variant="outline" size="icon" disabled={uploadingAudio}
              asChild>
              <span><Upload className="h-4 w-4" /></span>
            </Button>
          </label>
        </div>
        {content.audio_url && (
          <audio controls src={content.audio_url} className="w-full mt-2" />
        )}
      </div>

      {/* Prémiový text */}
      <div className="space-y-2">
        <Label>Prémiový textový obsah</Label>
        <Textarea value={content.text_content}
          onChange={e => setContent(c => ({ ...c, text_content: e.target.value }))}
          rows={8} placeholder="Podrobný historický popis, zajímavosti, příběhy..." />
      </div>

      {/* Extra fotky */}
      <div className="space-y-2">
        <Label>Extra fotografie (URL)</Label>
        <div className="flex gap-2">
          <Input value={newPhotoUrl} onChange={e => setNewPhotoUrl(e.target.value)}
            placeholder="https://..." />
          <Button type="button" variant="outline" size="icon"
            onClick={() => {
              if (newPhotoUrl) {
                setContent(c => ({ ...c, extra_photos: [...c.extra_photos, newPhotoUrl] }))
                setNewPhotoUrl('')
              }
            }}>
            <Plus className="h-4 w-4" />
          </Button>
        </div>
        <div className="flex flex-wrap gap-2">
          {content.extra_photos.map((url, i) => (
            <Badge key={i} variant="secondary" className="flex items-center gap-1 max-w-xs truncate">
              {url.split('/').pop()}
              <X className="h-3 w-3 cursor-pointer flex-shrink-0"
                onClick={() => setContent(c => ({
                  ...c, extra_photos: c.extra_photos.filter((_, j) => j !== i)
                }))} />
            </Badge>
          ))}
        </div>
      </div>

      {/* Related POI */}
      <div className="space-y-2">
        <Label>Propojená místa <span className="text-muted-foreground font-normal">(info panel)</span></Label>
        <select className="w-full border rounded-md p-2 text-sm"
          onChange={e => {
            const id = e.target.value
            if (id && !content.related_poi_ids.includes(id))
              setContent(c => ({ ...c, related_poi_ids: [...c.related_poi_ids, id] }))
          }} value="">
          <option value="">-- Přidat propojené místo --</option>
          {allPois
            .filter(p => p.id !== poiId && !content.related_poi_ids.includes(p.id))
            .map(p => <option key={p.id} value={p.id}>{p.name}</option>)}
        </select>
        <div className="flex flex-wrap gap-2">
          {content.related_poi_ids.map(id => {
            const poi = allPois.find(p => p.id === id)
            return (
              <Badge key={id} variant="outline" className="flex items-center gap-1">
                📍 {poi?.name || id}
                <X className="h-3 w-3 cursor-pointer"
                  onClick={() => setContent(c => ({
                    ...c, related_poi_ids: c.related_poi_ids.filter(x => x !== id)
                  }))} />
              </Badge>
            )
          })}
        </div>
      </div>

      <Button onClick={save} disabled={saving} className={saved ? 'bg-green-600' : ''}>
        {saving ? 'Ukládám...' : saved ? '✓ Uloženo' : 'Uložit prémiový obsah'}
      </Button>
    </div>
  )
}
```

### 3.3 Úprava `src/pages/admin/PoiDetailPage.tsx`

```tsx
import { PremiumContentTab } from '@/components/poi/PremiumContentTab'

// V <TabsList> přidat:
<TabsTrigger value="premium">⭐ Prémiový obsah</TabsTrigger>

// V <TabsContent> přidat:
<TabsContent value="premium">
  <PremiumContentTab poiId={poi.id} areaId={poi.area_id} />
</TabsContent>
```

### 3.4 Nový soubor `src/pages/admin/AreaPricingPage.tsx`

```tsx
import { useState, useEffect } from 'react'
import { useParams, Link } from 'react-router-dom'
import { supabaseAdmin } from '@/lib/supabase'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { ArrowLeft } from 'lucide-react'

export default function AreaPricingPage() {
  const { areaId } = useParams()
  const [area, setArea] = useState<any>(null)
  const [pois, setPois] = useState<any[]>([])
  const [saving, setSaving] = useState(false)
  const [saved, setSaved] = useState(false)

  useEffect(() => {
    Promise.all([
      supabaseAdmin.from('areas').select('*').eq('id', areaId).single(),
      supabaseAdmin.from('pois')
        .select('id, name, access_level, premium_price, slug')
        .eq('area_id', areaId)
        .order('name')
    ]).then(([{ data: a }, { data: p }]) => { setArea(a); setPois(p || []) })
  }, [areaId])

  const save = async () => {
    setSaving(true)
    await supabaseAdmin.from('areas').update({
      city_access_price: area.city_access_price,
      premium_bundle_price: area.premium_bundle_price,
      registered_sample_poi_id: area.registered_sample_poi_id || null,
    }).eq('id', areaId)
    setSaving(false)
    setSaved(true)
    setTimeout(() => setSaved(false), 2000)
  }

  if (!area) return <div className="p-8">Načítám...</div>

  const premiumPois = pois.filter(p => p.access_level === 'premium_poi')
  const totalPerPoiPrice = premiumPois.reduce((s, p) => s + (p.premium_price || 0), 0)
  const bundleSaving = area.premium_bundle_price
    ? Math.max(0, totalPerPoiPrice - area.premium_bundle_price)
    : null

  return (
    <div className="space-y-6 max-w-2xl">
      <div className="flex items-center gap-3">
        <Button variant="ghost" size="icon" asChild>
          <Link to={`/admin/areas/${areaId}`}><ArrowLeft className="h-4 w-4" /></Link>
        </Button>
        <h1 className="text-2xl font-bold">Ceník oblasti: {area.name?.cs || area.name}</h1>
      </div>

      {/* City Access */}
      <Card>
        <CardHeader>
          <CardTitle>🏙️ City Access</CardTitle>
          <CardDescription>Základní přístup ke všem POI v oblasti</CardDescription>
        </CardHeader>
        <CardContent className="space-y-3">
          <div>
            <Label>Cena (EUR)</Label>
            <Input type="number" step="0.50" min="0"
              value={area.city_access_price || ''}
              onChange={e => setArea((a: any) => ({ ...a, city_access_price: parseFloat(e.target.value) || null }))}
              placeholder="např. 1.00" className="max-w-xs mt-1" />
          </div>
        </CardContent>
      </Card>

      {/* Premium Bundle */}
      <Card>
        <CardHeader>
          <CardTitle>⭐ Premium Bundle</CardTitle>
          <CardDescription>Přístup ke všem prémiovým POI v oblasti najednou</CardDescription>
        </CardHeader>
        <CardContent className="space-y-3">
          <div>
            <Label>Cena bundlu (EUR)</Label>
            <Input type="number" step="0.50" min="0"
              value={area.premium_bundle_price || ''}
              onChange={e => setArea((a: any) => ({ ...a, premium_bundle_price: parseFloat(e.target.value) || null }))}
              placeholder="např. 15.00" className="max-w-xs mt-1" />
          </div>
          {premiumPois.length > 0 && (
            <div className="text-sm text-muted-foreground bg-muted rounded p-3">
              {premiumPois.length} prémiových POI, celková cena jednotlivě: {totalPerPoiPrice.toFixed(2)} EUR
              {bundleSaving !== null && bundleSaving > 0 && (
                <span className="text-green-600 font-medium ml-2">
                  (úspora {bundleSaving.toFixed(2)} EUR)
                </span>
              )}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Sample POI pro registrované */}
      <Card>
        <CardHeader>
          <CardTitle>👤 Sample místo pro registrované</CardTitle>
          <CardDescription>Jedno místo viditelné zdarma po registraci – motivuje k nákupu</CardDescription>
        </CardHeader>
        <CardContent>
          <select className="w-full border rounded-md p-2"
            value={area.registered_sample_poi_id || ''}
            onChange={e => setArea((a: any) => ({ ...a, registered_sample_poi_id: e.target.value || null }))}>
            <option value="">-- Žádné (vyberte místo) --</option>
            {pois.map(p => (
              <option key={p.id} value={p.id}>
                {p.name?.cs || p.name?.en || p.id} ({p.access_level})
              </option>
            ))}
          </select>
        </CardContent>
      </Card>

      {/* Přehled prémiových POI */}
      {premiumPois.length > 0 && (
        <Card>
          <CardHeader><CardTitle>Prémiová místa v oblasti</CardTitle></CardHeader>
          <CardContent>
            <table className="w-full text-sm">
              <thead><tr className="border-b text-muted-foreground">
                <th className="text-left py-2">Název</th>
                <th className="text-left py-2">Slug</th>
                <th className="text-right py-2">Cena (EUR)</th>
              </tr></thead>
              <tbody>
                {premiumPois.map(p => (
                  <tr key={p.id} className="border-b">
                    <td className="py-2">
                      <Link to={`/admin/pois/${p.id}`} className="text-primary hover:underline">
                        {p.name?.cs || p.name?.en || p.id}
                      </Link>
                    </td>
                    <td className="py-2 text-muted-foreground font-mono text-xs">{p.slug}</td>
                    <td className="py-2 text-right">{p.premium_price ? `${p.premium_price}` : '—'}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </CardContent>
        </Card>
      )}

      <Button onClick={save} disabled={saving} className={saved ? 'bg-green-600' : ''}>
        {saving ? 'Ukládám...' : saved ? '✓ Uloženo' : 'Uložit ceník'}
      </Button>
    </div>
  )
}
```

### 3.5 Nová stránka `src/pages/admin/PurchasesOverviewPage.tsx`

```tsx
// Přehled všech nákupů POI a premium bundlů – pro admin

import { useState, useEffect } from 'react'
import { supabaseAdmin } from '@/lib/supabase'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'

export default function PurchasesOverviewPage() {
  const [purchases, setPurchases] = useState<any[]>([])
  const [stats, setStats] = useState({ total: 0, poiCount: 0, bundleCount: 0 })

  useEffect(() => {
    supabaseAdmin
      .from('user_all_purchases')
      .select('*')
      .in('purchase_type', ['poi', 'area_premium'])
      .order('purchased_at', { ascending: false })
      .limit(200)
      .then(({ data }) => {
        const items = data || []
        setPurchases(items)
        setStats({
          total: items.reduce((s, i) => s + (i.price_paid || 0), 0),
          poiCount: items.filter(i => i.purchase_type === 'poi').length,
          bundleCount: items.filter(i => i.purchase_type === 'area_premium').length,
        })
      })
  }, [])

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold">Přehled nákupů prémiového obsahu</h1>

      <div className="grid grid-cols-3 gap-4">
        <Card><CardContent className="pt-6">
          <div className="text-2xl font-bold">{stats.total.toFixed(2)} EUR</div>
          <div className="text-muted-foreground text-sm">Celkové tržby</div>
        </CardContent></Card>
        <Card><CardContent className="pt-6">
          <div className="text-2xl font-bold">{stats.poiCount}</div>
          <div className="text-muted-foreground text-sm">Nákupů POI</div>
        </CardContent></Card>
        <Card><CardContent className="pt-6">
          <div className="text-2xl font-bold">{stats.bundleCount}</div>
          <div className="text-muted-foreground text-sm">Nákupů bundlů</div>
        </CardContent></Card>
      </div>

      <Card>
        <CardHeader><CardTitle>Poslední nákupy</CardTitle></CardHeader>
        <CardContent>
          <table className="w-full text-sm">
            <thead><tr className="border-b text-muted-foreground">
              <th className="text-left py-2">Datum</th>
              <th className="text-left py-2">Typ</th>
              <th className="text-left py-2">Místo / Oblast</th>
              <th className="text-right py-2">Cena</th>
            </tr></thead>
            <tbody>
              {purchases.map(p => (
                <tr key={p.payment_id + p.purchased_at} className="border-b">
                  <td className="py-2">{new Date(p.purchased_at).toLocaleDateString('cs')}</td>
                  <td className="py-2">
                    {p.purchase_type === 'poi' ? '⭐ POI' : '📦 Bundle'}
                  </td>
                  <td className="py-2">{p.item_name?.cs || p.item_name?.en || p.item_name}</td>
                  <td className="py-2 text-right">{p.price_paid ? `${p.price_paid} EUR` : '—'}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </CardContent>
      </Card>
    </div>
  )
}
```

### 3.6 Aktualizace routingu `src/router.tsx`

```tsx
// Přidat do admin routes:
{ path: '/admin/areas/:areaId/pricing', element: <AdminGuard><AreaPricingPage /></AdminGuard> },
{ path: '/admin/purchases/premium', element: <AdminGuard><PurchasesOverviewPage /></AdminGuard> },
```

### 3.7 Přidat do Sidebar navigace

```tsx
// V navigační skupině "Obsah" nebo nová skupina "Monetizace":
{ label: 'Prémiové nákupy', href: '/admin/purchases/premium', icon: Star },
```

### 3.8 Filtr v `PoisPage.tsx`

```tsx
const ACCESS_LEVELS = [
  { value: '', label: 'Vše' },
  { value: 'public', label: '🌐 Public' },
  { value: 'registered', label: '👤 Registered' },
  { value: 'city_access', label: '🏙️ City Access' },
  { value: 'premium_poi', label: '⭐ Premium' },
]
const [accessFilter, setAccessFilter] = useState('')

// Do query přidat: if (accessFilter) query = query.eq('access_level', accessFilter)

// V JSX nad tabulkou:
<div className="flex gap-2 flex-wrap">
  {ACCESS_LEVELS.map(l => (
    <Button key={l.value}
      variant={accessFilter === l.value ? 'default' : 'outline'} size="sm"
      onClick={() => setAccessFilter(l.value)}>
      {l.label}
    </Button>
  ))}
</div>
```

---

## SEKCE 4 – SMART URI (web + Flutter)

### 4.1 Web – route handler `src/pages/PlaceDetailPage.tsx`

```tsx
// Route: /place/:areaSlug/:poiSlug
// Veřejná stránka POI – funguje jako landing page pro sdílení

import { useEffect, useState } from 'react'
import { useParams, Link } from 'react-router-dom'
import { supabase } from '@/lib/supabase'
import { Helmet } from 'react-helmet-async'

export default function PlaceDetailPage() {
  const { areaSlug, poiSlug } = useParams()
  const [poi, setPoi] = useState<any>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    supabase.rpc('get_poi_by_slug', {
      p_area_slug: areaSlug,
      p_poi_slug: poiSlug,
    }).then(({ data }) => {
      setPoi(data?.[0] || null)
      setLoading(false)
    })
  }, [areaSlug, poiSlug])

  if (loading) return <div className="flex items-center justify-center min-h-screen">
    <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary" />
  </div>

  if (!poi) return <div className="flex items-center justify-center min-h-screen">
    <div className="text-center">
      <h1 className="text-2xl font-bold mb-2">Místo nenalezeno</h1>
      <p className="text-muted-foreground mb-4">Odkaz mohl být změněn nebo místo bylo smazáno.</p>
      <Link to="/" className="text-primary underline">Zpět na hlavní stránku</Link>
    </div>
  </div>

  const name = poi.poi_name?.cs || poi.poi_name?.en || 'Místo'
  const areaName = poi.area_name?.cs || poi.area_name?.en || ''
  const shareUrl = `https://placesecrets.app/place/${areaSlug}/${poiSlug}`

  return (
    <>
      {/* Open Graph meta tagy pro náhledy při sdílení */}
      <Helmet>
        <title>{name} – {areaName} | PlaceSecrets</title>
        <meta name="description" content={poi.poi_perex || `Objevte ${name} v ${areaName}`} />
        <meta property="og:title" content={`${name} – ${areaName}`} />
        <meta property="og:description" content={poi.poi_perex || ''} />
        <meta property="og:url" content={shareUrl} />
        <meta property="og:type" content="place" />
        <meta property="og:site_name" content="PlaceSecrets" />
        <meta name="twitter:card" content="summary" />
        <meta name="twitter:title" content={`${name} – ${areaName}`} />
        <meta name="twitter:description" content={poi.poi_perex || ''} />
        {/* Canonical URL */}
        <link rel="canonical" href={shareUrl} />
      </Helmet>

      <div className="min-h-screen bg-background">
        {/* Header */}
        <header className="border-b px-4 py-3 flex items-center justify-between">
          <Link to="/" className="font-bold text-primary text-lg">PlaceSecrets</Link>
          <div className="flex gap-2">
            <a href={`placesecrets://place/${areaSlug}/${poiSlug}`}
              className="text-sm text-primary underline">
              Otevřít v aplikaci
            </a>
          </div>
        </header>

        <main className="max-w-2xl mx-auto px-4 py-8">
          {/* Breadcrumb */}
          <nav className="text-sm text-muted-foreground mb-4">
            <Link to="/" className="hover:underline">PlaceSecrets</Link>
            {' › '}
            <span>{areaName}</span>
            {' › '}
            <span className="text-foreground">{name}</span>
          </nav>

          <h1 className="text-3xl font-bold mb-2">{name}</h1>
          <p className="text-muted-foreground mb-6">{areaName}</p>

          {poi.poi_perex && (
            <p className="text-lg leading-relaxed mb-6">{poi.poi_perex}</p>
          )}

          {/* Access level info */}
          <div className="border rounded-lg p-4 mb-6">
            {poi.poi_access_level === 'public' && (
              <p className="text-green-700">🌐 Toto místo je veřejně dostupné</p>
            )}
            {poi.poi_access_level === 'registered' && (
              <p className="text-blue-700">👤 Dostupné zdarma po registraci</p>
            )}
            {poi.poi_access_level === 'city_access' && (
              <p className="text-orange-700">🏙️ Dostupné s přístupem k oblasti</p>
            )}
            {poi.poi_access_level === 'premium_poi' && (
              <div>
                <p className="text-amber-700 font-medium">⭐ Prémiový obsah</p>
                {poi.poi_premium_price && (
                  <p className="text-sm text-muted-foreground mt-1">
                    Jednorázový přístup za {poi.poi_premium_price} EUR
                  </p>
                )}
              </div>
            )}
          </div>

          {/* CTA – otevřít v aplikaci */}
          <div className="bg-primary/5 border border-primary/20 rounded-lg p-6 text-center">
            <p className="font-medium mb-2">Audioprůvodce a plný obsah najdeš v aplikaci</p>
            <div className="flex gap-3 justify-center flex-wrap">
              <a href={`placesecrets://place/${areaSlug}/${poiSlug}`}
                className="bg-primary text-white px-6 py-2 rounded-lg font-medium hover:bg-primary/90">
                Otevřít v aplikaci
              </a>
              <a href="https://apps.apple.com/app/placesecrets" target="_blank" rel="noopener"
                className="border px-6 py-2 rounded-lg font-medium hover:bg-muted">
                App Store
              </a>
              <a href="https://play.google.com/store/apps/placesecrets" target="_blank" rel="noopener"
                className="border px-6 py-2 rounded-lg font-medium hover:bg-muted">
                Google Play
              </a>
            </div>
          </div>

          {/* Souřadnice / mapa odkaz */}
          {poi.poi_lat && poi.poi_lng && (
            <div className="mt-4 text-center">
              <a
                href={`https://www.google.com/maps?q=${poi.poi_lat},${poi.poi_lng}`}
                target="_blank" rel="noopener"
                className="text-sm text-muted-foreground hover:underline">
                📍 Zobrazit na Google Maps
              </a>
            </div>
          )}
        </main>
      </div>
    </>
  )
}
```

### 4.2 Přidat route do `src/router.tsx`

```tsx
// Veřejné routes (bez AuthGuard):
{ path: '/place/:areaSlug/:poiSlug', element: <PlaceDetailPage /> },
```

### 4.3 Nainstalovat `react-helmet-async`

```bash
npm install react-helmet-async
```

```tsx
// src/main.tsx – obalit app:
import { HelmetProvider } from 'react-helmet-async'

<HelmetProvider>
  <RouterProvider router={router} />
</HelmetProvider>
```

---

## SEKCE 5 – FLUTTER APLIKACE

### 5.1 Rozšíření `lib/models/poi_model.dart`

```dart
enum PoiAccessLevel { public, registered, cityAccess, premiumPoi }

// Přidat do třídy PoiModel:
final PoiAccessLevel accessLevel;
final String? perex;
final double? premiumPrice;
final String? slug;     // pro smart URI
final String? areaSlug; // pro smart URI – z join s areas

// V fromJson factory:
accessLevel: _parseAccessLevel(json['access_level']),
perex: json['perex'],
premiumPrice: (json['premium_price'] as num?)?.toDouble(),
slug: json['slug'],
areaSlug: json['areas']?['slug'] as String?,

// DŮLEŽITÉ: Všechny Supabase query načítající POI musí přidat join:
// .select('*, areas!inner(slug, name)')
// Platí pro: getPoiById, getPoisByArea, getPoiBySlug, getAllPois

static PoiAccessLevel _parseAccessLevel(String? v) {
  switch (v) {
    case 'public': return PoiAccessLevel.public;
    case 'registered': return PoiAccessLevel.registered;
    case 'premium_poi': return PoiAccessLevel.premiumPoi;
    default: return PoiAccessLevel.cityAccess;
  }
}
```

### 5.2 Nový soubor `lib/models/poi_premium_content_model.dart`

```dart
class PoiPremiumContent {
  final String id;
  final String poiId;
  final String? audioUrl;
  final String? textContent;
  final List<String> extraPhotos;
  final List<String> relatedPoiIds;

  const PoiPremiumContent({
    required this.id,
    required this.poiId,
    this.audioUrl,
    this.textContent,
    this.extraPhotos = const [],
    this.relatedPoiIds = const [],
  });

  factory PoiPremiumContent.fromJson(Map<String, dynamic> json) =>
    PoiPremiumContent(
      id: json['id'] as String,
      poiId: json['poi_id'] as String,
      audioUrl: json['audio_url'] as String?,
      textContent: json['text_content'] as String?,
      extraPhotos: List<String>.from(json['extra_photos'] ?? []),
      relatedPoiIds: List<String>.from(json['related_poi_ids'] ?? []),
    );
}
```

### 5.3 Rozšíření `lib/repositories/poi_repository.dart`

```dart
// Přidat tyto metody:

/// Vrátí přístupovou úroveň uživatele k danému POI
Future<String> getPoiAccess(String poiId) async {
  final response = await supabase.rpc(
    'get_poi_access',
    params: {'p_poi_id': poiId},
  );
  return (response as String?) ?? 'public';
}

/// Načte prémiový obsah (RLS zajistí přístup jen platícím)
Future<PoiPremiumContent?> getPremiumContent(String poiId) async {
  try {
    final data = await supabase
      .from('poi_premium_content')
      .select()
      .eq('poi_id', poiId)
      .single();
    return PoiPremiumContent.fromJson(data);
  } catch (_) {
    return null;
  }
}

/// Načte POI podle area slug + poi slug (pro deep link)
Future<PoiModel?> getPoiBySlug(String areaSlug, String poiSlug) async {
  try {
    final data = await supabase.rpc('get_poi_by_slug', params: {
      'p_area_slug': areaSlug,
      'p_poi_slug': poiSlug,
    });
    if (data == null || (data as List).isEmpty) return null;
    return PoiModel.fromJson(data[0]);
  } catch (_) {
    return null;
  }
}

/// Načte všechny nákupy uživatele (pro obnovu přístupu po přihlášení)
Future<List<String>> getUserPurchasedPoiIds() async {
  try {
    final data = await supabase
      .from('user_poi_purchases')
      .select('poi_id');
    return (data as List).map((r) => r['poi_id'] as String).toList();
  } catch (_) {
    return [];
  }
}

/// Načte všechny oblasti s premium bundle purchasem
Future<List<String>> getUserPurchasedAreaBundleIds() async {
  try {
    final data = await supabase
      .from('user_area_premium_purchases')
      .select('area_id');
    return (data as List).map((r) => r['area_id'] as String).toList();
  } catch (_) {
    return [];
  }
}
```

### 5.4 Nový soubor `lib/providers/poi_access_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Access level pro konkrétní POI
final poiAccessProvider = FutureProvider.family<String, String>((ref, poiId) async {
  // Sleduj změny auth stavu – při přihlášení/odhlášení se invaliduje
  ref.watch(authStateProvider);
  try {
    return await ref.read(poiRepositoryProvider).getPoiAccess(poiId);
  } catch (_) {
    // Offline fallback – zkontroluj lokální Drift cache
    // Potřebujeme area_id – zkus z lokální DB
    final localAccess = await ref.read(poiRepositoryProvider)
      .getPoiAccessOfflineByPoiId(poiId);
    return localAccess ?? 'public';
  }
});

// Prémiový obsah – načítá se jen pokud má uživatel přístup
final premiumContentProvider = FutureProvider.family<PoiPremiumContent?, String>((ref, poiId) async {
  ref.watch(authStateProvider); // invaliduje při auth změně
  final access = await ref.watch(poiAccessProvider(poiId).future);
  if (access != 'premium_poi' && access != 'full') return null;
  return ref.read(poiRepositoryProvider).getPremiumContent(poiId);
});

// Cache zakoupených POI IDs (rychlý lookup bez RPC)
final purchasedPoiIdsProvider = FutureProvider<Set<String>>((ref) async {
  ref.watch(authStateProvider);
  final ids = await ref.read(poiRepositoryProvider).getUserPurchasedPoiIds();
  return ids.toSet();
});

// Cache zakoupených area bundle IDs
final purchasedAreaBundleIdsProvider = FutureProvider<Set<String>>((ref) async {
  ref.watch(authStateProvider);
  final ids = await ref.read(poiRepositoryProvider).getUserPurchasedAreaBundleIds();
  return ids.toSet();
});
```

### 5.5 Auth state listener – invalidace přístupu při přihlášení/odhlášení

```dart
// lib/providers/auth_provider.dart – přidat do existujícího auth state listeneru:

// Při změně auth stavu invaliduj všechny access providery
ref.listen(authStateProvider, (previous, next) {
  // Invaliduj cache nákupů
  ref.invalidate(purchasedPoiIdsProvider);
  ref.invalidate(purchasedAreaBundleIdsProvider);
  // Pozn: poiAccessProvider.family se invaliduje automaticky
  // přes ref.watch(authStateProvider) uvnitř providerů výše
});
```

### 5.6 Drift lokální cache pro offline přístup

```dart
// lib/database/tables/purchased_pois_table.dart

import 'package:drift/drift.dart';

class PurchasedPois extends Table {
  TextColumn get poiId => text()();
  TextColumn get purchaseType => text()(); // 'poi' | 'area_premium'
  DateTimeColumn get purchasedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {poiId};
}

// lib/database/tables/purchased_area_bundles_table.dart
class PurchasedAreaBundles extends Table {
  TextColumn get areaId => text()();
  DateTimeColumn get purchasedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {areaId};
}

// Přidat do AppDatabase @DriftDatabase(tables: [..., PurchasedPois, PurchasedAreaBundles])
```

```dart
// lib/repositories/poi_repository.dart – přidat sync metodu:

/// Synchronizuje nákupy ze Supabase do lokální Drift DB (pro offline)
Future<void> syncPurchasesToLocal() async {
  try {
    final poiIds = await getUserPurchasedPoiIds();
    final areaIds = await getUserPurchasedAreaBundleIds();

    // Uložit do Drift
    await db.batch((batch) {
      batch.insertAllOnConflictUpdate(
        db.purchasedPois,
        poiIds.map((id) => PurchasedPoisCompanion.insert(
          poiId: id,
          purchaseType: const Value('poi'),
          purchasedAt: Value(DateTime.now()),
        )).toList(),
      );
      batch.insertAllOnConflictUpdate(
        db.purchasedAreaBundles,
        areaIds.map((id) => PurchasedAreaBundlesCompanion.insert(
          areaId: id,
          purchasedAt: Value(DateTime.now()),
        )).toList(),
      );
    });
  } catch (e) {
    // Offline – nevadí, lokální cache zůstává
    debugPrint('Sync purchases failed (offline?): $e');
  }
}

/// Offline check – má uživatel přístup k POI? (bez area_id)
Future<String?> getPoiAccessOfflineByPoiId(String poiId) async {
  final hasPoi = await (db.select(db.purchasedPois)
    ..where((t) => t.poiId.equals(poiId))).getSingleOrNull();
  if (hasPoi != null) return 'premium_poi';
  return null; // neznáme oblast offline, vrátíme null → provider použije 'public'
}

/// Offline check – má uživatel přístup k POI? (s area_id)
Future<String> getPoiAccessOffline(String poiId, String areaId) async {
  final hasPoi = await (db.select(db.purchasedPois)
    ..where((t) => t.poiId.equals(poiId))).getSingleOrNull();
  if (hasPoi != null) return 'premium_poi';

  final hasBundle = await (db.select(db.purchasedAreaBundles)
    ..where((t) => t.areaId.equals(areaId))).getSingleOrNull();
  if (hasBundle != null) return 'premium_poi';

  return 'registered_limited';
}
```

### 5.7 Úprava `lib/screens/poi/poi_detail_screen.dart`

```dart
// Kompletní logika zobrazení dle přístupu:

class PoiDetailScreen extends ConsumerWidget {
  final String poiId;
  const PoiDetailScreen({required this.poiId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final poiAsync = ref.watch(poiDetailProvider(poiId));
    final accessAsync = ref.watch(poiAccessProvider(poiId));

    return poiAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Chyba: $e'))),
      data: (poi) => accessAsync.when(
        loading: () => Scaffold(
          appBar: AppBar(title: Text(poi.localizedName)),
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => _buildContent(context, ref, poi, 'public'),
        data: (access) => _buildContent(context, ref, poi, access),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, PoiModel poi, String access) {
    return Scaffold(
      appBar: AppBar(
        title: Text(poi.localizedName),
        actions: [
          // Share button
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _sharePoi(context, poi),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(children: [
          // Hero fotka – vždy
          _PoiHeroImage(poi: poi),

          // Perex – vždy viditelný
          if (poi.perex != null && poi.perex!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text(poi.perex!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[700]
                )),
            ),

          // Anonymní uživatel
          if (access == 'public') ...[
            const SizedBox(height: 16),
            _RegisterCallToAction(context: context),
          ],

          // Přihlášený ale nic nekoupil
          if (access == 'registered_limited') ...[
            const SizedBox(height: 16),
            _PurchaseAreaCard(poi: poi),
          ],

          // Základní obsah
          if (['registered', 'city_access', 'premium_poi', 'full'].contains(access)) ...[
            const SizedBox(height: 16),
            _BasicPoiContent(poi: poi),
          ],

          // Prémiový obsah
          if (['premium_poi', 'full'].contains(access)) ...[
            const SizedBox(height: 8),
            _PremiumPoiContent(poiId: poiId),
          ],

          // Upgrade výzva
          if (['registered', 'city_access'].contains(access) &&
              poi.accessLevel == PoiAccessLevel.premiumPoi) ...[
            const SizedBox(height: 16),
            _PremiumUpgradeCard(poi: poi),
          ],

          const SizedBox(height: 32),
        ]),
      ),
    );
  }

  void _sharePoi(BuildContext context, PoiModel poi) async {
    // Smart URI sdílení
    final areaSlug = poi.areaSlug ?? ''; // přidat areaSlug do PoiModel
    final poiSlug = poi.slug ?? poi.id;
    final url = 'https://placesecrets.app/place/$areaSlug/$poiSlug';
    final name = poi.localizedName;

    await Share.share(
      '$name\n$url',
      subject: name,
    );
  }
}
```

### 5.8 Widgets pro prémiový obsah

```dart
// lib/screens/poi/widgets/premium_poi_content.dart

class _PremiumPoiContent extends ConsumerWidget {
  final String poiId;
  const _PremiumPoiContent({required this.poiId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(premiumContentProvider(poiId)).when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox(),
      data: (content) {
        if (content == null) return const SizedBox();
        return Column(children: [
          // Premium badge
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber[100],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber[300]!),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.star, size: 16, color: Colors.amber[700]),
              const SizedBox(width: 6),
              Text('Prémiový obsah', style: TextStyle(
                color: Colors.amber[800], fontWeight: FontWeight.w600, fontSize: 13)),
            ]),
          ),
          const SizedBox(height: 12),

          // Prémiový audio player
          if (content.audioUrl != null)
            _PremiumAudioPlayer(url: content.audioUrl!),

          // Prémiový text
          if (content.textContent != null && content.textContent!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(content.textContent!,
                style: Theme.of(context).textTheme.bodyMedium),
            ),

          // Extra fotky
          if (content.extraPhotos.isNotEmpty)
            _ExtraPhotosGallery(photos: content.extraPhotos),

          // Related POI panel
          if (content.relatedPoiIds.isNotEmpty)
            _RelatedPoisPanel(poiIds: content.relatedPoiIds),
        ]);
      },
    );
  }
}

class _RelatedPoisPanel extends ConsumerWidget {
  final List<String> poiIds;
  const _RelatedPoisPanel({required this.poiIds});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(children: [
              Icon(Icons.place, color: Colors.blue[700], size: 18),
              const SizedBox(width: 8),
              Text('Propojená místa',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[800])),
            ]),
          ),
          ...poiIds.map((id) => _RelatedPoiTile(poiId: id)),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _RelatedPoiTile extends ConsumerWidget {
  final String poiId;
  const _RelatedPoiTile({required this.poiId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(poiDetailProvider(poiId)).maybeWhen(
      data: (poi) => ListTile(
        dense: true,
        leading: const Icon(Icons.place_outlined, size: 20),
        title: Text(poi.localizedName),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: () => context.push('/poi/$poiId'),
      ),
      orElse: () => const SizedBox(),
    );
  }
}

class _PremiumUpgradeCard extends StatelessWidget {
  final PoiModel poi;
  const _PremiumUpgradeCard({required this.poi});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber[100]!, Colors.orange[50]!],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber[300]!),
        boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        const Icon(Icons.star_rounded, color: Colors.amber, size: 40),
        const SizedBox(height: 8),
        const Text('Prémiový obsah', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text(
          'Podrobný audioprůvodce, více fotografií\na propojená místa v okolí.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black87),
        ),
        const SizedBox(height: 16),
        if (poi.premiumPrice != null)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.lock_open),
            label: Text('Odemknout za ${poi.premiumPrice!.toStringAsFixed(2)} EUR'),
            onPressed: () => context.push('/purchase/poi/${poi.id}'),
          ),
      ]),
    );
  }
}
```

### 5.9 Nový soubor `lib/repositories/payment_repository.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CheckoutSession {
  final String url;
  final String sessionId;
  const CheckoutSession({required this.url, required this.sessionId});
}

class PaymentRepository {
  final SupabaseClient _supabase;
  PaymentRepository(this._supabase);

  /// Zavolá Edge Function create-poi-checkout a vrátí Stripe URL
  Future<CheckoutSession?> createPoiCheckout({
    required String purchaseType, // 'poi' | 'area_premium'
    String? poiId,
    String? areaId,
    required String successUrl,
    required String cancelUrl,
  }) async {
    final response = await _supabase.functions.invoke(
      'create-poi-checkout',
      body: {
        'purchase_type': purchaseType,
        if (poiId != null) 'poi_id': poiId,
        if (areaId != null) 'area_id': areaId,
        'success_url': successUrl,
        'cancel_url': cancelUrl,
      },
    );

    if (response.status != 200) {
      throw Exception('createPoiCheckout failed: ${response.status}');
    }

    final data = response.data as Map<String, dynamic>;
    return CheckoutSession(
      url: data['url'] as String,
      sessionId: data['session_id'] as String,
    );
  }
}

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository(Supabase.instance.client);
});
```

### 5.10 Nová obrazovka `lib/screens/purchase/purchase_poi_screen.dart`

```dart
// Route: /purchase/poi/:poiId

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class PurchasePoiScreen extends ConsumerStatefulWidget {
  final String poiId;
  const PurchasePoiScreen({required this.poiId, super.key});

  @override
  ConsumerState<PurchasePoiScreen> createState() => _PurchasePoiScreenState();
}

class _PurchasePoiScreenState extends ConsumerState<PurchasePoiScreen> {
  bool _loading = false;
  PoiModel? _poi;
  PoiPremiumContent? _preview; // preview prémiového obsahu (bez obsahu)
  AreaModel? _area;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final repo = ref.read(poiRepositoryProvider);
    // Načti POI metadata (bez prémiového obsahu)
    final poi = await repo.getPoiById(widget.poiId);
    setState(() => _poi = poi);

    if (poi?.areaId != null) {
      final area = await ref.read(areaRepositoryProvider).getAreaById(poi!.areaId);
      setState(() => _area = area);
    }
  }

  Future<void> _purchasePoi() async {
    if (_poi == null) return;
    setState(() => _loading = true);

    try {
      // Zavolej Edge Function create-poi-checkout
      final session = await ref.read(paymentRepositoryProvider).createPoiCheckout(
        purchaseType: 'poi',
        poiId: widget.poiId,
        successUrl: 'placesecrets://purchase/success?poi_id=${widget.poiId}',
        cancelUrl: 'placesecrets://purchase/cancel',
      );

      if (session?.url != null) {
        // Otevři Stripe Checkout ve webview nebo externím prohlížeči
        await launchUrl(Uri.parse(session!.url!), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chyba při zahájení platby: $e')),
        );
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _purchaseBundle() async {
    if (_area == null) return;
    setState(() => _loading = true);
    try {
      final session = await ref.read(paymentRepositoryProvider).createPoiCheckout(
        purchaseType: 'area_premium',
        areaId: _area!.id,
        successUrl: 'placesecrets://purchase/success?area_id=${_area!.id}',
        cancelUrl: 'placesecrets://purchase/cancel',
      );
      if (session?.url != null) {
        await launchUrl(Uri.parse(session!.url!), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chyba při zahájení platby: $e')),
        );
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_poi == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Odemknout prémiový obsah')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // POI info
          Text(_poi!.localizedName,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          if (_area != null)
            Text(_area!.localizedName,
              style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 24),

          // Co získáš
          const Text('Co získáš:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          _FeatureRow(icon: Icons.headphones, text: 'Podrobný audioprůvodce'),
          _FeatureRow(icon: Icons.article, text: 'Rozšířený textový popis'),
          _FeatureRow(icon: Icons.photo_library, text: 'Galerie extra fotografií'),
          _FeatureRow(icon: Icons.place, text: 'Propojená místa v okolí'),
          const SizedBox(height: 24),

          // Per POI karta
          _PurchaseOptionCard(
            title: 'Toto místo',
            description: 'Jednorázový přístup k prémiovému obsahu tohoto místa',
            price: _poi!.premiumPrice,
            onTap: _loading ? null : _purchasePoi,
            loading: _loading,
            highlighted: true,
          ),

          // Bundle karta (pokud oblast má bundle)
          if (_area?.premiumBundlePrice != null) ...[
            const SizedBox(height: 12),
            _PurchaseOptionCard(
              title: 'Premium Bundle – ${_area!.localizedName}',
              description: 'Prémiový obsah VŠECH prémiových míst v oblasti',
              price: _area!.premiumBundlePrice,
              onTap: _loading ? null : _purchaseBundle,
              loading: false,
              badge: 'Výhodné',
            ),
          ],
        ]),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Icon(icon, size: 18, color: Colors.amber[700]),
        const SizedBox(width: 10),
        Text(text),
      ]),
    );
  }
}

class _PurchaseOptionCard extends StatelessWidget {
  final String title;
  final String description;
  final double? price;
  final VoidCallback? onTap;
  final bool loading;
  final bool highlighted;
  final String? badge;

  const _PurchaseOptionCard({
    required this.title, required this.description,
    this.price, this.onTap, this.loading = false,
    this.highlighted = false, this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: highlighted ? Colors.amber[400]! : Colors.grey[300]!,
          width: highlighted ? 2 : 1),
        borderRadius: BorderRadius.circular(12),
        color: highlighted ? Colors.amber[50] : Colors.white,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            if (badge != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(badge!, style: TextStyle(color: Colors.green[700], fontSize: 11)),
              ),
            ]
          ]),
          const SizedBox(height: 4),
          Text(description, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: highlighted ? Colors.amber[700] : Colors.grey[800],
                foregroundColor: Colors.white,
              ),
              onPressed: onTap,
              child: loading
                ? const SizedBox(height: 18, width: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(price != null ? 'Zakoupit za ${price!.toStringAsFixed(2)} EUR' : 'Zakoupit'),
            ),
          ),
        ]),
      ),
    );
  }
}
```

### 5.11 Deep link handler – po návratu z Stripe

```dart
// lib/app/deep_link_handler.dart
// Přidat do existujícího deep link handleru.
// DŮLEŽITÉ: handleDeepLink musí být volána jako metoda ConsumerStatefulWidget
// nebo přijímat WidgetRef a BuildContext jako parametry.

// Správná signatura – volej z initState nebo app_links listeneru:
void handleDeepLink(Uri uri, WidgetRef ref, BuildContext context) {
  if (uri.scheme != 'placesecrets') return;

  // Úspěšná platba za POI
  if (uri.path == '/purchase/success') {
    final poiId = uri.queryParameters['poi_id'];
    final areaId = uri.queryParameters['area_id'];

    if (poiId != null) {
      ref.invalidate(poiAccessProvider(poiId));
      ref.invalidate(premiumContentProvider(poiId));
      ref.invalidate(purchasedPoiIdsProvider);
      ref.read(poiRepositoryProvider).syncPurchasesToLocal();
      context.go('/poi/$poiId');
      _showPurchaseSuccess('Prémiový obsah odemčen!', context);
    }

    if (areaId != null) {
      ref.invalidate(purchasedAreaBundleIdsProvider);
      ref.read(poiRepositoryProvider).syncPurchasesToLocal();
      context.go('/area/$areaId');
      _showPurchaseSuccess('Premium Bundle aktivován!', context);
    }
    return;
  }

  // Zrušená platba
  if (uri.path == '/purchase/cancel') {
    context.pop();
    return;
  }

  // Smart URI – otevřít místo podle slugu
  final segments = uri.pathSegments;
  if (segments.length >= 3 && segments[0] == 'place') {
    context.go('/place/${segments[1]}/${segments[2]}');
  }
}

void _showPurchaseSuccess(String message, BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle, color: Colors.white),
        const SizedBox(width: 8),
        Text(message),
      ]),
      backgroundColor: Colors.green[700],
      duration: const Duration(seconds: 4),
    ),
  );
}
```

### 5.12 Nová obrazovka `lib/screens/account/my_purchases_screen.dart`

```dart
// Route: /account/purchases
// Zobrazí seznam všech zakoupených POI a bundlů

class MyPurchasesScreen extends ConsumerWidget {
  const MyPurchasesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final poiIdsAsync = ref.watch(purchasedPoiIdsProvider);
    final bundleIdsAsync = ref.watch(purchasedAreaBundleIdsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Moje nákupy')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(purchasedPoiIdsProvider);
          ref.invalidate(purchasedAreaBundleIdsProvider);
        },
        child: ListView(children: [

          // City Access nákupy (existující)
          _SectionHeader(title: '🏙️ Přístupy k oblastem'),
          // ... existující implementace z původní spec

          // Premium POI nákupy
          _SectionHeader(title: '⭐ Prémiová místa'),
          poiIdsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const ListTile(title: Text('Chyba při načítání')),
            data: (ids) => ids.isEmpty
              ? const ListTile(
                  title: Text('Žádná prémiová místa'),
                  subtitle: Text('Zakoupená prémiová místa se zobrazí zde'),
                )
              : Column(
                  children: ids.map((id) => _PurchasedPoiTile(poiId: id)).toList(),
                ),
          ),

          // Premium Bundle nákupy
          _SectionHeader(title: '📦 Premium Bundly'),
          bundleIdsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const ListTile(title: Text('Chyba při načítání')),
            data: (ids) => ids.isEmpty
              ? const ListTile(
                  title: Text('Žádné bundly'),
                  subtitle: Text('Zakoupené premium bundly oblastí se zobrazí zde'),
                )
              : Column(
                  children: ids.map((id) => _PurchasedBundleTile(areaId: id)).toList(),
                ),
          ),
        ]),
      ),
    );
  }
}

// ── Pomocné widgety pro MyPurchasesScreen ──────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
    );
  }
}

class _PurchasedPoiTile extends ConsumerWidget {
  final String poiId;
  const _PurchasedPoiTile({required this.poiId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(poiDetailProvider(poiId)).maybeWhen(
      data: (poi) => ListTile(
        leading: const Icon(Icons.star, color: Colors.amber),
        title: Text(poi.localizedName),
        subtitle: poi.areaSlug != null ? Text(poi.areaSlug!) : null,
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: () => context.push('/poi/$poiId'),
      ),
      orElse: () => const ListTile(
        leading: SizedBox(width: 24, height: 24,
          child: CircularProgressIndicator(strokeWidth: 2)),
        title: Text('Načítám...'),
      ),
    );
  }
}

class _PurchasedBundleTile extends ConsumerWidget {
  final String areaId;
  const _PurchasedBundleTile({required this.areaId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(areaDetailProvider(areaId)).maybeWhen(
      data: (area) => ListTile(
        leading: const Icon(Icons.dashboard, color: Colors.orange),
        title: Text(area.localizedName),
        subtitle: const Text('Premium Bundle – veškerý prémiový obsah'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: () => context.push('/area/$areaId'),
      ),
      orElse: () => const ListTile(
        leading: SizedBox(width: 24, height: 24,
          child: CircularProgressIndicator(strokeWidth: 2)),
        title: Text('Načítám...'),
      ),
    );
  }
}
```

### 5.13 Smart URI – Flutter router handler

```dart
// lib/router/app_router.dart – přidat route pro smart URI:

GoRoute(
  path: '/place/:areaSlug/:poiSlug',
  builder: (context, state) {
    final areaSlug = state.pathParameters['areaSlug']!;
    final poiSlug = state.pathParameters['poiSlug']!;
    return PoiBySlugScreen(areaSlug: areaSlug, poiSlug: poiSlug);
  },
),
```

```dart
// lib/screens/poi/poi_by_slug_screen.dart
// Resolver – načte poiId ze slugu a přesměruje na PoiDetailScreen

class PoiBySlugScreen extends ConsumerWidget {
  final String areaSlug;
  final String poiSlug;
  const PoiBySlugScreen({required this.areaSlug, required this.poiSlug, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<PoiModel?>(
      future: ref.read(poiRepositoryProvider).getPoiBySlug(areaSlug, poiSlug),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final poi = snapshot.data;
        if (poi == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.place_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('Místo nenalezeno', style: TextStyle(fontSize: 18)),
                const SizedBox(height: 8),
                TextButton(onPressed: () => context.go('/'), child: const Text('Zpět na mapu')),
              ]),
            ),
          );
        }
        // Přesměruj na standardní POI detail
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.replace('/poi/${poi.id}');
        });
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
```

### 5.14 Aktualizace sdílení POI `share_poi_button.dart`

```dart
// lib/features/poi_detail/widgets/share_poi_button.dart
// Nahrazuje původní implementaci z UC-45

Future<void> sharePoi(PoiModel poi, String languageCode) async {
  final name = poi.localizedName;
  final areaSlug = poi.areaSlug ?? '';
  final poiSlug = poi.slug ?? poi.id;

  // Smart URI pro sdílení
  final smartUrl = 'https://placesecrets.app/place/$areaSlug/$poiSlug';

  await Share.share(
    '$name\n$smartUrl',
    subject: name,
  );
}
```

### 5.15 Filtry na mapě a v seznamu

```dart
// map_screen.dart – přidat filter chips:
Set<PoiAccessLevel> _accessFilter = PoiAccessLevel.values.toSet();

Wrap(spacing: 8, children: [
  FilterChip(label: const Text('🌐 Vše'),
    selected: _accessFilter.length == PoiAccessLevel.values.length,
    onSelected: (_) => setState(() => _accessFilter = PoiAccessLevel.values.toSet())),
  FilterChip(label: const Text('👤 Zdarma'),
    selected: _accessFilter.contains(PoiAccessLevel.registered),
    onSelected: (v) => setState(() => v
      ? _accessFilter.add(PoiAccessLevel.registered)
      : _accessFilter.remove(PoiAccessLevel.registered))),
  FilterChip(label: const Text('🏙️ Oblast'),
    selected: _accessFilter.contains(PoiAccessLevel.cityAccess),
    onSelected: (v) => setState(() => v
      ? _accessFilter.add(PoiAccessLevel.cityAccess)
      : _accessFilter.remove(PoiAccessLevel.cityAccess))),
  FilterChip(label: const Text('⭐ Premium'),
    selected: _accessFilter.contains(PoiAccessLevel.premiumPoi),
    onSelected: (v) => setState(() => v
      ? _accessFilter.add(PoiAccessLevel.premiumPoi)
      : _accessFilter.remove(PoiAccessLevel.premiumPoi))),
])

// Barvy a ikony pinů dle access level:
MarkerOptions _markerOptions(PoiModel poi) {
  final color = switch (poi.accessLevel) {
    PoiAccessLevel.public     => Colors.green,
    PoiAccessLevel.registered => Colors.blue,
    PoiAccessLevel.cityAccess => Colors.orange,
    PoiAccessLevel.premiumPoi => Colors.amber,
  };
  // Prémiové POI mají lock ikonu
  final icon = poi.accessLevel == PoiAccessLevel.premiumPoi
    ? Icons.lock
    : Icons.place;
  return MarkerOptions(color: color, icon: icon);
}
```

```dart
// area_detail_screen.dart – záložky + access stat widget:

// Stat widget nad seznamem:
Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
  _AccessStat(icon: '🌐', label: 'Veřejná', color: Colors.green,
    count: pois.where((p) => p.accessLevel == PoiAccessLevel.public).length),
  _AccessStat(icon: '👤', label: 'Zdarma', color: Colors.blue,
    count: pois.where((p) => p.accessLevel == PoiAccessLevel.registered).length),
  _AccessStat(icon: '🏙️', label: 'Oblast', color: Colors.orange,
    count: pois.where((p) => p.accessLevel == PoiAccessLevel.cityAccess).length),
  _AccessStat(icon: '⭐', label: 'Premium', color: Colors.amber,
    count: pois.where((p) => p.accessLevel == PoiAccessLevel.premiumPoi).length),
])

// Záložkový filtr:
DefaultTabController(length: 4, child: Column(children: [
  const TabBar(isScrollable: true, tabs: [
    Tab(text: '🌐 Vše'), Tab(text: '👤 Zdarma'),
    Tab(text: '🏙️ Oblast'), Tab(text: '⭐ Premium'),
  ]),
  Expanded(child: TabBarView(children: [
    _PoiList(pois: pois),
    _PoiList(pois: pois.where((p) => p.accessLevel == PoiAccessLevel.registered).toList()),
    _PoiList(pois: pois.where((p) => p.accessLevel == PoiAccessLevel.cityAccess).toList()),
    _PoiList(pois: pois.where((p) => p.accessLevel == PoiAccessLevel.premiumPoi).toList()),
  ])),
]))
```

---

## SEKCE 6 – KOMPLETNÍ CHECKLIST IMPLEMENTACE

### Databáze
- [ ] `supabase/migrations/010_access_levels.sql` – slugy, access_level, prémiový obsah, nákupy, RPC funkce, pohled
- [ ] Supabase Storage: vytvořit bucket `premium-audio` (private) + RLS policy
- [ ] Stripe Dashboard: přidat webhook endpoint `confirm-poi-payment`, uložit signing secret

### Edge Functions
- [ ] `supabase/functions/confirm-poi-payment/index.ts` – Stripe webhook → zápis nákupu + email
- [ ] `supabase/functions/create-poi-checkout/index.ts` – vytvoří Stripe Checkout session

### Admin panel (Vite/React)
- [ ] `npm install react-helmet-async`
- [ ] `src/main.tsx` – obalit HelmetProvider
- [ ] `src/components/poi/PoiForm.tsx` – slug field + access_level dropdown + perex + premium_price
- [ ] `src/components/poi/PremiumContentTab.tsx` – **NOVÝ** (audio upload, text, fotky, related POI)
- [ ] `src/pages/admin/PoiDetailPage.tsx` – přidat záložku ⭐ Prémiový obsah
- [ ] `src/pages/admin/AreaPricingPage.tsx` – **NOVÁ**
- [ ] `src/pages/admin/PurchasesOverviewPage.tsx` – **NOVÁ**
- [ ] `src/pages/PlaceDetailPage.tsx` – **NOVÁ** (veřejná smart URI stránka)
- [ ] `src/pages/admin/PoisPage.tsx` – přidat access_level filtr
- [ ] `src/router.tsx` – přidat 3 nové routes
- [ ] Sidebar – přidat odkaz na Prémiové nákupy

### Flutter aplikace
- [ ] `lib/models/poi_model.dart` – přidat accessLevel, perex, premiumPrice, slug, areaSlug + join `areas!inner(slug)` ve všech queries
- [ ] `lib/models/poi_premium_content_model.dart` – **NOVÝ**
- [ ] `lib/database/tables/purchased_pois_table.dart` – **NOVÝ**
- [ ] `lib/database/tables/purchased_area_bundles_table.dart` – **NOVÝ**
- [ ] `lib/repositories/poi_repository.dart` – přidat 6 nových metod vč. getPoiAccessOfflineByPoiId + syncPurchasesToLocal
- [ ] `lib/repositories/payment_repository.dart` – **NOVÝ** (createPoiCheckout → Edge Function)
- [ ] `lib/providers/poi_access_provider.dart` – **NOVÝ** (4 providery, offline fallback)
- [ ] `lib/providers/auth_provider.dart` – přidat invalidaci access providerů při auth change
- [ ] `lib/screens/poi/poi_detail_screen.dart` – přepsat s access logikou + share button
- [ ] `lib/screens/poi/widgets/premium_poi_content.dart` – **NOVÝ**
- [ ] `lib/screens/poi/poi_by_slug_screen.dart` – **NOVÝ** (smart URI resolver)
- [ ] `lib/screens/purchase/purchase_poi_screen.dart` – **NOVÁ**
- [ ] `lib/screens/purchase/purchase_area_screen.dart` – přidat premium bundle sekci
- [ ] `lib/screens/account/my_purchases_screen.dart` – **NOVÁ** (vč. _SectionHeader, _PurchasedPoiTile, _PurchasedBundleTile)
- [ ] `lib/screens/map/map_screen.dart` – filter chips + barevné piny + lock ikona
- [ ] `lib/screens/area/area_detail_screen.dart` – záložky + access stat widget
- [ ] `lib/screens/settings/settings_screen.dart` – access filter preference
- [ ] `lib/router/app_router.dart` – přidat route /place/:areaSlug/:poiSlug
- [ ] `lib/app/deep_link_handler.dart` – opravená signatura (WidgetRef + BuildContext parametry)
- [ ] `lib/features/poi_detail/widgets/share_poi_button.dart` – aktualizovat na smart URI
- [ ] `pubspec.yaml` – ověřit url_launcher

---

## SEKCE 7 – BUSINESS LOGIKA & SCÉNÁŘE

```
── VLOŽENÍ OBSAHU (admin) ─────────────────────────────────────
1. Admin vytvoří POI → vybere access_level + vyplní perex
2. Pokud premium_poi → nastaví premium_price
3. Na záložce "Prémiový obsah" přidá audio (upload do Storage),
   prémiový text, extra fotky, propojená místa
4. V AreaPricingPage nastaví city_access_price, premium_bundle_price,
   registered_sample_poi_id

── PLATEBNÍ FLOW ─────────────────────────────────────────────
5. Uživatel klikne "Zakoupit" v PurchasePoiScreen
6. App zavolá Edge Function create-poi-checkout
7. Edge Function vytvoří Stripe Checkout session s metadata
   (user_id, purchase_type, poi_id/area_id)
8. App otevře Stripe URL v externím prohlížeči
9. Uživatel zaplatí kartou na Stripe
10. Stripe odešle webhook na confirm-poi-payment Edge Function
11. Edge Function ověří podpis, zapíše do user_poi_purchases/
    user_area_premium_purchases (server-side, service_role)
12. Edge Function odešle potvrzovací email přes Resend
13. Stripe přesměruje uživatele na success_url
    (deep link: placesecrets://purchase/success?poi_id=...)
14. App zpracuje deep link → invaliduje poiAccessProvider
15. App sync do lokální Drift DB (syncPurchasesToLocal)
16. App přejde na POI detail → prémiový obsah je viditelný

── OPĚTOVNÉ PŘIHLÁŠENÍ ───────────────────────────────────────
17. Uživatel se odhlásí → authStateProvider emituje změnu
18. Všechny poiAccessProvider se invalidují (sledují authStateProvider)
19. purchasedPoiIdsProvider a purchasedAreaBundleIdsProvider
    se invalidují → vrátí prázdné sety
20. Uživatel se přihlásí → authStateProvider emituje změnu
21. Providery se re-fetched → načtou nákupy ze Supabase
22. syncPurchasesToLocal() zaktualizuje lokální Drift cache
23. Prémiový obsah je opět dostupný

── OFFLINE PŘÍSTUP ───────────────────────────────────────────
24. Uživatel je offline → poiAccessProvider selže (network error)
25. Fallback: getPoiAccessOffline() zkontroluje lokální Drift DB
26. Pokud má zakoupené POI v lokální DB → vrátí 'premium_poi'
27. Prémiový obsah (text, audio) musí být stažen při posledním
    online přístupu a cachován (TODO: implementovat download cache)

── SMART URI SDÍLENÍ ─────────────────────────────────────────
28. Uživatel sdílí POI → share_poi_button vytvoří URL:
    https://placesecrets.app/place/{area-slug}/{poi-slug}
29. Příjemce otevře URL v prohlížeči → PlaceDetailPage
30. Vidí název, perex, OG meta tagy (náhled ve zprávách)
31. Tlačítko "Otevřít v aplikaci" → deep link placesecrets://
32. Pokud app není nainstalovaná → odkaz na App Store / Google Play
33. Pokud app je nainstalovaná → PoiBySlugScreen resolves → PoiDetailScreen
```

---

*Konec DIFF-002-r2*
