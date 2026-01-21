FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Disable AVX-512 (X86_V4) optimizations at runtime
# NumPy pre-built wheels may include AVX-512 code paths that fail on older CPUs
# This only disables AVX-512, not AVX2 (X86_V3) which both CPUs support
ENV NPY_DISABLE_CPU_FEATURES="X86_V4 AVX512F AVX512CD AVX512VL AVX512BW AVX512DQ"

# Install system dependencies
# libgl1: OpenGL library required by OpenCV
# libglib2.0-0: GLib library required by OpenCV
# build-essential: required for building NumPy from source
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    curl \
    libgl1 \
    libglib2.0-0 \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python dependencies
# Build NumPy from source with MINIMAL cpu baseline for maximum compatibility
# Pre-built wheels from PyPI don't work on QEMU virtualization
# Force minimal baseline to avoid CPU detection issues on virtualization platforms
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir wheel meson-python ninja && \
    pip install --no-cache-dir --no-binary :none: --no-build-isolation \
    -Csetup-args=-Dcpu-baseline="minimal" \
    -Csetup-args=-Dcpu-dispatch="none" \
    'numpy>=1.26.3,<2.0' && \
    pip install --no-cache-dir -r requirements.txt --no-deps && \
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