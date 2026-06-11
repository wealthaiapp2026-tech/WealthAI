DO $$
DECLARE
  v_user_id        UUID;
  v_benchmark_n50  UUID;
  v_scheme_quant   UUID;
  v_scheme_parag   UUID;
  v_holding_quant  UUID;
  v_holding_parag  UUID;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE is_deleted = false LIMIT 1;
  
  -- Seed Benchmarks
  INSERT INTO mutual_fund.mf_benchmarks (name, symbol, provider)
  VALUES ('NIFTY 50 TRI', '^NSEI', 'NSE')
  ON CONFLICT (name) DO UPDATE SET symbol = EXCLUDED.symbol
  RETURNING benchmark_id INTO v_benchmark_n50;

  -- Seed Schemes
  INSERT INTO mutual_fund.mf_schemes (scheme_code, isin, scheme_name, fund_house, category, sub_category, plan_type, dividend_type, fund_type, benchmark_id)
  VALUES ('120847', 'INFaf01', 'Quant Small Cap Fund - Direct Plan - Growth', 'Quant Mutual Fund', 'Equity', 'Small Cap', 'Direct', 'Growth', 'Open-Ended', v_benchmark_n50)
  ON CONFLICT (scheme_code) DO UPDATE SET scheme_name = EXCLUDED.scheme_name
  RETURNING scheme_id INTO v_scheme_quant;

  -- Seed Holdings (Matches the new UNIQUE constraint)
  INSERT INTO mutual_fund.mf_holdings (user_id, scheme_id, folio_number, units, avg_nav, invested_amount)
  VALUES (v_user_id, v_scheme_quant, '123456789/0', 407.332, 122.75, 50000)
  ON CONFLICT (user_id, scheme_id) 
  DO UPDATE SET 
    units = EXCLUDED.units, 
    avg_nav = EXCLUDED.avg_nav, 
    invested_amount = EXCLUDED.invested_amount
  RETURNING id INTO v_holding_quant;

  RAISE NOTICE '✅ Seed complete for user: %', v_user_id;
END $$;