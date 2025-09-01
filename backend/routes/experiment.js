import express from "express";
import Experiment from "../models/Experiment.js";

const router = express.Router();

// Add new experiment
router.post("/add", async (req, res) => {
  try {
    const experiment = new Experiment(req.body);
    await experiment.save();
    res.json({ message: "Experiment added successfully", experiment });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to add experiment" });
  }
});

// Get all experiments
router.get("/", async (req, res) => {
  try {
    const experiments = await Experiment.find();
    res.json(experiments);
  } catch (err) {
    res.status(500).json({ error: "Failed to fetch experiments" });
  }
});

export default router;
