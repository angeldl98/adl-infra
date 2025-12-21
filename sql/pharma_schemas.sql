-- ADL Data Factory - Pharma schemas and tables
CREATE SCHEMA IF NOT EXISTS pharma_raw;
CREATE SCHEMA IF NOT EXISTS pharma_norm;
CREATE SCHEMA IF NOT EXISTS pharma_prod;
CREATE SCHEMA IF NOT EXISTS pharma_meta;

CREATE TABLE IF NOT EXISTS pharma_raw.documents (
  id SERIAL PRIMARY KEY,
  fetched_at TIMESTAMPTZ DEFAULT now(),
  url TEXT NOT NULL,
  payload_raw TEXT NOT NULL,
  checksum TEXT NOT NULL,
  UNIQUE(checksum)
);

CREATE TABLE IF NOT EXISTS pharma_meta.ingest_runs (
  run_id UUID PRIMARY KEY,
  started_at TIMESTAMPTZ NOT NULL,
  finished_at TIMESTAMPTZ,
  status TEXT,
  processed INT,
  errors INT
);

CREATE TABLE IF NOT EXISTS pharma_meta.job_locks (
  lock_key TEXT PRIMARY KEY,
  locked_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS pharma_norm.medicamentos (
  id SERIAL PRIMARY KEY,
  raw_id INT UNIQUE REFERENCES pharma_raw.documents(id),
  nombre TEXT,
  codigo_nacional TEXT,
  laboratorio TEXT,
  estado TEXT,
  presentacion TEXT,
  fecha_publicacion DATE,
  url TEXT,
  checksum TEXT
);

CREATE TABLE IF NOT EXISTS pharma_norm.desabastecimientos (
  id SERIAL PRIMARY KEY,
  raw_id INT UNIQUE REFERENCES pharma_raw.documents(id),
  producto TEXT,
  causa TEXT,
  fecha_publicacion DATE,
  fecha_actualizacion DATE,
  estado TEXT,
  url TEXT,
  checksum TEXT
);

