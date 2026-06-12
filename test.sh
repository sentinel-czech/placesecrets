#!/usr/bin/env bash
# Run all PlaceSecrets tests: web portal, TypeScript type check, Edge Functions.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EXIT_CODE=0

echo "=== PlaceSecrets Test Suite ==="
echo ""

# Web portal tests
echo "[1/3] Web portal tests..."
cd "$SCRIPT_DIR/web"
if npx vitest run 2>&1; then
  echo "  ✓ Web tests passed"
else
  echo "  ✗ Web tests failed"
  EXIT_CODE=1
fi

echo ""

# Web portal type check
echo "[2/3] TypeScript type check..."
if npx tsc --noEmit 2>&1; then
  echo "  ✓ Types OK"
else
  echo "  ✗ Type errors found"
  EXIT_CODE=1
fi

echo ""

# Edge function tests
echo "[3/3] Edge Function tests..."
cd "$SCRIPT_DIR/backend/supabase/functions/__tests__"
if npx vitest run 2>&1; then
  echo "  ✓ Edge Function tests passed"
else
  echo "  ✗ Edge Function tests failed"
  EXIT_CODE=1
fi

echo ""
if [ $EXIT_CODE -eq 0 ]; then
  echo "=== All tests passed ==="
else
  echo "=== Some tests failed ==="
fi
exit $EXIT_CODE
