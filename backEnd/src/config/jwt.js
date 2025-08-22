const jwt = require('jsonwebtoken');

module.exports = {
  generateToken: (user) => {
    return jwt.sign(
      { id: user._id, role: user.role.name }, // Assuming role populated
      process.env.SECRET_KEY,
      { expiresIn: '1h' }
    );
  },
  verifyToken: (token) => {
    return jwt.verify(token, process.env.SECRET_KEY);
  },
};