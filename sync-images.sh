#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

VAULT_PHOTOS="/Users/kevinlang/Library/Mobile Documents/iCloud~md~obsidian/Documents/Kevin/Recipes/Photos"
R2_REMOTE="r2:website-assets/recipe-photos"   # remote name must match the [section] in ./rclone.conf

# The directory of recipes whose images to validate. publish.sh passes its
# staging dir (the recipes about to be published) as $1.
RECIPES_DIR="${1:-}"
if [ -z "$RECIPES_DIR" ] || [ ! -d "$RECIPES_DIR" ]; then
  echo "ERROR: usage: sync-images.sh <recipes-dir>  (run ./publish.sh instead)" >&2
  exit 1
fi

# Use a project-local rclone config (gitignored) instead of ~/.config/rclone.
# Copy rclone.conf.example to rclone.conf and fill in your R2 credentials.
export RCLONE_CONFIG="$SCRIPT_DIR/rclone.conf"

if ! command -v rclone >/dev/null 2>&1; then
  echo "ERROR: rclone not found on PATH. Install it (https://rclone.org/downloads/) and retry." >&2
  exit 1
fi

if [ ! -f "$RCLONE_CONFIG" ]; then
  echo "ERROR: $RCLONE_CONFIG not found. Copy rclone.conf.example and fill in your R2 credentials." >&2
  exit 1
fi

# Guard against a missing / unsynced vault: an empty source would make
# `rclone sync` delete every image already in R2.
if [ ! -d "$VAULT_PHOTOS" ] || [ -z "$(find "$VAULT_PHOTOS" -type f -print -quit)" ]; then
  echo "ERROR: no photos found at $VAULT_PHOTOS (vault missing or not synced yet)." >&2
  exit 1
fi

echo "Validating recipe image references..."

# Source of truth: image filenames currently in the vault Photos folder.
# Validate against these *before* touching R2, so a broken reference aborts
# before anything destructive happens. Match on basename; `find` recurses,
# so images in Photos subfolders count too.
photo_names=$(find "$VAULT_PHOTOS" -type f -exec basename {} \; | sort -u)

missing=0

while IFS= read -r -d '' file; do
  image_value=$( { grep -m1 '^image:' "$file" || true; } | sed 's/^image:[[:space:]]*//; s/"//g; s/'"'"'//g')

  if [ -n "$image_value" ]; then
    if ! grep -qxF "$image_value" <<< "$photo_names"; then
      echo "MISSING: '$image_value' referenced in $(basename "$file") not found in $VAULT_PHOTOS"
      missing=$((missing + 1))
    fi
  fi
done < <(find "$RECIPES_DIR" -name "*.md" -print0)

if [ "$missing" -gt 0 ]; then
  echo ""
  echo "$missing broken image reference(s) found. Aborting before R2 sync."
  exit 1
fi

echo "All recipe images validated."

echo "Syncing images to R2..."
rclone sync "$VAULT_PHOTOS" "$R2_REMOTE" --progress

echo "Image sync complete."
