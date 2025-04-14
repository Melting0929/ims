// index.js
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const express = require("express");
const cors = require("cors");
const axios = require("axios");

admin.initializeApp();
const app = express();
app.use(cors({ origin: true }));

// Endpoint to proxy resume recommendation requests to the Flask backend
app.post("/recommend_jobs", async (req, res) => {
  try {
    const { resume_text, studentId } = req.body;
    if (!resume_text) {
      return res.status(400).json({ error: "Resume text is required" });
    }

    const flaskApiUrl = "https://ai-api-618402886119.us-central1.run.app";

    // Forward the POST request to the Flask API
    const response = await axios.post(flaskApiUrl, { resume_text });
    return res.status(200).json(response.data);
  } catch (error) {
    console.error("Error in Cloud Function:", error);
    return res.status(500).json({ error: "Internal server error" });
  }
});

exports.recommendJobs = functions.https.onRequest(app);