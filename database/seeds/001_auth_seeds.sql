-- LOGIN

INSERT INTO auth.logins (
    id,
    username,
    email,
    password_hash,
    full_name,
    role,
    is_email_verified,
    is_active
)
VALUES (
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    'testuser',
    'test@wealthai.com',
    'dummy_hash',
    'Test User',
    'user',
    true,
    true
);

-- USER

INSERT INTO auth.users (
    id,
    login_id,
    profile_name,
    relationship_type,
    full_name,
    email,
    mobile_number,
    role,
    is_active
)
VALUES (
    '11111111-1111-1111-1111-111111111111',
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    'Primary Portfolio',
    'self',
    'Test User',
    'test@wealthai.com',
    '9999999999',
    'user',
    true
);

-- USER SETTINGS

INSERT INTO auth.user_settings (
    user_id
)
VALUES (
    '11111111-1111-1111-1111-111111111111'
);

-- USER BROKER

INSERT INTO auth.user_brokers (
    id,
    user_id,
    broker_name,
    account_number,
    nickname,
    is_primary
)
VALUES (
    'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
    '11111111-1111-1111-1111-111111111111',
    'zerodha',
    'TEST12345',
    'Test Zerodha',
    true
);