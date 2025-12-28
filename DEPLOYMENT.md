# LatticeLock Deployment Guide

## Overview

LatticeLock consists of a Flutter frontend and FastAPI backend for professional PDF generation with security patterns. This guide covers local development and Docker deployment.

## Architecture

### Components

1. **Flutter Web Frontend** - UI for pattern generation and visualization
2. **FastAPI Backend** - Python backend with ReportLab for PDF generation
3. **Docker Compose** - Container orchestration for full-stack deployment

### Color Scheme Matching

The system now uses **exact Flutter UI colors** in both frontend and PDF generation:

| Ink ID | UI Label | Flutter Color | Hex Code | PDF Color |
|--------|----------|---------------|-----------|-----------|
| 0 | 75°C Reactive | `Colors.cyanAccent` | **#00E5FF** | CMYK(0.84, 0, 0.05, 0) |
| 1 | 75°C Protected | `Colors.cyan` | **#00BCD4** | CMYK(1, 0, 0.12, 0.15) |
| 2 | 55°C Reactive | `Colors.tealAccent` | **#1DE9B6** | CMYK(0.82, 0, 0.35, 0) |
| 3 | 55°C Protected | `Colors.teal` | **#009688** | CMYK(1, 0, 0.35, 0.24) |
| 4 | 35°C Marker | `Colors.blue` | **#2196F3** | CMYK(0.79, 0.49, 0, 0) |
| 5 | Default | `Colors.cyanAccent` | **#00E5FF** | CMYK(0.84, 0, 0.05, 0) |

## Architecture

### Multi-Stage Docker Build
- **Build Stage**: Flutter SDK environment for building the web application
- **Runtime Stage**: Lightweight Nginx Alpine image serving the static files

### Infrastructure Components
- **Flutter Web App**: Main application served by Nginx
- **Redis**: Session storage and caching
- **PostgreSQL**: Database for material profiles and user data
- **Backend API**: FastAPI backend (placeholder for future implementation)
- **Monitoring**: Grafana + Prometheus (optional)

## Prerequisites

- Docker 20.10+ and Docker Compose 2.0+
- Git
- Make (optional, for using the Makefile)
- Flutter 3.19+ (for local development)

## Flutter Environment Configuration

LatticeLock supports environment-based configuration for different deployment environments.

### PDF API Base URL

The `PDF_API_BASE_URL` environment variable controls the FastAPI backend endpoint for PDF generation.

#### Development Environment

Use the development environment file:

```bash
flutter run -d web-server --dart-define-from-file=lib/.env.dev
```

This will use the default development URL: `http://localhost:8001`

#### Production Environment

Use the production environment file:

```bash
flutter run -d web-server --dart-define-from-file=lib/.env.prod
```

This will use the production URL: `https://api.latticelock.com`

#### Custom Environment

You can also define the URL directly:

```bash
flutter run -d web-server --dart-define=PDF_API_BASE_URL=http://your-api-url.com
```

#### Environment File Format

Environment files use a simple key=value format:

```ini
# lib/.env.dev
PDF_API_BASE_URL=http://localhost:8001

# lib/.env.prod
PDF_API_BASE_URL=https://api.latticelock.com
```

#### Building for Production

When building for production, use the production environment:

```bash
flutter build web --dart-define-from-file=lib/.env.prod
```

## Quick Start

### 1. Clone and Setup
```bash
git clone <repository-url>
cd latticelock
cp .env.example .env
# Edit .env with your configuration
```

### 2. Development Deployment
```bash
# Deploy core services (web, redis, postgres)
docker-compose up -d

# Deploy with monitoring
docker-compose --profile monitoring up -d

# Deploy with production proxy
docker-compose --profile production up -d
```

### 3. Access the Application
- **Web App**: http://localhost:8080
- **API**: http://localhost:8000 (when backend is implemented)
- **Grafana**: http://localhost:3000 (monitoring profile)
- **Prometheus**: http://localhost:9090 (monitoring profile)

## Configuration

### Environment Variables
Copy `.env.example` to `.env` and configure:

```bash
# Database
POSTGRES_DB=latticelock
POSTGRES_USER=latticelock_user
POSTGRES_PASSWORD=your_secure_password

# Redis
REDIS_PASSWORD=your_redis_password

# Backend
SECRET_KEY=your_super_secret_key
DEBUG=false

# Monitoring
GRAFANA_USER=admin
GRAFANA_PASSWORD=your_grafana_password
```

