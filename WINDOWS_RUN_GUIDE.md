# Store Intelligence System — Windows Run Guide

## Prerequisites

Install these before anything else:

1. **Python 3.10.11** — https://python.org/downloads
   - During install: check **"Add Python to PATH"**

2. **Docker Desktop** — https://docker.com/products/docker-desktop
   - After install: start Docker Desktop and wait for **green "Engine running"** status

---

## One-Time Setup (run once)

Open **PowerShell** in the project folder:

```powershell
# If activate fails, run this first (one time only, as Admin):
Set-ExecutionPolicy RemoteSigned

# 1. Create virtual environment
python -m venv venv

# 2. Activate it — you should see (venv) in your prompt
venv\Scripts\activate

# 3. Install PyTorch FIRST (CPU — works on all machines)
pip install torch torchvision --index-url https://download.pytorch.org/whl/cpu

# If you have NVIDIA GPU, use this instead:
# pip install torch torchvision --index-url https://download.pytorch.org/whl/cu121

# 4. Install all project dependencies
pip install -r requirements.txt
```

---

## Add Your CCTV Video

1. Copy your video file into the `data\` folder:
   ```
   store-intelligence-system\data\your_video.mp4
   ```

   Sample videos already included in the repo use spaced names like `CAM 1.mp4`, `CAM 2.mp4`, and so on.

2. Open `.env` file with Notepad and update line 7:
   ```
   VIDEO_SOURCE=data/your_video.mp4
   ```

   If your file name contains spaces, keep the path exactly as written, for example:
   ```
   VIDEO_SOURCE=data/CAM 1.mp4
   ```

> **Live camera instead of file?**
> - USB webcam:  `VIDEO_SOURCE=0`
> - IP/RTSP cam: `VIDEO_SOURCE=rtsp://admin:password@192.168.1.100:554/stream1`

---

## Every Time You Run

### Step 1 — Start Docker services

```powershell
docker-compose up -d
```

If you get an error about `dockerDesktopLinuxEngine` or the Docker API pipe, Docker Desktop is not fully running yet.

Fix:

1. Open Docker Desktop from the Start menu.
2. Wait until the status shows **Engine running**.
3. Try the command again.

Wait 20 seconds, then verify 4 containers are running:

```powershell
docker ps
```

Expected: `zookeeper`, `kafka`, `postgres`, `redis`

---

### Step 2 — Open Terminal 1 (API Server)

```powershell
cd C:\Users\YourName\Downloads\store-intelligence-system
venv\Scripts\activate
python -m uvicorn src.api.main:app --host 0.0.0.0 --port 8000 --reload
```

Wait until you see: `Application startup complete`

---

### Step 3 — Open Terminal 2 (Video Pipeline)

```powershell
cd C:\Users\YourName\Downloads\store-intelligence-system
venv\Scripts\activate
python -m src.pipeline.pipeline
```

A window opens showing the video with detection boxes.

---

### Step 4 — Open Terminal 3 (Dashboard)

```powershell
cd C:\Users\YourName\Downloads\store-intelligence-system
venv\Scripts\activate
streamlit run src\dashboard\app.py
```

---

### Step 5 — Open in Browser

| What | URL |
|------|-----|
| Live Dashboard | http://localhost:8501 |
| API Docs | http://localhost:8000/docs |
| Health Check | http://localhost:8000/health |

---

## Shut Everything Down

```powershell
# In each terminal press:
Ctrl + C

# Stop Docker services:
docker-compose down
```

---

## Run Without Docker (quick test, no Kafka/Redis/DB)

Skip `docker-compose` entirely. Just run Terminals 1, 2, 3 above.
Everything still works — people counting, zones, anomalies, dashboard.
Events just won't be saved to the database.

---

## Troubleshooting

| Error | Fix |
|-------|-----|
| `python not found` | Reinstall Python, check "Add to PATH" |
| `venv\Scripts\activate` fails | Run `Set-ExecutionPolicy RemoteSigned` as Admin |
| `docker-compose not found` | Try `docker compose up -d` (no hyphen) |
| `failed to connect to the docker API at npipe:////./pipe/dockerDesktopLinuxEngine` | Start Docker Desktop and wait for **Engine running**, then rerun `docker-compose up -d` |
| `failed to resolve reference ... registry-1.docker.io` | Docker cannot reach Docker Hub. Check internet access, VPN, DNS, or company proxy settings, then retry `docker-compose up -d`. |
| `pip install` 403 error | Add `--trusted-host pypi.org --trusted-host files.pythonhosted.org` |
| `ModuleNotFoundError: cv2` | Run `pip install opencv-python` |
| `Cannot open video source` | Check `.env` VIDEO_SOURCE and make sure the file name matches the actual file in `data\` (for example `data/CAM 1.mp4`) |
| YOLOv8 slow first run | Normal — downloading `yolov8n.pt` (~6MB) automatically |
| Pipeline crashes on start | Check video file exists in `data\` folder |
| Dashboard shows no data | Make sure API (Terminal 1) is running first |

---

## For Better Detection Accuracy

Edit `config\config.yaml` and change the model:

```yaml
detection:
  model: yolov8n.pt    # small, fast
  # model: yolov8s.pt  # better accuracy
  # model: yolov8m.pt  # best accuracy, needs more RAM/GPU
  confidence: 0.5      # lower = more detections, higher = fewer false positives
```
