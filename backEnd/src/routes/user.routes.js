const express = require('express');
const router = express.Router();
const userCtrl = require('../controllers/user.controller');
const auth = require('../middleware/auth');

router.get('/', auth(['admin']), userCtrl.getUsers);
router.get('/:id', auth(), userCtrl.getUserById);
router.put('/:id', auth(), userCtrl.updateUser); 
router.get('/username/:username', auth(), userCtrl.getUserByUsername);
router.delete('/:id', auth(['admin']), userCtrl.deleteUser);
router.put('/:id/role', auth(['admin']), userCtrl.changeRole);

module.exports = router;