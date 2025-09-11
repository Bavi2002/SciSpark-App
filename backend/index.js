const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const parentRoutes = require('./routes/parentRoutes');
require('dotenv').config();

const app = express();

// Middleware
app.use(express.json());
app.use(cors());
app.use('/api/parent', parentRoutes);

// MongoDB connection
mongoose.connect(process.env.MONGO_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true
})
  .then(() => console.log("MongoDB connected"))
  .catch((err) => console.log("MongoDB connection error: ", err));

// Start server
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
