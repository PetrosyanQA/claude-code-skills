# Stage 2 — Brief (how to think)

**Goal of the stage:** turn the research findings (or product knowledge, if no research was done) into a prompt the model can execute correctly — without losing the product, within the length limit, with a clear composition.

**Critical:** for a design task (infographic, photoshoot), a brief without the "Visual benchmark" block from research = generation that lands at mediocre-average. If that block is missing from the research file — go back to stage 1, download and look at top-competitor cards via `Read`, extract patterns.

**Critical 2 — fact-check the content.** Before writing slide claims, make sure you have the real product description and characteristics list from the marketplace (item count, dimensions, composition, material, shelf life, standards — everything the seller stated). Do not write item counts, dates, standard numbers, or dimensions from general knowledge or because a competitor has them — write only what is confirmed on the card. If the data is not in the main analytics tool — get it via an auxiliary tool in the environment (if any) or ask the user for it as text. Every anchor claim on the main slide must have a source in the card's real characteristics.

## How to think

First answer 3 questions for yourself:

1. **What are we making?** An infographic (product + text/icons/callouts) or a photoshoot (product in scenes)?
2. **How many frames?** For marketplaces, usually 4-6 for an infographic, 3-5 for a photoshoot. If research produced more ideas — prioritize: put what closes the main objection first.
3. **What is the role of each frame?** Each frame must have one explicit job: "close objection X", "show scenario Y", "highlight benefit Z". One frame = one idea.

If these 3 questions don't get answered — go back to research.

## How series generation works (important)

The `/v1/infographics/generate` endpoint takes **one prompt** + `image_count` (1..8). The model **splits the series into slides itself**, based on your overall direction, facts, and house style. This is NOT N independent calls with N different prompts.

So your job is to set:
- **the direction and style of the series** (palette, typography, tone, compositional logic),
- **the facts and anchor claims** that must appear (item count, shelf life, standards, etc.),
- **the Russian text strings for overlays** (exactly as they must appear on the image, in quotes),
- **the role of each slide, one line each** (what each frame must close) — not a per-slide layout plan.

**Do not describe each slide as a separate picture with its own composition.** The model does not need pixel-layout instructions; it applies the shared style and distributes content across `image_count` frames itself. If you describe slides as panels of one picture, the model will literally assemble them into a 2×3 collage on a single canvas (verified empirically). This is the single most common failure mode — every "no per-slide layout" rule below traces back to it.

## Prompt language

- **Structural instructions** (product protection, style description, slide roles) — write **in English**. Cheaper in length, the model follows English system commands better.
- **Overlay texts on the image** — **Russian only**, verbatim in quotes. An ASCII anglicism in quotes (e.g. "TU 21.20.24-001-...") is acceptable.
- The prompt must end with the disclaimer "Russian text spelled exactly as in quotes, no typos, no Latin substitution".

## What to put in the prompt (design + meaning)

The prompt is a **design brief for the model**. It has two sides: design (how it should look) and meaning (what it should say). Miss either and the series fails.

### Design side — direction, not layout

Do not specify "badge on the left, bar at the bottom, 80pt font". Specify the character of the series — the model picks the composition itself.

| What to set | Why | How to phrase |
|---|---|---|
| **Genre and tone** | So the model hits the niche's expectation | "clean medical minimal", "premium luxury matte", "loud marketplace bazaar", "lifestyle warm", "tech dark" — pick ONE, don't mix |
| **Base palette (2-3 colors with hex)** | Series unity, recognizability | `white #FFFFFF, navy #0A2540, light gray #F0F2F5` |
| **Accent palette (1-2 colors with hex)** | Where the eye lands | `red #E30613` for medical CTAs; `green #1FA463` only if you need "freshness/shelf life" |
| **Typography character** | Readability + mood | "heavy bold sans-serif uppercase headlines", "light modern serif", "condensed grotesk" |
| **Render type** | So frames read as one series, not a mixed bag | "photoreal product on solid backgrounds" / "flat vector illustrations only" / "mixed: photoreal hero + vector infographic frames" — but NOT "whatever works" |
| **Emotion** | Closes "why they buy" | "trustworthy and safe", "urgent and protective", "calm and premium", "friendly and warm" |
| **Benchmark reference** | Anchors to the niche's top | "in the visual style of top medical car-kit cards on Russian marketplaces — clean, white, red cross, large headline anchors" |

