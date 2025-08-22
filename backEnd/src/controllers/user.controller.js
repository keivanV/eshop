const User = require('../models/user.model');
const Role = require('../models/role.model');

exports.getUsers = async (req, res) => {
  const users = await User.find().populate('role');
  res.json(users);
};

exports.getUserById = async (req, res) => {
  const user = await User.findById(req.params.id).populate('role');
  if (!user) return res.status(404).json({ msg: 'User not found' });
  res.json(user);
};

exports.updateUser = async (req, res) => {
  const user = await User.findByIdAndUpdate(req.params.id, req.body, { new: true }).populate('role');
  if (!user) return res.status(404).json({ msg: 'User not found' });
  res.json(user);
};

exports.deleteUser = async (req, res) => {
  const user = await User.findByIdAndDelete(req.params.id);
  if (!user) return res.status(404).json({ msg: 'User not found' });
  res.json({ msg: 'User deleted' });
};

exports.changeRole = async (req, res) => {
  const { roleName } = req.body;
  const role = await Role.findOne({ name: roleName });
  if (!role) return res.status(400).json({ msg: 'Invalid role' });
  const user = await User.findByIdAndUpdate(req.params.id, { role: role._id }, { new: true }).populate('role');
  res.json(user);
};