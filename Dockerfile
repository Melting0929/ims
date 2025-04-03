# Stage 1: Setup for Firebase Functions (Node.js)
FROM node:18 AS node-build

# Set the working directory for Node.js
WORKDIR /usr/src/app/functions

# Copy the Firebase functions code and install dependencies
COPY functions/package*.json ./
RUN npm install

# Stage 2: Setup for Python (Flask)
FROM python:3.9-slim AS python-build

# Install supervisor to manage multiple processes
RUN apt-get update && apt-get install -y supervisor

# Set the working directory for Python
WORKDIR /usr/src/app/functions

# Copy Python code (Flask API) into the container
COPY functions/python/ /usr/src/app/functions/python/

# Install necessary dependencies for the Python server
RUN pip install --upgrade pip && \
    pip install flask firebase-admin joblib requests scikit-learn PyPDF2

# Stage 3: Final Container
FROM node:18

# Set working directory
WORKDIR /usr/src/app

# Copy Node.js dependencies and code from the first stage
COPY --from=node-build /usr/src/app/functions /usr/src/app/functions

# Copy the Python code and pre-installed dependencies from the second stage
COPY --from=python-build /usr/src/app/functions /usr/src/app/functions

# Copy the supervisord configuration to manage both Flask and Node.js servers
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

WORKDIR /usr/src/app/functions
RUN npm install --production

# Expose the necessary ports
EXPOSE 8080 8491

# Start supervisord to manage both the Node.js and Flask processes
CMD ["/usr/bin/supervisord"]
