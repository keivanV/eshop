const express = require('express');
const router = express.Router();
const inventoryCtrl = require('../controllers/inventory.controller');
const auth = require('../middleware/auth');

router.put('/', auth(['admin', 'warehouse_manager']), inventoryCtrl.updateInventory);
router.get('/', auth(['admin', 'warehouse_manager']), inventoryCtrl.getInventory);
router.get('/:productId', auth(['admin', 'warehouse_manager']), inventoryCtrl.getInventoryByProduct);

module.exports = router;