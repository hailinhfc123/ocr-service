# The remote host needs to run these commands first
# pip install --no-cache-dir paddleocr fastapi uvicorn python-multipart opencv-python-headless
# apt-get update
# apt-get install -y libgl1 libglib2.0-0

from fastapi import FastAPI, UploadFile, File
from paddleocr import PaddleOCR
import numpy as np
import cv2
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI()

# Optimized for the strikethrough text in your image
ocr = PaddleOCR(lang='en', device='gpu', use_angle_cls=True, det_db_thresh=0.3)

@app.get("/")
async def root():
    return {"message": "OCR Service Online"}

@app.post("/solve")
async def solve(file: UploadFile = File(...)):
    contents = await file.read()
    nparr = np.frombuffer(contents, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

    # Get raw output from model
    result = ocr.predict(img)

    detected_items = []

    # --- NEW AGGRESSIVE PARSING LOGIC ---

    # 1. Ensure we are working with the dictionary inside the list
    if isinstance(result, list) and len(result) > 0:
        data_block = result[0]
    else:
        data_block = result

    # 2. Check for 'res' key first (as seen in your logs)
    if isinstance(data_block, dict):
        # Look inside 'res' if it exists, otherwise look at top level
        target = data_block.get('res', data_block)

        texts = target.get('rec_texts', [])
        scores = target.get('rec_scores', [])

        for text, score in zip(texts, scores):
            detected_items.append({
                "text": str(text),
                "confidence": float(score)
            })

    # Log what we are actually sending back to the Mac
    logger.info(f"Sending to Mac: {detected_items}")

    return {"status": "ok", "predictions": detected_items}
