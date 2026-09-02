# Recipes

Markdown recipes synced from Obsidian

## Setup

1. Clone this repo.
2. Update the `VAULT_RECIPES` path in `publish.sh` (and `VAULT_PHOTOS` in `sync-images.sh`) if your Obsidian vault path differs from the default.
3. Set up R2 access for image sync: `cp rclone.conf.example rclone.conf` and fill in your R2 credentials. `rclone.conf` is gitignored and stays local to this folder.

## Publishing

Whenever you've added or edited recipes in Obsidian and want them live on the site:

```bash
./publish.sh
```

Run it from anywhere — including the website repo if this is mounted there as a
submodule (`[...]/recipes/publish.sh`). When it detects it's running inside a
superproject, it offers to bump the submodule pointer there and push, so the
site picks up the new recipes.

This scans the whole vault Recipes folder, stages every `.md` whose frontmatter
`status` is `complete` or `publish` (flattened by filename), validates their
image references, syncs images to R2, then mirrors the staged set into
`Recipes/` here (removing anything no longer published) and pushes — which
triggers the site rebuild. Recipe folders in the vault (`Testing/`, `Review/`,
…) are just for organizing; only the `status` field decides what publishes.

## Recipe schema

See `recipe-schema.md` for the full frontmatter reference and required fields.
