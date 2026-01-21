FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies
# libgl1: OpenGL library required by OpenCV
# libglib2.0-0: GLib library required by OpenCV
# build-essential, ninja-build: required for building NumPy from source
RUN apt-get update && apt-get install -y \
    gcc \
    curl \
    libgl1 \
    libglib2.0-0 \
    build-essential \
    ninja-build \
    && rm -rf /var/lib/apt/lists/*

# Install Python build tools via pip
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir meson-python cython

# Build NumPy with X86_V3 baseline (AVX2 max) for cross-CPU compatibility
# - X86_V3 baseline: works on both Alder Lake (local build) and Broadwell-EP (server)
# - cpu-dispatch=none: no additional optimization paths (avoids AVX-512 compatibility issues)
# This ensures NumPy works when built on newer CPUs and deployed to older CPUs
RUN pip install --no-cache-dir --no-binary :all: 'numpy>=1.26.3' \
    -Csetup-args=-Dcpu-baseline="X86_V3" \
    -Csetup-args=-Dcpu-dispatch="none"

# Verify NumPy installation
RUN python -c "import numpy; print('NumPy version:', numpy.__version__); print('CPU config OK')"

# Copy requirements first for better caching
COPY requirements.txt .

# Install remaining Python dependencies (use pre-built wheels)
RUN pip install --no-cache-dir -r requirements.txt

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