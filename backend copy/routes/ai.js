import express from "express";
import fetch from "node-fetch";
import Experiment from "../models/Experiment.js";

const router = express.Router();

router.post("/ask", async (req, res) => {
  const { experimentId, question } = req.body;

  try {
    // Fetch experiment from DB
    const experiment = await Experiment.findById(experimentId);
    if (!experiment) return res.status(404).json({ error: "Experiment not found" });

    // Extract step number if mentioned
    let contextStep = "";
    const match = question.match(/step\s*(\d+)/i);
    if (match) {
      const stepNumber = parseInt(match[1]);
      const step = experiment.steps.find(s => s.stepNumber === stepNumber);
      if (step) {
        contextStep = `Step ${step.stepNumber}: ${step.instruction}`;
      }
    }

    // Build prompt
    const prompt = `
    You are a friendly tutor helping kids with science experiments.
    Experiment: ${experiment.title}
    ${contextStep ? "Relevant Step: " + contextStep : ""}
    Student Question: ${question}
    Explain in simple, encouraging words.
    `;

    // Call OpenAI
    const response = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${process.env.OPENAI_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "gpt-4o-mini",
        messages: [{ role: "user", content: prompt }],
      }),
    });

    const data = await response.json();
    res.json({ reply: data.choices[0].message.content });

  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "AI request failed" });
  }
});

export default router;
