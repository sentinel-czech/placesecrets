import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { handleAdminCors, adminJsonResponse, adminErrorResponse } from '../_shared/cors.ts'

Deno.serve(async (req) => {
  const corsResponse = handleAdminCors(req)
  if (corsResponse) return corsResponse

  try {
    const authHeader = req.headers.get('Authorization')
    if (!authHeader?.startsWith('Bearer ')) return adminErrorResponse('Invalid authorization', req, 401)
    const token = authHeader.substring(7)

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
      { auth: { persistSession: false } }
    )

    const { data: { user }, error: authError } = await supabaseAdmin.auth.getUser(token)
    if (authError || !user) return adminErrorResponse('Invalid token', req, 401)

    // Check caller is admin
    const { data: admin } = await supabaseAdmin
      .from('admin_users')
      .select('role')
      .eq('user_id', user.id)
      .single()

    if (!admin) {
      return adminErrorResponse('Insufficient permissions', req, 403)
    }

    // Check ACL for contributors write permission (superadmin bypasses)
    if (admin.role !== 'superadmin') {
      const { data: perms } = await supabaseAdmin.rpc('get_role_permissions', { target_role: admin.role })
      const contribPerm = (perms as { resource: string; can_write: boolean }[] | null)
        ?.find(p => p.resource === 'contributors')
      if (!contribPerm?.can_write) {
        return adminErrorResponse('Insufficient permissions', req, 403)
      }
    }

    const { email, display_name } = await req.json()
    if (!email || typeof email !== 'string') return adminErrorResponse('Email required', req)
    if (!display_name || typeof display_name !== 'string') return adminErrorResponse('Display name required', req)

    const emailRegex = /^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$/
    if (!emailRegex.test(email)) return adminErrorResponse('Invalid email format', req)

    // Send invite via Resend
    const resendKey = Deno.env.get('RESEND_API_KEY')
    if (resendKey) {
      const res = await fetch('https://api.resend.com/emails', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${resendKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          from: 'PlaceSecrets <noreply@placesecrets.app>',
          to: [email],
          subject: 'Invitation to contribute on PlaceSecrets',
          html: `
            <h2>Hello ${display_name.replace(/</g, '&lt;').replace(/>/g, '&gt;')}!</h2>
            <p>You've been invited to become a contributor on PlaceSecrets.</p>
            <p>Register at: <a href="https://admin.placesecrets.app/register/contributor">PlaceSecrets Contributor Portal</a></p>
            <p>Use this email address (${email.replace(/</g, '&lt;').replace(/>/g, '&gt;')}) when registering.</p>
          `,
        }),
      })

      if (!res.ok) {
        const errBody = await res.text()
        console.error('invite-contributor email error:', errBody)
        return adminErrorResponse('Failed to send invitation email', req, 500)
      }
    }

    return adminJsonResponse({ success: true, email }, req)
  } catch (e) {
    console.error('invite-contributor error:', e)
    return adminErrorResponse('Internal error', req, 500)
  }
})
