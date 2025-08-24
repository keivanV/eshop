const Inventory = require('../models/inventory.model');
const Product = require('../models/product.model');

exports.updateInventory = async (req, res) => {
  try {
    const { productId, quantity } = req.body;
    console.log(`Updating inventory for product: ${productId}, quantity: ${quantity}`);
    let inventory = await Inventory.findOne({ product: productId });
    if (!inventory) {
      inventory = new Inventory({
        product: productId,
        quantity,
        lastUpdated: new Date(),
      });
    } else {
      inventory.quantity = quantity;
      inventory.lastUpdated = new Date();
    }
    await inventory.save();
    console.log(`Inventory updated for product: ${productId}`);
    res.json(inventory);
  } catch (err) {
    console.error(`Error updating inventory: ${err}`);
    res.status(500).json({ msg: 'Server error' });
  }
};

exports.getInventory = async (req, res) => {
  try {
    console.log('Fetching all inventory records');
    const inventory = await Inventory.find().populate('product');
    console.log(`Found ${inventory.length} inventory records`);
    res.json(inventory);
  } catch (err) {
    console.error(`Error fetching inventory: ${err}`);
    res.status(500).json({ msg: 'Server error' });
  }
};

exports.getInventoryByProduct = async (req, res) => {
  try {
    console.log(`Fetching inventory for product: ${req.params.productId}`);
    const inventory = await Inventory.findOne({ product: req.params.productId });
    console.log(`Inventory found: ${JSON.stringify(inventory)}`);
    if (!inventory) {
      console.log(`No inventory found for product: ${req.params.productId}`);
      const newInventory = new Inventory({
        product: req.params.productId,
        quantity: 0,
        lastUpdated: new Date(),
      });
      await newInventory.save();
      console.log(`Created default inventory for product: ${req.params.productId}`);
      return res.json(newInventory);
    }
    res.json(inventory);
  } catch (err) {
    console.error(`Error fetching inventory for product ${req.params.productId}: ${err}`);
    res.status(500).json({ msg: 'Server error' });
  }
};