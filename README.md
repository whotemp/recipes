# Recipes

Markdown recipes synced from Obsidian

## Setup

1. Clone this repo.
2. Update the `VAULT_RECIPES` path in `publish.sh` if your Obsidian vault path differs from the default.

## Publishing

Whenever you've added or edited recipes in Obsidian and want them live on the site:

\```bash
./publish.sh
\```

This syncs recipes from your Obsidian vault into this repo (removing any deleted files) and pushes the changes, which triggers the site rebuild.

## Recipe schema

See `recipe-schema.md` for the full frontmatter reference and required fields.