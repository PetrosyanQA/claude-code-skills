# Stage 3 — Generation (how to think)

**Goal of the stage:** run generation so that (a) the chance of a bad result is minimized, (b) backend failures are handled without panic, (c) the user keeps control if they want it.

## Test frame: ask, don't assume

`infographics.sh auto` and `photoshoot.sh auto` do `test → generate` built in. That isn't always what's wanted: the user may want either the final batch right away (faster) or a preview frame first (control).

**Before running, ask in one line:** "Generate the whole batch (N frames) now, or a test frame first for approval?"

This question is about **generation flow only**. An answer like "whole batch" does NOT authorize skipping Stage 1 (research) or Stage 2 (brief) — those still happen first. "Fast" here refers to how generation runs, not to cutting analysis.

Based on the answer:
- **"Whole batch"** → `infographics.sh auto <img> "<prompt>" <count>` — runs `test → generate` without pausing for approval. **The test frame is still generated** and shown in the output; the difference is no approval gate between steps. This is NOT the same as skipping the test entirely.
- **"Skip test entirely"** (iterating on a known-good prompt) → `infographics.sh generate <existing_img> "<prompt>" <count>` directly.
- **"Test first"** → `infographics.sh test <img> "<prompt>"`, show it in chat, wait for approval, then `infographics.sh generate <approved_path> "<prompt>" <count>`
- **No explicit request from the user** (e.g. they just said "make an infographic") → choose by heuristic:
  - Simple product (1-2 frames, knowledge base works) → whole batch
  - Product with hallucination risk (name implies a different image, non-standard shape, or a color variant that differs from the category norm — e.g. a black item in a category dominated by white) → test first, on a wide/hero frame so any recolor surfaces immediately
  - Expensive iteration (an 8-frame photoshoot on a heavy model) → test first

## Model selection

The `model` argument accepts `model_1`..`model_5`. Default — `model_2`.

Heuristic:
- **Default:** `model_2` — best quality/speed balance, supports 3:4
- If the previous run **hallucinated the product** → try `model_5` or `model_3` — they have different image-conditioning behavior
- If you need **2:3 or 3:2 instead of 3:4** → `model_4`
- If the result is **bland, uninteresting** → try `model_3` for creative shots

Don't cycle through all models — it's expensive. Switch models only when you have a hypothesis why it would help.

## Handling errors

The backend returns structured errors. Don't stay silent — diagnose and resolve.

| Error | What it means | Action |
|---|---|---|
| `PROMPT_VALIDATION_ERROR: Prompt size exceeds maximum allowed length` | Prompt > 5000 units after JSON-escaping | Go back to brief.md, compress. Compute the estimate before retrying. |
| `The model cannot be null` | An empty `model` reached the API | Pass `model_1`..`model_5` explicitly; does not occur on a correct script call |
| `AUTH_ERROR: Invalid credentials` | Invalid token | Check `PHOTO_EDITOR_TOKEN` in `config/.env` |
| `process_completed` + `output.image: []` (empty array) | Content filter tripped on the wording | Rephrase block 3 of the brief: remove words of violence/danger/weapons. See brief.md → Wording rules. |
| `process_error` with `error.message` | Internal generation error | Show the message to the user, try another model |
| `process_timeout` | Server didn't finish within its timeout | Reduce count or use a faster model (`model_1` / `model_5`) |
| Local poll timeout (>900s) | Script stopped polling, but the event_id remains | `./scripts/poll.sh <event_id>` to fetch it |

## What to do if the test frame is bad

Signs of a bad test:
- **Product distorted or recolored** (different shape, wrong color/variant, no branding, geometry lost) → stop, redo. Check the brief: add or strengthen the per-product identity lock (especially color — see 02-brief.md → Block 1); no shape descriptions in words; try another model.
- **Text unreadable / wrong language / spelling** → rephrase the headlines, add an explicit `text in Russian` in the general rules.
- **Composition overloaded** → cut the number of callouts to 2-3 per frame.
- **Style misses the niche** → go back to research, check against the competitive pattern.

After any brief edit — one test frame again, not the whole batch.

## Do not run N>1 in parallel for one product

`auto` mode already runs `test → generate` inside. Running 2 batches at once wastes quota and produces inconsistent styles. Wait for completion, evaluate the result, decide.

## Save context for iterations

After a successful generation — add to the brief file (`~/.claude/output/photo-editor/<sku>/brief.md`):
- the model used
- aspect_ratio
- the result's event_id
- what the user asked for after delivery (if you iterated)

This saves time next time.
