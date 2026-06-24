const express = require('express');
const router = express.Router();
const {
  signup,
  login,
  forgotPassword,
  resetPassword,
  getAllUsers,
  updateUserRole,
} = require('../controllers/authController');
const { protect, adminOnly } = require('../middleware/authMiddleware');

router.post('/signup', signup);
router.post('/login', login);
router.post('/forgot-password', forgotPassword);
router.post('/reset-password', resetPassword);

// Admin Routes for User Approval
router.get('/users', protect, adminOnly, getAllUsers);
router.patch('/users/:id/role', protect, adminOnly, updateUserRole);

module.exports = router;
