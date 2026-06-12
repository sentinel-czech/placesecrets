#!/usr/bin/env bash
# Reset the local Supabase database: drops, re-applies all migrations, and reseeds.
# DESTRUCTIVE. Prompts for confirmation unless FORCE_RESET=1 or -y/--yes is passed.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Confirmation guard (skippable for CI/non-interactive)
if [[ "${FORCE_RESET:-}" != "1" && "${1:-}" != "-y" && "${1:-}" != "--yes" ]]; then
  echo "WARNING: this WIPES the local Supabase database (all local data is lost)."
  read -r -p "Type 'yes' to continue: " confirm
  if [[ "$confirm" != "yes" ]]; then
    echo "Aborted."
    exit 1
  fi
fi

echo "=== Resetting PlaceSecrets Database ==="
cd "$SCRIPT_DIR/backend/supabase"

npx supabase db reset

echo ""
echo "Database reset complete. Local seed credentials & ports: see DEV.md"
echo "  Studio: http://127.0.0.1:54323"
