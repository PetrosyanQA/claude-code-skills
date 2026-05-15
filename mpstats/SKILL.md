---
name: mpstats
description: "MPSTATS marketplace analytics API. Use when working with MPSTATS API, Wildberries analytics, Ozon analytics, Yandex Market analytics, marketplace data, product research, sales analytics, competitor analysis, niche research, SKU analysis, seller analytics, brand analytics."
license: MIT
metadata:
  version: "2.0.0"
---

# MPSTATS API

MPSTATS is a Russian marketplace analytics platform with data on Wildberries, Ozon, and Yandex Market: product research, category analysis, seller/brand monitoring, SKU-level sales, stock, and review data.

Work through the ready-made shell scripts in `scripts/` — call them via the Bash tool instead of writing HTTP code. Reference files in `references/` are API contracts only.

## Token setup

Scripts auto-load the token from `config/.env` via `scripts/common.sh`. A per-command `MPSTATS_TOKEN` env var overrides the file.

Setup and where to get the token: `config/README.md`.

If the token is missing, offer the user exactly 2 options before continuing:

1. User sends the token in chat → agent creates `config/.env` itself.
2. User runs locally: `cp config/.env.example config/.env` and pastes the token into `config/.env`.

Token page: https://mpstats.io/userpanel (API token block). Requires an active MPSTATS subscription.

## References

API contracts (endpoints, params, response semantics) — read on demand:

- `references/auth.md` — base URL, auth headers, response codes, rate limits
- `references/pagination-filter-sort.md` — common request/response model for all POST endpoints
- `references/wb-categories.md`, `references/wb-brands-sellers.md`, `references/wb-similar-sku.md` — Wildberries
- `references/ozon-categories.md`, `references/ozon-brands-sellers-sku.md` — Ozon
- `references/ym-categories.md` — Yandex Market
- `references/account.md` — API limits
- `references/coverage.md` — what is wrapped by scripts vs. still uncovered
- `references/presentation.md` — how to format analytical answers and brand-styled HTML/PDF reports

## Result formatting

Lead with a concise conclusion, then evidence. Use compact tables for multi-entity results, charts for trends/segmentation/comparisons. Don't dump raw JSON unless asked — interpret what the numbers mean for the decision. For HTML/PDF reports follow the MPSTATS brand style in `references/presentation.md`.

## Sanity check — flag anomalies, never report blindly

MPSTATS data can contain outliers, seller errors, unit mismatches, and stale rows. Reporting them as fact misleads the user. **Before presenting any number, sanity-check its magnitude.**

**Flag explicitly** when you see:

- **Price far outside the category norm** — e.g. napkins at 500 000 ₽ per item, a phone case at 50 ₽, a refrigerator at 200 ₽. Compare to the category median; if it's roughly >10× off, it is almost certainly a seller-side price error, a unit mismatch (pack vs piece), or a placeholder.
- **Implausible volumes** — a small seller suddenly at 1 000 000 units/month; revenue without sales; revenue ≠ approximately `price × units`.
- **Zero / null / negative values where they shouldn't be** — rating 0 on a SKU with reviews, stock = -5, "0 days since last sale" on an obviously inactive SKU.
- **Date / period weirdness** — requested period ≠ returned period, gaps in by-date series, future-dated rows.
- **Unit mismatches** — price per pack treated as price per piece; m² vs piece; liters vs ml.

**How to flag, in this order:**

1. Show the anomalous row clearly, with the value called out (e.g. "500 000 ₽ за упаковку — похоже на ошибку ценника продавца").
2. State your best guess at the cause (unit mismatch, seller error, stale data, placeholder).
3. Either drop the row from aggregates (and say you did) or note that aggregates are skewed by it.
4. Continue the analysis on cleaned data.

**Do NOT** silently drop or "round" anomalies. **Do NOT** report them as if they were real and let the user spot the absurdity. The conclusion must rely on cleaned data; the raw outlier is mentioned for transparency.

## Scripts

Ready-to-use shell scripts in `scripts/`. Call via the Bash tool, do not rewrite HTTP. Full catalog with per-script use-cases and routing guidance: `scripts/README.md`. Run any script with `--help` for parameters.

