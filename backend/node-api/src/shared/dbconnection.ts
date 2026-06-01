// ─────────────────────────────────────────────────────────────────
//  shared/dbconnection.js
//  PostgreSQL connection pool
//  Usage: const db = require('../../shared/dbconnection');
//         const { rows } = await db.query('SELECT * FROM auth.users WHERE id=$1', [id]);
// ─────────────────────────────────────────────────────────────────

const { Pool } = require('pg');
const logger   = require('./logger');

const pool: Pool = new Pool({
  host:                    process.env.DB_HOST     || 'localhost',
  port:                    parseInt(process.env.DB_PORT) || 5432,
  database:                process.env.DB_NAME     || 'wealthai_db',
  user:                    process.env.DB_USER     || 'postgres',
  password:                process.env.DB_PASSWORD || '',
  max:                     parseInt(process.env.DB_POOL_MAX) || 10,
  idleTimeoutMillis:       30000,
  connectionTimeoutMillis: 5000,
});

// Test connection on startup
pool.connect((err: Error | undefined, client: PoolClient | undefined, release: (err?: Error) => void) => {
  if (err) {
    logger.error(`PostgreSQL connection failed: ${err.message}`);
    process.exit(1); // Exit if DB is unreachable — no point running
  }
  logger.info('PostgreSQL connected successfully');
  release();
});

pool.on('error', (err) => {
  logger.error(`Unexpected PostgreSQL pool error: ${err.message}`);
});

module.exports = pool;
