-- =====================================================
-- BROKER
-- =====================================================

INSERT INTO algo.brokers (
    id,
    user_id,
    broker_id,
    broker_name,
    is_active
)
VALUES (
    '22222222-2222-2222-2222-222222222222',
    '11111111-1111-1111-1111-111111111111',
    'ZERODHA01',
    'Zerodha',
    true
)
ON CONFLICT (id) DO NOTHING;


-- =====================================================
-- STRATEGY
-- =====================================================

INSERT INTO algo.strategies (
    id,
    user_id,
    strategy_name,
    strategy_desc,
    capital,
    enabled
)
VALUES (
    '123e4567-e89b-12d3-a456-426614174000',
    '11111111-1111-1111-1111-111111111111',
    'Test Strategy',
    'Dummy strategy for engine testing',
    100000,
    true
)
ON CONFLICT (id) DO NOTHING;


-- =====================================================
-- STRATEGY SET
-- =====================================================

INSERT INTO algo.strategy_sets (
    id,
    strategy_id,
    set_order,
    name,
    segment,
    type,
    exchange,
    product
)
VALUES (
    '44444444-4444-4444-4444-444444444444',
    '123e4567-e89b-12d3-a456-426614174000',
    1,
    'Set 1',
    'equity',
    'directional',
    'NSE',
    'MIS'
)
ON CONFLICT (id) DO NOTHING;


-- =====================================================
-- POSITION 1
-- =====================================================

INSERT INTO algo.strategy_positions (
    id,
    set_id,
    name,
    position_order,
    position_type,
    transaction_type,
    segment,
    instrument,
    exchange,
    quantity,
    order_type,
    product
)
VALUES (
    '55555555-5555-5555-5555-555555555555',
    '44444444-4444-4444-4444-444444444444',
    'RELIANCE BUY',
    1,
    'equity',
    'BUY',
    'equity',
    'RELIANCE',
    'NSE',
    10,
    'MARKET',
    'MIS'
)
ON CONFLICT (id) DO NOTHING;


-- =====================================================
-- POSITION 2
-- =====================================================

INSERT INTO algo.strategy_positions (
    id,
    set_id,
    name,
    position_order,
    position_type,
    transaction_type,
    segment,
    instrument,
    exchange,
    quantity,
    order_type,
    product
)
VALUES (
    '66666666-6666-6666-6666-666666666666',
    '44444444-4444-4444-4444-444444444444',
    'TCS SELL',
    2,
    'equity',
    'SELL',
    'equity',
    'TCS',
    'NSE',
    10,
    'MARKET',
    'MIS'
)
ON CONFLICT (id) DO NOTHING;


-- =====================================================
-- DEPLOYMENT
-- =====================================================

INSERT INTO algo.deployments (
    id,
    user_id,
    strategy_id,
    broker_id,
    deployment_mode,
    multiplier,
    status,
    capital_allocated
)
VALUES (
    '550e8400-e29b-41d4-a716-446655440000',
    '11111111-1111-1111-1111-111111111111',
    '123e4567-e89b-12d3-a456-426614174000',
    '22222222-2222-2222-2222-222222222222',
    'paper',
    1,
    'active',
    100000
)
ON CONFLICT (id) DO NOTHING;