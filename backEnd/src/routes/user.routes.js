const express = require('express');
const router = express.Router();
const userCtrl = require('../controllers/user.controller');
const auth = require('../middleware/auth');

router.get('/', auth(['admin']), userCtrl.getUsers);
router.get('/:id', auth(['admin']), userCtrl.getUserById);
router.put('/:id', auth(['admin']), userCtrl.updateUser);
router.delete('/:id', auth(['admin']), userCtrl.deleteUser);
router.put('/:id/role', auth(['admin']), userCtrl.changeRole);

module.exports = router;