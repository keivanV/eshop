const Product = require('../models/product.model');
const Inventory = require('../models/inventory.model');
const multer = require('multer');
const path = require('path');
const fs = require('fs').promises;

const storage = multer.diskStorage({
  destination: async (req, file, cb) => {
    const productId = req.params.id;
    const uploadPath = path.join('uploads', productId);
    try {
      await fs.mkdir(uploadPath, { recursive: true });
      cb(null, uploadPath);
    } catch (error) {
      console.error('Error creating directory:', error);
      cb(new Error('Failed to create upload directory'), null);
    }
  },
  filename: (req, file, cb) => {
    cb(null, `${Date.now()}-${file.originalname}`);
  }
});

const upload = multer({
  storage,
  fileFilter: (req, file, cb) => {
    console.log('File received:', {
      originalname: file.originalname,
      mimetype: file.mimetype,
      extname: path.extname(file.originalname).toLowerCase()
    });
    const filetypes = /jpeg|jpg|png/i;
    const extname = filetypes.test(path.extname(file.originalname).toLowerCase());
    const mimetype = filetypes.test(file.mimetype.toLowerCase()) ||
                     file.mimetype.toLowerCase().includes('image/png') ||
                     file.mimetype.toLowerCase().includes('image/jpeg');
    if (extname && mimetype) {
      return cb(null, true);
    }
    cb(new Error('Only JPEG, JPG, and PNG images are allowed'));
  },
  limits: { fileSize: 5 * 1024 * 1024 }
}).array('images', 5);

exports.createProduct = async (req, res) => {
  try {
    const { name, price, category, stock, imageUrls } = req.body;
    if (!name || !price || !category || stock === undefined) {
      return res.status(400).json({ message: 'Missing required fields: name, price, category, stock' });
    }
    const parsedStock = parseInt(stock, 10);
    if (isNaN(parsedStock) || parsedStock < 0) {
      return res.status(400).json({ message: 'Invalid stock value' });
    }
    const product = new Product({
      name,
      price: parseFloat(price),
      category,
      stock: parsedStock,
      imageUrls: imageUrls || []
    });
    await product.save();
    console.log(`Product created: ${product._id}`);

    // Create or update inventory record
    let inventory = await Inventory.findOne({ product: product._id });
    if (!inventory) {
      inventory = new Inventory({ product: product._id, quantity: parsedStock });
    } else {
      inventory.quantity = parsedStock;
    }
    inventory.lastUpdated = new Date();
    await inventory.save();
    console.log(`Inventory created/updated for product: ${product._id}, quantity: ${inventory.quantity}`);

    res.status(201).json(product);
  } catch (error) {
    console.error('Error creating product:', error);
    res.status(400).json({ message: 'Error creating product', error: error.message });
  }
};

exports.getProducts = async (req, res) => {
  try {
    const products = await Product.find().populate('category');
    res.json(products);
  } catch (error) {
    console.error('Error fetching products:', error);
    res.status(500).json({ message: 'Error fetching products', error: error.message });
  }
};

exports.getProductById = async (req, res) => {
  try {
    const product = await Product.findById(req.params.id).populate('category');
    if (!product) return res.status(404).json({ message: 'Product not found' });
    res.json(product);
  } catch (error) {
    console.error('Error fetching product:', error);
    res.status(500).json({ message: 'Error fetching product', error: error.message });
  }
};

exports.updateProduct = async (req, res) => {
  try {
    const { name, price, category, stock, imageUrls } = req.body;
    const product = await Product.findById(req.params.id);
    if (!product) return res.status(404).json({ message: 'Product not found' });

    // Update product fields
    product.name = name || product.name;
    product.price = price !== undefined ? parseFloat(price) : product.price;
    product.category = category || product.category;
    const parsedStock = stock !== undefined ? parseInt(stock, 10) : product.stock;
    if (stock !== undefined && (isNaN(parsedStock) || parsedStock < 0)) {
      return res.status(400).json({ message: 'Invalid stock value' });
    }
    product.stock = parsedStock;
    product.imageUrls = Array.isArray(imageUrls)
      ? imageUrls.filter(url => url.startsWith(`/uploads/${req.params.id}/`))
      : product.imageUrls;
    await product.save();

    // Sync inventory
    let inventory = await Inventory.findOne({ product: product._id });
    if (!inventory) {
      inventory = new Inventory({ product: product._id, quantity: product.stock });
    } else {
      inventory.quantity = product.stock;
    }
    inventory.lastUpdated = new Date();
    await inventory.save();
    console.log(`Inventory updated for product: ${product._id}, quantity: ${inventory.quantity}`);

    res.json(product);
  } catch (error) {
    console.error('Error updating product:', error);
    res.status(500).json({ message: 'Error updating product', error: error.message });
  }
};

exports.deleteProduct = async (req, res) => {
  try {
    const product = await Product.findById(req.params.id);
    if (!product) return res.status(404).json({ message: 'Product not found' });
    await Product.findByIdAndDelete(req.params.id);
    await Inventory.findOneAndDelete({ product: req.params.id });
    const uploadPath = path.join('uploads', req.params.id);
    await fs.rm(uploadPath, { recursive: true, force: true });
    res.json({ message: 'Product deleted' });
  } catch (error) {
    console.error('Error deleting product:', error);
    res.status(500).json({ message: 'Error deleting product', error: error.message });
  }
};

exports.uploadProductImages = async (req, res) => {
  try {
    console.log('Request URL:', req.originalUrl);
    console.log('Request Headers:', req.headers);
    console.log('Product ID:', req.params.id);

    const productId = req.params.id;
    if (!productId.match(/^[0-9a-fA-F]{24}$/)) {
      return res.status(400).json({ message: 'Invalid product ID format' });
    }

    const product = await Product.findById(productId);
    if (!product) {
      return res.status(404).json({ message: 'Product not found' });
    }

    upload(req, res, async (err) => {
      if (err) {
        console.error('Multer error:', err.message);
        return res.status(400).json({ message: 'Error uploading images', error: err.message });
      }
      if (!req.files || req.files.length === 0) {
        return res.status(400).json({ message: 'No images provided' });
      }

      const imageUrls = req.files.map(file => `/uploads/${productId}/${file.filename}`);
      product.imageUrls = [...(product.imageUrls || []), ...imageUrls];
      await product.save();
      res.status(200).json({ message: 'Images uploaded successfully', imageUrls: product.imageUrls });
    });
  } catch (error) {
    console.error('Upload error:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};