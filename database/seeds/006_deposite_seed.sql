-- ============================================================
-- Seed: deposits module
-- Matches WealthOS frontend screenshot exactly:
--   HDFC 7.25% cumulative, PNB 7.1% quarterly payout,
--   Axis 7% cumulative, SBI 6.5% tax-saver, ICICI 7.15% monthly payout
-- Run AFTER: 000_wealthai_db.sql, 001_auth.sql, 006_deposits.sql
-- ============================================================

DO $$
DECLARE
  v_user_id   UUID;
  v_hdfc_id   UUID;
  v_pnb_id    UUID;
  v_axis_id   UUID;
  v_sbi_id    UUID;
  v_icici_id  UUID;
BEGIN

  -- Pick first active user; replace with a specific email if needed:
  -- SELECT id INTO v_user_id FROM auth.users WHERE email = 'rahul@example.com';
  SELECT id INTO v_user_id
    FROM auth.users
   WHERE is_deleted = false
   LIMIT 1;

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'No users found in auth.users. Run 001_auth.sql seed first.';
  END IF;

  RAISE NOTICE 'Seeding deposits for user_id: %', v_user_id;

  -- ── Clean previous seed data for idempotency ─────────────────
  DELETE FROM deposits.account_holdings WHERE user_id = v_user_id;
  -- Cascade DELETE on account_transactions via ON DELETE CASCADE

  -- ═══════════════════════════════════════════════════════════
  -- 1. HDFC Bank FD — Cumulative, AT_MATURITY
  --    Principal: ₹2,00,000 | Rate: 7.25% | Maturity: 15 Jun 2026
  --    Days left in screenshot: 17 days (screenshot date: 29 May 2026)
  -- ═══════════════════════════════════════════════════════════
  INSERT INTO deposits.account_holdings (
    user_id, account_type, account_number, account_name,
    institution_name, institution_branch,
    principal_amount, current_value,
    interest_rate, interest_type, compounding_freq,
    start_date, maturity_date, tenure_months,
    maturity_amount, maturity_action,
    nominee_name, status
  ) VALUES (
    v_user_id, 'FD', 'HDFC-3421-FD', 'My HDFC FD',
    'HDFC Bank', 'New Delhi - Connaught Place',
    200000, 246842,
    7.25, 'cumulative', 'quarterly',
    '2023-06-15', '2026-06-15', 36,
    246842, 'credit_to_account',
    'Priya Kumar', 'active'
  )
  RETURNING id INTO v_hdfc_id;

  INSERT INTO deposits.account_transactions
    (holding_id, user_id, transaction_type, amount, closing_balance, transaction_date, remarks)
  VALUES
    (v_hdfc_id, v_user_id, 'deposit',         200000, 200000, '2023-06-15', 'Opening deposit'),
    (v_hdfc_id, v_user_id, 'interest_credit',  14500, 214500, '2024-06-15', 'Annual interest FY 2023-24'),
    (v_hdfc_id, v_user_id, 'interest_credit',  15593, 230093, '2025-06-15', 'Annual interest FY 2024-25'),
    (v_hdfc_id, v_user_id, 'interest_credit',  16749, 246842, '2026-03-31', 'Q4 FY 2025-26 accrual');

  -- ═══════════════════════════════════════════════════════════
  -- 2. Punjab National Bank FD — Non-Cumulative, Quarterly Payout
  --    Principal: ₹75,000 | Rate: 7.1% | Maturity: 22 Nov 2026
  --    Days left: 177 days
  -- ═══════════════════════════════════════════════════════════
  INSERT INTO deposits.account_holdings (
    user_id, account_type, account_number, account_name,
    institution_name, institution_branch,
    principal_amount, current_value,
    interest_rate, interest_type, compounding_freq,
    start_date, maturity_date, tenure_months,
    maturity_amount, maturity_action,
    nominee_name, status
  ) VALUES (
    v_user_id, 'FD', 'PNB-8821-FD', 'PNB Quarterly Income FD',
    'Punjab National Bank', 'Mumbai - Bandra',
    75000, 80325,
    7.1, 'non_cumulative', 'quarterly',
    '2025-11-22', '2026-11-22', 12,
    80325, 'credit_to_account',
    'Rahul Kumar', 'active'
  )
  RETURNING id INTO v_pnb_id;

  INSERT INTO deposits.account_transactions
    (holding_id, user_id, transaction_type, amount, closing_balance,
     transaction_date, remarks, interest_period)
  VALUES
    (v_pnb_id, v_user_id, 'deposit',         75000, 75000, '2025-11-22', 'Opening deposit',           NULL),
    (v_pnb_id, v_user_id, 'interest_credit',  1331, 76331, '2026-02-22', 'Q1 interest payout',        'Q1 FY 2025-26'),
    (v_pnb_id, v_user_id, 'interest_credit',  1331, 77662, '2026-05-22', 'Q2 interest payout',        'Q2 FY 2025-26');

  -- ═══════════════════════════════════════════════════════════
  -- 3. Axis Bank FD — Cumulative, AT_MATURITY
  --    Principal: ₹1,25,000 | Rate: 7% | Maturity: 04 Jan 2027
  --    Days left: 220 days
  -- ═══════════════════════════════════════════════════════════
  INSERT INTO deposits.account_holdings (
    user_id, account_type, account_number, account_name,
    institution_name, institution_branch,
    principal_amount, current_value,
    interest_rate, interest_type, compounding_freq,
    start_date, maturity_date, tenure_months,
    maturity_amount, maturity_action,
    nominee_name, status
  ) VALUES (
    v_user_id, 'FD', 'AXIS-2241-FD', 'Axis Cumulative FD',
    'Axis Bank', 'Bengaluru - MG Road',
    125000, 143469,
    7.0, 'cumulative', 'quarterly',
    '2025-01-04', '2027-01-04', 24,
    143469, 'auto_renew',
    'Rahul Kumar', 'active'
  )
  RETURNING id INTO v_axis_id;

  INSERT INTO deposits.account_transactions
    (holding_id, user_id, transaction_type, amount, closing_balance, transaction_date, remarks)
  VALUES
    (v_axis_id, v_user_id, 'deposit',         125000, 125000, '2025-01-04', 'Opening deposit'),
    (v_axis_id, v_user_id, 'interest_credit',   9956, 134956, '2025-12-31', 'Annual interest FY 2025-26'),
    (v_axis_id, v_user_id, 'interest_credit',   8513, 143469, '2026-05-31', 'Partial year interest accrual');

  -- ═══════════════════════════════════════════════════════════
  -- 4. State Bank of India FD — Tax Saver (5Y lock-in, 80C)
  --    Principal: ₹1,50,000 | Rate: 6.5% | Maturity: 01 Apr 2028
  --    Days left: 672 days | TAX SAVER badge
  -- ═══════════════════════════════════════════════════════════
  INSERT INTO deposits.account_holdings (
    user_id, account_type, account_number, account_name,
    institution_name, institution_branch,
    principal_amount, current_value,
    interest_rate, interest_type, compounding_freq,
    start_date, maturity_date, tenure_months,
    maturity_amount, maturity_action,
    nominee_name, status
  ) VALUES (
    v_user_id, 'FD', 'SBI-5521-TSFG', 'SBI Tax Saver FD',
    'State Bank of India', 'Delhi - Karol Bagh',
    150000, 205828,
    6.5, 'cumulative', 'quarterly',
    '2023-04-01', '2028-04-01', 60,
    205828, 'credit_to_account',
    'Priya Kumar', 'active'
  )
  RETURNING id INTO v_sbi_id;

  INSERT INTO deposits.account_transactions
    (holding_id, user_id, transaction_type, amount, closing_balance, transaction_date, remarks)
  VALUES
    (v_sbi_id, v_user_id, 'deposit',         150000, 150000, '2023-04-01', 'Opening deposit - Sec 80C deduction'),
    (v_sbi_id, v_user_id, 'interest_credit',   9750, 159750, '2024-03-31', 'Annual interest FY 2023-24'),
    (v_sbi_id, v_user_id, 'interest_credit',  10384, 170134, '2025-03-31', 'Annual interest FY 2024-25'),
    (v_sbi_id, v_user_id, 'interest_credit',  35694, 205828, '2026-03-31', 'Annual interest FY 2025-26');

  -- ═══════════════════════════════════════════════════════════
  -- 5. ICICI Bank FD — Non-Cumulative, Monthly Payout
  --    Principal: ₹3,00,000 | Rate: 7.15% | Maturity: 10 Oct 2026
  --    Days left: 133 | TDS: -₹1,143 shown in red
  -- ═══════════════════════════════════════════════════════════
  INSERT INTO deposits.account_holdings (
    user_id, account_type, account_number, account_name,
    institution_name, institution_branch,
    principal_amount, current_value,
    interest_rate, interest_type, compounding_freq,
    start_date, maturity_date, tenure_months,
    maturity_amount, maturity_action,
    nominee_name, status
  ) VALUES (
    v_user_id, 'FD', 'ICICI-7741-FD', 'ICICI Monthly Income FD',
    'ICICI Bank', 'Mumbai - Andheri',
    300000, 321450,
    7.15, 'non_cumulative', 'monthly',
    '2025-10-10', '2026-10-10', 12,
    321450, 'credit_to_account',
    'Rahul Kumar', 'active'
  )
  RETURNING id INTO v_icici_id;

  INSERT INTO deposits.account_transactions
    (holding_id, user_id, transaction_type, amount, closing_balance,
     transaction_date, remarks, interest_period)
  VALUES
    (v_icici_id, v_user_id, 'deposit',         300000, 300000, '2025-10-10', 'Opening deposit',                  NULL),
    (v_icici_id, v_user_id, 'interest_credit',   1788, 301788, '2025-11-10', 'Monthly interest payout',          'Oct 2025'),
    (v_icici_id, v_user_id, 'interest_credit',   1788, 303576, '2025-12-10', 'Monthly interest payout',          'Nov 2025'),
    (v_icici_id, v_user_id, 'interest_credit',   1788, 305364, '2026-01-10', 'Monthly interest payout',          'Dec 2025'),
    (v_icici_id, v_user_id, 'interest_credit',   1788, 307152, '2026-02-10', 'Monthly interest payout',          'Jan 2026'),
    (v_icici_id, v_user_id, 'interest_credit',   1788, 308940, '2026-03-10', 'Monthly interest payout',          'Feb 2026'),
    (v_icici_id, v_user_id, 'interest_credit',   1788, 310728, '2026-04-10', 'Monthly interest payout',          'Mar 2026'),
    (v_icici_id, v_user_id, 'interest_credit',   1788, 312516, '2026-05-10', 'Monthly interest payout',          'Apr 2026'),
    -- FIX BUG 5: TDS deduction uses 'withdrawal' not 'penalty' (penalty has wrong semantic)
    -- Amount is positive; TDS is a deduction recorded as withdrawal
    (v_icici_id, v_user_id, 'withdrawal',        1143, 311373, '2026-03-31', 'TDS deducted Q4 FY 2025-26',       NULL);

  -- ═══════════════════════════════════════════════════════════
  -- Government Scheme Interest Rates (account_metadata)
  -- ═══════════════════════════════════════════════════════════
  -- Clean previous seed metadata
  DELETE FROM deposits.account_metadata;

  INSERT INTO deposits.account_metadata
    (account_type, interest_rate, effective_from, effective_to,
     period, is_active, announced_by)
  VALUES
    ('PPF',  7.10, '2023-04-01', NULL,         'Q1 FY2024 onwards',     true,  'Ministry of Finance'),
    ('EPF',  8.25, '2024-04-01', NULL,         'FY 2024-25',            true,  'EPFO'),
    ('EPF',  8.15, '2023-04-01', '2024-03-31', 'FY 2023-24',            false, 'EPFO'),
    ('SSY',  8.20, '2023-10-01', NULL,         'Q3 FY2024 onwards',     true,  'Ministry of Finance'),
    ('NPS', 10.00, '2023-04-01', NULL,         'Long-term indicative',  true,  'PFRDA'),
    ('NSC',  7.70, '2023-04-01', NULL,         'Q1 FY2024 onwards',     true,  'Ministry of Finance'),
    ('SCSS', 8.20, '2023-04-01', NULL,         'Q1 FY2024 onwards',     true,  'Ministry of Finance'),
    ('KVP',  7.50, '2023-04-01', NULL,         'Q1 FY2024 onwards',     true,  'Ministry of Finance'),
    ('FD',   7.25, '2025-01-01', NULL,         'Best rate Jan 2025+',   true,  'Various banks'),
    ('RD',   7.00, '2025-01-01', NULL,         'Best rate Jan 2025+',   true,  'Various banks');

  RAISE NOTICE '✅ Deposits seed complete for user: %', v_user_id;
  RAISE NOTICE '   5 FD holdings + transactions seeded';
  RAISE NOTICE '   10 interest rate metadata rows seeded';

END $$;