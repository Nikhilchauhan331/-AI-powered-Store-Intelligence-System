# Store Intelligence System — Windows Setup Guide

## Prerequisites (install first)

| Tool | Download |
|------|----------|
| Python 3.10+ | https://python.org/downloads/ |
| Docker Desktop | https://docker.com/products/docker-desktop/ |
| Git | https://git-scm.com/download/win |

---

## Step 1 — Copy Project

Transfer the `store-intelligence-system` folder to your Windows machine (USB / network share / zip).

---

## Step 2 — Create Virtual Environment

Open **PowerShell** (not cmd) in the project folder:

```powershell
python -m venv venv
venv\Scripts\Activate.ps1

# If execution policy blocks it:
# Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

## Step 3 — Install Dependencies

```powershell
pip install -r requirements.txt
```

> If behind a corporate proxy, use the internal mirror:
> ```powershell
> pip install -r requirements.txt --index-url https://repository.walmart.com/repository/pypi-proxy/simple/ --trusted-host repository.walmart.com
> ```

---

## Step 4 — Install YOLOv8 + Torch (GPU optional)

```powershell
# CPU only (lighter, works on any machine):
pip install torch==2.2.1 torchvision==0.17.1 --index-url https://download.pytorch.org/whl/cpu

# OR with CUDA GPU support (if you have NVIDIA GPU):
pip install torch==2.2.1 torchvision==0.17.1 --index-url https://download.pytorch.org/whl/cu121

pip install ultralytics==8.1.0
pip install deep-sort-realtime==1.3.2
```

---

## Step 5 — Configure Environment

Copy `.env.example` to `.env` and edit:

```powershell
copy .env.example .env
notepad .env
```

**Key settings to update:**

```env
# Path to your CCTV video file (use forward slashes or double backslashes)
VIDEO_SOURCE=C:/Users/YourName/Videos/store_cctv.mp4
# OR for live RTSP stream:
VIDEO_SOURCE=rtsp://admin:password@192.168.1.100:554/stream

CAMERA_ID=CAM_001
STORE_ID=STORE_001

# For GPU detection (faster):
DETECTION_DEVICE=cuda
# For CPU only:
DETECTION_DEVICE=cpu
```

---

## Step 6 — Start Infrastructure (Docker Desktop must be running)

```powershell
docker compose up -d
```

Verify all containers are healthy:
```powershell
docker compose ps
```

Wait for output showing all services as `healthy`:
- `zookeeper` (healthy)
- `kafka` (healthy)
- `postgres` (healthy)
- `redis` (healthy)
- `kafka-ui` (healthy)

---

## Step 7 — Initialize Database

```powershell
# Wait ~10s after docker compose up, then:
docker exec -i postgres psql -U store_user -d store_intelligence < scripts\init_db.sql
```

---

## Step 8 — Start Services (3 separate PowerShell windows)

**Window 1 — API Server:**
```powershell
venv\Scripts\Activate.ps1
python -m uvicorn src.api.main:app --host 0.0.0.0 --port 8000 --reload
```

**Window 2 — Dashboard:**
```powershell
venv\Scripts\Activate.ps1
python -m streamlit run src\dashboard\app.py --server.port 8501
```

**Window 3 — Detection Pipeline (needs video file):**
```powershell
venv\Scripts\Activate.ps1
python -m src.pipeline.pipeline
```

---

## Step 9 — Access the System

| Service | URL |
|---------|-----|
| **API Docs** | http://localhost:8000/docs |
| **Dashboard** | http://localhost:8501 |
| **Health Check** | http://localhost:8000/health |
| **Kafka UI** | http://localhost:8080 |

---

## Video Source Options

| Type | Example Value |
|------|---------------|
| Video file (MP4/AVI) | `C:/Videos/cctv.mp4` |
| Webcam | `0` |
| RTSP stream | `rtsp://admin:pass@192.168.1.100:554/stream` |
| HTTP stream | `http://192.168.1.100:8080/video` |

Update `VIDEO_SOURCE` in `.env` before starting the pipeline.

---

## Troubleshooting

**YOLO model not found:**
```powershell
# Auto-downloads on first run. If blocked by proxy:
python -c "from ultralytics import YOLO; YOLO('yolov8n.pt')"
# Model saved to: C:\Users\YourName\AppData\Roaming\Ultralytics\
```

**Port already in use:**
```powershell
netstat -ano | findstr :8000
taskkill /PID <PID> /F
```

**Docker not starting:**
- Ensure Docker Desktop is running (check system tray)
- Run PowerShell as Administrator for first-time setup

**Pipeline runs but no detections:**
- Check `DETECTION_CONFIDENCE` in `.env` — try lowering to `0.3`
- Check `VIDEO_SOURCE` path has no special characters
- Try `DETECTION_DEVICE=cpu` if GPU errors appear
