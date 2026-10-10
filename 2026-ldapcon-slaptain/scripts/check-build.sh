#!/bin/bash
# Lint the deck by actually building it: catches mermaid syntax errors, bad
# layouts, missing components and broken frontmatter — things `npm run dev`
# hides until you navigate to the offending slide.
#
# Run this after every non-trivial edit to slides.md.
#
# Usage: ./scripts/check-build.sh [slides.md]

set -uo pipefail

SLIDES="${1:-slides.md}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR/.."

OUT=$(mktemp -d -p . dist-check.XXXXXX)
trap 'rm -rf "$OUT"' EXIT

# The INVALID_ANNOTATION / rolldown / #__PURE__ lines are harmless warnings from
# dependencies — filter them out so real errors are visible.
npx slidev build "$SLIDES" --out "$OUT" 2>&1 \
  | grep -iE '✓ built|error|fail|warn' \
  | grep -viE 'INVALID_ANNOTATION|rolldown|#__PURE__|pure annotation'
STATUS=${PIPESTATUS[0]}

if [ "$STATUS" -eq 0 ]; then
  echo "OK: $SLIDES builds clean."
else
  echo "FAILED: $SLIDES did not build (exit $STATUS)." >&2
fi
exit "$STATUS"
