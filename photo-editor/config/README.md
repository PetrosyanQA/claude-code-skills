# Photo Editor — Config

Запросы идут через `https://mpstats.io/api/big_data/proxy/v1/...` с заголовком `X-Mpstats-TOKEN`.

## Setup

```bash
cp config/.env.example config/.env
perl -i -pe 's|^PHOTO_EDITOR_TOKEN=.*|PHOTO_EDITOR_TOKEN=ВАШ_ТОКЕН|' config/.env
```

## Переменные

| Переменная | Описание | По умолчанию |
|---|---|---|
| `PHOTO_EDITOR_BASE_URL` | Базовый URL без `/` на конце | `https://mpstats.io/api/big_data/proxy` |
| `PHOTO_EDITOR_TOKEN` | X-Mpstats-TOKEN | — |
| `PHOTO_EDITOR_OUTPUT_DIR` | Куда складывать результаты | `~/.claude/output/photo-editor/` |

Любая переменная окружения переопределяет значение из `.env`.

## Где взять токен

В личном кабинете MPSTATS → API.
