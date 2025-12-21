## ADL Suite - Inventario y congelación (SAFE MODE, sin borrados)

Fecha: 2025-12-21

### Repos Git detectados en VPS (/opt/adl-suite)
- adl-gateway (API actual)
- adl-web (web actual)
- adl-infra
- adl-boe-raw-scraper
- adl-boe-normalizer
- adl-df-pharma-raw
- adl-df-pharma-normalizer
- adl-data-analyst

### Carpetas top-level (resumen)
- Principales: adl-gateway, adl-web, adl-infra, adl-brain, adl-executor, adl-knowledge, adl-monitor, core-*, engines/*, data, logs, diagnostics, scripts, etc.
- BOE/Pharma auxiliares: adl-boe-raw-scraper, adl-boe-normalizer, adl-df-pharma-raw, adl-df-pharma-normalizer, adl-data-analyst.
- _graveyard existente con boe-legacy/engines-scraper y repos-frozen/adl-brain-v2, adl-executor-v2.

### Contenedores en ejecución (docker ps)
- adl-postgres (postgres:15)
- adl-gateway (adl-suite-adl-gateway) [unhealthy por healthcheck, puerto interno 4000]
- adl-web (adl-infra-adl-web)
- adl-brain, adl-executor, adl-monitor, adl-knowledge, core-* (auth, policy, secrets, etc.), engines-* (trading, solvency, npl, etc.), adl-caddy, adl-redis.

### Systemd timers/servicios relevantes
- boe-runner.timer (activo, cada 6h)
- pharma-runner.timer (activo, cada 6h)
- boe-runner.service / pharma-runner.service asociados.

### Elementos fuera de la lista de repos activos declarados (adl-scraper, adl-api, adl-brain, adl-trading, adl-solvencia, adl-infra)
- Presentes pero no movidos (SAFE MODE, sin impacto operativo): adl-boe-raw-scraper, adl-boe-normalizer, adl-df-pharma-raw, adl-df-pharma-normalizer, adl-data-analyst, adl-gateway (API actual), adl-web (web actual), engines/* y core/* (activos).
- Motivo de no mover: requeridos por pipelines BOE/Pharma en producción actual y/o servicios en ejecución; instrucción explícita de no tocar BOE ingestión y operar en modo no destructivo.
- adl-panel: no presente y sin uso; decisión final de no emplearlo.

### Pendientes de congelar en _graveyard/UNTRACKED_YYYYMMDD (no ejecutado)
- Todos los repos/folders no listados como activos oficiales (ver sección anterior) deberían moverse en fase aprobada futura, con reemplazo operativo definido (adl-scraper/adl-api/adl-panel).
- No se movió nada en esta fase por instrucción de “SAFE MODE, sin borrados y sin tocar BOE”.

### Siguiente paso sugerido
- Definir sustitutos en repos oficiales (adl-scraper/adl-api/adl-panel) antes de mover o eliminar; reconfigurar servicios para apuntar a los nuevos repos y entonces congelar los actuales en _graveyard.

