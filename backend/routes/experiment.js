
import express from "express";
import Experiment from "../models/Experiment.js";
import auth from "../middleware/auth.js";

const router = express.Router();

// Add new experiment (Teacher only, requires auth)
router.post("/add", async (req, res) => {
  try {
    const { title, description, subject, difficulty, materials, steps } = req.body;

    // Validate required fields
    if (!title || !description || !subject || !difficulty) {
      return res.status(400).json({ error: "Missing required fields" });
    }

    console.log("Creating experiment:", req.body);

    const experiment = new Experiment({
      title,
      description,
      subject,
      difficulty,
      materials: materials || [],
      steps: steps || []
    });

    console.log("Saving experiment:", experiment);

    await experiment.save();
    res.status(201).json({ message: "Experiment added successfully", experiment });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to add experiment" });
  }
});

// Get all experiments
router.get("/", async (req, res) => {
  try {
    const experiments = await Experiment.find().select("-steps"); // Exclude steps for lighter response
    res.json(experiments);
    console.log("Fetched experiments:", experiments);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to fetch experiments" });
  }
});

// Get single experiment by ID
router.get("/:id", async (req, res) => {
  try {
    const experiment = await Experiment.findById(req.params.id);
    if (!experiment) {
      return res.status(404).json({ error: "Experiment not found" });
    }
    res.json(experiment);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to fetch experiment" });
  }
});

// Update experiment (Teacher only, requires auth)
router.put("/:id", auth, async (req, res) => {
  try {
    const { title, description, subject, difficulty, materials, steps } = req.body;

    const experiment = await Experiment.findById(req.params.id);
    if (!experiment) {
      return res.status(404).json({ error: "Experiment not found" });
    }

 

    // Update fields if provided
    if (title) experiment.title = title;
    if (description) experiment.description = description;
    if (subject) experiment.subject = subject;
    if (difficulty) experiment.difficulty = difficulty;
    if (materials) experiment.materials = materials;
    if (steps) experiment.steps = steps;

    await experiment.save();
    res.json({ message: "Experiment updated successfully", experiment });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to update experiment" });
  }
});

// Delete experiment (Teacher only, requires auth)
router.delete("/:id", auth, async (req, res) => {
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
router.post("/:id/steps", auth, async (req, res) => {
  try {
    const {  stepNumber, instruction ,mediaUrl} = req.body;

    // Validate required fields
    if (!stepNumber || !mediaUrl || !instruction) {
      return res.status(400).json({ error: "All fields are required" });
    }

    const experiment = await Experiment.findById(req.params.id);
    if (!experiment) {
      return res.status(404).json({ error: "Experiment not found" });
    }

    const step = { stepNumber, instruction, mediaUrl };
    experiment.steps.push(step);
    await experiment.save();

    res.json({ message: "Step added successfully", experiment });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to add step" });
  }
});

// Update a specific step in an experiment (Teacher only, requires auth)
router.put("/:id/steps/:stepIndex", auth, async (req, res) => {
  try {
      const {  stepNumber, instruction ,mediaUrl} = req.body;
    const { id, stepIndex } = req.params;

    const experiment = await Experiment.findById(id);
    if (!experiment) {
      return res.status(404).json({ error: "Experiment not found" });
    }


    if (stepIndex >= experiment.steps.length || stepIndex < 0) {
      return res.status(400).json({ error: "Invalid step index" });
    }

    // Update step fields if provided
    if (stepNumber) experiment.steps[stepIndex].stepNumber = stepNumber;
    if (instruction) experiment.steps[stepIndex].instruction = instruction;
    if (mediaUrl) experiment.steps[stepIndex].mediaUrl = mediaUrl;

    await experiment.save();
    res.json({ message: "Step updated successfully", experiment });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to update step" });
  }
});

// Delete a specific step in an experiment (Teacher only, requires auth)
router.delete("/:id/steps/:stepIndex", auth, async (req, res) => {
  try {
    const { id, stepIndex } = req.params;

    const experiment = await Experiment.findById(id);
    if (!experiment) {
      return res.status(404).json({ error: "Experiment not found" });
    }



    if (stepIndex >= experiment.steps.length || stepIndex < 0) {
      return res.status(400).json({ error: "Invalid step index" });
    }

    experiment.steps.splice(stepIndex, 1); // Remove step at index
    await experiment.save();

    res.json({ message: "Step deleted successfully", experiment });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to delete step" });
  }
});

export default router;
