# STAGE 1: Download models on a CPU-friendly image
FROM python:3.10-slim AS downloader

# 1. We MUST install these even here, or 'import cv2' fails during download
RUN apt-get update && apt-get install -y libgl1 libglib2.0-0 && rm -rf /var/lib/apt/lists/*

# 2. Install CPU version of paddle to avoid libcuda.so errors on GitHub
RUN pip install paddleocr paddlepaddle

# 3. This will now work because libgl1 is present
RUN python3 -c "from paddleocr import PaddleOCR; PaddleOCR(lang='en', device='cpu')"

# STAGE 2: Final GPU Image
FROM paddlepaddle/paddle:3.3.1-gpu-cuda12.6-cudnn9.5

# 1. Install the same libraries for the final production environment
RUN apt-get update && apt-get install -y libgl1 libglib2.0-0 && rm -rf /var/lib/apt/lists/*

# 2. Copy the models we "baked" in Stage 1
COPY --from=downloader /root/.paddleocr /root/.paddleocr

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py .

CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
