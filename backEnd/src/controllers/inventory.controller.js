const Inventory = require('../models/inventory.model');
const Product = require('../models/product.model');

exports.updateInventory = async (req, res) => {
  const { productId, quantity } = req.body;
  let inventory = await Inventory.findOne({ product: productId });
  if (!inventory) {
    inventory = new Inventory({ product: productId, quantity });
  } else {
    inventory.quantity += quantity;
  }
  await inventory.save();

  // Sync with product stock
  const product = await Product.findById(productId);
  product.stock = inventory.quantity;
  await product.save();

  res.json(inventory);
};

exports.getInventory = async (req, res) => {
  const inventory = await Inventory.find().populate('product');
  res.json(inventory);
};

exports.getInventoryByProduct = async (req, res) => {
  const inventory = await Inventory.findOne({ product: req.params.productId }).populate('product');
  if (!inventory) return res.status(404).json({ msg: 'Inventory not found' });
  res.json(inventory);
};