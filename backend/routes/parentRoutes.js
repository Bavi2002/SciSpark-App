const express = require('express');
const User = require('../models/User');
const authMiddleware = require('../middleware/authMiddleware');
const router = express.Router();

// Get parent dashboard data (user's progress)
router.get('/dashboard', authMiddleware, async (req, res) => {
  try {
    const user = await User.findById(req.user._id).populate('progress.experimentId');
    res.json(user.progress);
  } catch (error) {
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;
