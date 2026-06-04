# CHOICES

## Model Selection
- Chosen model: YOLOv8n (`yolov8n.pt`) for its speed/size tradeoff on CPU for demo deployments.
- Rationale: Small models reduce latency and memory; allows local-first operation without GPU.
- Option to upgrade: yolov8s/yolov8m for higher accuracy; recommend benchmarking per-camera.

## Schema Design
- Event models implemented with Pydantic in `src/streaming/event_schema.py` to ensure strict typing and easy serialization.
- JSONL chosen for event logs: newline-delimited JSON is stream-friendly and easy to validate.
- Event types include detection, tracking, entry/exit, anomaly, analytics snapshot, and system health.
- Timestamps in UTC ISO-8601; `event_id` as UUID for deduplication.

## API Architecture
- FastAPI app located at `src/api/main.py`.
- Endpoints:
  - `/analytics` — returns latest analytics snapshot
  - `/events` — paginated event retrieval (supports filters by `event_type`, `camera_id`, `track_id`)
  - `/anomalies` — list active/past anomalies
  - `/health` — system health
- Design choices:
  - Use Redis for caching latest snapshots for low-latency reads
  - Use Kafka (optional) for durable event streaming to downstream consumers
  - Authentication via API token for demos; pluggable to OAuth2/JWT for production

## Testing & Validation
- Schema validation unit tests ensure event JSON conforms to Pydantic models.
- JSONL log validation script included in `scripts/` (if needed) to check each line parses and matches expected fields.

## Trade-offs
- Simplicity vs. accuracy: favor maintainability for a demo system; allow easy model swap.
- Local-first design may sacrifice scale; provide optional infra to scale horizontally.

## Future Work
- Add active learning loop to retrain detection model from curated false-positive examples.
- Integrate identity-preserving staff tagging (opt-in) using badge data and secure storage.
