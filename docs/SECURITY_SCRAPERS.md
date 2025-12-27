SECURITY / ANTI-SCRAPING SNAPSHOT (2025-12-27 UTC)

Superficie expuesta (adl-gateway):
- /health (GET) público.
- /metrics (GET) público.
- /info (GET) requiere API key/policy.
- /diagnostics (GET) requiere API key/policy.
- /auth/* proxy core-auth (API key/policy).
- /api/boe (GET list, limit fijo 50, orden updated_at desc; devuelve {ok,data,source}); /api/boe/stats (GET agregados); /api/boe/:subastaId (GET detalle).
- /api/pharma/search (GET, params q?, limit default 20 max 50; devuelve {ok,data,meta}).
- /api/subastas: /sync/status (GET proxy engine-scraper), /sync (POST async trigger), /stats (GET agregados), / (GET lista con provincia/estado/from/to, limit default 25 max 100, offset), /:idSub (GET detalle + docs/lotes), /documents/:id/download (GET proxy stream PDF).
- Rutas proxy estáticas: /auth, /executor, /knowledge, /monitor, /brain, /web, /engine-* (scraper/trading/solvency/etc.) vía http-proxy.

Riesgos detectados:
- Límite actual global express-rate-limit: 300 req/min IP, sin diferenciación por endpoint.
- Endpoint /api/subastas lista permite limit hasta 100 y offset libre (paginación pero sin pageSize cap duro a 50).
- /api/boe list devuelve 50 sin paginación; podría ser scrapeable secuencialmente cambiando updated_at pero sin page param (exposición de última ventana).
- /api/pharma/search limita a 50 pero sin paginación/offset (solo top recientes).
- No hay cache-control/etag en respuestas JSON.
- No existe /api/session/issue ni cookie anti-bot.
- No hay telemetría anti-scraper ni kill-switch de endurecimiento.
- Cloudflare/WAF no documentado en IaC (pendiente reglas edge).

Web (adl-web) consumidores principales:
- /app/(public)/subastas/page.tsx usa `/api/boe/subastas/free?limit=50&offset=0` (Next API interna, no “all” directo).
- /app/pharma/page.tsx usa `/api/pharma/list` (Next API interna).
- Dashboard/admin varias (logs, system, cognitive) internas; no endpoints públicos “all”.

Próximos pasos (según plan):
- Validar/limitar page/pageSize en endpoints list, 400 si excede.
- Añadir rate limiting por IP (ruta general y heavy) con Redis.
- Añadir cache-control/etag para list públicos.
- Añadir /api/session/issue + cookie HMAC y exigirla en endpoints de valor (ej. procurement list).
- Documentar reglas Cloudflare/WAF cuando se apliquen.

Actualización 2025-12-27:
- Gateway ahora aplica rate limiting diferenciada (general/heavy) con Redis o memoria, logs RATE_LIMIT_HIT.
- Endpoints list (boe/pharma/subastas) imponen page/pageSize max 50; 400 si excede; devuelven meta y ETag + Cache-Control s-maxage=60.
- /api/session/issue (gateway) y middleware en adl-web generan cookie HMAC `adl_session` (TTL 12h).
- Telemetría básica por minuto en gateway: top paths/UA/status en logs TRAFFIC_MINUTE.
- Pendiente: reglas Cloudflare (Bot Fight / WAF / UA vacíos) documentar cuando se desplieguen; aplicar sesión requerida en endpoints de alto valor (procurement cuando se publique).

