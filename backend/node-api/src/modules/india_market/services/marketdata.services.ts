// modules/india-market/services/marketdata.services.js

exports.getOhlcv = async ({ instrument_id, timeframe, from, to, limit = 365 }) => {
  let q = `
    SELECT timestamp, open, high, low, close, volume, oi
    FROM india_market.historical_ohlcv
    WHERE instrument_id = $1 AND timeframe = $2`;
  const p = [instrument_id, timeframe];
  if (from) { p.push(from); q += ` AND timestamp >= $${p.length}`; }
  if (to)   { p.push(to);   q += ` AND timestamp <= $${p.length}`; }
  p.push(parseInt(limit));
  q += ` ORDER BY timestamp DESC LIMIT $${p.length}`;
  const { rows } = await db.query(q, p);
  return rows;
};

exports.getFiiDii = async ({ from, to } = {}) => {
  let q = `SELECT * FROM india_market.fii_dii_cashflow WHERE 1=1`;
  const p = [];
  if (from) { p.push(from); q += ` AND trade_date >= $${p.length}`; }
  if (to)   { p.push(to);   q += ` AND trade_date <= $${p.length}`; }
  q += ` ORDER BY trade_date DESC LIMIT 90`;
  const { rows } = await db.query(q, p);
  return rows;
};

exports.getFiiDerivatives = async ({ from, to, instrument_type } = {}) => {
  let q = `SELECT * FROM india_market.fii_derivatives WHERE 1=1`;
  const p = [];
  if (from)            { p.push(from);            q += ` AND trade_date >= $${p.length}`; }
  if (to)              { p.push(to);              q += ` AND trade_date <= $${p.length}`; }
  if (instrument_type) { p.push(instrument_type); q += ` AND instrument_type = $${p.length}`; }
  q += ` ORDER BY trade_date DESC LIMIT 90`;
  const { rows } = await db.query(q, p);
  return rows;
};

exports.getOptionsChain = async ({ instrument_id, expiry_date, trade_date } = {}) => {
  const { rows } = await db.query(
    `SELECT *
     FROM india_market.options_data
     WHERE instrument_id = $1
       AND expiry_date   = $2
       AND trade_date    = COALESCE($3::date, CURRENT_DATE)
     ORDER BY strike_price ASC`,
    [instrument_id, expiry_date, trade_date || null]
  );
  return rows;
};

exports.getMmi = async () => {
  const { rows } = await db.query(
    `SELECT * FROM india_market.mmi ORDER BY fetched_at DESC LIMIT 30`
  );
  return rows;
};

exports.getVix = async ({ from, to } = {}) => {
  let q = `
    SELECT * FROM india_market.market_volatility_index
    WHERE index_name = 'INDIA_VIX'`;
  const p = [];
  if (from) { p.push(from); q += ` AND trade_date >= $${p.length}`; }
  if (to)   { p.push(to);   q += ` AND trade_date <= $${p.length}`; }
  q += ` ORDER BY trade_date DESC LIMIT 90`;
  const { rows } = await db.query(q, p);
  return rows;
};
