const ALLOWED_ORIGINS = [
  'https://admin.placesecrets.app',
  'https://admin.herodots.app',
  'http://localhost:5173',
  'http://localhost:4173',
]

function getOriginHeader(origin: string | null): string {
  if (origin && ALLOWED_ORIGINS.includes(origin)) return origin
  return ALLOWED_ORIGINS[0]
}

export const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-webhook-secret',
}

export const adminCorsHeaders = {
  'Access-Control-Allow-Origin': ALLOWED_ORIGINS[0],
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Credentials': 'true',
}

export function getAdminCorsHeaders(req: Request): Record<string, string> {
  const origin = req.headers.get('origin')
  return {
    ...adminCorsHeaders,
    'Access-Control-Allow-Origin': getOriginHeader(origin),
  }
}

export function handleCors(req: Request): Response | null {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }
  return null
}

export function handleAdminCors(req: Request): Response | null {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: getAdminCorsHeaders(req) })
  }
  return null
}

export function jsonResponse(body: Record<string, unknown>, status = 200, headers?: Record<string, string>): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...(headers || corsHeaders), 'Content-Type': 'application/json' },
  })
}

export function adminJsonResponse(body: Record<string, unknown>, req: Request, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...getAdminCorsHeaders(req), 'Content-Type': 'application/json' },
  })
}

export function errorResponse(message: string, status = 400): Response {
  return jsonResponse({ error: message }, status)
}

export function adminErrorResponse(message: string, req: Request, status = 400): Response {
  return adminJsonResponse({ error: message }, req, status)
}
