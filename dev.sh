#!/usr/bin/env bash
# Start both Supabase backend and web frontend in one command.
# Supabase runs first (blocking until ready), then Edge Functions + Vite.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== PlaceSecrets Dev Environment ==="
echo ""

# Start Supabase backend
echo "[1/4] Starting Supabase..."
cd "$SCRIPT_DIR/backend/supabase"
npx supabase start 2>&1 | tail -20

echo ""
echo "[2/4] Supabase ready."

# Show connection info
echo ""
echo "  Studio:    http://127.0.0.1:54323"
echo "  API:       http://127.0.0.1:54321"
echo "  DB:        postgresql://postgres:postgres@127.0.0.1:54322/postgres"
echo "  Mailpit:   http://127.0.0.1:54324"
echo ""

# Start Edge Functions in background
echo "[3/4] Starting Edge Functions..."
cd "$SCRIPT_DIR/backend/supabase"
npx supabase functions serve --no-verify-jwt > /tmp/placesecrets-functions.log 2>&1 &
echo "  Edge Functions running (log: /tmp/placesecrets-functions.log)"
echo ""

# Start web frontend
echo "[4/4] Starting web dev server..."
cd "$SCRIPT_DIR/web"
npm install --silent 2>/dev/null
echo ""
echo "  Web portal: http://localhost:5173"
echo "  Local seed login: see DEV.md"
echo ""
exec npm run dev
