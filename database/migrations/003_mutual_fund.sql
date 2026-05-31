-- ==============================================
----------- MUTUAL FUNDS EXPLORE ----------------
-- ==============================================
CREATE SCHEMA IF NOT EXISTS mutual_fund;
GRANT USAGE, CREATE ON SCHEMA mutual_fund TO public;
ALTER DEFAULT PRIVILEGES IN SCHEMA mutual_fund GRANT ALL ON TABLES TO public;


-- 1. Benchmark table
CREATE TABLE mutual_fund.mf_benchmarks (
    benchmark_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT UNIQUE NOT NULL,      -- e.g., "NIFTY 50 TRI"
    symbol TEXT UNIQUE NOT NULL,    -- e.g., "^NSEI" or "NIFTY50"
    provider TEXT,                  -- e.g., "NSE", "BSE", "S&P"
    tags TEXT[] DEFAULT '{}'
);

-- 2. Mutual Fund Schemes Master
CREATE TABLE mutual_fund.mf_schemes (
    scheme_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    scheme_code TEXT UNIQUE NOT NULL,      -- AMFI Code
    isin TEXT UNIQUE NOT NULL,             -- Essential for CAS imports
    scheme_name TEXT NOT NULL,
    fund_house TEXT NOT NULL,
    category TEXT,                         -- e.g., 'Equity', 'Debt'
    sub_category TEXT,                     -- e.g., 'Small Cap', 'Liquid'
    
    plan_type TEXT CHECK (plan_type IN ('Direct', 'Regular')),
    dividend_type TEXT CHECK (dividend_type IN ('Growth', 'IDCW-Payout', 'IDCW-Reinvestment')),
    fund_type TEXT CHECK (fund_type IN ('Open-Ended', 'ETF', 'FOF')),
    
    benchmark_id UUID REFERENCES mutual_fund.mf_benchmarks(benchmark_id),   -- e.g., 'NIFTY 50 TRI'
    face_value NUMERIC(10, 2) DEFAULT 10,  -- Usually 10 for most funds
    
    launch_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    last_updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    tags TEXT[] DEFAULT '{}'
);

-- 3. mf_nav_history: Depends on mf_schemes
CREATE TABLE mutual_fund.mf_nav_history (
    scheme_id UUID NOT NULL REFERENCES mutual_fund.mf_schemes(scheme_id) ON DELETE CASCADE,
    
    nav_date DATE NOT NULL,
    nav_value NUMERIC(15, 4) NOT NULL,
    nav_source TEXT,            -- AMFI , MFCentral, other feed
    
    -- Optional but highly recommended for performance
    day_change_percent NUMERIC(5, 2), 
    tags TEXT[] DEFAULT '{}',

    -- Ensuring we only have one NAV entry per fund per day
    PRIMARY KEY (scheme_id, nav_date)
);

-- 4. Mutual Fund Metadata
CREATE TABLE mutual_fund.mf_scheme_metadata (
    -- Matches the UUID from your mf_schemes table
    scheme_id UUID PRIMARY KEY REFERENCES mutual_fund.mf_schemes(scheme_id) ON DELETE CASCADE,

    -- Fund Management & Strategy
    fund_manager_name TEXT, 
    investment_objective TEXT,    -- For the "About this Fund" section in UI
    min_lumpsum_amount NUMERIC(15, 2),
    min_sip_amount NUMERIC(15, 2),
    exit_load_description TEXT,   -- e.g., "1% for redemption within 365 days"

    -- Key Stats (The "Highlights" bar in your UI)
    aum_in_crores NUMERIC(20, 2), -- Assets Under Management
    expense_ratio NUMERIC(5, 2),  -- Expressed as a percentage (e.g., 0.75)
    last_reported_aum_date DATE,

    -- Risk Metrics & Ratios
    sharpe_ratio NUMERIC(6, 2),
    standard_deviation NUMERIC(6, 2),
    beta NUMERIC(6, 2),
    alpha NUMERIC(6, 2),
    sortino_ratio NUMERIC(6, 2),
    STT NUMERIC(6, 2),

    -- Ratings & Popularity
    star_rating INT CHECK (star_rating BETWEEN 0 AND 5),
    is_top_rated BOOLEAN DEFAULT FALSE,

    -- System Metadata
    last_updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    tags TEXT[] DEFAULT '{}'
);

