# Paper Planes production Drive setup

Инструкция и проверочный скрипт для подключения компьютеров к производственным папкам Paper Planes на Google Drive.

## Файлы

- `outputs/instrukciya_podklyucheniya_proizvodstva_google_drive.md` — инструкция для настройки компьютера.
- `outputs/pp_production_drive_check.sh` — read-only сканер текущей настройки Google Drive.

## Быстрый запуск сканера

```bash
chmod +x outputs/pp_production_drive_check.sh
outputs/pp_production_drive_check.sh
outputs/pp_production_drive_check.sh "Гартенн"
```

Скрипт ничего не меняет на компьютере: только проверяет локальный Google Drive, производственную папку и расположение проекта.
