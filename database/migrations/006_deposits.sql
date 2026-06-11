-- ============================================================
-- Covers: FD, RD, PPF, EPF, SSY, NPS, NSC, SCSS, KVP
-- ============================================================
CREATE SCHEMA IF NOT EXISTS deposits;
GRANT USAGE, CREATE ON SCHEMA deposits TO public;
ALTER DEFAULT PRIVILEGES IN SCHEMA deposits GRANT ALL ON TABLES TO public;

-- ============================================================
-- TABLE 1: deposits.account_holdings
-- One row per deposit account a user holds.
-- Tracks current value, maturity, interest rate etc.
-- ============================================================
CREATE TABLE IF NOT EXISTS deposits.account_holdings (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID NOT NULL REFERENCES auth.users(id),

    -- Account type
    account_type        TEXT NOT NULL CHECK (account_type IN (
                            'FD',       -- Fixed Deposit
                            'RD',       -- Recurring Deposit
                            'PPF',      -- Public Provident Fund
                            'EPF',      -- Employee Provident Fund
                            'SSY',      -- Sukanya Samriddhi Yojana
                            'NPS',      -- National Pension Scheme
                            'NSC',      -- National Savings Certificate
                            'SCSS',     -- Senior Citizens Savings Scheme
                            'KVP'       -- Kisan Vikas Patra
                        )),

    -- Account identity
    account_number      TEXT,               -- account / folio number
    account_name        TEXT,               -- e.g. "My SBI FD", "PPF - SBI"
    institution_name    TEXT,               -- SBI, HDFC, Post Office, EPFO
    institution_branch  TEXT,               -- branch name or code

    -- Financial details
    principal_amount    NUMERIC(15,2) NOT NULL DEFAULT 0,   -- original invested amount
    current_value       NUMERIC(15,2) DEFAULT 0,            -- current value including interest
    interest_rate       NUMERIC(8,4),                       -- annual interest rate %
    interest_type       TEXT CHECK (interest_type IN (
                            'simple',
                            'compound',
                            'cumulative',
                            'non_cumulative'
                        )),
    compounding_freq    TEXT CHECK (compounding_freq IN (
                            'monthly',
                            'quarterly',
                            'half_yearly',
                            'yearly',
                            'at_maturity'
                        )),

    -- For RD specifically
    monthly_instalment  NUMERIC(12,2),      -- fixed monthly contribution amount

    -- Tenure and maturity
    start_date          DATE NOT NULL,
    maturity_date       DATE,               -- null for PPF/EPF (open-ended)
    tenure_months       INT,                -- total tenure in months

    -- Maturity config (for FD/RD)
    maturity_amount     NUMERIC(15,2),      -- expected maturity value
    maturity_action     TEXT CHECK (maturity_action IN (
                            'auto_renew',
                            'credit_to_account',
                            'withdraw'
                        )),

    -- Nomination
    nominee_name        TEXT,

    -- Status
    status              TEXT NOT NULL DEFAULT 'active'
                        CHECK (status IN (
                            'active',
                            'matured',
                            'closed',
                            'premature_closed'
                        )),

    -- For NPS specifically
    nps_tier            TEXT CHECK (nps_tier IN ('tier1','tier2') OR nps_tier IS NULL),
    nps_scheme          TEXT,               -- scheme name: aggressive, moderate, conservative

    -- Soft delete and audit
    is_deleted          BOOLEAN DEFAULT false,
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    updated_at          TIMESTAMPTZ DEFAULT NOW()
);


-- ============================================================
-- TABLE 2: deposits.account_transactions
-- Every financial event against a deposit account.
-- Deposits, withdrawals, interest credits, partial withdrawals.
-- ============================================================
CREATE TABLE IF NOT EXISTS deposits.account_transactions (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    holding_id          UUID NOT NULL REFERENCES deposits.account_holdings(id) ON DELETE CASCADE,
    user_id             UUID NOT NULL REFERENCES auth.users(id),

    -- Transaction classification
    transaction_type    TEXT NOT NULL CHECK (transaction_type IN (
                            'deposit',              -- new money added
                            'withdrawal',           -- full or partial withdrawal
                            'partial_withdrawal',   -- PPF allows partial after 7 years
                            'interest_credit',      -- interest added to account
                            'maturity_credit',      -- final payout on maturity
                            'penalty',              -- premature closure penalty
                            'transfer_in',          -- EPF transfer from previous employer
                            'transfer_out'          -- EPF transfer to new employer
                        )),

    -- Amount
    amount              NUMERIC(15,2) NOT NULL,
    closing_balance     NUMERIC(15,2),          -- account balance after this transaction

    -- Dates
    transaction_date    DATE NOT NULL,
    value_date          DATE,                   -- date interest or amount is effective

    -- Reference
    reference_number    TEXT,                   -- bank reference / cheque number
    remarks             TEXT,                   -- e.g. "Monthly RD instalment - Jan 2024"

    -- For interest transactions
    interest_rate       NUMERIC(8,4),           -- rate applicable for this credit
    interest_period     TEXT,                   -- e.g. "Q3 2024", "FY 2023-24"

    -- For EPF specifically
    employer_contribution   NUMERIC(12,2),      -- employer share for that month
    employee_contribution   NUMERIC(12,2),      -- employee share for that month
    eps_contribution        NUMERIC(12,2),      -- EPS portion of employer contribution

    -- Audit
    created_at          TIMESTAMP DEFAULT NOW()
);


CREATE TABLE IF NOT EXISTS deposits.account_metadata (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Which scheme this rate belongs to
    account_type    TEXT NOT NULL CHECK (account_type IN (
                        'FD', 'RD', 'PPF', 'EPF', 'SSY',
                        'NPS', 'NSC', 'SCSS', 'KVP'
                    )),

    -- Rate details
    interest_rate   NUMERIC(8,4) NOT NULL,      -- e.g. 7.10
    effective_from  DATE NOT NULL,              -- when this rate became applicable
    effective_to    DATE,                       -- null = still active

    -- Period reference
    period          TEXT,                       -- e.g. "Q1 FY2025", "FY 2024-25"

    -- Active flag — only one active rate per scheme at a time
    is_active       BOOLEAN DEFAULT false,

    -- Source for credibility
    announced_by    TEXT,                       -- "Ministry of Finance", "EPFO"
    source_url      TEXT,                       -- official notification link

    -- Audit
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);
