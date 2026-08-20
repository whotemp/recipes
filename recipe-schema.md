# Recipe Frontmatter Schema

## Example frontmatter

```yaml
---
title: "Weeknight Garlic Noodles"
publish: true
course: main
category: stir-fry
servings: 4
difficulty: easy
tags: ["noodles", "vegetarian", "quick"]
contains: ["dairy"]
season: ["summer"]
source: "adapted from [[Bon Appetit]]"
equipment: ["wok"]
image: "garlic-noodles.jpg"
---
```

## Field reference

| Field | Type | Required | Notes |
|---|---|---|---|
| `title` | string | yes | |
| `publish` | boolean | yes | Publish script only picks up `true` |
| `course` | enum | yes | `main` \| `side` \| `condiment` \| `sauce` \| `snack` \| `dessert` \| `beverage` — kept small and fast to classify |
| `category` | enum | optional | `baked` \| `grain` \| `noodle` \| `protein` \| `soup` \| `stew` \| `stir-fry` \| `veggie` — dish-type specificity, only fill in when it clarifies |
| `image` | string | optional | Path to image file, once you have one |
| `servings` | number | yes | |
| `difficulty` | enum | yes | `easy` \| `medium` \| `hard` |
| `tags` | array of strings | yes | Freeform |
| `contains` | array of enum | yes (can be empty array) | Lists exceptions only — empty array means vegan. `dairy` \| `eggs` \| `gluten` \| `meat` \| `fish` \| `nuts` |
| `season` | array of strings | optional | Only relevant if the recipe is seasonal |
| `source` | string | yes | Original source, URL, or `"original"` |
| `equipment` | array of strings | optional | Only when something specific is required (e.g. `wok`, `stand mixer`) |

## Zod schema (Astro content collection)

```ts
// src/content/config.ts
import { defineCollection, z } from 'astro:content';

const recipes = defineCollection({
  type: 'content',
  schema: z.object({
    title: z.string(),
    publish: z.boolean(),
    course: z.enum(['main', 'side', 'condiment', 'sauce', 'snack', 'dessert', 'beverage']),
    category: z.enum(['baked', 'grain', 'noodle', 'protein', 'soup', 'stew', 'stir-fry', 'veggie']).optional(),
    servings: z.number(),
    difficulty: z.enum(['easy', 'medium', 'hard']),
    tags: z.array(z.string()),
    contains: z.array(z.enum(['dairy', 'eggs', 'gluten', 'meat', 'fish', 'nuts'])),
    season: z.array(z.string()).optional(),
    source: z.string(),
    equipment: z.array(z.string()).optional(),
    image: z.string().optional(),
  }),
});

export const collections = { recipes };
```

## Fields considered and dropped

- `date` (date added) — dropped
- `lastMade` — dropped
- `notes` — dropped
- `rating` — dropped
- `mealType` — replaced by `course`, since it broke down for condiments and multi-meal dishes
- `heft` (light/moderate/hearty) — considered, dropped
- `status` (draft/ready) — replaced by `publish` boolean
- `slug` — dropped; Astro generates the URL from filename, and Obsidian already keeps internal vault links working on rename
- `dietary` (positive tags like vegetarian/vegan) — replaced by `contains`, listing exceptions only (shorter to maintain given a mostly-vegan kitchen); `shellfish` and `soy` excluded from the enum since they're not cooked with / easily substituted
- `main` / `side` (course values) — replaced by more specific categories (`soup`, `stew`, `veggie`, `stir-fry`) that better match actual cooking patterns; `stir-fry` covers mixed dishes like tofu + zucchini
- `cuisine` — dropped; redundant now that `category` exists, cuisine info can live in `tags` if it ever matters
- `course` (13-value version) — split into `course` (small, fast to classify) + `category` (optional, specific dish type) to reduce classification friction while keeping filtering power
- `prepTime` / `cookTime` — dropped
