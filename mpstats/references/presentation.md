# Presentation & Reporting Guidelines

This reference defines how MPSTATS-based analytical results should be presented to the user.

## Goal

MPSTATS outputs should feel like marketplace analytics, not raw API dumps.
The answer should help the user make a decision quickly:

- what is happening
- why it matters
- what to do next

## Default answer structure

For most analytical requests, use this order:

1. Short conclusion
2. Key metrics
3. Evidence in tables and/or charts
4. Interpretation
5. Risks, caveats, or next actions

If the task is simple, keep the structure compact. If the task is report-like, expand it.

## Tables: when they are required

Include at least one table when the result involves any of the following:

- multiple products, sellers, brands, or categories
- period comparisons
- price segmentation
- ranking lists
- niche comparisons
- seller or competitor comparisons
- SKU-level top rows

Good table examples:

- top sellers by revenue
- category or niche comparison
- price bucket breakdown
- month-by-month dynamics
- comparison of 2-5 candidate niches

Avoid giant tables. Prefer 5-15 rows unless the user asks for full exports.

## Charts: when they should be included

Include a chart, or a chart-ready block in the report, when there is meaningful visual signal in:

- time series (`by_date`, trends, forecasts, seasonality)
- price segmentation
- market share or seller concentration
- period comparison
- revenue distribution across buckets or entities

Recommended chart types:

- line chart for revenue/sales over time
- bar chart for top sellers, brands, SKUs, or categories
- stacked bar chart for price segmentation or share splits
- column chart for period-over-period comparisons

If the final output channel does not support rendered charts, provide a compact textual interpretation plus a table that clearly exposes the same pattern.

## Narrative rules

- Lead with insight, not with data extraction mechanics.
- Do not paste raw JSON unless explicitly requested.
- Every metric block should answer "why this matters."
- When discussing a niche, seller, or product, include both opportunity and risk.
- For recommendations, explicitly state why one option is stronger than the alternatives.

## HTML/PDF report standard

If a standalone HTML or PDF report is generated, it should follow MPSTATS-style presentation.

### MPSTATS-style principles

- Analytics-first, not brochure-first
- Clean dashboard/report hybrid
- Strong information hierarchy
- Data blocks, metric cards, and clear separators
- Branded but restrained visuals
- Focus on decisions, not decoration

### Expected report sections

Use the relevant subset for the task:

1. Title and report metadata
2. Executive summary
3. Methodology / data source note
4. KPI cards
5. Main analysis sections
6. Tables
7. Charts
8. Key takeaways
9. Risks / caveats
10. Recommended next steps

### MPSTATS Brand Color System

Reports MUST use the MPSTATS brand palette: bright green on near-white. **Values below are extracted from the official MPSTATS PPTX template** — do not approximate, use the exact hex codes.

**Core palette:**

| Role | Hex | Usage |
|------|-----|-------|
| Primary green | `#17BF50` | Accent, headings emphasis, chart primary, decorative orbs |
| Accent green (light) | `#4DF085` | Highlights inside green orbs, secondary accents |
| Ink (near-black) | `#171B20` | Headlines, body copy on light backgrounds |
| Muted text | `#676F79` | Labels, captions, subtitles, secondary text |
| Line (strong) | `#D3D2D2` | Stronger dividers, table borders |
| Line (soft) | `#DBE0E4` | Card strokes, subtle separators |
| Paper | `#F9FAFB` | Card background |
| Background | `#F3F5F7` | Page / canvas background |
| White | `#FFFFFF` | Inner content background where needed |
| Pure black | `#000000` | Wordmark, max-contrast text only |

The brand template does NOT use red/amber/risk colors decoratively. For analytics, risk and warning callouts are allowed but should be desaturated and used sparingly — they are utility colors, not brand colors:

