## PROD Web Source of Truth (adlsuite.com)

Fecha: 2025-12-21

- Dominio: `adlsuite.com` (y dashboard/api variantes)
- Proxy: Caddy (ver `/opt/adl-suite/Caddyfile`)
  - `adlsuite.com` → `reverse_proxy adl-web:3000`
  - `dashboard.adlsuite.com` → `reverse_proxy adl-web:3000`
  - `api.adlsuite.com` → `reverse_proxy adl-gateway:4000`
- Contenedor web activo: `adl-web`
  - Imagen: `adl-infra-adl-web`
  - Puerto interno: 3000
  - Fuente git usada para la imagen: repo `adl-web` (Dockerfile en `adl-web/`, build → dist)
- Contenedor API activo: `adl-gateway`
  - Imagen: `adl-suite-adl-gateway`
  - Puerto interno: 4000
  - Fuente git: `adl-gateway`

Evidencias:
- `Caddyfile`: rutas anteriores.
- `docker inspect adl-web` → imagen `adl-infra-adl-web`.
- `docker ps` muestra `adl-web` en ejecución.

Conclusión: la web en producción responde a la imagen construida desde el repo `adl-web`, no `adl-panel`. Para reflejar GitHub como fuente única, los cambios de visibilidad (Pharma/BOE) deben aplicarse en `adl-web` o se debe migrar explícitamente a `adl-panel` en un paso posterior aprobado.

