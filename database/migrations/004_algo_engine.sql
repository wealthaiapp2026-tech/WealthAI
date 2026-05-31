-- ============================================================
-- 🔧 STRATEGY ENGINE: MASTER DATABASE SCHEMA
-- ============================================================
CREATE SCHEMA algo;
GRANT USAGE, CREATE ON SCHEMA algo TO public;
ALTER DEFAULT PRIVILEGES IN SCHEMA algo GRANT ALL ON TABLES TO public;

CREATE TABLE IF NOT EXISTS algo.brokers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,

    broker_id TEXT NOT NULL,
    broker_name TEXT NOT NULL,
    api_key TEXT,
    api_secret TEXT,
    access_token TEXT,
    token_expiry TIMESTAMPTZ,

    ucc_id TEXT,
    ucc_password TEXT,

    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(user_id, broker_id)
);

CREATE TABLE IF NOT EXISTS algo.strategies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,

    strategy_name TEXT NOT NULL,
    strategy_desc TEXT,
    capital NUMERIC DEFAULT 0.0,

    entry_days JSONB,
    time_window JSONB,

    max_daily_entries INT,
    reentry_cooldown_minutes INT,
    
    entry_conditions JSONB,
    exit_conditions JSONB,
    risk_conditions JSONB,
    adjustments JSONB,
    
    version INT DEFAULT 1,                 -- strategy version number for safe editing
    enabled BOOLEAN DEFAULT true,          -- master on/off switch for the strategy 
    is_public BOOLEAN DEFAULT false,
    is_deleted BOOLEAN DEFAULT false,      -- soft delete

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS algo.strategy_sets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    strategy_id UUID REFERENCES algo.strategies(id) ON DELETE CASCADE,

    set_order INT,
    name TEXT,
    segment TEXT,
    type TEXT,

    instrument JSONB,

    exchange TEXT,
    product TEXT,

    entry_days JSONB,
    time_window JSONB,
    
    entry_conditions JSONB,
    exit_conditions JSONB,
    risk_conditions JSONB,
    adjustments JSONB,

    trigger_condition	JSONB,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS algo.strategy_positions (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    set_id           UUID NOT NULL REFERENCES algo.strategy_sets(id) ON DELETE CASCADE,

    -- Identity
    name             TEXT,
    position_order   INT DEFAULT 0,          -- execution sequence within the set
    enabled          BOOLEAN DEFAULT true,   -- disable one leg without deleting
    is_hedge         BOOLEAN DEFAULT false,  -- flag hedge legs for margin/risk display

    -- Instrument
    position_type    TEXT CHECK (position_type IN ('option','future','equity','basket')),
    transaction_type TEXT NOT NULL CHECK (transaction_type IN ('BUY','SELL')),
    segment          TEXT,                   -- equity / fno / crypto / commodity
    instrument       TEXT,                   -- base symbol: NIFTY, BANKNIFTY, RELIANCE
    exchange         TEXT CHECK (exchange IN ('NSE','BSE','NFO','BFO','MCX','CDS')),

    -- Quantity
    lots             INT,                    -- user input: number of lots
    quantity         INT,                    -- computed: lots × lot_size (engine fills this at runtime)

    -- Options-specific (nullable for equity/futures)
    option_type      TEXT CHECK (option_type IN ('CE','PE') OR option_type IS NULL),
    expiry           TEXT CHECK (expiry IN ('weekly','monthly','next_weekly','next_monthly') OR expiry IS NULL),
    strike_selection JSONB,                  -- {"type":"OTM","offset":2} or {"type":"ATM"}

    -- Order execution
    order_type       TEXT DEFAULT 'MARKET' CHECK (order_type IN ('MARKET','LIMIT','SL','SL-M')),
    product          TEXT CHECK (product IN ('MIS','NRML','CNC')),
    validity         TEXT DEFAULT 'DAY' CHECK (validity IN ('DAY','IOC','TTL')),
    price            NUMERIC,               -- for LIMIT orders. null when MARKET.
    trigger_price    NUMERIC,               

    -- Time
    time_window      JSONB,                 -- position-level override: {"start":"09:30","end":"10:00"}

    -- Conditions (position-level — override set-level when present)
    entry_conditions JSONB,                 -- when to enter this leg
    exit_conditions  JSONB,                 -- when to exit this leg
    risk_conditions  JSONB,                 -- {"sl":50,"target":120,"sl_type":"fixed"}
    adjustments      JSONB,                 -- roll / partial exit / reentry rules

    created_at       TIMESTAMPTZ DEFAULT NOW(),
    updated_at       TIMESTAMPTZ DEFAULT NOW()
);

