const { verifyToken } = require('../config/jwt');
const User = require('../models/user.model');

module.exports = (allowedRoles = []) => async (req, res, next) => {
  const token = req.header('Authorization')?.replace('Bearer ', '');
  if (!token) return res.status(401).json({ msg: 'No token' });

  try {
    const decoded = verifyToken(token);
    const user = await User.findById(decoded.id).populate('role');
    if (!user) return res.status(401).json({ msg: 'Invalid user' });
    req.user = user;

    // Allow users to access their own data if req.params.id matches req.user.id
    if (req.params.id && req.params.id === decoded.id) {
      return next();
    }

    // Check allowed roles for other cases
    if (allowedRoles.length && !allowedRoles.includes(user.role.name)) {
      return res.status(403).json({ msg: 'Access denied' });
    }
    next();
  } catch (err) {
    res.status(401).json({ msg: 'Invalid token' });
  }
};