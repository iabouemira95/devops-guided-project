CREATE TABLE IF NOT EXISTS items (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  service TEXT NOT NULL,
  environment TEXT NOT NULL,
  priority TEXT NOT NULL,
  status TEXT NOT NULL,
  owner_name TEXT NOT NULL,
  region TEXT NOT NULL,
  source TEXT NOT NULL,
  details TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO items (
  name,
  service,
  environment,
  priority,
  status,
  owner_name,
  region,
  source,
  details
)
VALUES
  (
    'Checkout API latency spike after release',
    'checkout-api',
    'prod-sim',
    'high',
    'investigating',
    'platform-oncall',
    'sweden-central',
    'synthetic-alert',
    'Latency increased after a simulated deployment and the team is validating logs, metrics, and rollback readiness.'
  ),
  (
    'Inventory sync backlog building up',
    'inventory-worker',
    'staging-sim',
    'medium',
    'monitoring',
    'data-ops',
    'westeurope',
    'queue-monitor',
    'The inventory worker is healthy, but queue depth is increasing and students should compare readiness with throughput.'
  ),
  (
    'Payments cache warmed successfully',
    'payments-api',
    'prod-sim',
    'low',
    'resolved',
    'cache-team',
    'uae-north',
    'redis-cache-demo',
    'A cache warm-up finished successfully and the result can be compared against the Redis-backed cache route.'
  ),
  (
    'Catalog import retry still pending review',
    'catalog-api',
    'training-vm',
    'medium',
    'pending-review',
    'release-manager',
    'uk-south',
    'manual-check',
    'A synthetic review item that helps students compare database-backed application data with deployment metadata.'
  )
ON CONFLICT DO NOTHING;
