-- ========================
-- BONDS
-- ========================
CREATE SCHEMA IF NOT EXISTS bond;
GRANT USAGE, CREATE ON SCHEMA bond TO public;
ALTER DEFAULT PRIVILEGES IN SCHEMA bond GRANT ALL ON TABLES TO public;

CREATE TABLE bond.bond_master (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    isin TEXT UNIQUE,
    
    bond_name TEXT NOT NULL,
    issuer_name TEXT,

    bond_type TEXT CHECK (
        bond_type IN (
            'government',
            'corporate',
            'tax_free',
            'sdl',
            'gsec',
            't_bill'
        )
    ),

    coupon_rate NUMERIC(8,4),

    face_value NUMERIC(15,2),

    interest_frequency TEXT CHECK (
        interest_frequency IN (
            'monthly',
            'quarterly',
            'semi_annual',
            'annual',
            'cumulative'
        )
    ),

    issue_date DATE,
    maturity_date DATE,

    credit_rating TEXT,

    is_listed BOOLEAN DEFAULT true,

    created_at TIMESTAMPTZ DEFAULT now(),

    tags TEXT[] DEFAULT '{}'
);

DROP TABLE IF EXISTS bond.bond_holdings CASCADE;
CREATE TABLE bond.bond_holdings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    bond_id UUID NOT NULL REFERENCES bond.bond_master(id),

    platform TEXT,
    demat_account TEXT,
    quantity NUMERIC(20,4) DEFAULT 0,
    avg_purchase_price NUMERIC(15,2),
    invested_amount NUMERIC(15,2),

    purchase_date DATE,

    maturity_amount NUMERIC(15,2),

    status TEXT CHECK (status IN ('active','matured','sold')) DEFAULT 'active',

    is_deleted BOOLEAN DEFAULT false,

    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),

    remarks TEXT,
    tags TEXT[] DEFAULT '{}'
);

CREATE TABLE bond.bond_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    holding_id UUID NOT NULL REFERENCES bond.bond_holdings(id) ON DELETE CASCADE,
    txn_type TEXT CHECK (txn_type IN ('buy', 'sell', 'interest_credit', 'maturity')),
    txn_date TIMESTAMPTZ NOT NULL,
    quantity NUMERIC(20,4),
    price NUMERIC(15,2),
    total_amount NUMERIC(15,2),
    accrued_interest NUMERIC(15,2) DEFAULT 0,
    remarks TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    tags TEXT[] DEFAULT '{}'
);