#!/bin/bash
VAULT_RECIPES="/Users/kevinlang/Library/Mobile\ Documents/iCloud\~md\~obsidian/Documents/Kevin/Cooking/Recipes"

rsync -av --delete "$VAULT_RECIPES" "."
git add -A && git commit -m "update recipes" && git push
