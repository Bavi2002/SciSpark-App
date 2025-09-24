const express = require('express');
const jwt = require('jsonwebtoken');
const User = require('../models/User'); // Your User model
const router = express.Router();

// GET Parent Dashboard Data
router.get('/dashboard', async (req, res) => {
  const token = req.header('Authorization').replace('Bearer ', '');

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const user = await User.findById(decoded.userId)
      .populate('progress.experimentId'); // Include experiment details

    if (!user) return res.status(404).json({ message: 'User not found' });

    // Format the response
    const dashboardData = user.progress.map(p => ({
      experimentName: p.experimentId.title,
      status: p.status,
      badges: p.badgesEarned || [],
    }));

    res.json(dashboardData);
  } catch (err) {
    res.status(401).json({ message: 'Not authorized' });
  }
});

module.exports = router;
