# Recipe Frontmatter Schema

## Example frontmatter

```yaml
---
status: publish
course: main
servings: 4
recipeTags: ["noodles", "vegetarian", "quick"]
source: "adapted from [[Bon Appetit]]"
image: "garlic-noodles.jpg"
---
```

## Field reference

| Field | Type | Required | Notes |
|---|---|---|---|
| `status` | enum | yes (can be `null`) | `complete` \| `publish` \| `review` \| `ignore` \| `null` |
| `course` | enum | yes | `main` \| `side` \| `condiment` \| `sauce` \| `snack` \| `dessert` \| `beverage` — kept small and fast to classify |
| `servings` | number | optional | Accepts `null` (empty YAML value) or omitted |
| `recipeTags` | array of strings | yes | Freeform, defaults to `[]`. Named to avoid colliding with Obsidian's native `tags` field |
| `source` | string | optional | Original source, URL, or `"original"`. Accepts `null` (empty YAML value) or omitted |
| `image` | string | optional | Path to image file, once you have one. Accepts `null` (empty YAML value) or omitted |

## Zod schema (Astro content collection)

```ts
// src/content.config.ts
import { defineCollection } from 'astro:content';
import { glob } from 'astro/loaders';
import { z } from 'astro/zod';

// Recipes live in a separate repo, mounted at src/content/recipes/
// (a git submodule). Markdown authored in Obsidian; no `title` field —
// the title comes from the filename (see src/lib/recipes.ts).
const recipes = defineCollection({
	loader: glob({
		// Recipe markdown lives (flat) under Recipes/; the repo root holds
		// only docs and the publish scripts.
		pattern: '**/*.md',
		base: './src/content/recipes/Recipes',
	}),
	schema: z.object({
		status: z.enum(['complete', 'publish', 'review', 'ignore']).nullable(),
		course: z.enum([
			'main',
			'side',
			'condiment',
			'sauce',
			'snack',
			'dessert',
			'beverage',
		]),
		// Empty YAML values (`servings:` / `image:`) parse as null, not undefined.
		servings: z.number().nullish(),
		recipeTags: z.array(z.string()).default([]),
		source: z.string().nullish(),
		image: z.string().nullish(),
	}),
});

export const collections = { recipes };
```