# Recipe Frontmatter Schema

## Example frontmatter

```yaml
---
publish: true
course: main
category: stir-fry
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
| `category` | enum | optional | `baked` \| `noodle` \| `protein` \| `rice` \| `soup` \| `stew` \| `stir-fry` \| `veggie` — dish-type specificity, only fill in when it clarifies |
| `servings` | number | optional | |
| `tags` | array of strings | yes | Freeform, defaults to `[]` |
| `source` | string | yes | Original source, URL, or `"original"` |
| `image` | string | optional | Path to image file, once you have one |

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
		// Every .md is a recipe, except the repo's own docs.
		pattern: ['**/*.md', '!**/README.*', '!**/recipe-schema.md'],
		base: './src/content/recipes',
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
		category: z
			.enum(['baked', 'noodle', 'protein', 'rice', 'soup', 'stew', 'stir-fry', 'veggie'])
			.optional(),
		servings: z.number().optional(),
		tags: z.array(z.string()).default([]),
		source: z.string(),
		image: z.string().optional(),
	}),
});

export const collections = { recipes };
```
