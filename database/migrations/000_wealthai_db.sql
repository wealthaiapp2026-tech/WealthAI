-- STEP 1: Create the database (run this inside the default "postgres" DB)
CREATE DATABASE wealthai_db
    WITH OWNER = postgres
    ENCODING = 'UTF8'
    CONNECTION LIMIT = -1;