# LatticeLock

A sophisticated Flutter application that generates secure spatial patterns for physical security tags using chaos-based pattern generation algorithms. Transform batch codes and serial numbers into unique 3×3 to 8×8 grid patterns using temperature-reactive inks for advanced anti-counterfeiting protection.

**Core Purpose**: Manufacturing control and authenticity verification (NOT encryption)
- Patterns serve as deposition maps for inkjet printing of perovskite quantum dot tags
- Scanner module verifies printed tags against stored patterns
- Physical material properties provide security through authenticity verification

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)
![OpenCV](https://img.shields.io/badge/OpenCV-5C3EE8?style=for-the-badge&logo=opencv&logoColor=white)

## Key Features

### Advanced Pattern Generation
- **Hybrid Chaotic Patterns**: Combines diffusion, permutation, and substitution stages
- **Deterministic Output**: Same input always generates identical patterns
- **Variable Grid Sizes**: Supports 3×3 to 8×8 grids for different use cases
- **Multi-Ink Support**: Configurable number of material inks (2-5 colors)

### Scanner & Verification
- **Hough Transform Detection**: Accurate grid line detection for sparse grids
- **Centroid-Based Fallback**: Reliable detection for dense grids
- **K-Means Color Clustering**: Automatic color identification with duplicate merging
- **Subset Color Matching**: Scanned patterns can use fewer colors than stored profile
- **Pattern Verification**: Database lookup with confidence scoring

### Physical Security Integration
- **Temperature-Reactive Inks**: 75°C, 55°C, and 35°C reactive materials
- **Multi-Role Ink System**: Data encoding, fake elements, and metadata layers
- **PDF Blueprint Generation**: Professional manufacturing specifications
- **CMYK Color Matching**: Exact color reproduction in printed PDFs

### Digital Signatures
- **HMAC-SHA256**: Cryptographic pattern signing
- **Authenticity Verification**: Tamper detection through signature validation
- **Secure Key Management**: Shared secret key model with constant-time comparison

### Cross-Platform Support
- **Web Application**: Browser-based access with PWA support
- **Mobile Apps**: Native Android and iOS applications
- **Desktop**: Windows, macOS, and Linux support

### Enterprise-Ready Architecture
- **Docker Deployment**: Containerized with multi-stage builds
- **Database Integration**: SQLite for pattern storage and retrieval
- **FastAPI Backend**: Modern async Python backend with OpenCV
- **Security**: Encrypted storage, digital signatures, CSP headers

## Quick Start

### Prerequisites
- Flutter SDK (3.9.0+)
- Docker & Docker Compose (20.10+)
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd latticelock
   ```

2. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the application**
   ```bash
   flutter run
   ```

### Docker Deployment

1. **Setup environment**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

2. **Deploy with Docker Compose**
   ```bash
   # Development deployment
   docker-compose up -d

   # Production with SSL
   docker-compose --profile production up -d

   # With monitoring
   docker-compose --profile monitoring up -d
   ```

3. **Access the application**
   - Web App: http://localhost:8080
   - API: http://localhost:8000
   - Grafana: http://localhost:3000

## How It Works

### Pattern Generation
1. **Batch Code Input**: Enter your unique batch code or serial number
2. **Grid Size Selection**: Choose from 3×3 to 8×8 grid size
3. **Material Profile**: Select appropriate ink configuration (2-5 colors)
4. **Pattern Generation**: Hybrid chaotic algorithm generates spatial deposition map
5. **Digital Signature**: Pattern signed with HMAC-SHA256 for authenticity

### Scanner Verification
1. **Image Upload**: Capture or upload printed tag image
2. **Grid Detection**: Hough transform detects grid lines (sparse) or centroids (dense)
3. **Color Clustering**: K-means identifies 2-5 colors with duplicate merging
4. **Pattern Extraction**: Grid converted to ink ID sequence
5. **Database Verification**: Match against stored patterns with confidence scoring

### PDF Export
1. **Visual Preview**: Real-time grid visualization with color coding
2. **PDF Generation**: Professional blueprint with exact CMYK colors
3. **Manufacturing**: PDF used as inkjet printing guide
4. **Secure Storage**: Encrypted local storage of patterns with signatures

## Material Profiles

### Standard Set A (Le Chatelier)
- **75°C Reactive** (75R): High-temperature data encoding
- **75°C Protected** (75P): Fake element for anti-counterfeiting
- **55°C Reactive** (55R): Low-temperature data encoding
- **55°C Protected** (55P): Additional fake element
- **35°C Marker** (35M): Metadata and alignment marking

## Architecture

### Frontend (Flutter)
```
lib/
├── main.dart                    # Application entry point
├── core/                        # Core services and utilities
│   ├── services/
│   │   ├── fastapi_pdf_service.dart  # PDF generation
│   │   ├── history_service.dart       # Pattern history
│   │   ├── pdf_download.dart          # Platform-specific download
│   │   └── indexeddb_storage_service.dart  # Web storage
│   └── models/
│       ├── grid_config.dart           # Grid configuration
│       ├── pattern_history_entry.dart # History records
│       └── signed_pattern.dart        # Pattern with signature
└── features/
    ├── pattern/                  # Pattern generation algorithms
    │   └── data/
    │       └── hybrid/           # Hybrid chaotic pattern
    │           ├── diffusion_stage.dart
    │           ├── permutation_stage.dart
    │           ├── substitution_stage.dart
    │           └── hybrid_chaotic_pattern.dart
    ├── scanner/                  # Image scanner & verification
    │   ├── domain/
    │   │   └── scanner_use_case.dart
    │   └── presentation/
    │       └── scanner_screen.dart
    ├── signature/                # Digital signatures
    │   └── domain/
    │       ├── signature_service.dart
    │       └── secure_pattern_generator.dart
    └── material/                 # Ink profiles
        └── models/
            └── ink_profile.dart
```

### Backend (FastAPI + OpenCV)
```
backend/
├── main.py                      # FastAPI app, scanner, PDF generation
├── database/                    # SQLite database
│   ├── models.py                # SQLAlchemy ORM
│   ├── repository.py            # Database repository
│   └── database.py              # Database initialization
└── requirements.txt             # Python dependencies
```

**Key Backend Features:**
- **Scanner**: Hough transform grid detection, K-means color clustering
- **PDF Generation**: ReportLab with CMYK color matching
- **Database**: SQLite for pattern storage and retrieval
- **API**: RESTful endpoints for scanner, verification, and PDF generation

## Development

### Running Tests
```bash
flutter test
```

### Building for Production
```bash
# Web build
flutter build web --release

# Mobile builds
flutter build apk --release
flutter build ios --release

# Desktop builds
flutter build windows --release
flutter build macos --release
flutter build linux --release
```

### Code Quality
```bash
# Lint check
flutter analyze

# Format code
flutter format .
```

## Docker Configuration

### Multi-Stage Build
```dockerfile
# Build stage
FROM cirrusci/flutter:stable AS build
WORKDIR /app
COPY . .
RUN flutter build web --release

# Runtime stage
FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf
```

### Environment Configuration
```bash
# Database
POSTGRES_DB=latticelock
POSTGRES_USER=latticelock_user
POSTGRES_PASSWORD=secure_password

# Redis
REDIS_PASSWORD=redis_password

# Application
SECRET_KEY=super_secret_key
DEBUG=false
```

## Security Features

### Data Protection
- **Encrypted Storage**: Platform-secure storage for sensitive patterns
- **Digital Signatures**: HMAC-SHA256 for authenticity verification
- **CSP Headers**: Content Security Policy implementation
- **XSS Protection**: Cross-site scripting prevention

### Pattern Security
- **Deterministic Generation**: Same input always produces identical pattern
- **Tamper Detection**: Signatures detect unauthorized modifications
- **Physical Security**: Material properties prevent cloning
- **Scanner Verification**: Database lookup confirms authenticity

### Infrastructure Security
- **Container Security**: Non-root execution and read-only filesystems
- **Network Isolation**: Docker network segmentation
- **Secrets Management**: Environment variable-based configuration

## Monitoring & Observability

### Health Checks
- Application health: `/health`
- API health: `/api/health`
- Container health checks via Docker

### Metrics
- Application performance metrics
- Database connection pooling stats
- Cache hit/miss ratios
- Error rates and response times

### Logging
```bash
# View application logs
docker-compose logs -f latticelock-web

# View all service logs
docker-compose logs -f
```

## Deployment Options

### Development
```bash
docker-compose up -d
```

### Production
```bash
docker-compose --profile production up -d
```

### High Availability
```bash
# Scale web application
docker-compose up -d --scale latticelock-web=3
```

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

## API Reference

### Pattern Generation
```dart
final pattern = await generatorUseCase.generatePattern(
  inputText: "LATTICE-2025-X",
  gridSize: 8,  // 3×3 to 8×8
  numInks: 3,   // 2 to 5 colors
);
```

### Scanner Analysis
```dart
final result = await scannerUseCase.analyzeImage(imageBytes);
// Returns: pattern (ink IDs), extractedColors (RGB), gridDetected
```

### Pattern Verification
```dart
final verification = await scannerUseCase.verifyPattern(
  pattern,
  algorithm: "hybrid_chaotic",
  extractedColors: rgbGrid,
);
// Returns: matches, partialMatches, confidence
```

### PDF Generation
```dart
await pdfService.generatePDF(
  pattern: pattern,
  material: selectedMaterial,
  inputText: batchCode,
  gridSize: 8,
);
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines
- Follow Flutter best practices and effective Dart
- Write comprehensive tests for new features
- Update documentation for API changes
- Ensure cross-platform compatibility

## License

MIT License - See LICENSE file for details

## Support

For support and questions:
- Create an issue in the repository
- Contact the development team
- Check the deployment documentation for common issues

## Roadmap

### Phase 1 (Current)
- Core pattern generation algorithms (Hybrid Chaotic Pattern)
- Cross-platform Flutter application
- Docker deployment infrastructure
- PDF blueprint generation with CMYK colors
- Scanner module with Hough transform grid detection
- Digital signatures with HMAC-SHA256
- Variable grid sizes (3×3 to 8×8)
- SQLite database for pattern storage

### Phase 2 (Upcoming)
- Mobile camera integration for real-time scanning
- Advanced material profile management
- Batch processing capabilities
- User authentication and authorization
- Analytics and reporting dashboard

### Phase 3 (Future)
- Machine learning for improved scanner accuracy
- Multi-language support
- Cloud deployment with auto-scaling
- Advanced analytics and pattern insights

---

**LatticeLock** - Securing the physical world with mathematical chaos.</content>
<filePath>README.md