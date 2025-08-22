const express = require('express');
const router = express.Router();
const productCtrl = require('../controllers/product.controller');
const auth = require('../middleware/auth');

router.post('/', auth(['admin', 'warehouse_manager']), productCtrl.createProduct);
router.get('/', productCtrl.getProducts);
router.get('/:id', productCtrl.getProductById);
router.put('/:id', auth(['admin', 'warehouse_manager']), productCtrl.updateProduct);
router.delete('/:id', auth(['admin', 'warehouse_manager']), productCtrl.deleteProduct);

module.exports = router;