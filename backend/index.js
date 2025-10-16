import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import connectDB from "./config/db.js";

import experimentRoutes from "./routes/experiment.js";
import aiRoutes from "./routes/ai.js";
import studentRoutes from "./routes/student.js"
import authRoutes from "./routes/auth.js"

dotenv.config();
const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Connect to DB
connectDB();

// Routes
app.use("/api/experiments", experimentRoutes);
app.use("/api/ai", aiRoutes);
app.use('/api/student', studentRoutes);
app.use('/api/auth', authRoutes);

// Default route
app.get("/", (req, res) => {
  res.send("🚀 SciSpark API is running...");
});

// Start the server
const PORT = process.env.PORT || 5000;
const server = app.listen(PORT, () => {
  console.log(`✅ Server running on http://localhost:${PORT}`);
});

// Handle server errors
server.on("error", (err) => {
  if (err.code === "EADDRINUSE") {
    console.error(`❌ Port ${PORT} is already in use. Please use a different port.`);
  } else if (err.code === "EACCES") {
    console.error(`❌ Permission denied. Try running with elevated privileges or a different port.`);
  } else {
    console.error("❌ Server failed to start:", err);
  }
  process.exit(1);
});
