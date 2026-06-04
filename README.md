### Store Intelligence System

> Lightweight, local-first people-counting and store analytics with a focused, developer-friendly UX.

[![Python](https://img.shields.io/badge/python-3.10-blue.svg)](https://www.python.org)
[![Streamlit](https://img.shields.io/badge/streamlit-ui-orange.svg)](https://streamlit.io)

What it does
- Detects people in video streams or files and maintains persistent tracks
- Computes per-zone occupancy, throughput, and simple heatmaps
- Emits anomaly alerts (loitering, overcrowding, off-hours) with configurable thresholds
- Optional persistence via Kafka/Redis/Postgres; runs fully locally without them

Why this repo
- Minimal, pragmatic implementation you can run locally for demos, testing, or small deployments
- Modular codebase: swap detection models, tune zone rules, or plug in your storage layer

Quick demo (copy-and-paste)

```powershell
# 1) create and activate env
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt

# 2) optional: start infra for persistence
docker-compose up -d

# 3) start API
python -m uvicorn src.api.main:app --host 0.0.0.0 --port 8000 --reload

# 4) start video pipeline (opens detection window)
python -m src.pipeline.pipeline

# 5) open dashboard
streamlit run src\dashboard\app.py
```

Configuration highlights
- Place video files in the `data/` folder and set `VIDEO_SOURCE` in `.env` (ex: `data/CAM 1.mp4` or `0` for webcam)
- `config/config.yaml` controls detection model, confidence threshold, zones, and anomaly rules

How the pieces fit
- `src/pipeline` — detection, tracking, analytics, anomaly checks; publishes snapshots to Redis/Kafka when available
- `src/api` — FastAPI server exposing analytics, anomaly, and events endpoints; reads cached snapshots if present
- `src/dashboard` — Streamlit UI with demo fallback when no live snapshots exist

Tips & Troubleshooting
- If Docker fails with `npipe` error: open Docker Desktop and wait for "Engine running" then retry `docker-compose up -d`
- If pipeline reports `Cannot open video source`: ensure `VIDEO_SOURCE` matches the filename (spaces matter) in `data/`
- The dashboard will show demo content until the API receives live snapshots (start API before pipeline)

Dev notes
- Run tests: `pytest -q`
- Add a new detection model by updating `config/config.yaml` (model path and confidence)

Contributing
- Open issues or PRs; add tests for new behavior and keep changes focused. Use small, incremental commits.
