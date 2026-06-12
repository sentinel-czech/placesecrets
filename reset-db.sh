#!/usr/bin/env bash
# Reset the local Supabase database: drops, re-applies all migrations, and reseeds.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Resetting PlaceSecrets Database ==="
cd "$SCRIPT_DIR/backend/supabase"

npx supabase db reset

echo ""
echo "Database reset complete."
echo "  Superadmin: vtm@placesecrets.cz / vtm999 (PIN: 123456)"
echo "  Studio:     http://127.0.0.1:54323"
