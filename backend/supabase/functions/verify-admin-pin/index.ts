import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import bcrypt from 'https://esm.sh/bcryptjs@2.4.3'
import { handleAdminCors, getAdminCorsHeaders } from '../_shared/cors.ts'

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

    const { pin } = await req.json()
    if (!pin || typeof pin !== 'string' || !/^\d{6}$/.test(pin)) {
      return err('PIN must be exactly 6 digits', req)
    }

    // Try selecting with must_change_pin; fall back without it if column doesn't exist yet
    let admin: Record<string, unknown> | null = null
    {
      const { data, error: e1 } = await supabaseAdmin
        .from('admin_users')
        .select('id, role, pin_hash, pin_attempts, pin_locked_until, must_change_pin')
        .eq('user_id', user.id)
        .single()

      if (e1 && e1.message?.includes('must_change_pin')) {
        // Column doesn't exist yet — query without it
        const { data: d2, error: e2 } = await supabaseAdmin
          .from('admin_users')
          .select('id, role, pin_hash, pin_attempts, pin_locked_until')
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

    // Check lockout
    if (admin.pin_locked_until) {
      const lockedUntil = new Date(admin.pin_locked_until)
      if (lockedUntil > new Date()) {
        const minutesLeft = Math.ceil((lockedUntil.getTime() - Date.now()) / 60000)
        return err(`Account locked. Try again in ${minutesLeft} minute(s).`, req, 429)
      }
    }

    // First time: set PIN
    if (!admin.pin_hash) {
      const hash = await bcrypt.hash(pin, 10)
      await supabaseAdmin
        .from('admin_users')
        .update({ pin_hash: hash, pin_set_at: new Date().toISOString(), pin_attempts: 0, pin_locked_until: null })
        .eq('id', admin.id)

      return json({ success: true, first_time: true, role: admin.role, must_change_pin: admin.must_change_pin ?? false }, req)
    }

    // Verify PIN
    const valid = await bcrypt.compare(pin, admin.pin_hash)

    if (!valid) {
      // Atomic increment to prevent race condition
      const { data: attemptResult } = await supabaseAdmin.rpc('increment_pin_attempts', {
        p_admin_id: admin.id,
      })
      const row = Array.isArray(attemptResult) ? attemptResult[0] : attemptResult
      if (row?.is_locked) {
        return err('Too many failed attempts. Account locked for 15 minutes.', req, 429)
      }
      return err('Invalid PIN', req, 401)
    }

    // Success: atomic reset
    await supabaseAdmin.rpc('reset_pin_attempts', { p_admin_id: admin.id })

    return json({ success: true, first_time: false, role: admin.role, must_change_pin: admin.must_change_pin ?? false }, req)
  } catch (e) {
    console.error('verify-admin-pin error:', e)
    return err('Internal error', req, 500)
  }
})