| Role | Hex | Usage |
|------|-----|-------|
| Risk (utility) | `#C23B32` | Risk badges, negative deltas only |
| Risk bg | `#FDEBEA` | Risk block background |
| Warn (utility) | `#C98900` | Caution badges only |
| Warn bg | `#FFF5DA` | Warning block background |

**Chart colors:**

Primary series is always `#17BF50`. Two-series charts: `#17BF50` vs `#D3D2D2` (green vs muted gray). Multi-series, in order:

1. `#17BF50` — primary
2. `#171B20` — ink (high contrast)
3. `#676F79` — muted
4. `#4DF085` — accent light
5. `#C98900` — amber (only if a 5th line is unavoidable)

The brand prefers monochromatic charts (green + neutrals). Do NOT introduce blue, purple, or teal — these are off-brand.

**CSS variables template for HTML reports:**

```css
:root {
  --bg: #F3F5F7;
  --paper: #F9FAFB;
  --card: #FFFFFF;
  --ink: #171B20;
  --muted: #676F79;
  --line: #DBE0E4;
  --line-strong: #D3D2D2;
  --accent: #17BF50;
  --accent-light: #4DF085;
  --good: #17BF50;
  --warn: #C98900;
  --warn-soft: #FFF5DA;
  --risk: #C23B32;
  --risk-soft: #FDEBEA;
  --radius-card: 24px;
  --radius-block: 12px;
  --card-shadow: 0 8px 24px rgba(23, 27, 32, 0.04);
}
```

### Typography

The brand font is **Manrope** (variable, weights 400/600/700/800). Fallback stack: `Manrope, "Helvetica Neue", Arial, sans-serif`. For data/numbers, Manrope works well at all sizes; if a tabular figure feel is needed, use `font-variant-numeric: tabular-nums`.

**Type scale** (extracted from template, in pt → px equivalents for HTML at 96 DPI):

| Role | Size | Weight | Notes |
|---|---|---|---|
| Hero stat / big number | 60-80pt (80-110px) | 800 | KPI cards, headline metrics |
| Section heading | 45-50pt (60-67px) | 700 | Page titles, deep-dive headings |
| Subheading | 22-30pt (30-40px) | 700 | Block titles, chart titles |
| Body large | 18-22pt (24-30px) | 600 | Lede paragraphs, callouts |
| Body | 12-15pt (16-20px) | 400-600 | Main copy, table rows |
| Caption / label | 9-11pt (12-15px) | 600 uppercase, or 400 | Axis labels, table headers, footers |

Body: line-height 1.4-1.5. Headings: line-height 1.1-1.2. Letter-spacing on captions/labels: `0.04em` uppercase.

### Content must never be clipped

HTML reports flow — they are **not** fixed-page slides. A "slide" in this style is a wide rounded card on the page, not a 16:9 box with hard edges. Therefore:

- Use `min-height: 720px; height: auto` (never `height: 720px`) on the card container
- Never set `overflow: hidden` on the card — overflow means a layout bug, not something to mask
- Put the footer meta in normal flow (`margin-top: auto` inside a flex column), not `position: absolute` — absolute footers overlap content as soon as the content grows
- When content doesn't fit visually balanced, **shrink the content** (tighter note, smaller callout, less prose), not the container
- Inside two-column layouts, set `align-items: stretch` so columns match height; don't fix column heights with `calc()` against the parent

If you notice a layout that needs `overflow: hidden` to look right, the layout is wrong — fix the layout. Never accept clipped text, especially numbers, anomaly notes, or footnotes — these are exactly the things a user needs to read.

### PDF export — pagination rules (mandatory)

If the report is going to be printed or exported to PDF (via `print`, `puppeteer`, `weasyprint`, `prince`, etc.), browsers do **not** preserve backgrounds, do **not** keep cards together, and split tables mid-row by default. You must include print CSS explicitly.

**Rules:**

