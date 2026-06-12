#!/usr/bin/env bash
# Start Vite dev server for the web portal (kill existing instance on the port first).

set -euo pipefail

PORT=5173
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Starting PlaceSecrets Web Portal ==="
echo ""

# Kill any process on the port
lsof -ti:"$PORT" | xargs kill 2>/dev/null || true

cd "$SCRIPT_DIR/web"

echo "Installing dependencies..."
npm install --silent

echo ""
echo "  Web portal: http://localhost:$PORT"
echo "  Login:      vtm@placesecrets.cz / vtm999 (PIN: 123456)"
echo ""
exec npx vite --port "$PORT"
