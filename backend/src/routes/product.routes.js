const express = require('express');
const router = express.Router();
const { createProduct, getAllProducts, getProductById, updateProduct, deleteProduct, getPendingProducts, approveProduct, rejectProduct} = require('@/controllers/product.controller');
const { authMiddleware } = require('@/middleware/auth.middleware');
const { roleMiddleware } = require('@/middleware/role.middleware');
const {upload} = require('@/middleware/image.up.middleware');


router.post('/create', authMiddleware, upload.single('image'), createProduct);
router.put('/update/:id', authMiddleware, updateProduct);
router.delete('/delete/:id', authMiddleware, deleteProduct);
//buat admin
router.get('/pending', authMiddleware, roleMiddleware, getPendingProducts);
router.put('/:id/approve', authMiddleware, roleMiddleware, approveProduct);
router.put('/:id/reject', authMiddleware, roleMiddleware, rejectProduct);

//ini buat public/user
router.get('/products', getAllProducts);
router.get('/:id', getProductById);



module.exports = router;