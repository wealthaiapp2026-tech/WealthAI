-- ========================
-- STOCKS
-- ========================
CREATE SCHEMA IF NOT EXISTS india_market;
GRANT USAGE, CREATE ON SCHEMA india_market TO public;
ALTER DEFAULT PRIVILEGES IN SCHEMA india_market GRANT ALL ON TABLES TO public;

CREATE TABLE IF NOT EXISTS india_market.instruments (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    symbol          TEXT NOT NULL,
    name            TEXT,
    exchange        TEXT NOT NULL CHECK (exchange IN ('NSE','BSE','NFO','BFO')),
    segment         TEXT CHECK (segment IN ('EQ','FNO','CDS','MCX')),
    instrument_type TEXT NOT NULL CHECK (instrument_type IN (
                        'equity','future','option','etf','index'
                    )),
    currency        TEXT DEFAULT 'INR',

    -- Equity specific
    isin            TEXT,
    listing_date    DATE,

    -- F&O specific
    lot_size        INT DEFAULT 1,
    expiry_date     DATE,
    strike_price    NUMERIC(12,2),
    option_type     TEXT CHECK (option_type IN ('CE','PE') OR option_type IS NULL),

    is_active       BOOLEAN DEFAULT true,
    tags            TEXT[] DEFAULT '{}',
    created_at      TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE (symbol, exchange, instrument_type, expiry_date, strike_price, option_type)
);

CREATE TABLE IF NOT EXISTS india_market.instrument_metadata (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    instrument_id   UUID NOT NULL REFERENCES india_market.instruments(id),

    -- Index membership
    index_name      TEXT NOT NULL,      -- 'NIFTY50','NIFTY100','SMALLCAP50','MIDCAP150'
    weightage       NUMERIC(5,2),       -- % weight in that index

    -- Classification
    sector          TEXT,               -- 'Financial Services','IT','Pharma'
    industry        TEXT,               -- 'Banking','Software','FMCG'

    -- Membership history
    added_date      DATE,
    removed_date    DATE,
    is_active       BOOLEAN DEFAULT true,

    created_at      TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE (instrument_id, index_name)
);

