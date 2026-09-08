# Standalone 3D-print library curator — NOT part of Manyfold UI.
# Talks to DGX Spark (Gemma / Qwen / NudeNet) and rearranges files on a mounted library volume.
FROM python:3.12-slim-bookworm

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    LIBRARY_ROOT=/library \
    WORK_DIR=/library/.spark-curate

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl ca-certificates libarchive13 \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY spark_curate ./spark_curate
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Health: process is a batch job; use smoke against Spark when asked.
ENTRYPOINT ["/entrypoint.sh"]
# Default: dry-run entire library once
CMD ["--library", "/library"]
