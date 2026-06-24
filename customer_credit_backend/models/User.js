const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  username: {
    type: String,
    required: true,
    unique: true,
    trim: true,
  },
  email: {
    type: String,
    required: true,
    unique: true,
    lowercase: true,
    trim: true,
  },
  password: {
    type: String,
    required: true,
  },
  role: {
    type: String,
    enum: ['admin', 'approved', 'pending'],
    default: 'pending',
  },
  resetCode: {
    type: String,
  },
  resetCodeExpiry: {
    type: Date,
  }
}, { timestamps: true });

const User = mongoose.model('User', userSchema);
module.exports = User;