- **One `.slide` = one page.** Each slide gets `page-break-after: always` / `break-after: page`. Set `@page { size: 1280px 720px; margin: 0 }` to match the slide canvas (or `size: A4 landscape; margin: 0` if you prefer paper sizing).
- **Backgrounds must print.** Use `print-color-adjust: exact` and the `-webkit-` prefix on `html, body` and `body *`. Without it, browsers strip card backgrounds, callout fills, and decorative orbs.
- **Cards/blocks/callouts never split.** Apply `break-inside: avoid` (and `page-break-inside: avoid` for legacy) to `.kpi`, `.block`, `.callout`, `.table-note`.
- **Table rows never split, headers repeat.** Set `thead { display: table-header-group }`, `tfoot { display: table-footer-group }`, `tr { break-inside: avoid }`. If a table spans pages, the header re-appears on each.
- **Fix slide dims for print.** In `@media print`, lock `.slide { width: 1280px; height: 720px; min-height: 720px; box-shadow: none; border-radius: 0 }`. The rounded card style is for screen; on a printed page the page IS the card.
- **Drop the last page-break.** `.slide:last-of-type { break-after: auto }` prevents a trailing blank page.

**Required print-CSS block (copy verbatim into the report's `<style>`):**

```css
@page {
  size: 1280px 720px;
  margin: 0;
}

@media print {
  html, body {
    background: var(--paper);
    -webkit-print-color-adjust: exact;
    print-color-adjust: exact;
  }
  body * { -webkit-print-color-adjust: exact; print-color-adjust: exact; }

  .slide {
    margin: 0;
    width: 1280px;
    height: 720px;
    min-height: 720px;
    box-shadow: none;
    border-radius: 0;
    page-break-after: always;
    break-after: page;
    page-break-inside: avoid;
    break-inside: avoid;
  }
  .slide:last-of-type { page-break-after: auto; break-after: auto; }

  .kpi, .block, .callout, .table-note { break-inside: avoid; page-break-inside: avoid; }

  thead { display: table-header-group; }
  tfoot { display: table-footer-group; }
  tr     { break-inside: avoid; page-break-inside: avoid; }
}
```

**Content fit:** in screen mode a slide grows under content (`min-height: 720px`, see «Content must never be clipped»); in print mode it is locked to one page. Therefore **each slide must fit a single 1280×720 canvas**. If it doesn't fit on screen at that size, the PDF will clip — solve at the content level (split into two slides, shrink callouts, fewer table rows), never by enlarging the print page.

**Recommended export commands:**

```bash
# Chrome / Chromium headless (best fidelity with web fonts, SVG charts, orbs)
chrome --headless --disable-gpu --no-margins \
       --print-to-pdf=report.pdf --print-to-pdf-no-header \
       --no-pdf-header-footer file://"$PWD"/report.html

# Puppeteer (Node) — pass { printBackground: true, preferCSSPageSize: true }
# WeasyPrint (Python) — respects @page and break-* properties out of the box
```

Always pass a flag equivalent to `printBackground: true` / `--no-margins` — otherwise the print engine strips backgrounds and adds its own header/footer.

### Visual motif: light card + green 3D orbs

The brand's signature is **soft-rendered 3D green orbs and leaf shapes** placed in the corners of a light rounded card on a near-white background. This is the recognizable MPSTATS look — flat green gradients are NOT the brand.

**Cover / hero page recipe:**

- Page background: `#F3F5F7`
- Centered rounded card: `#F9FAFB`, `border-radius: 24-32px`, soft shadow `0 8px 24px rgba(23,27,32,0.04)`
- 3D green orb decorations in 2-3 corners of the card (top-left, top-right, bottom-right). Orbs are spherical with subtle highlight; some are textured (mesh-like). Real renders, not CSS gradients — use static PNG/SVG assets when available.
- Logo `mpstats` top-left of the card (green square mark + black wordmark)
- Title: 60-80pt, weight 800, `#171B20`, left-aligned
- Subtitle: 22-30pt, `#676F79`, regular weight, below the title with `margin-top: 16px`

If 3D orb assets are unavailable, use a **fallback**: small clusters of overlapping circles in `#17BF50` / `#4DF085` with `filter: blur(4px)` and `opacity: 0.7-0.9`. Place them in corners, never across the content area.

**Section / content page recipe:**

- Same `#F3F5F7` page, same rounded card, but with **muted orbs** (only 1-2, smaller, in a single corner) so they don't compete with data
- Top row: section number + section title + page meta (date, source) on the right
- Content grid: 2-3 columns of KPI cards or a wide chart block + narrower commentary column

**Avoid:**

- Linear gradient hero banners (the old `linear-gradient(135deg, #004D26 → #00B956)` look is wrong — that is NOT this brand)
- Blue / purple / teal accents
- Multiple competing decorative elements per slide
- Heavy drop shadows or glassmorphism
- Dark page backgrounds (the brand is light-first)

### KPI card recipe

```
.kpi {
  background: var(--card);
  border: 1px solid var(--line);
  border-radius: var(--radius-block);
  padding: 24px 28px;
}
.kpi__label { color: var(--muted); font-size: 13px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.04em; }
.kpi__value { color: var(--ink); font-size: 56px; font-weight: 800; line-height: 1.05; margin-top: 8px; }
.kpi__delta--up { color: var(--accent); font-weight: 700; }
.kpi__delta--down { color: var(--risk); font-weight: 700; }
```

Use compact grids: 3 or 4 KPIs per row, equal width, `gap: 16-20px`.

### Table recipe

- Header row: `background: transparent; color: var(--muted); font-size: 12px; text-transform: uppercase; letter-spacing: 0.04em; border-bottom: 1px solid var(--line-strong); padding: 12px 16px;`
- Body rows: `border-bottom: 1px solid var(--line); padding: 14px 16px; color: var(--ink);`
- Numeric columns: right-aligned, `font-variant-numeric: tabular-nums`
- Top entity row (the "1st"): no special highlight; rely on order, not color
- Deltas: `▲` in `#17BF50`, `▼` in `#C23B32`, both at 12-13px next to the number
- No zebra-striping. No vertical grid lines. Borders only between rows.

### Chart recipe

- Single-series time chart: line in `#17BF50`, weight `2.5px`, with `#17BF50` filled area at `opacity: 0.08`
- Axis lines: `#DBE0E4`, `1px`
- Axis text: `#676F79`, `11-12px`, weight 500
- Gridlines: only horizontal, `#DBE0E4` at `opacity: 0.6`
- Title above the chart: 18-22px, weight 700, `#171B20`
- Subtitle / caption: 12-13px, `#676F79`
- Legend: small swatches `10×10px rounded 2px`, labels 12px `#171B20`
- No 3D, no shadows on bars/lines, no dual-axis unless explicitly required

### Takeaway / callout block

```
.callout {
  background: rgba(23, 191, 80, 0.06);   /* tinted with --accent */
  border-left: 3px solid var(--accent);
  border-radius: 8px;
  padding: 16px 20px;
  color: var(--ink);
}
.callout__label { color: var(--accent); font-size: 12px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.04em; margin-bottom: 4px; }
```

For risk callouts: swap `--accent` for `--risk`, background `rgba(194, 59, 50, 0.05)`. Use only when a real risk is being flagged — not for decoration.

## Minimal output rules by task type

### Quick factual answer

- short summary
- one small table if there are multiple rows

### Comparative analysis

- recommendation up front
- comparison table required
- chart if there is trend or share data

### Niche / product research

- summary of opportunity
- table with key metrics
- at least one trend or segmentation view when available
- explicit risks and entry considerations

### Seller / brand review

- headline conclusion
- KPI table
- top entities table
- chart for time dynamics if available

### Full report request

- HTML or PDF is appropriate
- include KPI cards, tables, and charts where applicable
- style should follow MPSTATS report principles above
