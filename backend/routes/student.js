import express from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import {auth, authorizeRole} from '../middleware/auth.js';
import Student from '../models/Student.js';
import Experiment from '../models/Experiment.js';
import Progress from '../models/Progress.js';
import Achievement from '../models/Achievement.js';

const router = express.Router();

// Start experiment
router.post('/progress/start', auth, authorizeRole(['student']), async (req, res) => {
  const { experimentId } = req.body;
  try {
    const experiment = await Experiment.findById(experimentId);
    if (!experiment) {
      return res.status(404).json({ message: 'Experiment not found' });
    }

    let progress = await Progress.findOne({ studentId: req.user.id, experimentId });
    if (progress) {
      return res.status(400).json({ message: 'Experiment already started' });
    }

    progress = new Progress({ studentId: req.user.id, experimentId });
    await progress.save();
    res.json(progress);
  } catch (error) {
    console.error('Start experiment error:', error.message);
    res.status(500).json({ message: 'Server error' });
  }
});

// Mark step as completed
router.post('/progress/step', auth, authorizeRole(['student']), async (req, res) => {
  const { experimentId, stepNumber } = req.body;
  try {
    let progress = await Progress.findOne({ studentId: req.user.id, experimentId });
    if (!progress) {
      return res.status(404).json({ message: 'Progress not found' });
    }

    if (!progress.completedSteps.includes(stepNumber)) {
      progress.completedSteps.push(stepNumber);
    }

    const experiment = await Experiment.findById(experimentId);
    if (!experiment) {
      return res.status(404).json({ message: 'Experiment not found' });
    }

    if (progress.completedSteps.length === experiment.steps.length) {
      progress.status = 'completed';
      progress.completedAt = new Date();

      const badge = `Completed ${experiment.title}`;
      const achievement = new Achievement({
        studentId: req.user.id,
        experimentId,
        badge,
      });
      await achievement.save();
    }

    await progress.save();
    res.json(progress);
  } catch (error) {
    console.error('Mark step error:', error.message);
    res.status(500).json({ message: 'Server error' });
  }
});

// Read student progress
router.get('/progress', auth, authorizeRole(['student']), async (req, res) => {
  try {
    const progress = await Progress.find({ studentId: req.user.id })
      .populate('experimentId', 'title description');
    res.json(progress);
  } catch (error) {
    console.error('Get progress error:', error.message);
    res.status(500).json({ message: 'Server error' });
  }
});

// Read student achievements
router.get('/achievements', auth, authorizeRole(['student']), async (req, res) => {
  try {
    const achievements = await Achievement.find({ studentId: req.user.id })
      .populate('experimentId', 'title');
    res.json(achievements);
  } catch (error) {
    console.error('Get achievements error:', error.message);
    res.status(500).json({ message: 'Server error' });
  }
});

export default router;