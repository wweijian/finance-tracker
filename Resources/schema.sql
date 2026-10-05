PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS transactions (
  id TEXT PRIMARY KEY,
  transaction_date TEXT NOT NULL,
  transaction_time TEXT,
  transaction_year INTEGER NOT NULL,
  transaction_type TEXT NOT NULL CHECK (transaction_type IN ('income', 'expense')),
  amount_cents INTEGER NOT NULL CHECK (amount_cents >= 0),
  currency TEXT NOT NULL DEFAULT 'SGD',
  description TEXT NOT NULL,
  category TEXT NOT NULL COLLATE NOCASE,
  notes TEXT,
  date_created TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  deleted_at TEXT,
  CHECK (transaction_year = CAST(substr(transaction_date, 1, 4) AS INTEGER))
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_transactions_exact_duplicate
ON transactions (transaction_date, IFNULL(transaction_time, ''), amount_cents, description COLLATE BINARY);

CREATE INDEX IF NOT EXISTS idx_transactions_active_year_date
ON transactions (transaction_year, transaction_date) WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_transactions_active_category
ON transactions (category, transaction_date) WHERE deleted_at IS NULL;