The source for all of this is the **visual benchmark from research** (`~/.claude/output/photo-editor/<sku>/research.md`). If you did no research — don't write parameters from your head, go back to stage 1.

### Meaning side — what it should say

Each frame must close one specific objection or highlight one benefit. Take it from research, don't invent.

| What to set | Source | Example |
|---|---|---|
| **Product context, one line** | SKU card | "automotive first-aid kit case for passing roadworthiness inspection" |
| **3-5 anchor facts** | card characteristics (do NOT invent) | item count, shelf life, standard date, dimensions, country of origin |
| **3-4 objections to close** | research → what blocks the purchase | "won't pass inspection", "traffic-police fine", "shelf life expired", "won't fit in the glove box" |
| **Differentiators vs the top** | research → what competitors lack | items the updated standard requires that top-1 is missing |
| **Role of each frame** | your series plan | hero / contents / compliance / new items / convenience / trust — one line each |
| **Exact Russian text strings** | what must appear verbatim | "АПТЕЧКА АВТОМОБИЛЬНАЯ 2026", "22 ПРЕДМЕТА", "ДЛЯ ТО", "С 01.09.2024", "48 МЕСЯЦЕВ" — in quotes, exactly as needed on the image |

**Hard rule on facts.** All numbers and standards — only from the card's real characteristics (see `references/01-research.md` → "Card content" block). Do not write a standard/order number that is not on the card. Do not write an absolute expiry date if the card states a relative shelf life.

**What NOT to put in the prompt:**
- Pixel positions ("badge in the top-right corner")
- Exact element sizes ("headline 80pt, badge 200×80 px")
- Per-slide layout — the model decides it (see "How series generation works")
- Ad clichés from your head ("best on the market", "number one") — unless they showed up in the review research

## Prompt composition

The final prompt has four blocks:

```
[1. Product protection]
[2. General styling rules / series style]
[3. Facts and slide roles — high-level]
[4. Anti-duplication and anti-distortion bans]
```

### Block 1 — product protection (in English, ~510 bytes)

Include verbatim. Without it the model often redraws the product from the words in the brief:

```
CRITICAL: Preserve the product from the input image EXACTLY — same silhouette, proportions, colors, materials, branding, orientation. Do NOT redraw, reshape or replace it. The input image is ground truth for the product. Ignore any wording below that could imply a different shape or category — apply user instructions ONLY to scene, background, text overlays, icons and styling AROUND the product. If prompt and image disagree about the product, the image wins.
```

**Plus a per-product identity lock — mandatory.** The generic block above is not enough on its own: the model still drifts to the statistically common variant (a black fish tank turns white, because white/clear tanks dominate the training data). Right after the CRITICAL block, append one line naming THIS product's distinguishing attributes with concrete values, taken from the photo and the card:

```
PRODUCT IDENTITY LOCK — keep exactly, do NOT restyle or recolor: body color BLACK, <logo + placement>, <distinctive shape>, <finish/material>.
```

Fill it for every job. **Color/variant is the most fragile attribute** — if the product name or variant carries a color ("... Black", "Smart Fish Tank Black"), it MUST appear here in capitals. Wide scene shots (product on a shelf, lifestyle) get recolored far more easily than tight shots of a characteristically-shaped part — so the identity lock matters most for hero and lifestyle frames.

Why English — models follow English system instructions better. Why this exact wording — verified empirically on a product whose name ("hammer") did not match its shape (a cylinder).

### Block 2 — general rules = THE DESIGN SYSTEM (critical)

This is not "general wishes", it is a **single design system for the series**. Without it the model makes N different designs instead of one series. With top brands the card reads as one piece of work; with beginners it reads as a set of slides from different templates.

