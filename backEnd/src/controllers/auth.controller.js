const User = require('../models/user.model');
const Role = require('../models/role.model');
const { generateToken } = require('../config/jwt');

exports.register = async (req, res) => {
  const { username, password, email, roleName } = req.body;
  const role = await Role.findOne({ name: roleName || 'user' });
  if (!role) return res.status(400).json({ msg: 'Invalid role' });

  const existingUser = await User.findOne({ username });
  if (existingUser) return res.status(400).json({ msg: 'User exists' });

  const user = new User({ username, password, email, role: role._id });
  await user.save();
  await user.populate('role');
  res.status(201).json({ token: generateToken(user), role: user.role.name });
};

exports.login = async (req, res) => {
  const { username, password } = req.body;
  const user = await User.findOne({ username }).populate('role');
  if (!user || !(await user.comparePassword(password))) {
    return res.status(401).json({ msg: 'Invalid credentials' });
  }
  res.json({ token: generateToken(user), role: user.role.name });
};