DROP TABLE IF EXISTS algo.deployments CASCADE;
CREATE TABLE algo.deployments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    strategy_id UUID REFERENCES algo.strategies(id) ON DELETE CASCADE,
    broker_id UUID REFERENCES algo.brokers(id) ON DELETE CASCADE,
    
    deployment_mode TEXT CHECK (deployment_mode IN ('live', 'paper', 'backtest')),

    multiplier INT DEFAULT 1,  
    status TEXT CHECK (status IN ('draft','active','paused','stopped')),           -- TEXT CHECK(draft/active/paused/stopped)

    capital_allocated NUMERIC(14,2),
    custom_target NUMERIC,
    custom_sl NUMERIC,
    total_pnl NUMERIC(14,2) DEFAULT 0,

    is_deleted BOOLEAN DEFAULT false,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

DROP TABLE IF EXISTS algo.deployment_runs CASCADE;
CREATE TABLE algo.deployment_runs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    deployment_id UUID REFERENCES algo.deployments(id) ON DELETE CASCADE,

    run_date DATE NOT NULL,

    trigger_type TEXT,              -- scheduled / manual
    status TEXT,                   -- e.g., "COMPLETED", "FAILED", "PARTIAL"
    
    start_time TIMESTAMPTZ,
    end_time TIMESTAMPTZ,

    stop_reason TEXT,           -- target_hit/sl_hit/market_close/manual/error 

    pnl NUMERIC(15,2),
    pnl_pct NUMERIC(12,2),
	capital NUMERIC(15,2),

    multiplier INT,
    
    logs JSONB,                      -- Optional log dump for the day
    metadata JSONB,                  -- Other runtime stats (latency, orders placed, etc.)
    strategy_snapshot JSONB,

    created_at TIMESTAMPTZ DEFAULT NOW(),

    tags TEXT[] DEFAULT '{}'
);

CREATE TABLE algo.trade_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    run_id UUID REFERENCES algo.deployment_runs(id) ON DELETE CASCADE,

    log_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    log_level VARCHAR(10) NULL,   -- e.g., INFO, WARN, ERROR
    log_message TEXT NOT NULL,
    
    log_context JSONB NULL,                -- optional, to store extra context data like order_id, symbol, etc.
    event_type TEXT,

    tags TEXT[] DEFAULT '{}'
);

DROP TABLE IF EXISTS algo.trade_orderbook CASCADE;
CREATE TABLE algo.trade_orderbook (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    run_id UUID REFERENCES algo.deployment_runs(id) ON DELETE CASCADE,
   
    instrument TEXT NOT NULL,
    product TEXT NULL,
    side TEXT NULL,
    
    quantity NUMERIC(12,2) NOT NULL DEFAULT 0,
    avg_price NUMERIC(12,2) NOT NULL DEFAULT 0,
    status TEXT NULL,
    order_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    order_type TEXT NULL,
    validity TEXT NULL,

    order_id TEXT NULL,   ---- we will obselete it  / not sure which order id it stores

    broker_order_id TEXT,
    exchange_order_id TEXT,
    rejection_reason TEXT,
    filled_quantity NUMERIC,
    pending_quantity NUMERIC,

    tags TEXT[] DEFAULT '{}'
);

DROP TABLE IF EXISTS algo.trade_positions CASCADE;
CREATE TABLE algo.trade_positions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    run_id UUID REFERENCES algo.deployment_runs(id) ON DELETE CASCADE,

    instrument TEXT NOT NULL,
    product TEXT NULL,
    status TEXT,
    quantity NUMERIC(12,2) NOT NULL DEFAULT 0,
    
    entry_time TIMESTAMPTZ,
    entry_price NUMERIC(12,2),
    entry_order_id TEXT,
   
    exit_time TIMESTAMPTZ,
    exit_price NUMERIC(12,2),
    exit_order_id TEXT,

    pnl NUMERIC(15,2) DEFAULT 0,
    pnl_pct NUMERIC(12,2) DEFAULT 0,

    tags TEXT[] DEFAULT '{}'
);

CREATE TABLE algo.strategy_subscriptions (
    id  UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    user_id  UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    strategy_id UUID NOT NULL REFERENCES algo.strategies(id) ON DELETE CASCADE,

    -- subscription state
    status          TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','paused','cancelled')),

    -- subscription type (for marketplace monetisation)
    subscription_type  TEXT DEFAULT 'free' CHECK (subscription_type IN ('free','paid')),
    subscribed_at   TIMESTAMPTZ DEFAULT NOW(),
    expires_at      TIMESTAMPTZ,               -- null = no expiry (free tier)

    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW(),

    -- one active subscription per user per strategy
    UNIQUE (user_id, strategy_id)
);