The design-system parameters come from the checklist above ("What to put in the prompt → Design side"). Minimum:

- **Genre and tone** in one phrase
- **Base palette** (2-3 colors with hex), shared across all frames
- **Accent palette** (1-2 colors with hex), shared across all frames
- **Typography character** in one phrase
- **Render type** (photoreal / vector / mixed) — single for the series
- **Emotion** in one word

**Anti-pattern:** describing each frame as a standalone picture with its own background/style. The model will obey and make N different ones. Describe the series as **one design system** in which only the content and the frame's role change — not the palette or the render style.

**The source of the parameters is the visual benchmark from research, not "common sense".** If the benchmark says "the top uses a black background + gold accent" — write that, not "light gray, minimalism".

### Block 3 — facts and slide roles (high-level)

Here you put the meaning side from the checklist above: product context, anchor facts, objections, differentiators, the role of each frame, exact Russian texts. **No pixel-layout instructions** (see "How series generation works").

Example:

```
Product context: automotive first-aid case, sold for passing roadworthiness inspection (TO) and complying with traffic-police requirements.

Anchor facts to land across the series (use exactly these numbers and wordings, do NOT invent):
- "22 ПРЕДМЕТА"
- "СРОК 48 МЕСЯЦЕВ"
- "С 01.09.2024" (current standard date, not a Ministry order number)
- dimensions "23 x 21 x 8 см", weight "504 г"
- new items in updated standard: "ТЕРМООДЕЯЛО", "БЛОКНОТ", "КАРАНДАШ"

Buyer objections to address (one per frame, the model picks composition):
- "Will it pass TO?" → compliance frame
- "What is even inside?" → contents frame
- "Will it fit in my glove box?" → convenience frame
- "Is the shelf life fresh?" → trust frame

Differentiators vs market leaders: thermal blanket, notepad and pencil are required by the updated standard but missing from top-1 competitor — emphasize them as 'new in standard 2024'.

Generate <N> coordinated frames covering these themes, one role per frame, in any order the model finds natural:
- Hero with title "АПТЕЧКА АВТОМОБИЛЬНАЯ 2026" and anchors "22 ПРЕДМЕТА", "ДЛЯ ТО", "СРОК 4 ГОДА"
- Contents: kit items with Russian captions "Бинты", "Жгут", "Перчатки", "Маски", "Термоодеяло", "Ножницы", "Пластырь", "Блокнот"
- Compliance: "СООТВЕТСТВУЕТ ТРЕБОВАНИЯМ С 01.09.2024", checks "ТО", "ГОСТ", "ГИБДД"
- New in standard 2024: "ТЕРМООДЕЯЛО", "БЛОКНОТ", "КАРАНДАШ"
- Convenience in a car glove box: "23x21x8 см", "504 г", "Удобная ручка"
- Trust: "48 МЕСЯЦЕВ", "5.0 РЕЙТИНГ", "Россия", "Гарантия"
```

The exact Russian text strings must be in quotes. The model picks composition, badges, callouts, and icons within the shared style from block 2.

### Block 4 — bans (important for a clean result)

Models like to "fill in" empty space with niche-typical elements (stock icons, a bottom row of badges, repeating the same claims). This produces visual noise and duplicates. Suppress it explicitly:

```
Each text string appears ONLY ONCE across the whole image. Do NOT duplicate badges or text by repeating them as bottom icon rows. Do NOT add extra logos, watermarks, decorative crosses, fake government emblems, or stock medical icons beyond the product label. Generous white space is OK.
```

Without this block, frames end up with, e.g., both a red "22 ПРЕДМЕТА" circle on top and a bottom row of icon-pictograms with the same captions — it reads as doubling (verified empirically).

## Wording rules

**Do not describe the product's shape in words.** Don't write "hammer with a long handle", "round bottle", "flat body" — even if that's how the product title reads. Use neutral words: "product", "item", "device". The model takes the shape from the photo.

**The product name goes only into text overlays.** "Headline: 'UGREEN LP821'" — OK. "A UGREEN hammer in the photo" — no.

