# Multi-stage build for production optimization
FROM python:3.10-slim as builder

# Set working directory
WORKDIR /app

# Set environment variables for build stage
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Install system dependencies for building
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

# Production stage
FROM python:3.10-slim as production

# Set working directory
WORKDIR /app

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/root/.local/bin:$PATH"

# Install runtime dependencies only
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Copy Python packages from builder stage
COPY --from=builder /root/.local /root/.local

# Create non-root user for security
RUN useradd --create-home --shell /bin/bash --uid 1000 app

# Copy application code
COPY --chown=app:app . .

# Create necessary directories
RUN mkdir -p logs saved_models && \
    chown -R app:app logs saved_models

# Switch to non-root user
USER app

# Add labels for metadata
LABEL maintainer="Wine Quality Prediction Team" \
      version="1.0.0" \
      description="Wine Quality Prediction API with ML models and AI insights"

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl --fail http://localhost:8000/api/v1/prediction/health || exit 1

# Use entrypoint script
COPY --chown=app:app docker-entrypoint.sh /app/
USER root
RUN chmod +x /app/docker-entrypoint.sh
USER app

# Run the application
ENTRYPOINT ["/app/docker-entrypoint.sh"]
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
