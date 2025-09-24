import mongoose from 'mongoose';

const achievementSchema = new mongoose.Schema({
  studentId: { type: mongoose.Schema.Types.ObjectId, ref: 'Student', required: true },
  experimentId: { type: mongoose.Schema.Types.ObjectId, ref: 'Experiment', required: true },
  badge: { type: String, required: true },
  earnedAt: { type: Date, default: Date.now },
});

export default mongoose.model('Achievement', achievementSchema);