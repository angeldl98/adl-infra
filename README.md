# adl-infra

Infra oficial (única fuente) para despliegue en docker-compose.

Servicios clave:
- `adl-gateway` expuesto en host: `4000:4000`. Endpoint oficial de ingesta: `POST http://localhost:4000/api/subastas/sync`.
- Resto de servicios se comunican en la red interna `adl-net`.

Notas:
- No se incluyen secretos. Variables en `data/secrets/runtime.env` se montan fuera del repo.
- No se exponen otros puertos adicionales en esta versión mínima.

