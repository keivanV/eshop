const Order = require('../models/order.model');
const Product = require('../models/product.model');
const Inventory = require('../models/inventory.model');

exports.createOrder = async (req, res) => {
  const { products, totalAmount } = req.body;
  // Check stock
  for (const item of products) {
    const product = await Product.findById(item.product);
    if (product.stock < item.quantity) return res.status(400).json({ msg: `Insufficient stock for ${product.name}` });
  }
  const order = new Order({ user: req.user._id, products, totalAmount });
  await order.save();

  // Deduct stock
  for (const item of products) {
    const inventory = await Inventory.findOne({ product: item.product });
    inventory.quantity -= item.quantity;
    await inventory.save();
    const product = await Product.findById(item.product);
    product.stock -= item.quantity;
    await product.save();
  }

  res.status(201).json(order);
};

exports.getOrders = async (req, res) => {
  let query = {};
  if (req.user.role.name === 'user') query.user = req.user._id;
  const orders = await Order.find(query).populate('products.product').populate('user');
  res.json(orders);
};

exports.getOrderById = async (req, res) => {
  const order = await Order.findById(req.params.id).populate('products.product').populate('user');
  if (!order) return res.status(404).json({ msg: 'Order not found' });
  if (req.user.role.name !== 'admin' && order.user._id.toString() !== req.user._id.toString()) {
    return res.status(403).json({ msg: 'Access denied' });
  }
  res.json(order);
};

exports.cancelOrder = async (req, res) => {
  const order = await Order.findById(req.params.id);
  if (!order) return res.status(404).json({ msg: 'Order not found' });
  if (order.user.toString() !== req.user._id.toString() || order.status !== 'pending') {
    return res.status(403).json({ msg: 'Cannot cancel' });
  }
  order.status = 'cancelled';
  await order.save();

  // Restore stock
  for (const item of order.products) {
    const inventory = await Inventory.findOne({ product: item.product });
    inventory.quantity += item.quantity;
    await inventory.save();
    const product = await Product.findById(item.product);
    product.stock += item.quantity;
    await product.save();
  }

  res.json(order);
};

exports.requestReturn = async (req, res) => {
  const order = await Order.findById(req.params.id);
  if (!order) return res.status(404).json({ msg: 'Order not found' });
  if (order.user.toString() !== req.user._id.toString() || order.status !== 'delivered') {
    return res.status(403).json({ msg: 'Cannot request return' });
  }
  order.returnRequest = true;
  await order.save();
  res.json(order);
};

exports.updateOrderStatus = async (req, res) => {
  const { status } = req.body;
  const order = await Order.findById(req.params.id);
  if (!order) return res.status(404).json({ msg: 'Order not found' });

  const userRole = req.user.role.name;
  if (userRole === 'admin') {
    // Admin can update to any status
    order.status = status;
  } else if (userRole === 'warehouse_manager' && ['processed', 'shipped'].includes(status)) {
    order.status = status;
  } else if (userRole === 'delivery_agent' && status === 'delivered') {
    order.status = status;
  } else if (userRole === 'warehouse_manager' && status === 'returned' && order.returnRequest) {
    order.status = status;
    // Restore stock for returned
    for (const item of order.products) {
      const inventory = await Inventory.findOne({ product: item.product });
      inventory.quantity += item.quantity;
      await inventory.save();
      const product = await Product.findById(item.product);
      product.stock += item.quantity;
      await product.save();
    }
  } else {
    return res.status(403).json({ msg: 'Access denied' });
  }
  await order.save();
  res.json(order);
};