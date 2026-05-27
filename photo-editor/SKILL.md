---
name: photo-editor
description: "MPSTATS Photo Editor API. Use when generating product photos, photoshoots, infographics, recolors, in-action scenes, background removal/replacement, upscaling, prompt-based image edits for marketplace sellers (Wildberries, Ozon, YM)."
license: MIT
metadata:
  author: mpstats
  version: "1.1.0"
---

# MPSTATS Photo Editor

Internal MPSTATS service for AI-generated visuals for marketplace product cards: background removal/replacement, upscaling, recolor, "product in action", prompt-edit, photoshoots, infographics.

All requests go through the ready-made scripts in `scripts/` (Bash tool, **do not rewrite the code**). Endpoints are asynchronous: each script handles submit → polling → saving files. Images are base64-encoded inside the scripts.

## Two modes of operation

Choose deliberately — it changes all downstream behavior.

**A. Technical operations (single-step)** — `remove-background`, `upscale`, `replace-background`, `in-action`, `recolor`, `freeform`. Run the script → get the result → deliver. No research/brief. Use when a concrete action is requested ("remove the background", "upscale", "recolor to blue").

**B. Design tasks (multi-stage)** — `infographics` and `photoshoot`. Full design work: think like a marketplace designer. Use when the request is about buyer value ("make an infographic", "refresh the card", "I need a photoshoot"). Use the stage guides in `references/` — these are thinking guides, not checklists:

| Stage | File | When |
|---|---|---|
| 1. Research | [references/01-research.md](references/01-research.md) | Default for mode B unless the user chose "no research". |
| 2. Brief | [references/02-brief.md](references/02-brief.md) | Always before generating in mode B. Also covers all prompt-craft: prompt structure, slide series, length limit, content-filter. |
| 3. Generate | [references/03-generate.md](references/03-generate.md) | Always. Before running, ask: "the full batch right away, or a test frame first?". |
| 4. Deliver | [references/04-deliver.md](references/04-deliver.md) | **Mandatory, read BEFORE showing the result.** Show every frame via `Read` with an anchor caption, not a list of paths. |

### Mode B start — mandatory question

**When a task is identified as mode B, the first thing to do is ask a single question:**

> Run full research (competitor analysis, reviews, visual benchmark) or generate right away from your prompt / description?

Possible answers and what to do:

