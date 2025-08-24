
const Product = require('../models/product.model');
const Inventory = require('../models/inventory.model');

const initializeInventory = async () => {
  try {
    const products = await Product.find();
    for (const product of products) {
      const inventory = await Inventory.findOne({ product: product._id });
      if (!inventory) {
        await Inventory.create({ product: product._id, quantity: product.stock });
        console.log(`Created inventory for product: ${product.name}`);
      }
    }
    console.log('Inventory initialization completed');
  } catch (error) {
    console.error('Error initializing inventory:', error);
  }
};

module.exports = { initializeInventory };
