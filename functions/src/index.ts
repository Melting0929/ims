import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import express from 'express';
import cors from 'cors';
import axios from 'axios';

admin.initializeApp();
const app = express();
app.use(cors({ origin: true })); // Allow CORS

// ✅ Root route to check if the function is deployed correctly
app.get('/', (req, res) => {
  res.status(200).send('Welcome to the Job Recommendation API. Use POST /recommend_jobs to get job recommendations.');
});

// ✅ Correctly handle POST requests to /recommend_jobs
app.post('/recommend_jobs', async (req, res) => {
  try {
    const { resume_text, studentId } = req.body;

    if (!resume_text) {
      return res.status(400).json({ error: "Missing resume_text parameter" });
    }

    if (!studentId) {
      return res.status(400).json({ error: "Missing studentId parameter" });
    }

    // ✅ Send request to the AI model API
    const apiResponse = await axios.post('https://recommendjobs-ayekkctrbq-uc.a.run.app', {
      resume_text,
      studentId,
    });

    return res.status(200).json(apiResponse.data);
  } catch (error) {
    console.error("Error in recommend_jobs function:", error);
    return res.status(500).json({ error: "Internal Server Error" });
  }
});

// ✅ Export Firebase Function
export const recommendJobs = functions.https.onRequest(app);
