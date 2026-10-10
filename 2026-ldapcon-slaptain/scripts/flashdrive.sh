#!/bin/bash
# Build everything needed to present from a flash drive / offline laptop into
# one ready-to-copy ./flashdrive/ folder:
#
#   index.html    — self-contained single-file deck (interactive, offline,
#                   no server and no npm — just open it in a browser)
#   <deck>.pdf    — universal static fallback (any PDF reader)   [needs Chromium]
#   <deck>.pptx   — PowerPoint fallback, slides as images        [needs Chromium]
#   README.txt    — how to present
#
# The single-file HTML always builds. PDF/PPTX need a Playwright Chromium
# binary; if it is absent they are skipped with a note rather than failing
# the whole run.
#
# Usage: ./scripts/flashdrive.sh [slides.md]

set -euo pipefail

SLIDES="${1:-slides.md}"
OUT="flashdrive"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR/.."
# shellcheck source=_deckname.sh
. "$SCRIPT_DIR/_deckname.sh"
DECK="$(deck_name)"

echo "==> Cleaning $OUT/"
rm -rf "$OUT"
mkdir -p "$OUT"

echo "==> [1/3] Single-file portable HTML"
SLIDEV_PORTABLE=1 npx slidev build "$SLIDES" --base ./ --out dist-single
cp dist-single/index.html "$OUT/index.html"

# PDF/PPTX export drives a real browser. Prefer Playwright's own Chromium; fall
# back to a browser already installed on the host (very common, and it saves a
# ~200 MB download); skip the exports only if neither exists.
EXEC=""
if node -e "const{chromium}=require('playwright-chromium');process.exit(require('fs').existsSync(chromium.executablePath())?0:1)" 2>/dev/null; then
  EXEC="playwright"
else
  for b in chromium chromium-browser google-chrome-stable google-chrome; do
    if command -v "$b" >/dev/null 2>&1; then EXEC="$(command -v "$b")"; break; fi
  done
fi

case "$EXEC" in
  "")          EXPORT_ARGS="" ;;
  playwright)  EXPORT_ARGS="" ;;
  *)           EXPORT_ARGS="--executable-path $EXEC"; echo "    (using system browser: $EXEC)" ;;
esac

if [ -n "$EXEC" ]; then
  echo "==> [2/3] PDF (click-steps flattened into separate pages)"
  npx slidev export "$SLIDES" --with-clicks $EXPORT_ARGS --output "$OUT/$DECK.pdf"
  echo "==> [3/3] PPTX"
  npx slidev export "$SLIDES" --format pptx $EXPORT_ARGS --output "$OUT/$DECK.pptx"
else
  echo "==> [2/3] PDF  — SKIPPED: no Chromium found (Playwright's or the host's)."
  echo "==> [3/3] PPTX — SKIPPED: same reason."
  echo "           To enable: npx playwright-chromium install chromium"
  echo "           …or install a system chromium; this script will find it."
fi

cat > "$OUT/README.txt" <<TXT
Presenting from this folder
===========================

PREFERRED — interactive, works offline, no install:
  Open  index.html  in any modern browser (Chrome/Edge/Firefox).
  - Arrow keys or click to advance. Press F for fullscreen, O for overview.
  - Everything (fonts, images, code) is embedded; no internet needed.

FALLBACK — if the browser is locked down, or only Office is available
(present only if the files are actually in this folder):
  $DECK.pdf     Open in any PDF reader or browser. Use fullscreen.
  $DECK.pptx    Open in PowerPoint / LibreOffice Impress / Google Slides.
                (Slides are images — layout is exact, but not editable.)
TXT

echo
echo "==> Done. Copy the whole folder:"
ls -lh "$OUT"
echo
echo "    $OUT/ total: $(du -sh "$OUT" | cut -f1)"
