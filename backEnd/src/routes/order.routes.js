const express = require('express');
const router = express.Router();
const orderCtrl = require('../controllers/order.controller');
const auth = require('../middleware/auth');

router.post('/', auth(['user']), orderCtrl.createOrder);
router.get('/', auth(), orderCtrl.getOrders); // Allowed for all authenticated, but filtered by role
router.get('/:id', auth(), orderCtrl.getOrderById);
router.put('/:id/cancel', auth(['user', 'warehouse_manager', 'admin']), orderCtrl.cancelOrder);
router.put('/:id/return', auth(['user' , 'delivery_agent']), orderCtrl.requestReturn);
router.put('/:id/status', auth(['admin', 'warehouse_manager', 'delivery_agent']), orderCtrl.updateOrderStatus);

module.exports = router;