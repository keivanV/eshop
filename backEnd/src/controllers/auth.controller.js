const User = require('../models/user.model');
const Role = require('../models/role.model');
const { generateToken } = require('../config/jwt');

exports.register = async (req, res, next) => {
  try {
    const { username, password, email, roleName } = req.body;

    // Validate required fields
    if (!username || !password || !email) {
      return res.status(400).json({ msg: 'Username, password, and email are required' });
    }

    // Additional validation (optional)
    if (username.length < 3) {
      return res.status(400).json({ msg: 'Username must be at least 3 characters long' });
    }
    if (password.length < 6) {
      return res.status(400).json({ msg: 'Password must be at least 6 characters long' });
    }
    if (!/\S+@\S+\.\S+/.test(email)) {
      return res.status(400).json({ msg: 'Invalid email format' });
    }

    const role = await Role.findOne({ name: roleName || 'user' });
    if (!role) return res.status(400).json({ msg: 'Invalid role' });

    const existingUser = await User.findOne({ username });
    if (existingUser) return res.status(400).json({ msg: 'User exists' });

    const user = new User({ username, password, email, role: role._id });
    await user.save();
    await user.populate('role');
    res.status(201).json({ token: generateToken(user), role: user.role.name });
  } catch (error) {
    next(error); // Pass to global error handler
  }
};

exports.login = async (req, res, next) => {
  try {
    const { username, password } = req.body;

    // Validate required fields
    if (!username || !password) {
      return res.status(400).json({ msg: 'Username and password are required' });
    }

    const user = await User.findOne({ username }).populate('role');
    if (!user || !(await user.comparePassword(password))) {
      return res.status(401).json({ msg: 'Invalid credentials' });
    }
    res.json({ token: generateToken(user), role: user.role.name });
  } catch (error) {
    next(error); // Pass to global error handler
  }
};