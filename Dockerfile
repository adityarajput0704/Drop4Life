# ── Dockerfile ────────────────────────────────────────────────────────────────
# Location: Drop4life/Dockerfile  (project root)
#
# Multi-stage build:
# Stage 1 (builder) → installs dependencies into a clean layer
# Stage 2 (runtime) → copies only what's needed, no build tools
#
# Why multi-stage?
# Keeps the final image small. Build tools (gcc, pip, etc.) stay
# in the builder stage and are never shipped to production.
# ─────────────────────────────────────────────────────────────────────────────

# ── Stage 1: Builder ──────────────────────────────────────────────────────────
FROM python:3.11-slim AS builder

# Set working directory inside the container
WORKDIR /app

# Why copy requirements first (before code)?
# Docker caches each layer. If requirements.txt hasn't changed,
# Docker reuses the cached pip install layer — much faster rebuilds.
COPY requirements.txt .

# Install dependencies into a separate directory
# --no-cache-dir    → don't cache pip downloads (smaller image)
# --prefix=/install → installs to /install so we can copy cleanly to runtime
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ── Stage 2: Runtime ─────────────────────────────────────────────────────────
FROM python:3.11-slim AS runtime

WORKDIR /app

# Copy installed packages from builder stage
COPY --from=builder /install /usr/local

# Copy only the backend code — not Flutter app, not frontend, not .env
# We explicitly list what we need. Nothing else enters the image.
COPY backend/ ./backend/
COPY alembic/ ./alembic/
COPY alembic.ini .

# Security: run as non-root user
# If an attacker breaks into your container, they get this user — not root.
RUN useradd --create-home --shell /bin/bash appuser
USER appuser

# Document which port the app listens on (informational — Render reads $PORT)
EXPOSE 8000

# Health check — Render and Docker can detect if your app is alive
# Tries /  every 30s. If it fails 3 times, container is marked unhealthy.
HEALTHCHECK --interval=30s --timeout=10s --start-period=20s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/')" \
    || exit 1

# ── Startup command ───────────────────────────────────────────────────────────
# Why not --reload?
# --reload watches files for changes — useful in dev, wasteful in prod.
# In production, the image itself is the "version" — no hot reloading needed.
#
# $PORT → Render sets this dynamically. We must read it.
# workers 1 → Start with 1. Scale horizontally on Render, not vertically here.
CMD ["sh", "-c", "alembic upgrade head && uvicorn backend.main:app --host 0.0.0.0 --port ${PORT:-8000} --workers 1"]