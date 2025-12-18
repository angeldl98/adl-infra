# adl-infra

Infra oficial (única fuente) para despliegue en docker-compose.

Un solo compose activo para BOE:
- Compose activo: `docker-compose.boe.yml` (gateway + scraper + postgres + web).
- Composes legacy/full se mueven a `graveyard/` y no se usan.
- Endpoint oficial: `POST http://localhost:4000/api/subastas/sync` (gateway).

Bootstrap (no arranca nada):
1) Ejecutar `./bootstrap.sh`:
   - Verifica que `/opt/adl-suite/data/secrets/runtime.env` exista (no se guarda en git).
   - Crea `.env` vacío con comentarios si falta y asegura que esté ignorado.
   - Imprime el endpoint oficial.

Arranque del stack BOE:
- Tras bootstrap, ejecutar `docker compose -f docker-compose.boe.yml up -d`.
- Sin cron, sin rutas legacy. Solo este compose.

Ingesta única (cuando se autorice):
- `POST http://localhost:4000/api/subastas/sync` con `x-api-key` adecuado (en runtime.env).
- Sin proxies adicionales, sin PDFs, sin paralelismo, sin cron.

Secretos:
- No se incluyen en git. Usar `/opt/adl-suite/data/secrets/runtime.env`.

