const User = require('../models/user.model');
const Role = require('../models/role.model');
const { generateToken } = require('../config/jwt');

exports.register = async (req, res, next) => {
  try {
    const { username, password, email, roleName } = req.body;

    // Trim input values
    const trimmedUsername = username.trim();
    const trimmedEmail = email.trim();

    // Validate required fields
    if (!trimmedUsername || !password || !trimmedEmail) {
      return res.status(400).json({ msg: 'Username, password, and email are required' });
    }

    // Additional validation (optional)
    if (trimmedUsername.length < 3) {
      return res.status(400).json({ msg: 'Username must be at least 3 characters long' });
    }
    if (password.length < 6) {
      return res.status(400).json({ msg: 'Password must be at least 6 characters long' });
    }
    if (!/\S+@\S+\.\S+/.test(trimmedEmail)) {
      return res.status(400).json({ msg: 'Invalid email format' });
    }

    const role = await Role.findOne({ name: roleName || 'user' });
    if (!role) return res.status(400).json({ msg: 'Invalid role' });

    const existingUser = await User.findOne({ username: trimmedUsername });
    if (existingUser) return res.status(400).json({ msg: 'Username already exists' });

    const existingEmailUser = await User.findOne({ email: trimmedEmail });
    if (existingEmailUser) return res.status(400).json({ msg: 'Email already exists' });

    const user = new User({ username: trimmedUsername, password, email: trimmedEmail, role: role._id });
    await user.save();
    await user.populate('role');
    res.status(201).json({ 
      token: generateToken(user), 
      role: user.role.name,
      username: user.username,
      userId: user._id.toString()
    });
  } catch (error) {
    if (error.code === 11000) {
      const field = Object.keys(error.keyValue)[0];
      return res.status(400).json({ msg: `${field.charAt(0).toUpperCase() + field.slice(1)} already exists` });
    }
    console.error('Registration error:', error.message);
    res.status(500).json({ msg: 'Server error', error: error.message });
  }
};

exports.login = async (req, res, next) => {
  try {
    const { username, password } = req.body;

    // Trim input values
    const trimmedUsername = username.trim();

    // Validate required fields
    if (!trimmedUsername || !password) {
      return res.status(400).json({ msg: 'Username and password are required' });
    }

    const user = await User.findOne({ username: trimmedUsername }).populate('role');
    if (!user || !(await user.comparePassword(password))) {
      return res.status(401).json({ msg: 'Invalid credentials' });
    }
    res.json({ 
      token: generateToken(user), 
      role: user.role.name,
      username: user.username,
      userId: user._id.toString()
    });
  } catch (error) {
    console.error('Login error:', error.message);
    res.status(500).json({ msg: 'Server error', error: error.message });
  }
};