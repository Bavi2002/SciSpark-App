const mongoose = require('mongoose');

const progressSchema = new mongoose.Schema({
  experimentId: { type: mongoose.Schema.Types.ObjectId, ref: 'Experiment' },
  status: { type: String, enum: ['in-progress', 'completed'], default: 'in-progress' },
  badgesEarned: [{ type: String }] // Array of badges earned for this experiment
});

const userSchema = new mongoose.Schema({
  username: { type: String, required: true },
  password: { type: String, required: true },
  email: { type: String, required: true },
  role: { type: String, enum: ['parent', 'admin'], required: true },
  progress: [{
  experimentId: { type: mongoose.Schema.Types.ObjectId, ref: 'Experiment' },
  status: { type: String, enum: ['in-progress', 'completed'], default: 'in-progress' }
  }]
});

const User = mongoose.model('User', userSchema);

module.exports = User;
