---
name: photo-editor
description: "MPSTATS Photo Editor API. Use when generating product photos, photoshoots, infographics, recolors, in-action scenes, background removal/replacement, upscaling, prompt-based image edits for marketplace sellers (Wildberries, Ozon, YM)."
license: MIT
metadata:
  author: esporykhin
  version: "1.1.0"
---

# MPSTATS Photo Editor

Внутренний MPSTATS-сервис AI-генерации визуала под маркетплейс-карточки: удаление/замена фона, апскейл, перекраска, «товар в действии», prompt-edit, фотосессии, инфографика.

Все запросы — через готовые скрипты в `scripts/` (Bash tool, **не писать код заново**). Эндпоинты асинхронные: скрипт сам делает submit → поллинг → сохранение файлов. Картинки кодируются в base64 внутри скриптов.

## Два режима работы

Выбирай осознанно — это меняет всё дальнейшее поведение.

**A. Технические операции (одношаговые)** — `remove-background`, `upscale`, `replace-background`, `in-action`, `recolor`, `freeform`. Запустил скрипт → получил результат → доставил. Без research/brief. Применять, когда просят конкретное действие («убери фон», «увеличь», «перекрась в синий»).

**B. Дизайнерские задачи (multi-stage)** — `infographics` и `photoshoot`. Полноценная дизайн-работа: думай как маркетплейс-дизайнер. Применять, когда речь о ценности для покупателя («сделай инфографику», «обнови карточку», «нужна фотосессия»). Используй стадийные гайды в `references/` — это гайды мышления, не чек-листы:

| Стадия | Файл | Когда |
|---|---|---|
| 1. Research | [references/01-research.md](references/01-research.md) | По умолчанию для режима B, если пользователь не выбрал «без исследования». |
| 2. Brief / ТЗ | [references/02-brief.md](references/02-brief.md) | Всегда перед генерацией в режиме B. Также — вся prompt-craft: структура промпта, серия слайдов, лимит длины, content-filter. |
| 3. Generate | [references/03-generate.md](references/03-generate.md) | Всегда. Перед запуском спроси: «сразу пачку или сначала test-кадр?». |
| 4. Deliver | [references/04-deliver.md](references/04-deliver.md) | **Обязательно, читай ПЕРЕД показом результата.** Показывай каждый кадр через `Read` с подписью-якорем, не список путей. |

### Старт режима B — обязательный вопрос

**Когда задача определена как режим B, первым делом задай один вопрос:**

> Запустить полное исследование (анализ конкурентов, отзывы, визуальный бенчмарк) или сразу сгенерировать по вашему промпту / описанию?

Варианты ответа и что делать:

| Ответ пользователя | Действие |
|---|---|
| «с исследованием» / «полный анализ» / молчание (нет явного отказа) | Запускай Stage 1 → 2 → 3 → 4 в полном объёме |
| «без исследования» / «сразу генерируй» / «по моему промпту» | Пропускай Stage 1, переходи сразу к Stage 2 (brief по описанию пользователя) → 3 → 4. Явно сообщи: «Пропускаю исследование — качество может быть ниже, зато быстрее». |
| Пользователь сам даёт готовый промпт в сообщении | Уточни: использовать его как есть или прогнать через brief (проверка длины, структура блоков, product lock)? |

**Исключение:** если пользователь уже явно указал «без анализа» / «no research» в первом сообщении — вопрос не задавай, сразу переходи к Stage 2.

## Config

Креды в `config/.env` (gitignored): `PHOTO_EDITOR_TOKEN` (заголовок `X-Mpstats-TOKEN`) и опц. `PHOTO_EDITOR_BASE_URL` (дефолт `https://mpstats.io/api/big_data/proxy`). Setup и переменные: [config/README.md](config/README.md).

Если токена нет (или он `your_token_here`), агент **обязан** попросить:

```
Нужен MPSTATS API-токен (X-Mpstats-TOKEN) для Photo Editor — возьмите в ЛК MPSTATS → API и пришлите, я пропишу в config/.env.
```

## Output location

**НЕ складывай результаты в папку скилла** — скилл это код, output это данные. Дефолт `~/.claude/output/photo-editor/<event_id>/`, override через `PHOTO_EDITOR_OUTPUT_DIR`.

Для режима B после генерации скопируй файлы в чистую папку по SKU с осмысленными именами (`slide_1_hero.png` и т.п.) — `event_id` содержит `:`, что ломает рендер картинок в части UI-клиентов, и по SKU пользователю проще искать.

## Multi-angle вход: `wb:<sku>`

В `infographics.sh` и `photoshoot.sh` первым аргументом можно передать `wb:<sku>` или `wb:<wb-url>` вместо пути к файлу. Скилл скачает все фото товара с WB CDN (`wb-fetch-photos.sh`, кеш в `~/.claude/cache/photo-editor/wb-photos/<sku>/`): первое → `main_image`, остальные → `reference_images` (максимум 5, API не принимает больше).


