# Multi-stage Dockerfile for LatticeLock (Backend + Frontend in single container)
# Stage 1: Flutter Build Stage
FROM ghcr.io/cirruslabs/flutter:3.35.7 AS flutter-build

WORKDIR /app
ENV NODE_OPTIONS=--max-old-space-size=4096

COPY pubspec.* ./
RUN flutter pub get --verbose
COPY . .
RUN flutter create . --platforms=web --project-name=latticelock

ARG PDF_API_BASE_URL=http://localhost:8000
RUN echo "=== Starting Flutter web build ===" && \
    flutter build web --release --no-pub --csp --verbose \
    --dart-define=PDF_API_BASE_URL=${PDF_API_BASE_URL} \
    --no-wasm-dry-run && \
    echo "=== Build completed successfully ==="

# Stage 2: Backend Stage
FROM python:3.11-slim AS backend-build

WORKDIR /app

# Disable AVX-512 optimizations at runtime
ENV NPY_DISABLE_CPU_FEATURES="X86_V4 AVX512F AVX512CD AVX512VL AVX512BW AVX512DQ"

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    curl \
    supervisor \
    libgl1 \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY backend/ /app/

# Create non-root user
RUN useradd --create-home --shell /bin/bash app && \
    chown -R app:app /app

# Stage 3: Final Runtime Image (Backend + nginx + Flutter web)
FROM python:3.11-slim

WORKDIR /app

# Disable AVX-512 optimizations
ENV NPY_DISABLE_CPU_FEATURES="X86_V4 AVX512F AVX512CD AVX512VL AVX512BW AVX512DQ"

# Install system dependencies (nginx + supervisor + OpenCV deps)
RUN apt-get update && apt-get install -y \
    gcc \
    curl \
    supervisor \
    nginx \
    libgl1 \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/* \
    && rm -f /etc/nginx/conf.d/default.conf

# Copy Python dependencies from backend-build stage
COPY --from=backend-build /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=backend-build /usr/local/bin /usr/local/bin

# Copy backend application code
COPY --from=backend-build /app /app

# Copy Flutter web build
COPY --from=flutter-build /app/build/web /usr/share/nginx/html

# Copy nginx configuration
COPY nginx-simple.conf /etc/nginx/nginx.conf

# Copy supervisor configuration
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Copy entrypoint script
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# Create non-root user and set permissions
RUN useradd --create-home --shell /bin/bash app && \
    chown -R app:app /app /usr/share/nginx/html /var/log/nginx /var/lib/nginx /run

# Expose ports
EXPOSE 80 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8000/health && curl -f http://localhost/ || exit 1

# Run supervisor to manage both processes
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
