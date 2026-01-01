CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE IF NOT EXISTS public.boe_subastas_norm (
  id BIGSERIAL PRIMARY KEY,
  boe_subasta_raw_id INTEGER NOT NULL REFERENCES public.boe_subastas_raw(id),
  auction_type TEXT,
  issuing_authority TEXT,
  province TEXT,
  municipality TEXT,
  auction_status TEXT,
  start_date TIMESTAMPTZ,
  end_date TIMESTAMPTZ,
  starting_price NUMERIC,
  deposit_amount NUMERIC,
  normalized_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  normalization_version INTEGER NOT NULL DEFAULT 1,
  CONSTRAINT boe_subastas_norm_raw_unique UNIQUE (boe_subasta_raw_id)
);

CREATE INDEX IF NOT EXISTS idx_boe_subastas_norm_province ON public.boe_subastas_norm (province);
CREATE INDEX IF NOT EXISTS idx_boe_subastas_norm_status ON public.boe_subastas_norm (auction_status);
CREATE INDEX IF NOT EXISTS idx_boe_subastas_norm_start_date ON public.boe_subastas_norm (start_date);
CREATE INDEX IF NOT EXISTS idx_boe_subastas_norm_end_date ON public.boe_subastas_norm (end_date);

