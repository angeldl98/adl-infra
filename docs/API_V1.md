# API v1 (Read-only data exposition)

Auth: JWT (obtain via `POST /login` on adl-gateway, same secret).  
Base path: `https://api.adlsuite.com/api/v1` (via gateway).  
Pagination: `limit` (default 50, max 200), `offset` (default 0).

## GET /api/v1/boe-auctions
- Filters: `auction_status` (exact match), `province` (exact match).
- Fields: `id, auction_type, auction_status, start_date, end_date, starting_price, deposit_amount, province, municipality, normalized_at`.
- Order: `normalized_at DESC`.

Example:
```
GET /api/v1/boe-auctions?limit=50&offset=0&auction_status=active&province=MADRID
Authorization: Bearer <JWT>
```

## GET /api/v1/pharma-medicines
- Filters: `search` (ILIKE on `nombre`).
- Fields: `nregistro, nombre, dci, forma_farmaceutica, via_administracion, updated_at`.
- Order: `updated_at DESC NULLS LAST`.

Example:
```
GET /api/v1/pharma-medicines?search=ibuprofeno&limit=25
Authorization: Bearer <JWT>
```

