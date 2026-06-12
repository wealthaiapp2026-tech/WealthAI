// ─────────────────────────────────────────────────────────────────
//  WealthAI — Node.js API Entry Point
//  Start : node index.js
//  Dev   : npm run dev  (nodemon)
// ─────────────────────────────────────────────────────────────────

import 'dotenv/config';

const express = require('express');
const cors    = require('cors');
const helmet  = require('helmet');
const morgan  = require('morgan');

const logger       = require('./shared/logger');
const errorHandler = require('./shared/middleware/errorHandler');
const scheduler    = require('./shared/scheduler');

// ── Route imports ─────────────────────────────────────────────────
const authRoutes     = require('./modules/auth/routes/auth.routes');
const bondRoutes     = require('./modules/bond/routes/bond.routes');
const depositsRoutes = require('./modules/deposits/routes/deposits.routes');
const mfRoutes       = require('./modules/mutual_fund/routes/mf.routes');
const algoRoutes     = require('./modules/algo_engine/routes/algo.routes');
const marketRoutes   = require('./modules/india_market/routes/market.routes');
const portfolioRoutes= require('./modules/portfolio/routes/portfolio.routes');

const app: import('express').Application = express();
const PORT = process.env.PORT || 3000;

// ── Security ──────────────────────────────────────────────────────
app.use(helmet());

// ── CORS ──────────────────────────────────────────────────────────
const allowedOrigins = process.env.ALLOWED_ORIGINS
  ? process.env.ALLOWED_ORIGINS.split(',')
  : '*';

app.use(cors({
  origin: allowedOrigins,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));

// ── Body parsing ──────────────────────────────────────────────────
app.use(express.json());

// ── HTTP request logging (dev only) ──────────────────────────────
if (process.env.NODE_ENV !== 'production') {
  app.use(morgan('dev'));
}

// ── Health check ──────────────────────────────────────────────────
app.get('/health', (req, res) => {
  res.json({
    status:    'ok',
    service:   'node-api',
    env:       process.env.NODE_ENV,
    timestamp: new Date(),
  });
});

// just testing for db connection only
app.get('/db-test', async (req: any, res: any) => {
  try {
    const result = await pool.query('SELECT current_database() as db, now() as time');
    res.json({ success: true, connected: true, data: result.rows[0] });
  } catch (err: any) {
    res.json({ success: false, connected: false, error: err.message });
  }
});

// ── API Routes  (all prefixed /api/v1) ───────────────────────────
app.use('/api/v1/auth',      authRoutes);
app.use('/api/v1/bond',      bondRoutes);
app.use('/api/v1/fd',        depositsRoutes);
app.use('/api/v1/mf',        mfRoutes);
app.use('/api/v1/algo',      algoRoutes);
app.use('/api/v1/market',    marketRoutes);
app.use('/api/v1/portfolio', portfolioRoutes);

// ── 404 ───────────────────────────────────────────────────────────
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: `Route not found: ${req.method} ${req.originalUrl}`,
  });
});

// ── Global error handler (must be last) ──────────────────────────
app.use(errorHandler);

// ── Start ─────────────────────────────────────────────────────────
app.listen(PORT, () => {
  logger.info(`WealthAI API running on port ${PORT} [${process.env.NODE_ENV}]`);
  scheduler.init();
});

module.exports = app;
