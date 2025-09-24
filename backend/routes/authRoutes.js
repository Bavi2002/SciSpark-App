// Example for `authRoutes.js` in the backend
const express = require('express');
const jwt = require('jsonwebtoken');
const User = require('../models/User'); // Assuming User model is in models
const bcrypt = require('bcryptjs');
const router = express.Router();

// POST route for login
router.post('/login', async (req, res) => {
  const { email, password } = req.body;

  const user = await User.findOne({ email: email });
  if (!user) {
    return res.status(400).json({ message: 'Invalid email or password' });
  }

  const isMatch = await bcrypt.compare(password, user.password);
  if (!isMatch) {
    return res.status(400).json({ message: 'Invalid email or password' });
  }

  const token = jwt.sign({ userId: user._id }, process.env.JWT_SECRET, { expiresIn: '1h' });

  res.json({ token });
});

module.exports = router;
