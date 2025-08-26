const mongoose = require('mongoose');
const Order = require('../models/order.model');
const Product = require('../models/product.model');
const Inventory = require('../models/inventory.model');

exports.createOrder = async (req, res) => {
  try {
    const { products, totalAmount } = req.body;

    // Validate request body
    if (!products || !Array.isArray(products) || !totalAmount) {
      return res.status(400).json({ msg: 'Invalid request: products and totalAmount are required' });
    }

    // Check stock availability and ensure inventory exists
    for (const item of products) {
      if (!item.product || !item.quantity || item.quantity <= 0) {
        return res.status(400).json({ msg: 'Invalid product data: product ID and quantity are required' });
      }
      const product = await Product.findById(item.product);
      if (!product) {
        return res.status(404).json({ msg: `Product not found: ${item.product}` });
      }
      if (product.stock < item.quantity) {
        return res.status(400).json({ msg: `Insufficient stock for ${product.name}` });
      }

      let inventory = await Inventory.findOne({ product: item.product });
      if (!inventory) {
        console.log(`Creating inventory for product: ${item.product}, quantity: ${product.stock}`);
        inventory = new Inventory({ product: item.product, quantity: product.stock, lastUpdated: new Date() });
        await inventory.save();
      }
      if (inventory.quantity < item.quantity) {
        return res.status(400).json({ msg: `Insufficient inventory for ${product.name} (Inventory: ${inventory.quantity}, Requested: ${item.quantity})` });
      }
    }

    // Create the order
    const order = new Order({ user: req.user._id, products, totalAmount });
    await order.save();

    // Deduct stock and inventory
    for (const item of products) {
      await Inventory.findOneAndUpdate(
        { product: item.product },
        { $inc: { quantity: -item.quantity }, lastUpdated: new Date() }
      );
      await Product.findByIdAndUpdate(item.product, { $inc: { stock: -item.quantity } });
    }

    res.status(201).json(order);
  } catch (error) {
    console.error('Error creating order:', error);
    res.status(500).json({ msg: 'Server error while creating order', error: error.message });
  }
};

exports.getOrders = async (req, res) => {
  try {
    let query = {};
    const userRole = req.user.role.name;

    if (userRole === 'user') {
      query.user = req.user._id;
    } else if (userRole === 'warehouse_manager') {
      query.status = { $in: ['pending', 'processed'] };
    } else if (userRole === 'delivery_agent') {
      query.status = { $in: ['processed', 'shipped'] };
    } else if (userRole !== 'admin') {
      return res.status(403).json({ msg: 'Access denied' });
    }

    const orders = await Order.find(query).populate('products.product').populate('user');
    res.json(orders);
  } catch (error) {
    console.error('Error fetching orders:', error);
    res.status(500).json({ msg: 'Server error while fetching orders', error: error.message });
  }
};

exports.getOrderById = async (req, res) => {
  try {
    const order = await Order.findById(req.params.id).populate('products.product').populate('user');
    if (!order) return res.status(404).json({ msg: 'Order not found' });
    if (req.user.role.name !== 'admin' && order.user._id.toString() !== req.user._id.toString()) {
      return res.status(403).json({ msg: 'Access denied' });
    }
    res.json(order);
  } catch (error) {
    console.error('Error fetching order by ID:', error);
    res.status(500).json({ msg: 'Server error while fetching order', error: error.message });
  }
};

