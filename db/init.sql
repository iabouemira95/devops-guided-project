CREATE TABLE IF NOT EXISTS items (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  book_title TEXT NOT NULL,
  member_name TEXT NOT NULL,
  membership_tier TEXT NOT NULL,
  item_format TEXT NOT NULL,
  shelf_code TEXT NOT NULL,
  due_date DATE NOT NULL,
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

ALTER TABLE items ADD COLUMN IF NOT EXISTS book_title TEXT;
ALTER TABLE items ADD COLUMN IF NOT EXISTS member_name TEXT;
ALTER TABLE items ADD COLUMN IF NOT EXISTS membership_tier TEXT;
ALTER TABLE items ADD COLUMN IF NOT EXISTS item_format TEXT;
ALTER TABLE items ADD COLUMN IF NOT EXISTS shelf_code TEXT;
ALTER TABLE items ADD COLUMN IF NOT EXISTS due_date DATE;

UPDATE items
SET
  book_title = COALESCE(book_title, name),
  member_name = COALESCE(member_name, owner_name, 'Unknown Member'),
  membership_tier = COALESCE(membership_tier, 'standard'),
  item_format = COALESCE(item_format, 'book'),
  shelf_code = COALESCE(shelf_code, 'LEGACY-01'),
  due_date = COALESCE(due_date, CURRENT_DATE + INTERVAL '7 days');

INSERT INTO items (
  name,
  book_title,
  member_name,
  membership_tier,
  item_format,
  shelf_code,
  due_date,
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
    'The Pragmatic Programmer loan needs desk review',
    'The Pragmatic Programmer',
    'Nora Hassan',
    'research',
    'book',
    'A-14',
    CURRENT_DATE + INTERVAL '7 days',
    'circulation-desk',
    'training-vm',
    'high',
    'pending-review',
    'desk-lead',
    'central-branch',
    'self-checkout-kiosk',
    'A self-checkout loan needs review because the borrower changed branches during pickup.'
  ),
  (
    'Clean Code hold pickup is waiting',
    'Clean Code',
    'Mariam Samir',
    'standard',
    'book',
    'B-07',
    CURRENT_DATE + INTERVAL '4 days',
    'holds-queue',
    'staging-sim',
    'medium',
    'ready-for-pickup',
    'branch-librarian',
    'west-end-branch',
    'manual-desk',
    'The hold is staged for pickup and helps students compare PostgreSQL-backed state with readiness and logs.'
  ),
  (
    'Designing Data-Intensive Applications popularity cache refreshed',
    'Designing Data-Intensive Applications',
    'Omar Fares',
    'premium',
    'ebook',
    'DIGITAL-22',
    CURRENT_DATE + INTERVAL '10 days',
    'catalog-search',
    'prod-sim',
    'low',
    'resolved',
    'digital-services',
    'north-branch',
    'catalog-sync',
    'A catalog cache refresh completed successfully and can be compared against the Redis-backed popularity route.'
  ),
  (
    'Refactoring return bin intake still pending review',
    'Refactoring',
    'Salma Adel',
    'community',
    'book',
    'C-03',
    CURRENT_DATE + INTERVAL '2 days',
    'member-notify',
    'training-vm',
    'medium',
    'pending-review',
    'shift-supervisor',
    'east-branch',
    'returns-bin',
    'A borrower return is waiting for confirmation and helps students compare application state with deployment metadata.'
  )
ON CONFLICT DO NOTHING;
