FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Disable AVX-512 optimizations at runtime
# Pre-built wheels are built on Alder Lake (AVX-512) but deployed to Broadwell-EP (AVX2 only)
# This only disables AVX-512 features, preserves AVX2 which sg-server supports
ENV NPY_DISABLE_CPU_FEATURES="X86_V4 AVX512F AVX512CD AVX512VL AVX512BW AVX512DQ"

# Install system dependencies
# libgl1: OpenGL library required by OpenCV
# libglib2.0-0: GLib library required by OpenCV
RUN apt-get update && apt-get install -y \
    gcc \
    curl \
    libgl1 \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python dependencies
# Use pre-built wheels for speed (sg-server has real CPU with AVX2 support)
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create non-root user for security
RUN useradd --create-home --shell /bin/bash app && \
    chown -R app:app /app
USER app

# Expose port
EXPOSE 8000

# Health check - give backend enough time to initialize OpenCV and database
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=5 \
    CMD curl -f http://localhost:8000/health || exit 1

# Run the application
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]