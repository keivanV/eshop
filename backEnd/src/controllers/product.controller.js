const Product = require('../models/product.model');
const multer = require('multer');
const path = require('path');

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/');
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

    const filetypes = /jpeg|jpg|png/i; // Case-insensitive regex
    const extname = filetypes.test(path.extname(file.originalname).toLowerCase());
    const mimetype = filetypes.test(file.mimetype.toLowerCase()) || file.mimetype.toLowerCase().includes('image/png') || file.mimetype.toLowerCase().includes('image/jpeg');

    if (extname && mimetype) {
      return cb(null, true);
    }
    cb(new Error('Only JPEG, JPG, and PNG images are allowed'));
  },
  limits: { fileSize: 5 * 1024 * 1024 } // 5MB limit
}).array('images', 5);

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

      const imageUrls = req.files.map(file => `/uploads/${file.filename}`);
      product.imageUrls = [...(product.imageUrls || []), ...imageUrls];
      await product.save();
      res.status(200).json({ message: 'Images uploaded successfully', imageUrls: product.imageUrls });
    });
  } catch (error) {
    console.error('Upload error:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

exports.createProduct = async (req, res) => {
  try {
    const { _id, ...productData } = req.body;
    const product = new Product({ ...productData, imageUrls: [] });
    await product.save();
    res.status(201).json(product);
  } catch (error) {
    res.status(400).json({ message: 'Error creating product', error: error.message });
  }
};

exports.getProducts = async (req, res) => {
  try {
    const products = await Product.find().populate('category');
    res.json(products);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching products', error: error.message });
  }
};

exports.getProductById = async (req, res) => {
  try {
    const product = await Product.findById(req.params.id).populate('category');
    if (!product) return res.status(404).json({ message: 'Product not found' });
    res.json(product);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching product', error: error.message });
  }
};

exports.updateProduct = async (req, res) => {
  try {
    const product = await Product.findByIdAndUpdate(req.params.id, { ...req.body, imageUrls: req.body.imageUrls || [] }, { new: true }).populate('category');
    if (!product) return res.status(404).json({ message: 'Product not found' });
    res.json(product);
  } catch (error) {
    res.status(500).json({ message: 'Error updating product', error: error.message });
  }
};

exports.deleteProduct = async (req, res) => {
  try {
    const product = await Product.findByIdAndDelete(req.params.id);
    if (!product) return res.status(404).json({ message: 'Product not found' });
    res.json({ message: 'Product deleted' });
  } catch (error) {
    res.status(500).json({ message: 'Error deleting product', error: error.message });
  }
};