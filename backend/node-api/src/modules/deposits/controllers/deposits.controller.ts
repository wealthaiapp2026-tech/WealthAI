// modules/deposits/controllers/deposits.controller.js
const services                   = require('../services/deposits.services');
const { sendSuccess, sendError } = require('../../../shared/response');

exports.addHolding = async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const { account_type, principal_amount, start_date } = req.body;
    if (!account_type || !principal_amount || !start_date) {
      return sendError(res, 'account_type, principal_amount and start_date are required', 400);
    }
    const holding = await services.addHolding({ ...req.body, user_id: req.user.user_id });
    return sendSuccess(res, holding, 'Deposit account added', 201);
  } catch (err) { next(err); }
};

exports.getAllHoldings = async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const holdings = await services.getAllHoldings(req.user.user_id, req.query.account_type);
    return sendSuccess(res, holdings);
  } catch (err) { next(err); }
};

exports.getHoldingById = async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const holding = await services.getHoldingById(req.params.id);
    if (!holding) return sendError(res, 'Deposit not found', 404);
    return sendSuccess(res, holding);
  } catch (err) { next(err); }
};

exports.updateHolding = async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const holding = await services.updateHolding(req.params.id, req.body);
    return sendSuccess(res, holding, 'Deposit updated');
  } catch (err) { next(err); }
};

exports.deleteHolding = async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    await services.deleteHolding(req.params.id);
    return sendSuccess(res, null, 'Deposit deleted');
  } catch (err) { next(err); }
};

exports.addTransaction = async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const txn = await services.addTransaction({
      ...req.body,
      holding_id: req.params.id,
      user_id: req.user.user_id,
    });
    return sendSuccess(res, txn, 'Transaction added', 201);
  } catch (err) { next(err); }
};

exports.getTransactions = async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const txns = await services.getTransactions(req.params.id);
    return sendSuccess(res, txns);
  } catch (err) { next(err); }
};
