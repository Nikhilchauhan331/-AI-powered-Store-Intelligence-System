# DESIGN

## Executive summary
This document describes the Store Intelligence System's end-to-end architecture, event model, AI-assisted design decisions, and operational guidance for a production-ready deployment. It is intended to support reviewers and operators with the reasoning behind key trade-offs (accuracy vs. latency, local-first vs. scalable infra) and to provide concrete runbook, test, and validation steps.

## Architecture (high level)
- Ingest: CCTV sources (MP4, RTSP), preprocessed frames
- Detection: lightweight YOLOv8 (configurable) for person detection
- Tracking: DeepSORT-like tracker to provide stable `track_id`s and short-term re-identification
- Eventing: Kafka producer publishes typed events; consumers include analytics, anomaly detector, and storage
- Serving: FastAPI (REST + WebSocket) exposes analytics and events; Streamlit dashboard for operators

**Architecture diagram**
┌─────────────┐     ┌──────────────┐     ┌─────────────┐     ┌──────────────┐
│  CCTV Feed  │────▶│  YOLOv8      │────▶│  DeepSORT   │────▶│  Kafka       │
│ (MP4/RTSP)  │     │  Detector    │     │  Tracker    │     │  Producer    │
└─────────────┘     └──────────────┘     └─────────────┘     └──────┬───────┘
                                                                     │ store.*
                                                              ┌──────▼───────┐
                                                              │    Kafka     │
                                                              │   Broker     │
                                                              └──┬───┬───┬───┘
                                                                 │   │   │
                                               ┌─────────────────┘   │   └──────────────┐
                                               ▼                     ▼                  ▼
                                        ┌────────────┐       ┌────────────┐      ┌────────────┐
                                        │ Analytics  │       │  Anomaly   │      │  Storage   │
                                        │  Engine    │       │  Detector  │      │  Consumer  │
                                        └─────┬──────┘       └─────┬──────┘      └─────┬──────┘
                                              │                     │                   │
                                              └──────────┬──────────┘                   │
                                                         ▼                               ▼
                                                  ┌────────────┐                ┌────────────┐
                                                  │  FastAPI   │                │ PostgreSQL  │
                                                  │  REST+WS   │                │  + Redis   │
                                                  └─────┬──────┘                └────────────┘
                                                        │
                                                 ┌──────▼──────┐
                                                 │  Streamlit  │
                                                 │  Dashboard  │
                                                 └─────────────┘


Notes:
- The pipeline ingests CCTV feeds (file or RTSP) and runs a lightweight YOLOv8 detector for person detection.
- Detections are passed to a tracker (DeepSORT or similar) which assigns stable `track_id`s.
- A Kafka producer serializes events (see `src/streaming/event_schema.py`) and publishes to topics (e.g. `store.<store_id>.events`).
- The Kafka broker fans events out to multiple consumers:
	- `Analytics Engine` — computes zone counts, throughput, heatmaps, and snapshots
	- `Anomaly Detector` — runs rule-based and ML-assisted anomaly classification
	- `Storage Consumer` — persists events and aggregates to PostgreSQL/Redis for queries
- `FastAPI` serves analytics and events (REST + WebSocket). `Streamlit` consumes APIs for the operator dashboard.
- Topic naming and retention policies are configurable in `config/config.yaml` for privacy and storage cost control.

## Eventing & Schema
- Events are typed using Pydantic models in `src/streaming/event_schema.py`.
- Primary event types: `person_detected`, `person_tracked`, `person_entered`, `person_exited`, `analytics_snapshot`, `anomaly_detected`, `zone_updated`, `system_health`.
- Events are emitted as newline-delimited JSON (JSONL) for log portability and streaming.

## AI-Assisted Decisions
- Model selection: initial choice of a lightweight YOLOv8-n model (`yolov8n.pt`) to balance accuracy and inference cost for CPU-based demo systems.
- Threshold tuning: confidence thresholds and NMS parameters tuned automatically by a small search over validation clips (scripted). AI-assist (LLM) used to analyze historical false-positive patterns and suggest updated thresholds and augmentation strategies.
- Staff exclusion heuristics: AI-assisted clustering on tracked trajectories and badge/appearance metadata is used to propose staff-identification rules. Human-in-the-loop validation is required before applying to production.
- Anomaly classification: a simple rule-based detector is primary; an LLM-assisted post-processor enriches anomaly descriptions for human operators and suggests severity levels based on historical labels.

## Production Readiness
- Backpressure: when Kafka/Redis unavailable, events are buffered locally with size limits and dropped oldest-first when full.
- Observability: structured JSONL logs, Prometheus-compatible metrics, and health endpoints.
- Testing: unit tests for detectors, integration tests for API endpoints, and schema validation for event logs.

## Deployment
- Dockerized with `docker-compose.yml` for optional Postgres/Kafka/Redis.
- Config-driven via `config/config.yaml` for model paths, zone definitions, and thresholds.

## Security/Privacy
- PII avoidance: events include bounding boxes and track IDs, but no facial or identity data is stored by default.
- Access control: API protected by simple token mechanism for demos; recommend OAuth2 for production.

## Appendix
- See `src/streaming/event_schema.py` for authoritative event field definitions.
![](<Screenshot 2026-06-04 at 10.53.48 PM.png>)