exports.cancelOrder = async (req, res) => {
  try {
    console.log(`Attempting to cancel order ${req.params.id} by user ${req.user._id} with role ${req.user.role.name}`);
    const order = await Order.findById(req.params.id).populate('products.product');
    if (!order) {
      console.log(`Order ${req.params.id} not found`);
      return res.status(404).json({ msg: 'Order not found' });
    }

    const userRole = req.user.role.name;
    console.log(`Order status: ${order.status}, User role: ${userRole}`);
    if (userRole === 'user' && (order.user.toString() !== req.user._id.toString() || order.status !== 'pending')) {
      console.log(`Access denied for user: userId mismatch or status is ${order.status}`);
      return res.status(403).json({ msg: 'Cannot cancel: Only pending orders owned by the user can be cancelled' });
    } else if (['warehouse_manager', 'admin'].includes(userRole) && order.status !== 'pending') {
      console.log(`Access denied for ${userRole}: status is ${order.status}`);
      return res.status(403).json({ msg: 'Cannot cancel: Only pending orders can be cancelled' });
    } else if (!['user', 'warehouse_manager', 'admin'].includes(userRole)) {
      console.log(`Access denied: Insufficient permissions for role ${userRole}`);
      return res.status(403).json({ msg: 'Access denied: Insufficient permissions' });
    }

    // Update order status to cancelled
    order.status = 'cancelled';
    await order.save();
    console.log(`Order ${order._id} status updated to cancelled`);

    // Restore stock and inventory
    for (const item of order.products) {
      if (!item.product) {
        console.warn(`Product not found for item: ${item.product}`);
        continue;
      }

      // Update inventory
      let inventory = await Inventory.findOne({ product: item.product._id });
      if (!inventory) {
        console.log(`Creating inventory record for product: ${item.product._id}`);
        inventory = new Inventory({ product: item.product._id, quantity: 0, lastUpdated: new Date() });
      }
      inventory.quantity += item.quantity;
      inventory.lastUpdated = new Date();
      await inventory.save();
      console.log(`Restored ${item.quantity} to inventory for product: ${item.product.name}`);

      // Update product stock
      await Product.findByIdAndUpdate(item.product._id, { $inc: { stock: item.quantity } });
      console.log(`Restored ${item.quantity} to stock for product: ${item.product.name}`);
    }

    res.json({ msg: 'Order cancelled successfully', order });
  } catch (error) {
    console.error('Error cancelling order:', error);
    res.status(500).json({ msg: 'Server error while cancelling order', error: error.message });
  }
};

exports.requestReturn = async (req, res) => {
  try {
    const order = await Order.findById(req.params.id);
    if (!order) return res.status(404).json({ msg: 'Order not found' });
    if (order.user.toString() !== req.user._id.toString() || order.status !== 'delivered') {
      return res.status(403).json({ msg: 'Cannot request return: Only delivered orders can be returned' });
    }
    order.returnRequest = true;
    await order.save();
    res.json(order);
  } catch (error) {
    console.error('Error requesting return:', error);
    res.status(500).json({ msg: 'Server error while requesting return', error: error.message });
  }
};

exports.updateOrderStatus = async (req, res) => {
  try {
    const { status } = req.body;
    const order = await Order.findById(req.params.id).populate('products.product');
    if (!order) return res.status(404).json({ msg: 'Order not found' });

    const userRole = req.user.role.name;
    const allowedTransitions = {
      'warehouse_manager': {
        from: ['pending'],
        to: ['processed', 'cancelled']
      },
      'delivery_agent': {
        from: ['processed', 'shipped'],
        to: ['delivered', 'returned']
      },
      'admin': {
        from: ['pending', 'processed', 'shipped', 'delivered', 'returned', 'cancelled'],
        to: ['pending', 'processed', 'shipped', 'delivered', 'returned', 'cancelled']
      }
    };

    if (!allowedTransitions[userRole] || !allowedTransitions[userRole].from.includes(order.status) || !allowedTransitions[userRole].to.includes(status)) {
      return res.status(403).json({ msg: 'Access denied or invalid status transition' });
    }

    if (status === 'returned' && !order.returnRequest) {
      return res.status(403).json({ msg: 'Cannot return without request' });
    }

    order.status = status;
    await order.save();

    if (status === 'returned') {
      // Restore stock for returned items
      for (const item of order.products) {
        const product = item.product;
        if (!product) {
          console.warn(`Product not found for item: ${item.product}`);
          continue;
        }

        let inventory = await Inventory.findOne({ product: item.product._id });
        if (!inventory) {
          console.log(`Creating inventory record for product: ${item.product._id}`);
          inventory = new Inventory({ product: item.product._id, quantity: 0, lastUpdated: new Date() });
        }
        inventory.quantity += item.quantity;
        inventory.lastUpdated = new Date();
        await inventory.save();
        console.log(`Restored ${item.quantity} to inventory for product: ${product.name}`);

        await Product.findByIdAndUpdate(item.product._id, { $inc: { stock: item.quantity } });
        console.log(`Restored ${item.quantity} to stock for product: ${product.name}`);
      }
    }

    res.json(order);
  } catch (error) {
    console.error('Error updating order status:', error);
    res.status(500).json({ msg: 'Server error while updating order status', error: error.message });
  }
};