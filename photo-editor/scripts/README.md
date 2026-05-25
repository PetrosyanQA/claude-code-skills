# Photo Editor — Scripts

Каждый скрипт работает по схеме:
1. Загружает креды из `config/.env` (env vars override).
2. Кодирует входное изображение в base64 (принимает локальный путь или URL).
3. Шлёт POST на нужный эндпоинт с Basic Auth.
4. Получает `event_id`, поллит `POST /v1/images/status` каждые 5с.
5. По завершении сохраняет картинки в `output/<event_id>/` и печатает JSON с **абсолютными путями к файлам**.

## Catalog

| Script | Endpoint | Use case |
|---|---|---|
| `health.sh` | `GET /health` | Проверка сервиса |
| `templates.sh backgrounds [key]` | `GET /v1/templates/backgrounds[/{key}]` | Список фоновых шаблонов |
| `templates.sh in-action [key]` | `GET /v1/templates/in-action[/{key}]` | Список "в действии" шаблонов |
| `remove-background.sh` | `/v1/images/remove_background` | Удалить фон |
| `upscale.sh` | `/v1/images/upscale` | Увеличить разрешение |
| `replace-background.sh` | `/v1/images/replace-background` | Заменить фон по template_key |
| `in-action.sh` | `/v1/images/in-action` | Товар в сцене использования |
| `recolor.sh` | `/v1/images/recolor` | Перекраска товара в hex-цвет |
| `freeform.sh` | `/v1/images/freeform` | Произвольный prompt-edit (с реф-картинками) |
| `photoshoot.sh test\|generate\|auto` | `/v1/photoshoot/*` | Фотосессия товара (1..8 кадров) |
| `infographics.sh test\|generate\|auto` | `/v1/infographics/*` | Инфографика для карточки (1..8 кадров) |
| `run.sh` | любой POST `/v1/...` | Универсальный submit + poll |
| `poll.sh <event_id>` | `/v1/images/status` | Дождаться готовый event_id и сохранить файлы |

## Output

Все артефакты складываются в `<skill>/output/<event_id>/`:
- `image_1.png`, `image_2.png`, ... — изображения
- `meta.json` — финальный webhook-payload (для отладки)

После завершения скрипт печатает JSON вида:
```json
{"status":"completed","event_id":"...","kind":"image","files":["/abs/path/image_1.png"]}
```

## Models

| Маска | Тир | Aspect ratios | Эндпоинты |
|---|---|---|---|
| `model_1` | Standard | 1:1, 3:4, 4:3, 2:3, 3:2 | все |
| `model_2` | PRO | 1:1, 3:4, 4:3, 2:3, 3:2 | все |
| `model_3` | PRO | 1:1, 3:4, 4:3, 2:3, 3:2 | все |
| `model_4` | PRO | 1:1, 3:4, 4:3, 2:3, 3:2 | все |
| `model_5` | PRO | 1:1, 3:4, 4:3 | freeform, photoshoot |

Defaults: `model_1` везде, `model_2` для infographics. `auto` → `model_1` (резолвится в скрипте, бэкенд не принимает).



## Examples

```bash
# Удалить фон
./scripts/remove-background.sh ~/Desktop/product.jpg

# Перекрасить товар в коралловый
./scripts/recolor.sh ~/Desktop/product.jpg "#FF5733" model_2 1:1

# Списать шаблоны фонов и поставить товар на студийный фон
./scripts/templates.sh backgrounds | jq '.groups | keys'
./scripts/replace-background.sh ~/Desktop/product.jpg studio_light model_2 1:1

# Произвольный edit с референсом
./scripts/freeform.sh ~/Desktop/product.jpg \
  "Поставь товар на мраморную столешницу при мягком утреннем свете" \
  auto 3:4 ~/Desktop/ref.jpg

# Фотосессия 4 кадра в один шаг
./scripts/photoshoot.sh auto ~/Desktop/product.jpg \
  "Линейка маркетплейс-кадров: лайфстайл, разные ракурсы, мягкий студийный свет" 4

# Инфографика 3 кадра
./scripts/infographics.sh auto ~/Desktop/product.jpg \
  "Инфографика для WB-карточки: акцент на материале, размере, гарантии" 3
```
