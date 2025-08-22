const Role = require('../models/role.model');
const User = require('../models/user.model');

const seedRolesAndAdmin = async () => {
  const roles = ['admin', 'warehouse_manager', 'delivery_agent', 'user'];
  for (const name of roles) {
    const existingRole = await Role.findOne({ name });
    if (!existingRole) {
      await new Role({ name }).save();
      console.log(`Role ${name} created`);
    }
  }

  const adminRole = await Role.findOne({ name: 'admin' });
  const admin = await User.findOne({ username: 'admin' });
  if (!admin) {
    const user = new User({
      username: 'admin',
      password: 'admin', // Will be hashed
      email: 'admin@example.com',
      role: adminRole._id,
    });
    await user.save();
    console.log('Default admin created: username=admin, password=admin');
  }
};

module.exports = { seedRolesAndAdmin };