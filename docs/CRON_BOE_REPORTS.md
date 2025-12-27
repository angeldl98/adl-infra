CRON BOE Reports
================

Objetivo
--------
Generar el informe BOE solo cuando hay datos suficientes (subastas activas y PDFs analizados) sin forzar scraping.

Programación
------------
- 09:00 UTC (1 vez/día)

Comando (cron)
--------------
```
cd /opt/adl-suite && /usr/bin/docker compose run --rm boe-reports-runner >> /opt/adl-suite/logs/boe-reports.log 2>&1
```

Lógica de readiness
-------------------
- MIN_ELIGIBLE_SUBASTAS = 20 (subastas activas con fecha_fin futura en `boe_prod.subastas_pro`)
- MIN_PDFS_ANALYZED = 5 (`boe_aux.pdf_signals` con extract_ok=true)
- Si no se cumple: `REPORT_SKIPPED | reason=insufficient_data` y `RUN_OK`.

Instalación
-----------
```
sudo bash /opt/adl-suite/adl-infra/scripts/install-cron-boe-reports.sh
```
(ya existente para reports runner)

Logs
----
- `/opt/adl-suite/logs/boe-reports.log`

Notas
-----
- No fuerza scraping; depende de la acumulación periódica del scraper BOE.
- No genera informes vacíos.

