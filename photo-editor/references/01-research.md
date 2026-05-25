# Stage 1 — Research (how to think)

**Goal of the stage:** gather exactly enough data about the product and the market for the final card to hit real buyer doubts and to differentiate from competitors. No more, no less.

This stage is **default-on for mode B**, not "optional whenever convenient". Run it whenever the user asks for a "good" card, a marketplace infographic, or an update to an existing card. Skip it only when (a) the task is a technical operation (remove background, recolor, compress), or (b) the user **explicitly** opts out of research ("no research", "без анализа"). Do not infer a skip from urgency or "do it fast" / "whole batch at once" signals — those refer to execution speed, not to analysis. If you skip research, say so explicitly to the user up front — never silently.

**Critical:** research for a design task without a visual benchmark of the top competitors is not research, it is collecting text statistics. Text data is not enough to reproduce the level of a top designer. You **must look with your eyes** at competitors' reference cards via `Read` (multimodal reading), extract visual patterns, and record them in the brief. See the "Visual benchmark" section below — it is not optional.

## How to think

Don't run the stage as a checklist. First **formulate the questions** whose answers will affect the card's design. Then for each question pick the minimum data needed for a reliable answer.

Base questions — ask them yourself every time, drop the irrelevant ones:

1. **What is the product, in which niche, in which price segment?** → defines style, tone, infographic density (premium — minimalism, mass-market — lots of text)
2. **Why do people buy it?** → JTBD, key usage scenes
3. **What do buyers in this category fear?** → objections to close with visuals
4. **What is praised in positive reviews?** → accents to reinforce
5. **What do the top cards look like?** → a reference for the market's level and templates
6. **How can we differentiate?** → what the top lacks, what we can show
7. **What words and images are in buyers' heads?** → vocabulary for icons and captions
8. **Is there seasonality / a usage context?** → affects scenes and timing

Not every question needs data — for some, the agent's knowledge and common sense are enough. Data is needed where **the hypothesis is easy to verify and the cost of a mistake is high**.

## From question to data (via the `mpstats` skill)

All data about the product, competitors, niche, and search queries comes through the **`mpstats`** skill — it knows the current MPSTATS API endpoints for Wildberries, Ozon, Yandex Market. The specific commands/scripts inside the skill may change — do NOT hardcode them here, always go through the skill.

**Before concluding research is impossible — actually invoke the `mpstats` skill.** Do not assume it is unavailable because some other tool is blocked: the WB CDN returning 451/empty says nothing about the MPSTATS API — they are different paths. Try first, then decide. If the `mpstats` skill is genuinely not installed — tell the user and offer to install it (without it, research for a marketplace card is impossible). Ask: continue without research (worse quality, but faster) or install the skill and come back.

Don't run everything at once. For each question — the minimum necessary data set via `mpstats`:

- **What the product is (metrics)** → the full SKU card (category, brand, price, rating, sales, photo count). One request.
- **Card content (description + characteristics)** → MANDATORY before generation. You need the real product description, the characteristics list, color/variant (e.g. "Black" — critical, the generator recolors easily), exact dimensions, composition/contents, material, shelf life, country, etc. — everything the seller stated on the marketplace. Without it you will invent infographic claims from your head and miss: get the item count wrong, mix up dimensions, write a non-existent standard. This is a **separate source** from analytics metrics — the marketplace-analytics API usually does not return it. If the main tool doesn't have this data — ask the user whether the environment has an auxiliary tool for fetching card content (description/characteristics), and use it. As a last resort — ask the user to send the description and characteristics as text.
- **Why they buy / what is praised / what they fear** → reviews for your SKU + reviews of the top 2-3 competitors. If your own reviews are few — increase the competitor share.
- **What's in buyers' heads** → search queries (by SKU or by subcategory/subject).
- **What the top looks like** → similar products to our SKU or the subcategory top, sorted by revenue. Take just enough to spot a pattern (see below).
- **How to differentiate** → assembled from comparing our product with the top (photo style, features, extra value). Needs no separate data.
- **Seasonality** → subcategory seasonality or SKU dynamics over periods. Run it ONLY if the product logically can be seasonal (Christmas trees, swimwear, umbrellas). For everyday accessories — skip.

## Visual benchmark (mandatory for design tasks)

Text data ("what is praised", "what they fear") does not convey the visual level. To hit the level of a top designer — look at how competitors' cards are actually designed.

### How to do it

