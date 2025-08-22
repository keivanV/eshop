const express = require('express');
const router = express.Router();
const userCtrl = require('../controllers/user.controller');
const auth = require('../middleware/auth');

router.get('/', auth(['admin']), userCtrl.getUsers);
router.get('/:id', auth(), userCtrl.getUserById); // Removed admin restriction
router.put('/:id', auth(), userCtrl.updateUser); // Removed admin restriction
router.delete('/:id', auth(['admin']), userCtrl.deleteUser);
router.put('/:id/role', auth(['admin']), userCtrl.changeRole);

module.exports = router;