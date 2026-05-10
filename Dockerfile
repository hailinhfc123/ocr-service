# Use the official Paddle GPU base
FROM paddlepaddle/paddle:3.3.1-gpu-cuda12.6-cudnn9.5

# 1. Install system dependencies
RUN apt-get update && apt-get install -y \
    libgl1 \
    libglib2.0-0 \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

# 2. INSTALL THE LIBRARIES FIRST
# We need the code to exist before we can ask it to download models
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 3. NOW THE TRICK: Create fake libcuda, download models, then delete fake
# This uses the paddleocr we just installed in step 2
RUN ln -s /usr/lib/x86_64-linux-gnu/librt.so.1 /usr/lib/x86_64-linux-gnu/libcuda.so.1 && \
    python3 -c "from paddleocr import PaddleOCR; PaddleOCR(lang='en', device='cpu')" && \
    rm /usr/lib/x86_64-linux-gnu/libcuda.so.1

# 4. Copy your app code last
COPY app.py .

# 5. Start the engine
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
