# Use the official Paddle GPU base
FROM paddlepaddle/paddle:3.3.1-gpu-cuda12.6-cudnn9.5

# 1. Install all system dependencies in one go
RUN apt-get update && apt-get install -y \
    libgl1 \
    libglib2.0-0 \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

# 2. THE TRICK: Create a fake libcuda.so.1
# We link it to librt (a standard library) just to satisfy the 'import' check.
# Then we download the models, and finally DELETE the fake link.
RUN ln -s /usr/lib/x86_64-linux-gnu/librt.so.1 /usr/lib/x86_64-linux-gnu/libcuda.so.1 && \
    python3 -c "from paddleocr import PaddleOCR; PaddleOCR(lang='en', device='cpu')" && \
    rm /usr/lib/x86_64-linux-gnu/libcuda.so.1

# 3. Set up your app
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py .

# 4. Start the engine
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
