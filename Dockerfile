# Face-Swapping Service Dockerfile
# Use standard Python image instead of slim to avoid security issues with ONNX Runtime
FROM python:3.10

# Install system dependencies for OpenCV, image processing, and build tools
RUN apt-get update && apt-get install -y \
    build-essential \
    g++ \
    gcc \
    cmake \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    libgl1 \
    execstack \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python dependencies with precompiled ONNX Runtime
# Use onnxruntime CPU package to avoid executable stack issues
RUN pip install --no-cache-dir -r requirements.txt

# Clear executable stack flag from ONNX Runtime shared libraries to fix Railway compatibility
RUN find /usr/local/lib/python3.10/site-packages/onnxruntime -name "*.so" -exec execstack -c {} \; 2>/dev/null || true

# Set environment variable to disable ONNX Runtime telemetry and use CPU execution provider
ENV ORT_DISABLE_TELEMETRY=1

# Copy application code
COPY app.py .

# Create models directory
RUN mkdir -p ./models

# Expose port
EXPOSE 5000

# Run with Python directly instead of gunicorn to avoid ONNX Runtime executable stack issues
CMD ["python", "app.py"]
