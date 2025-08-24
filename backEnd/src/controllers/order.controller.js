const Order = require('../models/order.model');
const Product = require('../models/product.model');
const Inventory = require('../models/inventory.model');

exports.createOrder = async (req, res) => {
  const { products, totalAmount } = req.body;

  try {
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

      // Ensure inventory record exists
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
      const inventory = await Inventory.findOne({ product: item.product });
      inventory.quantity -= item.quantity;
      inventory.lastUpdated = new Date();
      await inventory.save();

      const product = await Product.findById(item.product);
      product.stock -= item.quantity;
      await product.save();
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
      query.status = { $in: ['pending', 'processed'] }; // Updated to include both pending and processed
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
    const order = await Order.findById(req.params.id);
    if (!order) return res.status(404).json({ msg: 'Order not found' });

    const userRole = req.user.role.name;
    if (userRole === 'user' && (order.user.toString() !== req.user._id.toString() || order.status !== 'pending')) {
      return res.status(403).json({ msg: 'Cannot cancel' });
    } else if (userRole === 'warehouse_manager' && order.status !== 'pending') {
      return res.status(403).json({ msg: 'Cannot cancel non-pending orders' });
    } else if (!['user', 'warehouse_manager'].includes(userRole)) {
      return res.status(403).json({ msg: 'Access denied' });
    }

    order.status = 'cancelled';
    await order.save();

    // Restore stock
    for (const item of order.products) {
      const inventory = await Inventory.findOne({ product: item.product });
      if (inventory) {
        inventory.quantity += item.quantity;
        inventory.lastUpdated = new Date();
        await inventory.save();
      }
      const product = await Product.findById(item.product);
      if (product) {
        product.stock += item.quantity;
        await product.save();
      }
    }

    res.json(order);
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
      return res.status(403).json({ msg: 'Cannot request return' });
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
    const order = await Order.findById(req.params.id);
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
      'admin': { from: ['pending', 'processed', 'shipped', 'delivered', 'returned', 'cancelled'], to: ['pending', 'processed', 'shipped', 'delivered', 'returned', 'cancelled'] }
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
        const inventory = await Inventory.findOne({ product: item.product });
        if (inventory) {
          inventory.quantity += item.quantity;
          inventory.lastUpdated = new Date();
          await inventory.save();
        }
        const product = await Product.findById(item.product);
        if (product) {
          product.stock += item.quantity;
          await product.save();
        }
      }
    }

    res.json(order);
  } catch (error) {
    console.error('Error updating order status:', error);
    res.status(500).json({ msg: 'Server error while updating order status', error: error.message });
  }
};