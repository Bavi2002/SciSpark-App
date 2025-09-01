import express from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import auth from '../middleware/auth.js';
import Student from '../models/Student.js';
import Experiment from '../models/Experiment.js';
import Progress from '../models/Progress.js';
import Achievement from '../models/Achievement.js';

const router = express.Router();

// Register student
router.post('/register', async (req, res) => {
  const { email, password, name } = req.body;
  try {
    let student = await Student.findOne({ email });
    if (student) {
      return res.status(400).json({ message: 'Student already exists' });
    }

    student = new Student({ email, password, name });
    await student.save();

    const payload = { id: student._id };
    const token = jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: '1h' });

    res.status(201).json({ token, student: { id: student._id, email, name } });
  } catch (error) {
    res.status(500).json({ message: 'Server error' });
  }
});

// Login student
router.post('/login', async (req, res) => {
  const { email, password } = req.body;
  try {
    const student = await Student.findOne({ email });
    if (!student) {
      return res.status(400).json({ message: 'Invalid credentials' });
    }

    const isMatch = await student.comparePassword(password);
    if (!isMatch) {
      return res.status(400).json({ message: 'Invalid credentials' });
    }

    const payload = { id: student._id };
    const token = jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: '1h' });

    res.json({ token, student: { id: student._id, email, name: student.name } });
  } catch (error) {
    res.status(500).json({ message: 'Server error' });
  }
});

// Browse experiments
router.get('/experiments', auth, async (req, res) => {
  try {
    const experiments = await Experiment.find().select('-steps');
    res.json(experiments);
  } catch (error) {
    res.status(500).json({ message: 'Server error' });
  }
});

// Get experiment details
router.get('/experiments/:id', auth, async (req, res) => {
  try {
    const experiment = await Experiment.findById(req.params.id);
    if (!experiment) {
      return res.status(404).json({ message: 'Experiment not found' });
    }
    res.json(experiment);
  } catch (error) {
    res.status(500).json({ message: 'Server error' });
  }
});

// Start experiment
router.post('/progress/start', auth, async (req, res) => {
  const { experimentId } = req.body;
  try {
    const experiment = await Experiment.findById(experimentId);
    if (!experiment) {
      return res.status(404).json({ message: 'Experiment not found' });
    }

    let progress = await Progress.findOne({ studentId: req.student.id, experimentId });
    if (progress) {
      return res.status(400).json({ message: 'Experiment already started' });
    }

    progress = new Progress({ studentId: req.student.id, experimentId });
    await progress.save();
    res.json(progress);
  } catch (error) {
    res.status(500).json({ message: 'Server error' });
  }
});

// Mark step as completed
router.post('/progress/step', auth, async (req, res) => {
  const { experimentId, stepNumber } = req.body;
  try {
    let progress = await Progress.findOne({ studentId: req.student.id, experimentId });
    if (!progress) {
      return res.status(404).json({ message: 'Progress not found' });
  }

    if (!progress.completedSteps.includes(stepNumber)) {
      progress.completedSteps.push(stepNumber);
    }

    const experiment = await Experiment.findById(experimentId);
    if (progress.completedSteps.length === experiment.steps.length) {
      progress.status = 'completed';
      progress.completedAt = new Date();

      const badge = `Completed ${experiment.title}`;
      const achievement = new Achievement({
        studentId: req.student.id,
        experimentId,
        badge,
      });
      await achievement.save();
    }

    await progress.save();
    res.json(progress);
  } catch (error) {
    res.status(500).json({ message: 'Server error' });
  }
});

// Get student progress
router.get('/progress', auth, async (req, res) => {
  try {
    const progress = await Progress.find({ studentId: req.student.id })
      .populate('experimentId', 'title description');
    res.json(progress);
seekerss
  } catch (error) {
    res.status(500).json({ message: 'Server error' });
  }
});

// Get student achievements
router.get('/achievements', auth, async (req, res) => {
  try {
    const achievements = await Achievement.find({ studentId: req.student.id })
      .populate('experimentId', 'title');
    res.json(achievements);
  } catch (error) {
    res.status(500).json({ message: 'Server error' });
  }
});

export default router;