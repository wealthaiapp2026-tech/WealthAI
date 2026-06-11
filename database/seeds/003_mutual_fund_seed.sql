-- ═══════════════════════════════════════════════════
-- Mutual Fund Seed — Fixed column names per migration
-- ═══════════════════════════════════════════════════

-- 1. Benchmarks (column is 'symbol' NOT 'index_code')
INSERT INTO mutual_fund.mf_benchmarks (benchmark_id, name, symbol)
VALUES
  ('b1000000-0000-0000-0000-000000000001', 'Nifty 50 TRI',         'NIFTY50'),
  ('b1000000-0000-0000-0000-000000000002', 'Nifty Midcap 150 TRI', 'NIFTYMID150'),
  ('b1000000-0000-0000-0000-000000000003', 'S&P BSE Sensex TRI',   'SENSEX')
ON CONFLICT (name) DO NOTHING;

-- 2. Schemes
INSERT INTO mutual_fund.mf_schemes
  (scheme_id, scheme_code, isin, scheme_name, fund_house, category, sub_category, plan_type, benchmark_id)
VALUES
  ('a1111111-1111-1111-1111-111111111111', '119598', 'INF209K01YJ5',
   'Mirae Asset Large Cap Fund - Growth',          'Mirae Asset', 'Equity', 'Large Cap',  'Regular',
   'b1000000-0000-0000-0000-000000000001'),
  ('a2222222-2222-2222-2222-222222222222', '120503', 'INF846K01DP4',
   'Axis Bluechip Fund - Direct Growth',           'Axis',        'Equity', 'Large Cap',  'Direct',
   'b1000000-0000-0000-0000-000000000001'),
  ('a3333333-3333-3333-3333-333333333333', '119063', 'INF179K01950',
   'HDFC Mid-Cap Opportunities Fund - Growth',     'HDFC',        'Equity', 'Mid Cap',    'Regular',
   'b1000000-0000-0000-0000-000000000002'),
  ('a4444444-4444-4444-4444-444444444444', '120612', 'INF200K01VW1',
   'SBI Small Cap Fund - Direct Growth',           'SBI',         'Equity', 'Small Cap',  'Direct',
   'b1000000-0000-0000-0000-000000000002'),
  ('a5555555-5555-5555-5555-555555555555', '122639', 'INF769K01131',
   'Parag Parikh Flexi Cap Fund - Direct Growth',  'PPFAS',       'Equity', 'Flexi Cap',  'Direct',
   'b1000000-0000-0000-0000-000000000001')
ON CONFLICT (scheme_code) DO NOTHING;

-- 3. Metadata (NO launch_date column; use min_lumpsum_amount NOT min_investment)
INSERT INTO mutual_fund.mf_scheme_metadata
  (scheme_id, expense_ratio, aum_in_crores, star_rating, fund_manager_name, min_lumpsum_amount, min_sip_amount)
VALUES
  ('a1111111-1111-1111-1111-111111111111', 1.62, 32500.00, 4, 'Gaurav Misra',       5000.00, 1000.00),
  ('a2222222-2222-2222-2222-222222222222', 0.65, 34000.00, 3, 'Shreyash Devalkar',  5000.00,  500.00),
  ('a3333333-3333-3333-3333-333333333333', 1.68, 45000.00, 4, 'Chirag Setalvad',    5000.00,  500.00),
  ('a4444444-4444-4444-4444-444444444444', 0.70, 21000.00, 5, 'R. Srinivasan',      5000.00,  500.00),
  ('a5555555-5555-5555-5555-555555555555', 0.61, 48000.00, 5, 'Rajeev Thakkar',     1000.00, 1000.00)
ON CONFLICT (scheme_id) DO NOTHING;

-- 4. NAV History
INSERT INTO mutual_fund.mf_nav_history (scheme_id, nav_date, nav_value, day_change_percent)
VALUES
  ('a1111111-1111-1111-1111-111111111111', CURRENT_DATE,                  95.42,  0.45),
  ('a1111111-1111-1111-1111-111111111111', CURRENT_DATE - INTERVAL '1 day', 94.99, -0.20),
  ('a1111111-1111-1111-1111-111111111111', CURRENT_DATE - INTERVAL '2 days',95.18,  0.10),
  ('a2222222-2222-2222-2222-222222222222', CURRENT_DATE,                  72.15,  0.30),
  ('a2222222-2222-2222-2222-222222222222', CURRENT_DATE - INTERVAL '1 day', 71.93,  0.12),
  ('a3333333-3333-3333-3333-333333333333', CURRENT_DATE,                 115.60,  0.55),
  ('a3333333-3333-3333-3333-333333333333', CURRENT_DATE - INTERVAL '1 day',114.97,  0.22),
  ('a4444444-4444-4444-4444-444444444444', CURRENT_DATE,                 145.20, -0.15),
  ('a4444444-4444-4444-4444-444444444444', CURRENT_DATE - INTERVAL '1 day',145.42,  0.08),
  ('a5555555-5555-5555-5555-555555555555', CURRENT_DATE,                  62.45,  0.80),
  ('a5555555-5555-5555-5555-555555555555', CURRENT_DATE - INTERVAL '1 day', 61.96,  0.35)
ON CONFLICT (scheme_id, nav_date) DO NOTHING;

-- 5. Holdings for dev test user (UUID from auth seed: 11111111-1111-1111-1111-111111111111)
INSERT INTO mutual_fund.mf_holdings
  (user_id, scheme_id, folio_number, units, avg_nav, invested_amount)
VALUES
  ('11111111-1111-1111-1111-111111111111',
   'a1111111-1111-1111-1111-111111111111', 'MF-12345678', 150.2340, 84.50, 12694.77),
  ('11111111-1111-1111-1111-111111111111',
   'a2222222-2222-2222-2222-222222222222', 'MF-87654321', 200.0000, 65.20, 13040.00),
  ('11111111-1111-1111-1111-111111111111',
   'a3333333-3333-3333-3333-333333333333', 'MF-11223344',  80.0000,108.50,  8680.00)
ON CONFLICT (user_id, scheme_id, folio_number) DO NOTHING;
