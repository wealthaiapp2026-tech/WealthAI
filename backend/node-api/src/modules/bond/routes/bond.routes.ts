// modules/bond/routes/bond.routes.js
const express        = require('express');
const bondRouter     = express.Router();
const bondCtrl       = require('../controllers/bond.controller');
// const authMiddleware = require('../../../shared/middleware/auth.middleware');

// bondRouter.use(authMiddleware);

bondRouter.get('/master',            bondCtrl.getBondMaster);
bondRouter.post('/add',              bondCtrl.addHolding);
bondRouter.get('/all',               bondCtrl.getAllHoldings);
bondRouter.get('/:id',               bondCtrl.getHoldingById);
bondRouter.put('/update/:id',        bondCtrl.updateHolding);
bondRouter.delete('/delete/:id',     bondCtrl.deleteHolding);
bondRouter.post('/:id/transaction',  bondCtrl.addTransaction);
bondRouter.get('/:id/transactions',  bondCtrl.getTransactions);

module.exports = bondRouter;
