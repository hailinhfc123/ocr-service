# Use official Paddle GPU base
FROM paddlepaddle/paddle:3.3.1-gpu-cuda12.6-cudnn9.5

# 1. Fix the libGL and glib errors we saw on Vast.ai
RUN apt-get update && apt-get install -y libgl1 libglib2.0-0 && rm -rf /var/lib/apt/lists/*

# 2. Set up workspace
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 3. PRE-DOWNLOAD MODELS (Crucial to avoid cold-start delays)
# This runs once during build and saves the models into the image
RUN python3 -c "from paddleocr import PaddleOCR; PaddleOCR(lang='en', device='cpu')"

# 4. Copy app code
COPY app.py .

# 5. Start command
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
