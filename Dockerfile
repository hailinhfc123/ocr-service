# STAGE 1: Download models on a lightweight CPU image
FROM python:3.10-slim as downloader
RUN pip install paddleocr paddlepaddle
# This downloads models to /root/.paddleocr
RUN python3 -c "from paddleocr import PaddleOCR; PaddleOCR(lang='en', device='cpu')"

# STAGE 2: Final GPU Image
FROM paddlepaddle/paddle:3.3.1-gpu-cuda12.6-cudnn9.5
RUN apt-get update && apt-get install -y libgl1 libglib2.0-0 && rm -rf /var/lib/apt/lists/*

# Copy the models from the first stage
COPY --from=downloader /root/.paddleocr /root/.paddleocr

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py .

CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
