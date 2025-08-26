const mongoose = require('mongoose');
const User = require('../models/user.model');
const Role = require('../models/role.model');
const bcrypt = require('bcryptjs');

exports.getUsers = async (req, res) => {
  try {
    const users = await User.find().populate('role');
    res.json(users);
  } catch (error) {
    console.error('Error fetching users:', error.message);
    res.status(500).json({ msg: 'Server error', error: error.message });
  }
};

exports.getUserById = async (req, res) => {
  try {
    const user = await User.findById(req.params.id).populate('role');
    if (!user) return res.status(404).json({ msg: 'User not found' });
    res.json({
      _id: user._id.toString(),
      username: user.username,
      email: user.email,
      role: user.role ? user.role.name : null
    });
  } catch (error) {
    console.error('Error fetching user by ID:', error.message);
    res.status(500).json({ msg: 'Server error', error: error.message });
  }
};

exports.getUserByUsername = async (req, res) => {
  try {
    const user = await User.findOne({ username: req.params.username }).populate('role');
    if (!user) return res.status(404).json({ msg: 'User not found' });
    res.json({
      _id: user._id.toString(),
      username: user.username,
      email: user.email,
      role: user.role ? user.role.name : null
    });
  } catch (error) {
    console.error('Error fetching user by username:', error.message);
    res.status(500).json({ msg: 'Server error', error: error.message });
  }
};

exports.updateUser = async (req, res) => {
  try {
    const { id } = req.params;
    const { email, password } = req.body;

    // Check if the user is updating their own account
    if (req.user.id !== id) {
      console.log(`Unauthorized attempt to update user ${id} by user ${req.user.id}`);
      return res.status(403).json({ msg: 'You can only update your own account' });
    }

    console.log(`Updating user with ID: ${id}`); // Debug log

    // Validate ID format
    if (!mongoose.Types.ObjectId.isValid(id)) {
      console.log(`Invalid user ID format: ${id}`);
      return res.status(400).json({ msg: 'Invalid user ID format' });
    }

    const trimmedEmail = email ? email.trim() : null;
    const trimmedPassword = password ? password.trim() : null;

    const updateData = {};
    if (trimmedEmail) {
      const existingEmail = await User.findOne({ email: trimmedEmail, _id: { $ne: id } });
      if (existingEmail) {
        console.log(`Email already taken: ${trimmedEmail}`);
        return res.status(400).json({ msg: 'Email already taken' });
      }
      updateData.email = trimmedEmail;
    }
    if (trimmedPassword) {
      if (typeof trimmedPassword !== 'string' || trimmedPassword.length < 6) {
        console.log(`Invalid password: ${trimmedPassword}`);
        return res.status(400).json({ msg: 'Password must be a string and at least 6 characters long' });
      }
      updateData.password = await bcrypt.hash(trimmedPassword, 10);
      console.log(`Hashed password for user ${id}`);
    }

    if (Object.keys(updateData).length === 0) {
      console.log('No changes provided');
      return res.status(400).json({ msg: 'No changes provided' });
    }

    // Update user
    const updatedUser = await User.findByIdAndUpdate(
      id,
      { $set: updateData },
      { new: true }
    ).populate('role');

    if (!updatedUser) {
      console.log(`User not found for ID: ${id}`);
      return res.status(404).json({ msg: 'User not found' });
    }

    console.log(`User updated successfully: ${updatedUser._id}`);
    res.json({
      _id: updatedUser._id.toString(),
      username: updatedUser.username,
      email: updatedUser.email,
      role: updatedUser.role ? updatedUser.role.name : null
    });
  } catch (error) {
    console.error('Update user error:', error.message);
    if (error.code === 11000) {
      const field = Object.keys(error.keyValue)[0];
      return res.status(400).json({ msg: `${field.charAt(0).toUpperCase() + field.slice(1)} already taken` });
    }
    res.status(500).json({ msg: 'Server error', error: error.message });
  }
};

exports.deleteUser = async (req, res) => {
  try {
    const user = await User.findByIdAndDelete(req.params.id);
    if (!user) return res.status(404).json({ msg: 'User not found' });
    res.json({ msg: 'User deleted' });
  } catch (error) {
    console.error('Error deleting user:', error.message);
    res.status(500).json({ msg: 'Server error', error: error.message });
  }
};

exports.changeRole = async (req, res) => {
  try {
    const { roleName } = req.body;
    if (!roleName) {
      return res.status(400).json({ msg: 'Role name is required' });
    }
    const role = await Role.findOne({ name: roleName });
    if (!role) {
      console.log(`Role not found: ${roleName}`);
      return res.status(400).json({ msg: 'Invalid role' });
    }
    const user = await User.findByIdAndUpdate(
      req.params.id,
      { role: role._id },
      { new: true }
    ).populate('role');
    if (!user) {
      console.log(`User not found for ID: ${req.params.id}`);
      return res.status(404).json({ msg: 'User not found' });
    }
    console.log(`User role updated successfully: ${user._id} to ${roleName}`);
    res.json({
      _id: user._id.toString(),
      username: user.username,
      email: user.email,
      role: user.role ? user.role.name : null
    });
  } catch (error) {
    console.error('Error changing user role:', error.message);
    res.status(500).json({ msg: 'Server error', error: error.message });
  }
};