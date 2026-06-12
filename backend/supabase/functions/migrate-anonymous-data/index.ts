import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
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

  if (req.method !== 'POST') {
    return err('Method Not Allowed', req, 405)
  }

  const ct = req.headers.get('content-type') ?? ''
  if (!ct.includes('application/json')) {
    return err('Content-Type must be application/json', req, 415)
  }

  const authHeader = req.headers.get('Authorization')
  if (!authHeader?.startsWith('Bearer ')) {
    return err('Invalid authorization', req, 401)
  }
  const token = authHeader.substring(7)

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    { auth: { persistSession: false } }
  )

  const { data: { user }, error: authError } = await supabase.auth.getUser(token)
  if (authError || !user) return err('Unauthorized', req, 401)

  let body: Record<string, unknown>
  try {
    body = await req.json()
  } catch {
    return err('Invalid JSON body', req)
  }

  const { old_device_id } = body as { old_device_id?: string }
  if (!old_device_id || typeof old_device_id !== 'string') {
    return err('Missing required field: old_device_id', req)
  }

  if (!/^[a-zA-Z0-9_-]{1,128}$/.test(old_device_id)) {
    return err('Invalid device_id format', req)
  }

  try {
    const { error: rpcError } = await supabase.rpc('migrate_anonymous_data', {
      p_old_device_id: old_device_id,
      p_new_user_id: user.id,
    })

    if (rpcError) {
      console.error('migrate-anonymous-data RPC error:', rpcError.message)
      return err('Failed to migrate data', req, 500)
    }

    return json({ success: true }, req)
  } catch (e) {
    console.error('migrate-anonymous-data error:', e)
    return err('Internal error', req, 500)
  }
})