CREATE TABLE IF NOT EXISTS india_market.orders (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID NOT NULL REFERENCES auth.users(id),
    broker_account_id   UUID NOT NULL REFERENCES auth.user_brokers(id),

    -- Instrument
    instrument_id       UUID NOT NULL REFERENCES india_market.instruments(id),

    -- Order details
    transaction_type    TEXT NOT NULL CHECK (transaction_type IN ('BUY','SELL')),
    order_type          TEXT NOT NULL CHECK (order_type IN ('MARKET','LIMIT','SL','SL-M')),
    product             TEXT NOT NULL CHECK (product IN ('CNC','MIS','NRML')),

    -- Quantity and price
    quantity            INT NOT NULL,
    price               NUMERIC(12,2),      -- null for MARKET orders
    avg_fill_price      NUMERIC(12,2),      -- actual execution price

    -- Source
    order_source        TEXT NOT NULL CHECK (order_source IN (
                            'manual', 'algo', 'copy_trade')),

    -- Status
    status              TEXT NOT NULL DEFAULT 'pending'
                        CHECK (status IN (
                            'pending', 'open', 'partial', 'complete', 'cancelled','rejected')),

    broker_order_id     TEXT,
    placed_at           TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS india_market.equity_holdings (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID NOT NULL REFERENCES auth.users(id),
    broker_account_id   UUID NOT NULL REFERENCES auth.user_brokers(id),
    instrument_id       UUID NOT NULL REFERENCES india_market.instruments(id),

    -- Position
    quantity            INT NOT NULL DEFAULT 0,
    avg_buy_price       NUMERIC(12,2) NOT NULL DEFAULT 0,

    -- P&L (updated by price sync job)
    current_price       NUMERIC(12,2),
    unrealised_pnl      NUMERIC(12,2),

    last_updated        TIMESTAMPTZ DEFAULT NOW(),
    created_at          TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE (user_id, broker_account_id, instrument_id)
);

CREATE TABLE IF NOT EXISTS india_market.equity_transactions (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID NOT NULL REFERENCES auth.users(id),
    broker_account_id   UUID NOT NULL REFERENCES auth.user_brokers(id),
    instrument_id       UUID NOT NULL REFERENCES india_market.instruments(id),
    order_id            UUID REFERENCES india_market.orders(id),

    -- Trade details
    transaction_type    TEXT NOT NULL CHECK (transaction_type IN ('BUY','SELL')),
    trade_type          TEXT NOT NULL CHECK (trade_type IN ('delivery','intraday')),
    quantity            INT NOT NULL,
    price               NUMERIC(12,2) NOT NULL,

    -- P&L (only on SELL)
    realised_pnl        NUMERIC(12,2),      -- null for BUY rows

    -- Charges
    brokerage           NUMERIC(10,2),
    taxes_and_charges   NUMERIC(10,2),

    traded_at           TIMESTAMPTZ NOT NULL,
    created_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS india_market.fno_positions (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID NOT NULL REFERENCES auth.users(id),
    broker_account_id   UUID NOT NULL REFERENCES auth.user_brokers(id),
    instrument_id       UUID NOT NULL REFERENCES india_market.instruments(id),

    -- Position
    transaction_type    TEXT NOT NULL CHECK (transaction_type IN ('BUY','SELL')),
    product             TEXT NOT NULL CHECK (product IN ('MIS','NRML')),
    lots                INT NOT NULL DEFAULT 0,
    quantity            INT NOT NULL DEFAULT 0,     -- lots × lot_size
    avg_price           NUMERIC(12,2) NOT NULL DEFAULT 0,

    -- P&L
    current_price       NUMERIC(12,2),
    unrealised_pnl      NUMERIC(12,2),

    -- Position state
    status              TEXT NOT NULL DEFAULT 'open'
                        CHECK (status IN (
                            'open',
                            'closed',
                            'expired'
                        )),

    opened_at           TIMESTAMPTZ DEFAULT NOW(),
    closed_at           TIMESTAMPTZ,
    created_at          TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE (user_id, broker_account_id, instrument_id, transaction_type, product)
);

CREATE TABLE IF NOT EXISTS india_market.fno_transactions (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID NOT NULL REFERENCES auth.users(id),
    broker_account_id   UUID NOT NULL REFERENCES auth.user_brokers(id),
    instrument_id       UUID NOT NULL REFERENCES india_market.instruments(id),
    order_id            UUID REFERENCES india_market.orders(id),
    position_id         UUID REFERENCES india_market.fno_positions(id),

    -- Trade details
    transaction_type    TEXT NOT NULL CHECK (transaction_type IN ('BUY','SELL')),
    product             TEXT NOT NULL CHECK (product IN ('MIS','NRML')),
    lots                INT NOT NULL,
    quantity            INT NOT NULL,
    price               NUMERIC(12,2) NOT NULL,

    -- P&L (only on exit trades)
    realised_pnl        NUMERIC(12,2),

    -- Charges
    brokerage           NUMERIC(10,2),
    taxes_and_charges   NUMERIC(10,2),

    -- Trade type
    trade_type          TEXT NOT NULL CHECK (trade_type IN (
                            'entry',        -- opening a position
                            'exit',         -- closing a position
                            'expiry'        -- settled at expiry
                        )),

    traded_at           TIMESTAMPTZ NOT NULL,
    created_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS india_market.dividends (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID NOT NULL REFERENCES auth.users(id),
    broker_account_id   UUID NOT NULL REFERENCES auth.user_brokers(id),
    instrument_id       UUID NOT NULL REFERENCES india_market.instruments(id),

    dividend_per_share  NUMERIC(10,2) NOT NULL,
    quantity            INT NOT NULL,           -- shares held on record date
    total_amount        NUMERIC(12,2) NOT NULL, -- dividend_per_share × quantity

    ex_date             DATE NOT NULL,          -- stock goes ex-dividend on this date
    payment_date        DATE,                   -- when money credited to account

    created_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS india_market.corporate_actions (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    instrument_id       UUID NOT NULL REFERENCES india_market.instruments(id),

    action_type         TEXT NOT NULL CHECK (action_type IN (
                            'split',
                            'bonus',
                            'rights',
                            'merger',
                            'demerger',
                            'buyback'
                        )),

    ex_date             DATE NOT NULL,          -- effective date
    record_date         DATE,
    ratio               TEXT,                   -- e.g. 1:2 for split, 1:1 for bonus
    notes               TEXT,

    created_at          TIMESTAMPTZ DEFAULT NOW()
);

-- ========================
-- Market Data Tables
-- ========================

CREATE TABLE IF NOT EXISTS india_market.historical_ohlcv (
    id              BIGSERIAL PRIMARY KEY,
    instrument_id   UUID NOT NULL REFERENCES india_market.instruments(id),

    timeframe       TEXT NOT NULL,          -- '1m','5m','15m','1h','1d','1w'
    timestamp       TIMESTAMPTZ NOT NULL,

    open            NUMERIC(15,4),
    high            NUMERIC(15,4),
    low             NUMERIC(15,4),
    close           NUMERIC(15,4),
    volume          BIGINT,
    oi              BIGINT,                 -- open interest for F&O

    UNIQUE (instrument_id, timeframe, timestamp)
);

CREATE TABLE IF NOT EXISTS india_market.fii_dii_cashflow (
    trade_date      DATE PRIMARY KEY,

    fii_buy         NUMERIC,
    fii_sell        NUMERIC,
    fii_net         NUMERIC,

    dii_buy         NUMERIC,
    dii_sell        NUMERIC,
    dii_net         NUMERIC,

    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS india_market.fii_derivatives (
    trade_date          DATE NOT NULL,
    instrument_type     TEXT NOT NULL CHECK (instrument_type IN (
                            'index_futures',
                            'index_options',
                            'stock_futures',
                            'stock_options'
                        )),

    long_contracts      BIGINT,
    short_contracts     BIGINT,
    long_value          NUMERIC,
    short_value         NUMERIC,
    oi_long_contracts   BIGINT,
    oi_short_contracts  BIGINT,

    created_at          TIMESTAMPTZ DEFAULT NOW(),

    PRIMARY KEY (trade_date, instrument_type)
);

CREATE TABLE IF NOT EXISTS india_market.mmi (
    id          BIGSERIAL PRIMARY KEY,
    mmi_score   NUMERIC(5,2) NOT NULL,
    mmi_mood    TEXT NOT NULL CHECK (mmi_mood IN (
                    'Extreme Greed',
                    'Greed',
                    'Neutral',
                    'Fear',
                    'Extreme Fear'
                )),
    fetched_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS india_market.options_data (
    instrument_id       UUID NOT NULL REFERENCES india_market.instruments(id),
    trade_date          DATE NOT NULL,
    expiry_date         DATE NOT NULL,
    strike_price        NUMERIC NOT NULL,
    option_type         TEXT NOT NULL CHECK (option_type IN ('CE','PE')),

    oi                  BIGINT,
    change_in_oi        BIGINT,
    volume              BIGINT,
    implied_volatility  NUMERIC,
    ltp                 NUMERIC,

    created_at          TIMESTAMPTZ DEFAULT NOW(),

    PRIMARY KEY (instrument_id, trade_date, expiry_date, strike_price, option_type)
);

CREATE TABLE IF NOT EXISTS india_market.market_volatility_index (
    index_name  TEXT NOT NULL,          -- 'INDIA_VIX', 'CBOE_VIX'
    trade_date  DATE NOT NULL,

    open        NUMERIC,
    high        NUMERIC,
    low         NUMERIC,
    close       NUMERIC,

    created_at  TIMESTAMPTZ DEFAULT NOW(),

    PRIMARY KEY (index_name, trade_date)
);