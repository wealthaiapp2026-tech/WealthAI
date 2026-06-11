// ─────────────────────────────────────────────────────────────────
//  shared/response.js
//  Consistent API response helpers
//  Usage: const { sendSuccess, sendError } = require('../../shared/response');
//         sendSuccess(res, data, 'Created', 201);
//         sendError(res, 'Not found', 404);
// ─────────────────────────────────────────────────────────────────

const sendSuccess = (res: Response, data: unknown = null, message = 'Success', statusCode = 200): Response => {
  const payload = { success: true, message };
  if (data !== null) payload.data = data;
  return res.status(statusCode).json(payload);
};

const sendError = (res: Response, message = 'Something went wrong', statusCode = 500): Response => {
  return res.status(statusCode).json({ success: false, message });
};

module.exports = { sendSuccess, sendError };
