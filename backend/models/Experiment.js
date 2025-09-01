import mongoose from "mongoose";

const stepSchema = new mongoose.Schema({
  stepNumber: Number,
  instruction: String,
  mediaUrl: String, // optional (image/video)
});

const experimentSchema = new mongoose.Schema({
  title: String,
  description: String,
  subject: String,
  difficulty: String,
  materials: [String],
  steps: [stepSchema],
});

const Experiment = mongoose.model("Experiment", experimentSchema);
export default Experiment;
