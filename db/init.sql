CREATE TABLE IF NOT EXISTS items (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO items (name)
VALUES
  ('seed-item-1'),
  ('seed-item-2'),
  ('seed-item-3')
ON CONFLICT DO NOTHING;
