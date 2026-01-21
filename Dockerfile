# Multi-stage Dockerfile for LatticeLock Flutter Web Application
# Stage 1: Flutter Build Stage
FROM ghcr.io/cirruslabs/flutter:3.35.7 AS build-stage

# Set working directory
WORKDIR /app

# Increase Node heap size for better memory management
ENV NODE_OPTIONS=--max-old-space-size=4096

# Copy pubspec files
COPY pubspec.* ./

# Download dependencies with verbose output
RUN flutter pub get --verbose

# Copy the rest of the source code
COPY . .

# Configure web platform and build for production
RUN flutter create . --platforms=web --project-name=latticelock

# Build with API URL from build argument (defaults to localhost:8000)
# Added verbose logging and disabled wasm dry run for faster builds
ARG PDF_API_BASE_URL=http://localhost:8000
RUN echo "=== Starting Flutter web build ===" && \
    flutter build web --release --no-pub --csp --verbose \
    --dart-define=PDF_API_BASE_URL=${PDF_API_BASE_URL} \
    --no-wasm-dry-run && \
    echo "=== Build completed successfully ===" && \
    ls -lh build/web/

# Stage 2: Nginx Runtime Stage
FROM nginx:alpine AS runtime-stage

# Install additional nginx modules for better SPA support
RUN apk add --no-cache curl

# Remove default nginx content
RUN rm -rf /usr/share/nginx/html/*

# Copy built Flutter app from build stage
COPY --from=build-stage /app/build/web /usr/share/nginx/html

# Copy custom nginx configuration
COPY nginx-simple.conf /etc/nginx/nginx.conf

# Set proper permissions
RUN chown -R nginx:nginx /usr/share/nginx/html && \
    chmod -R 755 /usr/share/nginx/html

# Expose port 80
EXPOSE 80

# Add health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

# Start nginx
CMD ["nginx", "-g", "daemon off;"]