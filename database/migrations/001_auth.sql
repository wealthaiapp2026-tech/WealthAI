-- STEP 2: Connect to the newly created DB
-- In CLI: \c wealthai_db
-- In PGAdmin: connect manually to wealthai_db

-- STEP 3: Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- STEP 4: Create module-wise schemas
-- STEP 5: (Optional) Allow everyone full access to all schemas
-- Default privilege: allow SELECT/INSERT/UPDATE/DELETE on all future tables
CREATE SCHEMA IF NOT EXISTS auth;
GRANT USAGE, CREATE ON SCHEMA auth TO public;
ALTER DEFAULT PRIVILEGES IN SCHEMA auth GRANT ALL ON TABLES TO public;


CREATE TABLE IF NOT EXISTS auth.logins (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Login Credentials
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,

    -- Account Details
    full_name VARCHAR(100),

    role VARCHAR(20)
        CHECK (role IN ('user', 'admin', 'advisor'))
        DEFAULT 'user',

    -- Security
    is_email_verified BOOLEAN DEFAULT false,
    is_mobile_verified BOOLEAN DEFAULT false,

    last_login_at TIMESTAMPTZ,

    -- Status
    is_active BOOLEAN DEFAULT true,
    is_deleted BOOLEAN DEFAULT false,

    -- Audit
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Optional Metadata
    tags TEXT[] DEFAULT '{}'
);

CREATE TABLE auth.login_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    login_id UUID NOT NULL REFERENCES auth.logins(id) ON DELETE CASCADE,

    refresh_token TEXT,
    device_info TEXT,
    ip_address TEXT,

    login_at TIMESTAMPTZ DEFAULT now(),
    expires_at TIMESTAMPTZ,

    is_active BOOLEAN DEFAULT true
);
-- USERS
CREATE TABLE IF NOT EXISTS auth.users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Parent Login Account
    login_id UUID NOT NULL REFERENCES auth.logins(id) ON DELETE CASCADE,

    -- Profile / Portfolio Identity
    profile_name VARCHAR(100) NOT NULL,

    relationship_type VARCHAR(20)
        CHECK (
            relationship_type IN (
                'self',
                'spouse',
                'child',
                'parent',
                'sibling',
                'friend',
                'client',
                'other'
            )
        )
        DEFAULT 'self',

    -- Personal Details
    full_name VARCHAR(100),
    email VARCHAR(255),
    mobile_number TEXT,
    pan_number TEXT,

    dob DATE,

    -- Access / Role
    role VARCHAR(20)
        CHECK (role IN ('user', 'admin', 'advisor'))
        DEFAULT 'user',

    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    is_deleted BOOLEAN DEFAULT FALSE,

    -- Audit
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Extra Metadata
    remarks TEXT,
    tags TEXT[] DEFAULT '{}'
);

CREATE TABLE IF NOT EXISTS auth.user_brokers (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES auth.users(id),

    broker_name     TEXT NOT NULL CHECK (broker_name IN (
                        'zerodha', 'upstox', 'angel',
                        'fyers', 'hdfc_securities',
                        'icici_direct', 'kotak', 'groww'
                    )),
    account_number  TEXT NOT NULL,      -- demat / trading account number
    nickname        TEXT,               -- "My Zerodha", "Salary Account"

    is_primary      BOOLEAN DEFAULT false,
    is_active       BOOLEAN DEFAULT true,

    created_at      TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE (user_id, broker_name, account_number)
);

CREATE TABLE auth.user_settings (
    user_id UUID PRIMARY KEY
        REFERENCES auth.users(id)
        ON DELETE CASCADE,

    theme TEXT DEFAULT 'light',

    currency TEXT DEFAULT 'INR',

    timezone TEXT DEFAULT 'Asia/Kolkata',

    notifications_enabled BOOLEAN DEFAULT true,

    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE auth.user_notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    user_id UUID NOT NULL
        REFERENCES auth.users(id)
        ON DELETE CASCADE,

    title TEXT,
    message TEXT,

    notification_type TEXT,

    is_read BOOLEAN DEFAULT false,

    created_at TIMESTAMPTZ DEFAULT now()
);