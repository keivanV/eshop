const express = require('express');
const router = express.Router();
const categoryCtrl = require('../controllers/category.controller');
const auth = require('../middleware/auth');

router.post('/', auth(['admin', 'warehouse_manager']), categoryCtrl.createCategory);
router.get('/', categoryCtrl.getCategories);
router.get('/:id', categoryCtrl.getCategoryById);
router.put('/:id', auth(['admin', 'warehouse_manager']), categoryCtrl.updateCategory);
router.delete('/:id', auth(['admin', 'warehouse_manager']), categoryCtrl.deleteCategory);

module.exports = router;