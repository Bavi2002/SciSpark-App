import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import connectDB from "./config/db.js";

import experimentRoutes from "./routes/experiment.js";
import aiRoutes from "./routes/ai.js";
import studentRoutes from "./routes/student.js"

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

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`🚀 Server running on port ${PORT}`));
