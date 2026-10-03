# ============================================
# Stage 1 — Base image
# ============================================
FROM python:3.11-slim-bullseye
WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8080 \
    MODE=cloud   # default mode (can be overridden to 'local')

# ============================================
# Stage 2 — OS + Python dependencies
# ============================================
RUN apt-get update && apt-get upgrade -y && apt-get clean && rm -rf /var/lib/apt/lists/*
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt && rm -rf ~/.cache/pip

# ============================================
# Stage 3 — Copy project files
# ============================================
COPY app ./app

# ============================================
# Stage 4 — Non-root runtime user
# ============================================
RUN useradd -m appuser
USER appuser

EXPOSE 8080

# ============================================
# Stage 5 — Conditional start command
# ============================================
# When MODE=local: bind only to localhost (safer on dev machine)
# When MODE=cloud: bind to all interfaces and trust Cloud Run proxy
CMD ["sh", "-c", "\
if [ \"$MODE\" = 'local' ]; then \
    echo '🚧 Running in LOCAL mode' && \
    uvicorn app.main:app --host 127.0.0.1 --port ${PORT:-8080}; \
else \
    echo '☁️  Running in CLOUD mode' && \
    uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8080} --proxy-headers; \
fi"]
