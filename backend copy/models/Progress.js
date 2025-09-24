import mongoose from 'mongoose';

const progressSchema = new mongoose.Schema({
  studentId: { type: mongoose.Schema.Types.ObjectId, ref: 'Student', required: true },
  experimentId: { type: mongoose.Schema.Types.ObjectId, ref: 'Experiment', required: true },
  status: { type: String, enum: ['started', 'completed'], default: 'started' },
  completedSteps: [{ type: Number }],
  startedAt: { type: Date, default: Date.now },
  completedAt: { type: Date },
});

export default mongoose.model('Progress', progressSchema);