| User answer | Action |
|---|---|
| "with research" / "full analysis" / silence (no explicit refusal) | Run Stage 1 → 2 → 3 → 4 in full |
| "no research" / "generate right away" / "from my prompt" | Skip Stage 1, go straight to Stage 2 (brief from the user's description) → 3 → 4. State explicitly: "Skipping research — quality may be lower, but it's faster." |
| User provides a ready prompt in the message | Clarify: use it as-is or run it through the brief (length check, block structure, product lock)? |

**Exception:** if the user already explicitly stated "no analysis" / "no research" in the first message — don't ask, go straight to Stage 2.

## Config

Credentials in `config/.env` (gitignored): `PHOTO_EDITOR_TOKEN` (header `X-Mpstats-TOKEN`) and optional `PHOTO_EDITOR_BASE_URL` (default `https://mpstats.io/api/big_data/proxy`). Setup and variables: [config/README.md](config/README.md).

If the token is missing (or it is `your_token_here`), the agent **must** ask:

```
I need an MPSTATS API token (X-Mpstats-TOKEN) for Photo Editor — get it from your MPSTATS account → API and send it over, I'll write it into config/.env.
```

## Output location

**Do NOT put results in the skill folder** — the skill is code, output is data. Default `~/.claude/output/photo-editor/<event_id>/`, override via `PHOTO_EDITOR_OUTPUT_DIR`.

For mode B, after generation copy the files into a clean per-SKU folder with meaningful names (`slide_1_hero.png`, etc.) — `event_id` contains `:`, which breaks image rendering in some UI clients, and per-SKU is easier for the user to navigate.

## Multi-angle input: `wb:<sku>`

In `infographics.sh` and `photoshoot.sh` the first argument can be `wb:<sku>` or `wb:<wb-url>` instead of a file path. The skill downloads all product photos from the WB CDN (`wb-fetch-photos.sh`, cached in `~/.claude/cache/photo-editor/wb-photos/<sku>/`): the first → `main_image`, the rest → `reference_images` (max 5, the API won't accept more).


```bash
infographics.sh generate wb:164419278 "$PROMPT" 5
```

For multi-angle input, in the product-lock instruction write "preserve product **identity**", NOT "preserve same orientation" — otherwise the model copies the first photo's angle onto every slide. More on the prompt — `references/02-brief.md`.

## Infographics: a series of N slides

`infographics.sh generate <img> "<prompt>" <count>` creates a **series of `count` slides** (1..6) in a single call. Flow: `test` (a trial frame) → approve → `generate <N>`; or `auto` (test + generate at once).

> **Minimum output is 4 frames.** The endpoint always returns `max(4, image_count)` images — requesting count=1..3 still yields 4. Photoshoot has no such limit.

The prompt sets the **high-level direction + frame themes**, not the layout of each slide — otherwise you get a 2×3 collage on a single canvas. Prompt-craft details — `references/02-brief.md`.

## Models

| Mask | Tier | Default | Aspect ratios | Available for |
|---|---|---|---|---|
| `model_1` | **Standard** | ✅ all except infographics | 1:1, 3:4, 4:3, 2:3, 3:2 | all endpoints |
| `model_2` | **PRO** | ✅ infographics | 1:1, 3:4, 4:3, 2:3, 3:2 | all endpoints |
| `model_3` | PRO | — | 1:1, 3:4, 4:3, 2:3, 3:2 | all endpoints |
| `model_4` | PRO | — | 1:1, 3:4, 4:3, 2:3, 3:2 | all endpoints |
| `model_5` | PRO | — | 1:1, 3:4, 4:3 | freeform, photoshoot |

The backend does not accept `model=auto` — the skill resolves it to `model_1` (Standard). For infographics the default is hard-wired to `model_2` (PRO) — best Cyrillic quality. Specify an explicit model only if you have a hypothesis why.

## Scripts

| Script | When to use |
|---|---|
| `remove-background.sh <img>` | Remove the background |
| `upscale.sh <img>` | Increase resolution |
| `replace-background.sh <img> <template_key>` | Place the product on a stock background |
| `in-action.sh <img> <template_key>` | Product in a ready usage scene |
| `recolor.sh <img> <#hex>` | Recolor the product |
| `freeform.sh <img> "<prompt>" [model] [ar] [refs]` | Freeform edit (single-step) |
| `photoshoot.sh auto <img> "<prompt>" <count>` | Photoshoot (test → generate in one command) |
| `photoshoot.sh test \| generate` | When you need to approve the test frame separately |
| `infographics.sh auto <img> "<prompt>" <count>` | Infographics (test → generate) |
| `infographics.sh test \| generate` | Same as photoshoot |
| `templates.sh backgrounds [key]` | List `template_key` for replace-background |
| `templates.sh in-action [key]` | List `template_key` for in-action |
| `wb-fetch-photos.sh <sku-or-url> [max=8]` | Download WB product photos. Called automatically on `wb:<sku>` input |
| `health.sh` | Check the service |
| `run.sh <endpoint> <body_json>` | Universal submit + poll |
| `poll.sh <event_id>` | Wait for a ready event_id |

## Decision Guide

- "clean up the background" → A, `remove-background.sh`
- "make it bigger/sharper" → A, `upscale.sh`
- "change the background to a studio/marble" → A, `templates.sh backgrounds` → `replace-background.sh`
- "show the product in use" → A, `templates.sh in-action` → `in-action.sh`
- "recolor to #hex" → A, `recolor.sh`
- "fix the lighting / remove the glare / add a shadow" → A, `freeform.sh`
- "make an infographic / photoshoot", "refresh product card X" → B, start with `references/01-research.md`

## Errors

| msg | What to do |
|---|---|
| `process_completed` | Done, files saved |
| `process_completed` + `output.image: []` | Content-filter → rephrase the prompt (`references/02-brief.md`) |
| `process_error` | Read `error.message`, show it to the user |
| `process_timeout` | The server didn't finish in time; reduce count or change the model |
| `Prompt size exceeds maximum allowed length` | **Most often the cause is line breaks (`\n`) in the prompt**, not an actual limit overflow. Pass the prompt as a single line. If the error persists after that — shorten the prompt: `references/02-brief.md` → Technical limits. |
| `AUTH_ERROR` | Invalid credentials — see the Config section |
| Local poll timeout | The script stopped polling; the event_id remains — `poll.sh <event_id>` |