### SSL Configuration (Production)
1. Place SSL certificates in `./ssl/` directory:
   - `cert.pem` - SSL certificate
   - `key.pem` - Private key

2. Enable production profile:
```bash
docker-compose --profile production up -d
```

## Build and Deployment Options

### Option 1: Full Docker Compose
```bash
# Build and deploy all services
docker-compose up -d --build
```

### Option 2: Individual Service Management
```bash
# Build only the web application
docker-compose build latticelock-web

# Deploy specific services
docker-compose up -d latticelock-web redis postgres
```

### Option 3: Production Deployment
```bash
# Deploy with SSL and reverse proxy
docker-compose --profile production up -d

# Deploy with monitoring
docker-compose --profile production --profile monitoring up -d
```

## Health Checks and Monitoring

### Health Endpoints
- **App Health**: http://localhost:8080/health
- **API Health**: http://localhost:8000/health
- **Nginx Health**: curl -f http://localhost/

### Container Status
```bash
# Check all containers
docker-compose ps

# View logs
docker-compose logs -f latticelock-web

# Check resource usage
docker stats
```

## Performance Optimization

### Build Optimization
- Multi-stage builds reduce final image size
- `.dockerignore` excludes unnecessary files
- Layer caching for faster rebuilds

### Runtime Optimization
- Nginx gzip compression
- Static asset caching
- CanvasKit rendering for better performance

### Database Optimization
- PostgreSQL connection pooling
- Redis caching for frequent operations
- Index optimization for material profiles

## Security Features

### Web Security
- CSP headers
- XSS protection
- Clickjacking protection
- HTTPS enforcement (production)

### Container Security
- Non-root user execution
- Read-only filesystem where possible
- Secrets management via environment variables
- Network isolation via Docker networks

### Data Security
- Encrypted localStorage for web platform
- Platform secure storage for mobile
- Database encryption
- Redis authentication

## Troubleshooting

### Common Issues

1. **Build Fails**:
   ```bash
   # Clean and rebuild
   docker-compose down
   docker system prune -f
   docker-compose build --no-cache
   ```

2. **Port Conflicts**:
   ```bash
   # Check port usage
   netstat -tulpn | grep :8080
   # Modify ports in docker-compose.yml
   ```

3. **Permission Issues**:
   ```bash
   # Fix volume permissions
   sudo chown -R $USER:$USER ./
   ```

4. **Memory Issues**:
   ```bash
   # Increase Docker memory limit
   # Or use resource limits in docker-compose.yml
   ```

### Debugging
```bash
# View container logs
docker-compose logs -f <service-name>

# Execute commands in container
docker-compose exec latticelock-web sh

# Inspect container
docker inspect latticelock-web
```

## Scaling and High Availability

### Horizontal Scaling
```bash
# Scale web application
docker-compose up -d --scale latticelock-web=3
```

### Load Balancing
The Nginx configuration supports multiple web instances and includes:
- Round-robin load balancing
- Health checks
- Graceful shutdown handling

## CI/CD Integration

### GitHub Actions Example
```yaml
name: Deploy LatticeLock
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Deploy to Docker
        run: |
          echo "${{ secrets.DOCKER_PASSWORD }}" | docker login -u "${{ secrets.DOCKER_USERNAME }}" --password-stdin
          docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d --build
```

## Maintenance

### Backup
```bash
# Backup database
docker-compose exec postgres pg_dump -U latticelock_user latticelock > backup.sql

# Backup volumes
docker run --rm -v latticelock_postgres-data:/data -v $(pwd):/backup alpine tar czf /backup/postgres-backup.tar.gz -C /data .
```

### Updates
```bash
# Update application
docker-compose pull
docker-compose up -d

# Update with zero downtime
docker-compose up -d --no-deps latticelock-web
```

### Cleanup
```bash
# Remove unused images and containers
docker system prune -a

# Remove unused volumes
docker volume prune
```

## Support and Monitoring

### Monitoring Dashboard
Access Grafana at http://localhost:3000 for:
- Application metrics
- System performance
- Database statistics
- Custom alerts

### Logs
```bash
# Aggregate logs from all services
docker-compose logs

# Real-time log monitoring
docker-compose logs -f --tail=100
```

## Next Steps

1. **Backend Integration**: Implement FastAPI backend service
2. **Database Setup**: Create PostgreSQL schema and migrations
3. **SSL Setup**: Configure SSL certificates for production
4. **Monitoring**: Set up custom Grafana dashboards
5. **CI/CD**: Configure automated deployment pipeline
6. **Scaling**: Implement Kubernetes deployment for larger scale