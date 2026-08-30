#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VAULT_RECIPES="/Users/kevinlang/Library/Mobile Documents/iCloud~md~obsidian/Documents/Kevin/Cooking/Recipes"

cd "$SCRIPT_DIR"

# Guard against an unsynced / missing iCloud vault: without this, an empty
# source plus --delete would wipe every published recipe and commit it.
if [ ! -d "$VAULT_RECIPES" ] || [ -z "$(find "$VAULT_RECIPES" -name '*.md' -print -quit)" ]; then
  echo "ERROR: no recipes found at $VAULT_RECIPES (vault missing or not synced yet)." >&2
  exit 1
fi

echo "=== Step 1: Sync + validate images ==="
"$SCRIPT_DIR/sync-images.sh"

echo ""
echo "=== Step 2: Publish recipes ==="
rsync -av --delete --exclude='.DS_Store' "$VAULT_RECIPES" "."
git add -A

if git diff --cached --quiet; then
  echo "No changes to commit."
else
  git commit -m "update recipes"
  git push origin HEAD
fi

echo ""
echo "Done."