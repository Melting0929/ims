import numpy as np
import firebase_admin
from firebase_admin import firestore, functions
from flask import Flask, request, jsonify
import joblib
import gensim

# Initialize Firebase
firebase_admin.initialize_app()
db = firestore.client()

# Load trained RandomForest model
clf = joblib.load('resume_match_model.pkl')

# Load Word2Vec model
word2vec_model = gensim.models.Word2Vec.load('word2vec_model.bin')

# Define constants
SIMILARITY_THRESHOLD = 0.8
TOP_K = 10

# Flask app for API
app = Flask(__name__)

def get_embedding(text):
    """Convert text to Word2Vec embedding by averaging word vectors."""
    words = text.split()
    vectors = [word2vec_model.wv[word] for word in words if word in word2vec_model.wv]
    if vectors:
        return np.mean(vectors, axis=0)
    else:
        return np.zeros(word2vec_model.vector_size)

@app.route('/recommend_jobs', methods=['POST'])
def recommend_jobs():
    data = request.get_json()
    resume_text = data.get('resume_text', '')

    # Compute resume embedding
    resume_embedding = get_embedding(resume_text)

    # Fetch jobs from Firestore
    jobs_ref = db.collection('Job').stream()
    job_scores = []

    for job in jobs_ref:
        job_data = job.to_dict()
        job_id = job.id
        job_tags = " ".join(job_data.get('tags', []))  # Convert tags list to text

        # Compute job embedding
        job_embedding = get_embedding(job_tags)

        # Compute similarity using Word2Vec embeddings (cosine similarity)
        similarity = np.dot(job_embedding, resume_embedding) / (np.linalg.norm(job_embedding) * np.linalg.norm(resume_embedding))

        # Store top K matches
        job_scores.append((job_id, job_embedding, similarity, job_data.get('tags', [])))

    # Sort jobs by similarity and pick top K
    job_scores.sort(key=lambda x: x[2], reverse=True)
    top_jobs = job_scores[:TOP_K]

    # Predict matches for top K jobs
    job_matches = []
    for job_id, job_embedding, similarity, job_tags in top_jobs:
        combined_features = np.hstack([job_embedding, resume_embedding]).reshape(1, -1)
        match_prediction = clf.predict(combined_features)[0]

        if match_prediction == 1 and similarity > SIMILARITY_THRESHOLD:
            job_matches.append({'job_id': job_id, 'tags': job_tags, 'similarity': similarity})

    return jsonify({'recommended_jobs': job_matches})

# Export as Firebase Function
recommend_jobs_fn = functions.https.on_request(app)
