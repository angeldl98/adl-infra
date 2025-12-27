CRON BOE Scraper
================

Objetivo
--------
Ejecutar el scraper histórico BOE de forma periódica para acumular subastas activas y PDFs bajo la política de presupuesto.

Programación
------------
- 08:30 UTC y 20:30 UTC (2 veces/día)

Comando (cron)
--------------
```
cd /opt/adl-suite && BOE_PDF_DAILY_BUDGET=10 BOE_PDF_MAX_DAYS_AHEAD=45 BOE_PDF_ONLY_ACTIVE=true BOE_PDF_ONLY_INMUEBLE=true BOE_PDF_DRY_RUN=false /usr/bin/docker compose run --rm boe-runner >> /opt/adl-suite/logs/boe-runner.log 2>&1
```

Instalación
-----------
```
sudo bash /opt/adl-suite/adl-infra/scripts/install-cron-boe-scraper.sh
```
Crea `/etc/cron.d/adl-boe-scraper`.

Logs
----
- `/opt/adl-suite/logs/boe-runner.log` (la salida del runner ya escribe ahí; el cron redirige al mismo).

Política de PDFs (resumen)
--------------------------
- Budget: `BOE_PDF_DAILY_BUDGET` (default 20; cron usa 10).
- Ventana: `BOE_PDF_MAX_DAYS_AHEAD` (45).
- Solo activas (`BOE_PDF_ONLY_ACTIVE=true`) e inmuebles (`BOE_PDF_ONLY_INMUEBLE=true`).
- Delays humanos: `BOE_PDF_DELAY_MIN_MS` / `BOE_PDF_DELAY_MAX_MS`.
- `BOE_PDF_DRY_RUN` controla si descarga o solo simula.

