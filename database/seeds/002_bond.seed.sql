DO $$
DECLARE
  v_user_id        UUID;
  v_bond_gsec      UUID;
  v_bond_corp      UUID;
  v_holding_gsec   UUID;
  v_holding_corp   UUID;
BEGIN
  -- 1. Fetch an active test user
  SELECT id INTO v_user_id FROM auth.users WHERE is_deleted = false LIMIT 1;
  
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'No active user found in auth.users to link seed data.';
  END IF;

  -- 2. Seed Bond Master Data
  -- Government Security Example
  INSERT INTO bond.bond_master (isin, bond_name, issuer_name, bond_type, coupon_rate, face_value, interest_frequency, issue_date, maturity_date, credit_rating, is_listed, tags)
  VALUES ('IN0020230081', '7.18% GS 2033', 'Government of India', 'gsec', 7.1800, 100.00, 'semi_annual', '2023-08-14', '2033-08-14', 'SOVEREIGN', true, '{"gsec", "safe"}')
  ON CONFLICT (isin) DO UPDATE SET bond_name = EXCLUDED.bond_name
  RETURNING id INTO v_bond_gsec;

  -- Corporate Bond Example
  INSERT INTO bond.bond_master (isin, bond_name, issuer_name, bond_type, coupon_rate, face_value, interest_frequency, issue_date, maturity_date, credit_rating, is_listed, tags)
  VALUES ('INE040A07RF4', '8.75% HDFC Bank Corporate Bond', 'HDFC Bank Limited', 'corporate', 8.7500, 1000.00, 'annual', '2024-01-15', '2029-01-15', 'AAA', true, '{"corporate", "high-yield"}')
  ON CONFLICT (isin) DO UPDATE SET bond_name = EXCLUDED.bond_name
  RETURNING id INTO v_bond_corp;


  -- 3. Seed Bond Holdings (Upsert matching the unique constraint)
  -- G-Sec Holding
  INSERT INTO bond.bond_holdings (user_id, bond_id, platform, demat_account, quantity, avg_purchase_price, invested_amount, purchase_date, status)
  VALUES (v_user_id, v_bond_gsec, 'Zerodha Coin', 'DP12345678', 500.0000, 100.50, 50250.00, '2025-02-10', 'active')
  ON CONFLICT (user_id, bond_id, demat_account) 
  DO UPDATE SET 
    quantity = EXCLUDED.quantity, 
    avg_purchase_price = EXCLUDED.avg_purchase_price, 
    invested_amount = EXCLUDED.invested_amount,
    updated_at = now()
  RETURNING id INTO v_holding_gsec;

  -- Corporate Bond Holding
  INSERT INTO bond.bond_holdings (user_id, bond_id, platform, demat_account, quantity, avg_purchase_price, invested_amount, purchase_date, status)
  VALUES (v_user_id, v_bond_corp, 'Wint Wealth', 'DP12345678', 50.0000, 1010.00, 50500.00, '2025-05-20', 'active')
  ON CONFLICT (user_id, bond_id, demat_account) 
  DO UPDATE SET 
    quantity = EXCLUDED.quantity, 
    avg_purchase_price = EXCLUDED.avg_purchase_price, 
    invested_amount = EXCLUDED.invested_amount,
    updated_at = now()
  RETURNING id INTO v_holding_corp;


  -- 4. Seed Transactions (Always inserted sequentially to maintain history ledger)
  -- Transaction 1: Buy G-Sec
  INSERT INTO bond.bond_transactions (holding_id, txn_type, txn_date, quantity, price, total_amount, accrued_interest, remarks)
  VALUES (v_holding_gsec, 'buy', '2025-02-10 10:00:00+05:30', 500.0000, 100.50, 50250.00, 0.00, 'Initial setup purchase');

  -- Transaction 2: First Interest Credit for G-Sec
  INSERT INTO bond.bond_transactions (holding_id, txn_type, txn_date, quantity, price, total_amount, accrued_interest, remarks)
  VALUES (v_holding_gsec, 'interest_credit', '2025-08-14 00:00:00+05:30', NULL, NULL, 1795.00, 0.00, 'Semi-annual interest received');

  -- Transaction 3: Buy Corporate Bond
  INSERT INTO bond.bond_transactions (holding_id, txn_type, txn_date, quantity, price, total_amount, accrued_interest, remarks)
  VALUES (v_holding_corp, 'buy', '2025-05-20 11:30:00+05:30', 50.0000, 1010.00, 50500.00, 150.00, 'Purchased via secondary market with accrued interest');


  RAISE NOTICE '✅ Bond schema successfully seeded for user: %', v_user_id;
END $$;
-- DO $$
-- DECLARE
--   v_user_id        UUID;
--   v_benchmark_n50  UUID;
--   v_scheme_quant   UUID;
--   v_scheme_parag   UUID;
--   v_holding_quant  UUID;
--   v_holding_parag  UUID;
-- BEGIN
--   SELECT id INTO v_user_id FROM auth.users WHERE is_deleted = false LIMIT 1;
  
--   -- Seed Benchmarks
--   INSERT INTO mutual_fund.mf_benchmarks (name, symbol, provider)
--   VALUES ('NIFTY 50 TRI', '^NSEI', 'NSE')
--   ON CONFLICT (name) DO UPDATE SET symbol = EXCLUDED.symbol
--   RETURNING benchmark_id INTO v_benchmark_n50;

--   -- Seed Schemes
--   INSERT INTO mutual_fund.mf_schemes (scheme_code, isin, scheme_name, fund_house, category, sub_category, plan_type, dividend_type, fund_type, benchmark_id)
--   VALUES ('120847', 'INFaf01', 'Quant Small Cap Fund - Direct Plan - Growth', 'Quant Mutual Fund', 'Equity', 'Small Cap', 'Direct', 'Growth', 'Open-Ended', v_benchmark_n50)
--   ON CONFLICT (scheme_code) DO UPDATE SET scheme_name = EXCLUDED.scheme_name
--   RETURNING scheme_id INTO v_scheme_quant;

--   -- Seed Holdings (Matches the new UNIQUE constraint)
--   INSERT INTO mutual_fund.mf_holdings (user_id, scheme_id, folio_number, units, avg_nav, invested_amount)
--   VALUES (v_user_id, v_scheme_quant, '123456789/0', 407.332, 122.75, 50000)
--   ON CONFLICT (user_id, scheme_id) 
--   DO UPDATE SET 
--     units = EXCLUDED.units, 
--     avg_nav = EXCLUDED.avg_nav, 
--     invested_amount = EXCLUDED.invested_amount
--   RETURNING id INTO v_holding_quant;

--   RAISE NOTICE '✅ Seed complete for user: %', v_user_id;
-- END $$;