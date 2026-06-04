FROM python:3.10-slim

WORKDIR /app

RUN apt-get update &amp;&amp; apt-get install -y --no-install-recommends \
    libgl1-mesa-glx libglib2.0-0 ffmpeg &amp;&amp; \
    rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

RUN python -c "from ultralytics import YOLO; YOLO('yolov8n.pt')"

EXPOSE 8000 8501

CMD ["uvicorn", "src.api.main:app", "--host", "0.0.0.0", "--port", "8000"]