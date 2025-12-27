BOE Reports Runner
==================

Descripción
-----------
Servicio interno que genera informes semanales BOE por provincia (PDF/CSV) usando `adl-data-analyst` (`src/boe/reports/run.ts`). Opcionalmente envía emails si hay SMTP configurado.

Configuración
-------------
Variables (en runtime.env o env del servicio):
- BOE_REPORT_TOPN (default 20)
- BOE_REPORT_MIN_DISCOUNT (default 30)
- BOE_REPORT_OUTPUT_DIR (default /opt/adl-suite/data/reports/boe)
- BOE_REPORT_DRY_RUN (default true) — evita envíos de email
- SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS, SMTP_FROM (opcionales; requeridos para envío)

Ejecución manual
----------------
```
docker compose run --rm boe-reports-runner
```
Salida en `/opt/adl-suite/logs/boe-reports.log` si se usa cron; en stdout si manual.

Cron
----
Instalar cron:
```
sudo bash /opt/adl-suite/adl-infra/scripts/install-cron-boe-reports.sh
```
Archivo creado: `/etc/cron.d/adl-boe-reports`
Schedule: lunes 09:00 UTC
Comando ejecutado:
```
cd /opt/adl-suite && docker compose run --rm boe-reports-runner >> /opt/adl-suite/logs/boe-reports.log 2>&1
```

Montajes
--------
- Monta `/opt/adl-suite/data/reports` para guardar PDFs/CSVs.

Logs
----
- `/opt/adl-suite/logs/boe-reports.log` (cron)
- RUN_OK / RUN_FAIL en stdout/stderr.

