
import express from "express";
import Experiment from "../models/Experiment.js";
import { auth, authorizeRole } from "../middleware/auth.js";
const router = express.Router();


// Get all experiments
router.get('/', async (req, res) => {
  try {
    const experiments = await Experiment.find().select('-steps');
    res.json(experiments);
  } catch (error) {
    console.error('Get experiments error:', error.message);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get teacher-specific experiments
router.get('/teacher/:id', auth, async (req, res) => {
  try {
    const experiments = await Experiment.find({ user: req.params.id }).select('-steps');
    res.json(experiments);
  } catch (error) {
    console.error('Get teacher experiments error:', error.message);
    res.status(500).json({ message: 'Server error' });
  }
});

// Add experiment
router.post('/add', auth, authorizeRole(['teacher']), async (req, res) => {
  try {
    const { title, description, subject, difficulty, materials, steps, thumbnail } = req.body;
    console.log(req.body);

    // Validate required fields
    if (!title || !description || !subject || !difficulty) {
      return res.status(400).json({ message: 'Title, description, subject, and difficulty are required' });
    }

    // Validate thumbnail (optional; must be .jpg, .jpeg, or .png if provided)
    if (thumbnail && !/\.(jpg|jpeg|png)$/i.test(thumbnail)) {
      return res.status(400).json({ message: 'Thumbnail must be a valid image URL (.jpg, .jpeg, .png)' });
    }

    // Validate steps (optional; each mediaUrl must be a valid YouTube URL if provided)
    if (steps && Array.isArray(steps)) {
      for (const step of steps) {
        if (!step.stepNumber || !step.instruction) {
          return res.status(400).json({ message: 'Each step must have a stepNumber and instruction' });
        }
        if (step.mediaUrl && !/^(https?:\/\/)?(www\.)?(youtube\.com\/watch\?v=|youtu\.be\/)[\w-]{11}($|\?.*)/.test(step.mediaUrl)) {
          return res.status(400).json({ message: 'Step mediaUrl must be a valid YouTube URL' });
        }
      }
    }

    const experiment = new Experiment({
      user: req.user.id,
      title,
      description,
      subject,
      difficulty,
      materials: materials || [],
      steps: steps || [],
      thumbnail: thumbnail || null,
      createdAt: new Date(),
    });

    await experiment.save();
    res.status(201).json(experiment);
  } catch (error) {
    console.error('Experiment creation error:', error.message);
    res.status(400).json({ message: error.message });
  }
});


// Get single experiment
router.get('/:id', async (req, res) => {
  try {
    const experiment = await Experiment.findById(req.params.id);
    if (!experiment) {
      return res.status(404).json({ message: 'Experiment not found' });
    }
    res.json(experiment);
  } catch (error) {
    console.error('Get experiment error:', error.message);
    res.status(500).json({ message: 'Server error' });
  }
});

// Update experiment
router.put('/:id', auth, authorizeRole(['teacher']), async (req, res) => {
  try {
    const { title, description, subject, difficulty, materials } = req.body;
    const experiment = await Experiment.findById(req.params.id);
    if (!experiment) {
      return res.status(404).json({ message: 'Experiment not found' });
    }
    if (experiment.user.toString() !== req.user.id) {
      return res.status(403).json({ message: 'Not authorized' });
    }
    experiment.title = title || experiment.title;
    experiment.description = description || experiment.description;
    experiment.subject = subject || experiment.subject;
    experiment.difficulty = difficulty || experiment.difficulty;
    experiment.materials = materials || experiment.materials;
    await experiment.save();
    res.json(experiment);
  } catch (error) {
    console.error('Update experiment error:', error.message);
    res.status(400).json({ message: error.message });
  }
});


// Delete experiment (Teacher only, requires auth)
router.delete("/:id", auth, authorizeRole("teacher"), async (req, res) => {
  try {
    const experiment = await Experiment.findById(req.params.id);
    if (!experiment) {
      return res.status(404).json({ error: "Experiment not found" });
    }


    await experiment.deleteOne();
    res.json({ message: "Experiment deleted successfully" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to delete experiment" });
  }
});

// Add a step to an experiment (Teacher only, requires auth)
router.post('/:id/steps', auth, authorizeRole(['teacher']), async (req, res) => {
  try {
    const { stepNumber, instruction, mediaUrl } = req.body;
    if (!stepNumber || !instruction) {
      return res.status(400).json({ message: 'Step number and instruction are required' });
    }
    const experiment = await Experiment.findById(req.params.id);
    if (!experiment) {
      return res.status(404).json({ message: 'Experiment not found' });
    }
    if (experiment.user.toString() !== req.user.id) {
      return res.status(403).json({ message: 'Not authorized' });
    }
    experiment.steps.push({ stepNumber, instruction, mediaUrl });
    await experiment.save();
    res.status(201).json(experiment);
  } catch (error) {
    console.error('Add step error:', error.message);
    res.status(400).json({ message: error.message });
  }
});

// Update a specific step in an experiment (Teacher only, requires auth)
router.put('/:id/steps/:stepIndex', auth, authorizeRole(['teacher']), async (req, res) => {
  try {
    const { stepNumber, instruction, mediaUrl } = req.body;
    console.log(req.body);
    if (!instruction) {
      return res.status(400).json({ message: 'Step number and instruction are required' });
    }
    const experiment = await Experiment.findById(req.params.id);
    if (!experiment) {
      return res.status(404).json({ message: 'Experiment not found' });
    }
    if (experiment.user.toString() !== req.user.id) {
      return res.status(403).json({ message: 'Not authorized' });
    }
    const step = experiment.steps[req.params.stepIndex];
    if (!step) {
      return res.status(404).json({ message: 'Step not found' });
    }
    step.stepNumber = stepNumber;
    step.instruction = instruction;
    step.mediaUrl = mediaUrl || step.mediaUrl;
    await experiment.save();
    res.json(experiment);
  } catch (error) {
    console.error('Update step error:', error.message);
    res.status(400).json({ message: error.message });
  }
});

// Delete a specific step in an experiment (Teacher only, requires auth)
// Delete step
router.delete('/:id/steps/:stepIndex', auth, authorizeRole(['teacher']), async (req, res) => {
  try {
    const experiment = await Experiment.findById(req.params.id);
    if (!experiment) {
      return res.status(404).json({ message: 'Experiment not found' });
    }
    if (experiment.user.toString() !== req.user.id) {
      return res.status(403).json({ message: 'Not authorized' });
    }
    experiment.steps.splice(parseInt(req.params.stepIndex), 1);
    await experiment.save();
    res.json(experiment);
  } catch (error) {
    console.error('Delete step error:', error.message);
    res.status(400).json({ message: error.message });
  }
});
export default router;
