#!/usr/bin/env bash
# Stop all PlaceSecrets dev services (web frontend + Supabase).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Stopping PlaceSecrets Dev Environment ==="

# Stop web frontend (kill port 5173)
if lsof -ti:5173 >/dev/null 2>&1; then
  echo "Stopping web dev server (port 5173)..."
  kill $(lsof -ti:5173) 2>/dev/null || true
fi

# Stop Edge Functions serve
if pgrep -f 'edge-runtime' >/dev/null 2>&1; then
  echo "Stopping Edge Functions..."
  pkill -f 'edge-runtime' 2>/dev/null || true
fi

# Stop Supabase
echo "Stopping Supabase..."
cd "$SCRIPT_DIR/backend/supabase"
npx supabase stop 2>&1 || true

echo ""
echo "All services stopped."
