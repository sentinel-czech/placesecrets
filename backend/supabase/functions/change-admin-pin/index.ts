import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import bcrypt from 'https://esm.sh/bcryptjs@2.4.3'
import { handleAdminCors, getAdminCorsHeaders } from '../_shared/cors.ts'
import { PIN_RE } from '../_shared/validation.ts'

function json(body: Record<string, unknown>, req: Request, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...getAdminCorsHeaders(req), 'Content-Type': 'application/json' },
  })
}

function err(message: string, req: Request, status = 400): Response {
  return json({ error: message }, req, status)
}

Deno.serve(async (req) => {
  const corsResponse = handleAdminCors(req)
  if (corsResponse) return corsResponse

  try {
    const authHeader = req.headers.get('Authorization')
    if (!authHeader?.startsWith('Bearer ')) {
      return err('Invalid authorization', req, 401)
    }
    const token = authHeader.substring(7)

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
      { auth: { persistSession: false } }
    )

    const { data: { user }, error: authError } = await supabaseAdmin.auth.getUser(token)
    if (authError || !user) return err('Invalid token', req, 401)

    const { current_pin, new_pin } = await req.json()

    if (!new_pin || typeof new_pin !== 'string' || new_pin.length === 0) {
      return err('New PIN is required', req)
    }

    // Try selecting with must_change_pin; fall back without it if column doesn't exist yet
    let admin: Record<string, unknown> | null = null
    {
      const { data, error: e1 } = await supabaseAdmin
        .from('admin_users')
        .select('id, pin_hash, must_change_pin')
        .eq('user_id', user.id)
        .single()

      if (e1 && e1.message?.includes('must_change_pin')) {
        const { data: d2, error: e2 } = await supabaseAdmin
          .from('admin_users')
          .select('id, pin_hash')
          .eq('user_id', user.id)
          .single()
        if (e2 || !d2) return err('Not an admin user', req, 403)
        admin = { ...d2, must_change_pin: false }
      } else if (e1 || !data) {
        return err('Not an admin user', req, 403)
      } else {
        admin = data
      }
    }

    if (!admin) return err('Not an admin user', req, 403)

    // Force-change mode: must_change_pin is true, skip current_pin verification
    if (admin.must_change_pin) {
      // No current_pin required in force-change mode
    } else if (admin.pin_hash) {
      // Normal mode: verify current PIN
      if (!current_pin) return err('Current PIN required', req)
      const valid = await bcrypt.compare(current_pin, admin.pin_hash)
      if (!valid) {
        return err('Current PIN is incorrect', req, 401)
      }
    }

    // Validate new PIN. Must be exactly 6 digits (shared PIN_RE), consistent with
    // verify-admin-pin — a longer PIN set here could never be verified at login,
    // and an unbounded length is also a bcrypt-input DoS vector.
    if (typeof new_pin !== 'string' || !PIN_RE.test(new_pin)) {
      return err('PIN must be exactly 6 digits', req)
    }

    const newHash = await bcrypt.hash(new_pin, 10)
    const { error: updateErr } = await supabaseAdmin
      .from('admin_users')
      .update({
        pin_hash: newHash,
        pin_set_at: new Date().toISOString(),
        must_change_pin: false,
      })
      .eq('id', admin.id)

    if (updateErr) {
      console.error('PIN update error:', updateErr.message)
      return err('Failed to save PIN', req, 500)
    }

    return json({ success: true }, req)
  } catch (e) {
    console.error('change-admin-pin error:', e)
    return err('Internal error', req, 500)
  }
})
