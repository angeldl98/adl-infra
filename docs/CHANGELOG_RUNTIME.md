## fix/control-plane-and-boe
- Ajuste de boe-raw-runner en compose.apps para apuntar a host Postgres `adl-postgres` y habilitar DOCKER_ENV/DATABASE_URL con variable de secreto.
- Volumen de debug para BOE y timers systemd para ejecuciones periódicas (boe 15m, pharma 5m) usando `docker compose run`.
- Compose: runners sin restart automático y con host PG explícito; servicios de systemd versionados en `systemd/`.

