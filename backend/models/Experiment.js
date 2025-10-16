import mongoose from "mongoose";

const stepSchema = new mongoose.Schema({
  stepNumber: { type: Number, required: true },
  instruction: { type: String, required: true },
  mediaUrl: { type: String, required: false }, // Optional YouTube URL
});

const experimentSchema = new mongoose.Schema({
  title: { type: String, required: true },
  user: { type: mongoose.Schema.Types.ObjectId, ref: "Teacher", required: true },
  description: { type: String, required: true },
  subject: { type: String, required: true },
  difficulty: { type: String, required: true },
  materials: { type: [String], default: [] },
  steps: { type: [stepSchema], default: [] },
  thumbnail: { type: String, required: false }, 
  createdAt: { type: Date, default: Date.now },
});

const Experiment = mongoose.model("Experiment", experimentSchema);
export default Experiment;
