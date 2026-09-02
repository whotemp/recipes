#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VAULT_RECIPES="/Users/kevinlang/Library/Mobile Documents/iCloud~md~obsidian/Documents/Kevin/Recipes"
DEST="$SCRIPT_DIR/Recipes"

cd "$SCRIPT_DIR"

# Guard against an unsynced / missing iCloud vault: without this, an empty
# source plus --delete would wipe every published recipe and commit it.
if [ ! -d "$VAULT_RECIPES" ] || [ -z "$(find "$VAULT_RECIPES" -name '*.md' -print -quit)" ]; then
  echo "ERROR: no recipes found at $VAULT_RECIPES (vault missing or not synced yet)." >&2
  exit 1
fi

# Prints the frontmatter `status` of a recipe (lowercased, unquoted), or nothing
# if the file has no frontmatter or no status field.
recipe_status() {
  awk '
    NR == 1 && $0 != "---" { exit }              # no frontmatter block
    NR == 1 { next }
    $0 == "---" { exit }                          # end of frontmatter
    /^status:[[:space:]]*/ {
      v = $0
      sub(/^status:[[:space:]]*/, "", v)
      sub(/[[:space:]]*#.*$/, "", v)              # strip trailing comment
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", v)  # trim
      gsub(/^["'"'"']|["'"'"']$/, "", v)          # strip surrounding quotes
      print tolower(v)
      exit
    }
  ' "$1"
}

# Stage the recipes to publish: every .md anywhere under the vault Recipes
# folder whose frontmatter status is `complete` or `publish`, flattened by
# basename. Staging first means image validation and the --delete rsync run
# against exactly the set we're about to publish. Vault folders (Testing/,
# Review/, …) are just for organizing — only `status` decides what publishes.
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

echo "=== Step 1: Stage published recipes ==="
count=0
while IFS= read -r -d '' src; do
  case "$(recipe_status "$src")" in
    complete|publish) ;;
    *) continue ;;
  esac
  base="$(basename "$src")"
  if [ -e "$STAGE/$base" ]; then
    echo "ERROR: two recipes share the name '$base' — rename one in the vault." >&2
    exit 1
  fi
  cp "$src" "$STAGE/$base"
  count=$((count + 1))
  echo "  $base"
done < <(find "$VAULT_RECIPES" -type f -name '*.md' -print0)

if [ "$count" -eq 0 ]; then
  echo "ERROR: no recipes with status 'complete' or 'publish' found. Aborting." >&2
  exit 1
fi
echo "$count recipe(s) staged."

echo ""
echo "=== Step 2: Sync + validate images ==="
"$SCRIPT_DIR/sync-images.sh" "$STAGE"

echo ""
echo "=== Step 3: Publish recipes ==="
mkdir -p "$DEST"
rsync -av --delete --exclude='.DS_Store' "$STAGE/" "$DEST/"
git add -A

if git diff --cached --quiet; then
  echo "No changes to commit."
  pushed=0
else
  git commit -m "update recipes"
  git push origin HEAD
  pushed=1
fi

# If this repo is checked out as a submodule, the superproject still records the
# old commit. Offer to bump its pointer so the site actually picks up the change.
SUPER="$(git rev-parse --show-superproject-working-tree 2>/dev/null || true)"
if [ "$pushed" -eq 1 ] && [ -n "$SUPER" ]; then
  echo ""
  echo "This repo is a submodule of $SUPER"
  read -r -p "Bump the submodule pointer there and push? [y/N] " reply
  if [[ "$reply" =~ ^[Yy]$ ]]; then
    git -C "$SUPER" add "$SCRIPT_DIR"
    git -C "$SUPER" commit -m "Bump recipes submodule"
    git -C "$SUPER" push
    echo "Superproject pointer updated."
  else
    echo "Skipped. Update it later with:"
    echo "  git -C \"$SUPER\" add \"$SCRIPT_DIR\" && git -C \"$SUPER\" commit -m 'Bump recipes submodule' && git -C \"$SUPER\" push"
  fi
fi

echo ""
echo "Done."