-- 5. Dividend Payouts (Optional Table)
CREATE TABLE mutual_fund.mf_dividends (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    -- Consistent with UUID scheme_id
    scheme_id UUID NOT NULL REFERENCES mutual_fund.mf_schemes(scheme_id) ON DELETE CASCADE,
    
    declaration_date DATE NOT NULL,
    record_date DATE, -- Date you must own the units to get the dividend
    payout_date DATE,
    
    -- In India, dividends are usually expressed in Rupees per unit or % of Face Value
    dividend_per_unit NUMERIC(12, 4) NOT NULL,
    
    -- Categorization for tax logic
    is_tax_free BOOLEAN DEFAULT FALSE, 
    tags TEXT[] DEFAULT '{}',

    UNIQUE(scheme_id, record_date) -- Prevents duplicate entries for the same dividend cycle
);

-- 6. Mutual Fund Systematic plans
CREATE TABLE mutual_fund.mf_systematic_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    user_id UUID NOT NULL REFERENCES auth.users(id),
    scheme_id UUID NOT NULL REFERENCES mutual_fund.mf_schemes(scheme_id),

    plan_type TEXT CHECK (plan_type IN ('SIP', 'STP', 'SWP')),

    amount NUMERIC(15,2) NOT NULL,
    frequency TEXT CHECK (frequency IN ('daily','weekly','monthly','quarterly')),

    sip_date INT CHECK (sip_date BETWEEN 1 AND 31),
    start_date DATE,
    end_date DATE,

    status TEXT CHECK (status IN ('active','paused','cancelled','completed')),

    mandate_id TEXT,

    created_at TIMESTAMPTZ DEFAULT now()
);


-- =============================================
------------- MUTUAL FUNDS CRUD ----------------
-- =============================================
CREATE TABLE mutual_fund.mf_holdings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,

    scheme_id UUID NOT NULL REFERENCES mutual_fund.mf_schemes(scheme_id),

    folio_number TEXT, 
    units NUMERIC(20,4) DEFAULT 0, -- Higher precision for fractional units
    avg_nav NUMERIC(15,4) DEFAULT 0, -- Cost price per unit
    invested_amount NUMERIC(15,2) DEFAULT 0, -- (units * avg_nav)
    
    -- Metadata
    is_active BOOLEAN DEFAULT TRUE, -- Useful if a user sells everything but you want to keep the history
    last_updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    tags TEXT[] DEFAULT '{}',
    
    -- Prevent duplicate holdings for the same scheme/folio per user
    UNIQUE(user_id, scheme_id, folio_number)
);

DROP TABLE IF EXISTS mutual_fund.mf_transactions CASCADE;
CREATE TABLE mutual_fund.mf_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    holding_id UUID NOT NULL REFERENCES mutual_fund.mf_holdings(id) ON DELETE CASCADE,
    scheme_id UUID NOT NULL REFERENCES mutual_fund.mf_schemes(scheme_id),

    -- Transaction Metadata
    folio_no TEXT, -- Redundant but good for double-checking against statements
    txn_type TEXT CHECK (txn_type IN ('buy', 'sell', 'dividend_reinvest', 'switch_in', 'switch_out')),
    status TEXT DEFAULT 'completed' CHECK (status IN ('pending', 'completed', 'failed', 'reversed')),

    -- Financial Data (High precision)
    units NUMERIC(20,4) NOT NULL, -- Units can be very small (e.g., 0.0001)
    nav NUMERIC(15,4) NOT NULL,
    amount NUMERIC(20,2) NOT NULL, -- The actual cash value (units * nav)
    
    -- Tax & Charges (Critical for Fintech)
    stamp_duty NUMERIC(12,2) DEFAULT 0,
    stt_charges NUMERIC(12,2) DEFAULT 0, -- Securities Transaction Tax
    exit_load NUMERIC(12,2) DEFAULT 0,   -- Calculated during 'sell'

    -- Timestamps
    transaction_date TIMESTAMP WITH TIME ZONE NOT NULL, -- The date the AMC processed it
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, -- When it hit your DB

    remarks TEXT,
    tags TEXT[] DEFAULT '{}'
);


----- Implement Later - Weighted Average Logic
----- CREATE OR REPLACE FUNCTION mutual_fund.fn_update_mf_holding()
----- CREATE TRIGGER trg_after_mf_transaction
--AFTER INSERT ON mutual_fund.mf_transactions
--FOR EACH ROW
--EXECUTE FUNCTION mutual_fund.fn_update_mf_holding();