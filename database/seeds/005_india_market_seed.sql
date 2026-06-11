-- 005_india_market_seed.sql — Seed data for india_market schema. Run after 005_india_market.sql migration.

DO $$
DECLARE
    v_user_id UUID := '11111111-1111-1111-1111-111111111111';
    v_broker_id UUID := 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
    v_infy_id UUID;
    v_hdfc_id UUID;
    v_rel_id UUID;
    v_tcs_id UUID;
    v_ap_id UUID;
    v_bf_id UUID;
    v_sun_id UUID;
    v_mar_id UUID;
    v_hold UUID;
BEGIN
    -- INFY
    SELECT id INTO v_infy_id FROM india_market.instruments WHERE symbol = 'INFY' AND exchange = 'NSE' AND instrument_type = 'equity';
    IF v_infy_id IS NULL THEN
        INSERT INTO india_market.instruments (symbol, name, exchange, instrument_type, segment)
        VALUES ('INFY', 'Infosys Ltd', 'NSE', 'equity', 'EQ') RETURNING id INTO v_infy_id;
    END IF;

    -- HDFCBANK
    SELECT id INTO v_hdfc_id FROM india_market.instruments WHERE symbol = 'HDFCBANK' AND exchange = 'NSE' AND instrument_type = 'equity';
    IF v_hdfc_id IS NULL THEN
        INSERT INTO india_market.instruments (symbol, name, exchange, instrument_type, segment)
        VALUES ('HDFCBANK', 'HDFC Bank Ltd', 'NSE', 'equity', 'EQ') RETURNING id INTO v_hdfc_id;
    END IF;

    -- RELIANCE
    SELECT id INTO v_rel_id FROM india_market.instruments WHERE symbol = 'RELIANCE' AND exchange = 'NSE' AND instrument_type = 'equity';
    IF v_rel_id IS NULL THEN
        INSERT INTO india_market.instruments (symbol, name, exchange, instrument_type, segment)
        VALUES ('RELIANCE', 'Reliance Industries Ltd', 'NSE', 'equity', 'EQ') RETURNING id INTO v_rel_id;
    END IF;

    -- TCS
    SELECT id INTO v_tcs_id FROM india_market.instruments WHERE symbol = 'TCS' AND exchange = 'NSE' AND instrument_type = 'equity';
    IF v_tcs_id IS NULL THEN
        INSERT INTO india_market.instruments (symbol, name, exchange, instrument_type, segment)
        VALUES ('TCS', 'Tata Consultancy Services Ltd', 'NSE', 'equity', 'EQ') RETURNING id INTO v_tcs_id;
    END IF;

    -- ASIANPAINT
    SELECT id INTO v_ap_id FROM india_market.instruments WHERE symbol = 'ASIANPAINT' AND exchange = 'NSE' AND instrument_type = 'equity';
    IF v_ap_id IS NULL THEN
        INSERT INTO india_market.instruments (symbol, name, exchange, instrument_type, segment)
        VALUES ('ASIANPAINT', 'Asian Paints Ltd', 'NSE', 'equity', 'EQ') RETURNING id INTO v_ap_id;
    END IF;

    -- BAJFINANCE
    SELECT id INTO v_bf_id FROM india_market.instruments WHERE symbol = 'BAJFINANCE' AND exchange = 'NSE' AND instrument_type = 'equity';
    IF v_bf_id IS NULL THEN
        INSERT INTO india_market.instruments (symbol, name, exchange, instrument_type, segment)
        VALUES ('BAJFINANCE', 'Bajaj Finance Ltd', 'NSE', 'equity', 'EQ') RETURNING id INTO v_bf_id;
    END IF;

    -- SUNPHARMA
    SELECT id INTO v_sun_id FROM india_market.instruments WHERE symbol = 'SUNPHARMA' AND exchange = 'NSE' AND instrument_type = 'equity';
    IF v_sun_id IS NULL THEN
        INSERT INTO india_market.instruments (symbol, name, exchange, instrument_type, segment)
        VALUES ('SUNPHARMA', 'Sun Pharmaceutical Industries Ltd', 'NSE', 'equity', 'EQ') RETURNING id INTO v_sun_id;
    END IF;

    -- MARUTI
    SELECT id INTO v_mar_id FROM india_market.instruments WHERE symbol = 'MARUTI' AND exchange = 'NSE' AND instrument_type = 'equity';
    IF v_mar_id IS NULL THEN
        INSERT INTO india_market.instruments (symbol, name, exchange, instrument_type, segment)
        VALUES ('MARUTI', 'Maruti Suzuki India Ltd', 'NSE', 'equity', 'EQ') RETURNING id INTO v_mar_id;
    END IF;

    -- Holdings
    -- INFY
    SELECT id INTO v_hold FROM india_market.equity_holdings WHERE user_id = v_user_id AND broker_account_id = v_broker_id AND instrument_id = v_infy_id;
    IF v_hold IS NULL THEN
        INSERT INTO india_market.equity_holdings (user_id, broker_account_id, instrument_id, quantity, avg_buy_price, current_price, unrealised_pnl)
        VALUES (v_user_id, v_broker_id, v_infy_id, 200, 1320.00, 1892.00, (1892.00 - 1320.00) * 200);
    END IF;

    -- HDFCBANK
    SELECT id INTO v_hold FROM india_market.equity_holdings WHERE user_id = v_user_id AND broker_account_id = v_broker_id AND instrument_id = v_hdfc_id;
    IF v_hold IS NULL THEN
        INSERT INTO india_market.equity_holdings (user_id, broker_account_id, instrument_id, quantity, avg_buy_price, current_price, unrealised_pnl)
        VALUES (v_user_id, v_broker_id, v_hdfc_id, 150, 1580.00, 1724.00, (1724.00 - 1580.00) * 150);
    END IF;

    -- RELIANCE
    SELECT id INTO v_hold FROM india_market.equity_holdings WHERE user_id = v_user_id AND broker_account_id = v_broker_id AND instrument_id = v_rel_id;
    IF v_hold IS NULL THEN
        INSERT INTO india_market.equity_holdings (user_id, broker_account_id, instrument_id, quantity, avg_buy_price, current_price, unrealised_pnl)
        VALUES (v_user_id, v_broker_id, v_rel_id, 80, 2240.00, 2918.00, (2918.00 - 2240.00) * 80);
    END IF;

    -- TCS
    SELECT id INTO v_hold FROM india_market.equity_holdings WHERE user_id = v_user_id AND broker_account_id = v_broker_id AND instrument_id = v_tcs_id;
    IF v_hold IS NULL THEN
        INSERT INTO india_market.equity_holdings (user_id, broker_account_id, instrument_id, quantity, avg_buy_price, current_price, unrealised_pnl)
        VALUES (v_user_id, v_broker_id, v_tcs_id, 60, 3420.00, 4218.00, (4218.00 - 3420.00) * 60);
    END IF;

    -- ASIANPAINT
    SELECT id INTO v_hold FROM india_market.equity_holdings WHERE user_id = v_user_id AND broker_account_id = v_broker_id AND instrument_id = v_ap_id;
    IF v_hold IS NULL THEN
        INSERT INTO india_market.equity_holdings (user_id, broker_account_id, instrument_id, quantity, avg_buy_price, current_price, unrealised_pnl)
        VALUES (v_user_id, v_broker_id, v_ap_id, 100, 2680.00, 2412.00, (2412.00 - 2680.00) * 100);
    END IF;

    -- BAJFINANCE
    SELECT id INTO v_hold FROM india_market.equity_holdings WHERE user_id = v_user_id AND broker_account_id = v_broker_id AND instrument_id = v_bf_id;
    IF v_hold IS NULL THEN
        INSERT INTO india_market.equity_holdings (user_id, broker_account_id, instrument_id, quantity, avg_buy_price, current_price, unrealised_pnl)
        VALUES (v_user_id, v_broker_id, v_bf_id, 40, 6200.00, 7840.00, (7840.00 - 6200.00) * 40);
    END IF;

    -- SUNPHARMA
    SELECT id INTO v_hold FROM india_market.equity_holdings WHERE user_id = v_user_id AND broker_account_id = v_broker_id AND instrument_id = v_sun_id;
    IF v_hold IS NULL THEN
        INSERT INTO india_market.equity_holdings (user_id, broker_account_id, instrument_id, quantity, avg_buy_price, current_price, unrealised_pnl)
        VALUES (v_user_id, v_broker_id, v_sun_id, 120, 980.00, 1284.00, (1284.00 - 980.00) * 120);
    END IF;

    -- MARUTI
    SELECT id INTO v_hold FROM india_market.equity_holdings WHERE user_id = v_user_id AND broker_account_id = v_broker_id AND instrument_id = v_mar_id;
    IF v_hold IS NULL THEN
        INSERT INTO india_market.equity_holdings (user_id, broker_account_id, instrument_id, quantity, avg_buy_price, current_price, unrealised_pnl)
        VALUES (v_user_id, v_broker_id, v_mar_id, 30, 9400.00, 12240.00, (12240.00 - 9400.00) * 30);
    END IF;

END $$;
