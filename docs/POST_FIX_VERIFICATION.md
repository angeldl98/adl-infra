## Pruebas ejecutadas (fix/control-plane-and-boe)

- Conectividad Postgres desde boe-raw-runner:
```
[ { '?column?': 1 } ]
```

- BOE scraper ejecutado vía systemd (15 enlaces procesados, pipeline_runs registrado):
```
SELECT pipeline,status,stats->>'listing_links',started_at,finished_at FROM pipeline_runs ORDER BY started_at DESC LIMIT 3;
 boe-raw | ok | 15 | 2026-01-01 11:25:08+00 | 2026-01-01 11:26:56+00
```
```
boe_subastas_raw count=162 last_fetched_at=2026-01-01 11:26:56+00
```

- Pharma ingesta (upsert + métricas):
```
SELECT pipeline,status,stats FROM pipeline_runs WHERE pipeline='pharma-raw' ORDER BY started_at DESC LIMIT 1;
 status=ok stats={"total":25412,"updated":0,"inserted":0,"unchanged":25412}
```

- Timers systemd activos:
```
systemctl list-timers --all | grep runner
pharma-runner.timer next=11:31:10 (5m) prev=11:26:10
boe-runner.timer    next=11:40:05 (15m) prev=11:10:35
```

- Estado contenedores activos:
```
docker ps:
adl-gateway (Up), adl-web (Up), adl-postgres (healthy), adl-redis (healthy), adl-caddy (Up)
```

- Liveness / readiness gateway:
```
curl http://localhost/healthz -> 200 {"status":"ok"}
curl -H "Authorization: Bearer <jwt>" http://localhost/readyz -> 200 {"status":"ok","db":{"ok":true},"web":{"ok":true,"status":200}}
```

