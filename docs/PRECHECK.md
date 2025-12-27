PRECHECK · 2025-12-27 UTC

- Docker `docker compose ps`:
  - Postgres/Redis/Web/Gateway/Brain/Executor/Knowledge/Monitor running and healthy.
  - Caddy up on :80/:443.
  - boe-runner up; pharma-runner defined but not currently running (on-demand OK).
- Listeners: :80 and :443 bound via docker-proxy (Caddy).
- Git status:
  - adl-infra: clean (main).
  - adl-web: dirty (user change in `app/(pro)/subastas/pro/[id]/page.tsx`).
  - adl-data-analyst: dirty only in `dist/` (ignored build artefacts).
  - adl-gateway: clean.

Notes:
- Compose warnings about POSTGRES_PASSWORD default; runtime env file provides it (set when running runners).
- No config changes applied in this precheck.

