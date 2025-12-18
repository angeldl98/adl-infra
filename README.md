# adl-infra

Infra oficial (única fuente) para despliegue en docker-compose.

Un solo compose, un solo endpoint:
- Compose: este repo `adl-infra/docker-compose.yml`.
- Endpoint oficial: `POST http://localhost:4000/api/subastas/sync` (gateway).

Bootstrap (no arranca nada):
1) Ejecutar `./bootstrap.sh`:
   - Verifica que `/opt/adl-suite/data/secrets/runtime.env` exista (no se guarda en git).
   - Crea `.env` vacío con comentarios si falta y asegura que esté ignorado.
   - Imprime el endpoint oficial.

Arranque del stack:
- Tras bootstrap, ejecutar `docker compose up -d` desde este repo.
- Sin cron, sin rutas legacy. Solo este compose.

Ingesta única (cuando se autorice):
- `POST http://localhost:4000/api/subastas/sync` con `x-api-key` adecuado (en runtime.env).
- Sin proxies, sin PDFs, sin paralelismo.

Secretos:
- No se incluyen en git. Usar `/opt/adl-suite/data/secrets/runtime.env`.

