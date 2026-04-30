# Builder stage: build wheels with build dependencies
FROM python:3.12.0-slim AS builder

ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
WORKDIR /app

# Install build dependencies (only in builder)
RUN apt-get update \
 && apt-get install -y --no-install-recommends build-essential gcc \
 && rm -rf /var/lib/apt/lists/*

# Copy requirements and build wheels so final image doesn't need compilers
COPY requirements.txt .
RUN python -m pip install --no-cache-dir pip setuptools wheel \
 && pip wheel --no-cache-dir --wheel-dir /wheels -r requirements.txt

# Final runtime image: no build deps, smaller attack surface
FROM python:3.12.0-slim

ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
WORKDIR /app

# Copy pre-built wheels and install from them (no compilers at runtime)
COPY --from=builder /wheels /wheels
COPY requirements.txt .
RUN python -m pip install --upgrade pip \
 && pip install --no-cache-dir --no-index --find-links /wheels -r requirements.txt \
 && rm -rf /wheels

# Copy application code
COPY app ./app

# Create a non-root user and give ownership of the app directory
RUN useradd --create-home --shell /bin/false appuser \
 && chown -R appuser /app
USER appuser

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