```bash
infographics.sh generate wb:164419278 "$PROMPT" 5
```

При multi-angle входе в защите товара пиши «preserve product **identity**», НЕ «preserve same orientation» — иначе модель скопирует ракурс первого фото на все слайды. Подробнее о промпте — `references/02-brief.md`.

## Infographics: серия из N слайдов

`infographics.sh generate <img> "<prompt>" <count>` создаёт **серию из `count` слайдов** (1..6) одним вызовом. Поток: `test` (пристрелочный кадр) → апрув → `generate <N>`; либо `auto` (test + generate сразу).

> **Минимальный выход — 4 кадра.** Endpoint всегда возвращает `max(4, image_count)` изображений — запрос count=1..3 всё равно даст 4. Для photoshoot такого ограничения нет.

Промпт задаёт **высокоуровневое направление + темы кадров**, не layout каждого слайда — иначе выйдет коллаж 2×3 на одном холсте. Детали prompt-craft — `references/02-brief.md`.

## Models

| Маска | Тир | Дефолт | Aspect ratios | Доступен для |
|---|---|---|---|---|
| `model_1` | **Standard** | ✅ все кроме infographics | 1:1, 3:4, 4:3, 2:3, 3:2 | все эндпоинты |
| `model_2` | **PRO** | ✅ infographics | 1:1, 3:4, 4:3, 2:3, 3:2 | все эндпоинты |
| `model_3` | PRO | — | 1:1, 3:4, 4:3, 2:3, 3:2 | все эндпоинты |
| `model_4` | PRO | — | 1:1, 3:4, 4:3, 2:3, 3:2 | все эндпоинты |
| `model_5` | PRO | — | 1:1, 3:4, 4:3 | freeform, photoshoot |

Бэкенд не принимает `model=auto` — скилл резолвит его в `model_1` (Standard). Для инфографики дефолт жёстко прошит как `model_2` (PRO) — лучшее качество кириллицы. Явную модель указывай только если есть гипотеза почему.

## Scripts

| Script | Когда использовать |
|---|---|
| `remove-background.sh <img>` | Убрать фон |
| `upscale.sh <img>` | Увеличить разрешение |
| `replace-background.sh <img> <template_key>` | Поставить товар на стоковый фон |
| `in-action.sh <img> <template_key>` | Товар в готовой сцене использования |
| `recolor.sh <img> <#hex>` | Перекрасить товар |
| `freeform.sh <img> "<prompt>" [model] [ar] [refs]` | Произвольный edit (одношаговый) |
| `photoshoot.sh auto <img> "<prompt>" <count>` | Фотосессия (test → generate в одну команду) |
| `photoshoot.sh test \| generate` | Если нужен апрув test-кадра отдельно |
| `infographics.sh auto <img> "<prompt>" <count>` | Инфографика (test → generate) |
| `infographics.sh test \| generate` | Аналогично photoshoot |
| `templates.sh backgrounds [key]` | Списать `template_key` для replace-background |
| `templates.sh in-action [key]` | Списать `template_key` для in-action |
| `wb-fetch-photos.sh <sku-or-url> [max=8]` | Скачать WB-фото товара. Вызывается автоматически при `wb:<sku>` входе |
| `health.sh` | Проверить сервис |
| `run.sh <endpoint> <body_json>` | Универсальный submit + poll |
| `poll.sh <event_id>` | Дождаться готовый event_id |

## Decision Guide

- «почисти фон» → A, `remove-background.sh`
- «сделай больше/чётче» → A, `upscale.sh`
- «поменяй фон на студию/мрамор» → A, `templates.sh backgrounds` → `replace-background.sh`
- «покажи товар в использовании» → A, `templates.sh in-action` → `in-action.sh`
- «перекрась в #hex» → A, `recolor.sh`
- «поправь освещение / убери блик / добавь тень» → A, `freeform.sh`
- «сделай инфографику / фотосессию», «обнови карточку товара X» → B, начинай с `references/01-research.md`

## Errors

| msg | Что делать |
|---|---|
| `process_completed` | Готово, файлы сохранены |
| `process_completed` + `output.image: []` | Content-filter → перефразируй prompt (`references/02-brief.md`) |
| `process_error` | Прочитать `error.message`, показать пользователю |
| `process_timeout` | Сервер не уложился; уменьши count или поменяй модель |
| `Prompt size exceeds maximum allowed length` | **Чаще всего причина — переносы строк (`\n`) в промпте**, а не реальное превышение лимита. Передавай промпт одной строкой. Если после этого ошибка осталась — сократи промпт: `references/02-brief.md` → Технические ограничения. |
| `AUTH_ERROR` | Неверные креды — см. секцию Config |
| Локальный poll timeout | Скрипт остановил поллинг; event_id остался — `poll.sh <event_id>` |