1. **Find the top 5-8 SKUs in the same subcategory** by 30-day revenue via the `mpstats` skill (similar products to our SKU or the subcategory top, sorted by revenue). Filter by a similar price segment (±50% of our price).

2. **For each competitor, pull the card photo URLs** via `mpstats` (the SKU card returns a list of full-size photos).

3. **Download at least 3 photos per competitor** (main + 2 infographics) into `/tmp/visual-bench-<sku>/<competitor_id>/`. Use `curl -s -o`.

4. **Read each photo via `Read`** — Claude is multimodal, it sees images. Not "open and look at" — literally call `Read` on each file.

5. **Extract visual patterns** in writing:
   - Palette (the dominant 2-3 colors, accents)
   - Background (white/gray/black/lifestyle/gradient)
   - Composition of the main photo (product centered/offset, size relative to the frame)
   - Infographic structure (how many slides, which roles — hero/specs/usage/contents/trust)
   - Typography (sans/serif, weight, headline size relative to the frame, alignment)
   - Scenes/contexts (lifestyle, studio, in-action, cutaways, before/after)
   - Iconography (flat/3D/realistic)
   - Text density (minimalism vs. heavy)
   - What almost ALL of the top does (= mandatory hygiene)
   - What nobody does (= a differentiation opportunity)

### What to record

Add a block to `~/.claude/output/photo-editor/<sku>/research.md`:

```
## Visual benchmark
- Cards studied: N (id1, id2, ...)
- Dominant palette: ...
- Background standard: ...
- Hero composition: ...
- Standard infographic structure (what everyone does): ...
- Typography: ...
- What almost nobody does (our opportunity): ...
```

This block is the main input for the brief. Without it, generation falls back to an average "a lamp on a gray background with a yellow bar".

### Visual-benchmark anti-patterns

- Downloading photos and not opening them via `Read` → you didn't see them, there are no patterns
- Describing competitors in words without downloading → hallucination instead of analysis
- Looking only at the main photo → you miss the infographic, and that's 80% of the work
- Taking random competitors instead of the revenue top → you repeat the mistakes of weak sellers
- Writing "everyone has a light background, minimalism" — too vague. Be specific: "5 of 6 use pure white #FFFFFF, the lamp takes 60-70% of the frame height, headlines 80-100pt"

## How many competitors to look at

Not "top N". The goal is to find recurring patterns.

Heuristic:
- Opened the top 3 → you see 3 different approaches → keep going
- Opened the top 5 → 4 of 5 do it the same way → pattern found, stop
- If by the top 10 no pattern has formed — the market is unstructured, take the best 2-3 as a reference and trust your own design judgment

It helps to write 1 line about each competitor: "<main photo: studio/lifestyle/infographic>, <composition type>, <unique card feature>".

## What to write in the report

File: `~/.claude/output/photo-editor/<sku>/research.md`. Not long, not "everything I collected", but **conclusions** that directly feed the brief:

- **Positioning** (1 line). Who the audience is, in which price-meaning quadrant.
- **JTBD** (1-3 lines). What people actually pay for, in which situations they use it.
- **Objections** (3-5 points). What blocks the purchase — and how it's closed with visuals.
- **Benefits to reinforce** (3-5 points). What is praised — this must be shown.
- **Competitive patterns** (2-4 lines). What the top does, which style dominates.
- **Visual benchmark** (see the separate section). Concrete patterns: palette, composition, slide structure, typography, scenes.
- **Differentiation** (1-3 points). What the top lacks — our potential.
- **Vocabulary** (5-10 words/phrases). Buyers' words for captions and icons.
- **Seasonality** (if applicable). 1 line.

## When to stop research

Signs that's enough:
- 6 of 8 base questions have a confident answer
- A hypothesis has formed for 2-3 infographic frames or photoshoot scenes
- Digging further yields 5-10% improvements — not worth the time

Signs it's not enough:
- You don't understand why people buy it
- You don't see how we're better / worse than the top
- The icon captions are still "durable, high-quality, convenient" (= the vocabulary hasn't crystallized)

## Anti-patterns

- Pulling every available endpoint "just in case" → noise, not conclusions
- Copying raw JSON responses into the research file → the file should be conclusions, not data
- Doing research for a technical operation (remove background) → wasted work
- Generating infographic claims from your knowledge / generic phrasing instead of the card's real characteristics → near-guaranteed falsehood (a non-existent standard, a wrong item count, invented dimensions). Pull the description and characteristics first, then write the claims.
- Taking characteristics only from analytics metrics (sales, rating, price) → not enough. The real description and characteristics list is a mandatory separate source.