| Script | Purpose | Usage |
|--------|---------|-------|
| `account/account-limits.sh` | Check API quota remaining | `./scripts/account/account-limits.sh` |
| `wb/wb-categories-list.sh` | Full WB category tree | `./scripts/wb/wb-categories-list.sh` |
| `wb/wb-category.sh` | WB category products | `./scripts/wb/wb-category.sh "Электроника/Смартфоны" 2024-01-01 2024-03-01` |
| `wb/wb-category-stats.sh` | WB category breakdown (subcategories/brands/sellers/trends) | `./scripts/wb/wb-category-stats.sh "Электроника" subcategories` |
| `wb/wb-sku.sh` | WB SKU analytics (full/sales/balance/keywords/comments) | `./scripts/wb/wb-sku.sh 152490541 sales` |
| `wb/wb-card-content.sh` | WB card content (description, characteristics, dimensions) — uses WB CDN, not MPSTATS | `./scripts/wb/wb-card-content.sh 290784358 .description` |
| `wb/wb-brand.sh` | WB brand products or analytics | `./scripts/wb/wb-brand.sh "Nike" products` |
| `wb/wb-seller.sh` | WB seller products or analytics | `./scripts/wb/wb-seller.sh 123456 products` |
| `wb/wb-search.sh` | WB subjects/niches list for research | `./scripts/wb/wb-search.sh` |
| `wb/wb-subject.sh` | WB subject endpoints (`products`, `categories`, `brands`, `sellers`, `trends`, `by_date`, `price_segmentation`, `keywords`, `similar`, `geography`, `warehouses`) | `./scripts/wb/wb-subject.sh 70 products` |
| `wb/wb-similar.sh` | WB similar families (`identical`, `identical_wb`, `similar`, `in_similar`) | `./scripts/wb/wb-similar.sh similar 72124874 products` |
| `wb/wb-analytics.sh` | WB AI forecasts and season effects | `./scripts/wb/wb-analytics.sh category forecast/daily "Женщинам/Платья и сарафаны"` |
| `wb/wb-warehouses.sh` | WB warehouse distribution for brand/seller | `./scripts/wb/wb-warehouses.sh brand "Mango"` |
| `wb/wb-compare.sh` | WB period compare for category/brand/seller/subject | `./scripts/wb/wb-compare.sh subject 70 2024-01-01 2024-01-15 2024-01-16 2024-01-31` |
| `ozon/ozon-categories-list.sh` | Full Ozon category tree | `./scripts/ozon/ozon-categories-list.sh` |
| `ozon/ozon-category.sh` | Ozon category products or stats | `./scripts/ozon/ozon-category.sh "Автотовары" products` |
| `ozon/ozon-sku.sh` | Ozon SKU reports (`sales`, `by_day`, `balance`, `categories`, `keywords`, `full`, `by_period`, `search_stats`, `stores`, `comments`) | `./scripts/ozon/ozon-sku.sh 123456789 keywords 2023-11-27 2023-12-26` |
| `ozon/ozon-brand.sh` | Ozon brand products or analytics | `./scripts/ozon/ozon-brand.sh "Samsung" categories` |
| `ozon/ozon-seller.sh` | Ozon seller products or analytics by seller id or name | `./scripts/ozon/ozon-seller.sh 987654 products` |
| `ozon/ozon-compare.sh` | Ozon period compare for category/brand/seller | `./scripts/ozon/ozon-compare.sh category "Автотовары/..." 2024-01-01 2024-01-15 2024-01-16 2024-01-31` |
| `ym/ym-category.sh` | Yandex Market category products or stats | `./scripts/ym/ym-category.sh "Электроника/Смартфоны"` |
| `ym/ym-brand.sh` | Yandex Market brand products or analytics | `./scripts/ym/ym-brand.sh "Samsung" categories` |
| `ym/ym-seller.sh` | Yandex Market seller products or analytics | `./scripts/ym/ym-seller.sh "Эльдорадо" products` |
| `ym/ym-sku.sh` | Yandex Market item sales history with optional dates | `./scripts/ym/ym-sku.sh 12345678 2024-01-01 2024-01-31` |
| `ym/ym-compare.sh` | Yandex Market period compare for category/brand/seller | `./scripts/ym/ym-compare.sh category "Электроника/Смартфоны" 2024-01-01 2024-01-15 2024-01-16 2024-01-31` |
| `request.sh` | Universal raw API caller for any MPSTATS method/path | `./scripts/request.sh POST subject/items 'path=70&d1=2024-01-01&d2=2024-01-31'` |

