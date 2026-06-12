#!/usr/bin/env bash
# Start Supabase backend (stop existing instance first).
# Ports configured in backend/supabase/config.toml.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Starting PlaceSecrets Backend ==="
echo ""

cd "$SCRIPT_DIR/backend/supabase"

echo "Stopping existing Supabase instance..."
npx supabase stop 2>/dev/null || true

echo "Starting Supabase..."
npx supabase start

echo ""
echo "=== Supabase is running ==="
echo "  Studio:    http://127.0.0.1:54323"
echo "  API:       http://127.0.0.1:54321"
echo "  DB:        postgresql://postgres:postgres@127.0.0.1:54322/postgres"
echo "  Mailpit:   http://127.0.0.1:54324"
