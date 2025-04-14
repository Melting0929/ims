import sys
import json
import joblib
from sentence_transformers import SentenceTransformer
from sklearn.metrics.pairwise import cosine_similarity

# Load job data
job_data = joblib.load(open("job_data.pkl", "rb"))
job_titles = job_data["job_titles"]
job_texts = job_data["job_texts"]

# Load model
model = SentenceTransformer("sbert_model")

def get_recommendations(resume_text):
    resume_vec = model.encode([resume_text])
    job_vecs = model.encode(job_texts)

    similarities = cosine_similarity(resume_vec, job_vecs)[0]
    top_indices = similarities.argsort()[-3:][::-1]
    return [job_titles[i] for i in top_indices]

if __name__ == '__main__':
    input_text = sys.argv[1]
    recommendations = get_recommendations(input_text)
    print(json.dumps(recommendations))