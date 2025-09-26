import express from "express";
import jwt from "jsonwebtoken";
import { auth, authorizeRole } from "../middleware/auth.js";
import Student from "../models/Student.js";
import Teacher from "../models/Teacher.js";

const router = express.Router();

// Register student
router.post("/register/student", async (req, res) => {
  const { email, password, name } = req.body;
  try {
    let user = await Student.findOne({ email });
    if (user) {
      return res.status(400).json({ message: "Student already exists" });
    }

    user = new Student({ email, password, name, role: "student" });
    await user.save();

    const payload = { id: user._id, role: user.role };
    const token = jwt.sign(payload, process.env.JWT_SECRET, {
      expiresIn: "1h",
    });

    res
      .status(201)
      .json({ token, user: { id: user._id, email, name, role: user.role } });
  } catch (error) {
    res.status(500).json({ message: "Server error" });
  }
});

// Register teacher
router.post("/register/teacher", async (req, res) => {
  const { email, password, name } = req.body;
  try {
    let user = await Teacher.findOne({ email });
    if (user) {
      return res.status(400).json({ message: "Teacher already exists" });
    }

    user = new Teacher({ email, password, name, role: "teacher" });
    await user.save();

    const payload = { id: user._id, role: user.role };
    const token = jwt.sign(payload, process.env.JWT_SECRET, {
      expiresIn: "1h",
    });

    res
      .status(201)
      .json({ token, user: { id: user._id, email, name, role: user.role } });
  } catch (error) {
    res.status(500).json({ message: "Server error" });
  }
});

// Login (for both student and teacher)
router.post("/login", async (req, res) => {
  console.log("Login request received:", req.body);
  const { email, password } = req.body;
  try {
    let user =
      (await Student.findOne({ email })) || (await Teacher.findOne({ email }));
    if (!user) {
      return res.status(400).json({ message: "Invalid credentials" });
    }

    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      return res.status(400).json({ message: "Invalid credentials" });
    }

    const payload = { id: user._id, role: user.role };
    const token = jwt.sign(payload, process.env.JWT_SECRET, {
      expiresIn: "1h",
    });

    res.json({
      token,
      user: { id: user._id, email, name: user.name, role: user.role },
    });
  } catch (error) {
    res.status(500).json({ message: "Server error" });
  }
});

// Example protected route for teachers only
router.get(
  "/teacher/dashboard",
  auth,
  authorizeRole(["teacher"]),
  async (req, res) => {
    try {
      const teacher = await Teacher.findById(req.user.id).select("-password");
      res.json({ teacher });
    } catch (error) {
      res.status(500).json({ message: "Server error" });
    }
  }
);

// Example protected route for students only
router.get(
  "/student/dashboard",
  auth,
  authorizeRole(["student"]),
  async (req, res) => {
    try {
      const student = await Student.findById(req.user.id).select("-password");
      res.json({ student });
    } catch (error) {
      res.status(500).json({ message: "Server error" });
    }
  }
);

router.get("/me", auth, async (req, res) => {
  try {
    const user = await Teacher.findById(req.teacher.id); // Adjust for your model
    if (!user) {
      return res.status(404).json({ error: "User not found" });
    }
    res.json({ id: user._id, role: req.teacher.role, email: user.email });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

export default router;