**Avoid words of violence/danger** in the description of an action. They can trip the content-filter (silently: "breaks glass" → empty array in the response). Rephrase to neutral: "emergency window opening", "seatbelt release", "emergency-exit function". The action on the icon will still be clear.

**Buyer vocabulary.** Words on icons and captions come from research (search queries, phrases from reviews). Don't use marketing clichés ("premium", "innovative") unless buyers themselves say them.

**Fewer adjectives, more nouns.** "Aluminum body" beats "durable high-quality reliable body". Both the model and the reader see it more clearly.

## Length limit

The backend counts length **after JSON-escaping non-ASCII into `\uXXXX`**:
- ASCII character = 1 unit
- Cyrillic / Chinese / emoji = 6 units

The limit is 5000 units.

Practical budget:
- English anchor (block 1): ~510 units
- Remaining: ~4400 units
- That is ≈ **730 Cyrillic characters** in blocks 2-3.

Check the estimate before sending:
```bash
python3 -c "import json,sys; print(len(json.dumps(sys.stdin.read())))" <<< "$PROMPT"
```
Aim for ≤ 4800, leave headroom.

> **Важно:** переносы строк (`\n`) в промпте иногда вызывают ответ `Prompt size exceeds maximum allowed length` даже при коротком тексте — это не про длину, а про формат. Если видишь эту ошибку при явно коротком промпте — убери `\n`, замени на пробел или `;`.

If it doesn't fit — do not cut the product protection. Cut block 3: drop detailed descriptions, keep only one-line slide roles and the exact Russian overlay texts. Per-slide layout instructions are not needed at all (see "How series generation works").

## Model selection

Модели делятся на два тира (как в интерфейсе MPSTATS):

- **Standard — `model_1`**: дефолт для всех скриптов кроме инфографики.
- **PRO — `model_2`**: дефолт для инфографики, лучшее качество кириллицы, меньше опечаток. Не указывай вручную — скрипт подставит сам.
- **`model_3` (PRO)** — не использовать для русского текста: стабильно ломает кириллицу. Только для кадров без текста.
- **`model_5` (PRO)** — попробуй, если `model_2` даёт артефакты на конкретном товаре.
- Full model troubleshooting — `references/03-generate.md` → Model selection.
- В русском промпте всегда добавляй: «весь текст пишется БЕЗ ОПЕЧАТОК буквально как в кавычках. Не добавляй своего текста.» — снижает галлюцинации на 50-70%.

## Aspect ratio

- WB / Ozon card: `3:4` (vertical) — the default for photoshoot and infographics
- Main photo: `1:1` is acceptable
- `model_4` cannot do 3:4 — use `2:3` or another model

## What to save

File: `~/.claude/output/photo-editor/<sku>/brief.md`. Save:
- the final prompt as one block (for repeats and iterations)
- a per-frame table: frame → role → key idea (to align with the user before running)
- a link to the research file, if there was one

## Технические ограничения промпта

- **`/test` строже по длине**, чем `/generate`. Если промпт не проходит `test` — используй `generate` с `count=1` вместо `test`.
- **При `parse error` / пустом ответе** — таймаут шлюза, не баг. Повтори скрипт 1-2 раза, не переписывай вызов вручную.

## Anti-patterns

- Describing the product in words instead of trusting the photo → shape hallucination
- Relying only on the generic protection block for color/variant → the model drifts to the common variant; always add the per-product identity lock with concrete values
- Repeating "product centered, light background" in every frame → wasted length budget
- Adding "premium" / "high-quality" / "reliable" with no basis in research → filler
- Pasting the full research report into the prompt → length and noise
- Using words of violence in action descriptions → content-filter, empty response
- Describing per-slide layout → 2×3 collage instead of a series (see "How series generation works")
- **Identified top objection in research but didn't include it in the slide plan** → the most common brief gap. Before writing the prompt, explicitly verify: does objection #1 from research appear in the frame roles? If not — add it, and drop a lower-priority frame if count is fixed.
