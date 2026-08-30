# Recipe Frontmatter Schema

## Example frontmatter

```yaml
---
publish: true
course: main
servings: 4
tags: ["noodles", "vegetarian", "quick"]
source: "adapted from [[Bon Appetit]]"
image: "garlic-noodles.jpg"
---
```

## Field reference

| Field | Type | Required | Notes |
|---|---|---|---|
| `publish` | boolean | yes | Publish script only picks up `true` |
| `course` | enum | yes | `main` \| `side` \| `condiment` \| `sauce` \| `snack` \| `dessert` \| `beverage` — kept small and fast to classify |
| `servings` | number | optional | Accepts `null` (empty YAML value) or omitted |
| `tags` | array of strings | yes | Freeform, defaults to `[]` |
| `source` | string | yes | Original source, URL, or `"original"` |
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
		// Recipe markdown lives under Recipes/; the repo root holds only
		// README.md, publish.sh, and recipe-schema.md.
		pattern: '**/*.md',
		base: './src/content/recipes/Recipes',
	}),
	schema: z.object({
		publish: z.boolean().default(false),
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
		tags: z.array(z.string()).default([]),
		source: z.string(),
		image: z.string().nullish(),
	}),
});

export const collections = { recipes };
```
