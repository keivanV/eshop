const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const dotenv = require('dotenv');
const path = require('path');

dotenv.config();

const app = express();

// Middleware
app.use(cors({ origin: '*' })); // Allow all origins for testing; restrict in production
app.use(express.json());
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Routes
app.use('/api/auth', require('./routes/auth.routes'));
app.use('/api/categories', require('./routes/category.routes'));
app.use('/api/inventory', require('./routes/inventory.routes'));
app.use('/api/orders', require('./routes/order.routes'));
app.use('/api/products', require('./routes/product.routes'));
app.use('/api/users', require('./routes/user.routes'));

// DB Connection
require('./config/db')();

// Seed roles and admin on startup
const { seedRolesAndAdmin } = require('./utils/seed');
seedRolesAndAdmin();

// 404 Handler
app.use((req, res, next) => {
  res.status(404).json({ message: `Cannot ${req.method} ${req.originalUrl}` });
});

// Error Handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ message: 'Server error', error: err.message });
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));