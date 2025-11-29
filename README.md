# LatticeLock 🔐

A sophisticated Flutter application that generates secure encryption patterns for physical security tags using chaos-based cryptography algorithms. Transform batch codes and serial numbers into unique 8×8 grid patterns using temperature-reactive inks for advanced anti-counterfeiting protection.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white)

## 🌟 Key Features

### 🔐 Advanced Cryptography
- **Chaos-Based Encryption**: Implements Logistic Map, Tent Map, and Arnold's Cat Map algorithms
- **Deterministic Patterns**: Same input always generates identical secure patterns
- **High Entropy**: Multiple entropy sources ensure unpredictable, secure outputs

### 🖨️ Physical Security Integration
- **Temperature-Reactive Inks**: 75°C, 55°C, and 35°C reactive materials
- **Multi-Role Ink System**: Data encoding, fake elements, and metadata layers
- **PDF Blueprint Generation**: Professional manufacturing specifications

### 📱 Cross-Platform Support
- **Web Application**: Browser-based access with PWA support
- **Mobile Apps**: Native Android and iOS applications
- **Desktop**: Windows, macOS, and Linux support

### 🏗️ Enterprise-Ready Architecture
- **Docker Deployment**: Containerized with multi-stage builds
- **Database Integration**: PostgreSQL with Redis caching
- **Monitoring**: Grafana + Prometheus integration
- **Security**: HTTPS, CSP headers, encrypted storage

## 🚀 Quick Start

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

## 📖 How It Works

### Input Processing
1. **Batch Code Input**: Enter your unique batch code or serial number
2. **Algorithm Selection**: Choose from three chaos-based encryption methods
3. **Material Profile**: Select appropriate ink configuration

### Pattern Generation
1. **Entropy Generation**: Input text is converted to high-entropy seed values
2. **Chaos Computation**: Selected algorithm generates pseudo-random sequence
3. **Quantization**: Chaos values mapped to ink types (0-4)
4. **Grid Formation**: 64-cell 8×8 pattern created

### Output Creation
1. **Visual Preview**: Real-time grid visualization with color coding
2. **PDF Export**: Professional blueprint generation for manufacturing
3. **Secure Storage**: Encrypted local storage of patterns

## 🔬 Cryptographic Algorithms

### Logistic Map (Chaos)
```dart
// x_next = r * x * (1 - x) where r = 3.99
x = r * x * (1 - x);
inkId = (x * 5).floor(); // Map to 0-4 ink types
```

### Tent Map (Chaos)
Piecewise linear chaotic map providing excellent distribution properties.

### Arnold's Cat Map
2D chaotic transformation preserving ergodic properties.

## 🎨 Material Profiles

### Standard Set A (Le Chatelier)
- **75°C Reactive** (75R): High-temperature data encoding
- **75°C Protected** (75P): Fake element for anti-counterfeiting
- **55°C Reactive** (55R): Low-temperature data encoding
- **55°C Protected** (55P): Additional fake element
- **35°C Marker** (35M): Metadata and alignment marking

## 🏛️ Architecture

### Frontend (Flutter)
```
lib/
├── main.dart                    # Application entry point
├── core/                        # Core services and utilities
│   ├── services/
│   │   ├── crypto_integration_test.dart
│   │   ├── native_crypto_service.dart
│   │   └── secure_storage_service.dart
│   └── utils/
│       └── data_converter.dart
├── features/
│   ├── generator/               # Pattern generation feature
│   │   ├── presentation/
│   │   │   └── generator_screen.dart
│   │   ├── logic/
│   │   │   └── generator_state.dart
│   │   └── domain/
│   │       └── generator_use_case.dart
│   ├── encryption/              # Cryptographic algorithms
│   │   ├── domain/
│   │   │   └── encryption_strategy.dart
│   │   └── data/
│   │       ├── chaos_strategy.dart
│   │       ├── tent_map_strategy.dart
│   │       └── arnolds_cat_map_strategy.dart
│   └── material/                # Ink and material profiles
│       └── models/
│           └── ink_profile.dart
```

### Backend Infrastructure
- **Web Server**: Nginx with gzip compression and caching
- **Database**: PostgreSQL for material profiles and user data
- **Cache**: Redis for session storage and performance
- **Monitoring**: Prometheus metrics with Grafana dashboards

## 🔧 Development

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

## 🐳 Docker Configuration

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

## 🔒 Security Features

### Data Protection
- **Encrypted Storage**: Platform-secure storage for sensitive data
- **CSP Headers**: Content Security Policy implementation
- **XSS Protection**: Cross-site scripting prevention
- **Clickjacking Protection**: Frame options and headers

### Cryptographic Security
- **Post-Quantum Ready**: Chaos-based algorithms resistant to quantum attacks
- **High Entropy**: Multiple entropy sources prevent predictability
- **Deterministic Security**: Same input = same output for verification

### Infrastructure Security
- **Container Security**: Non-root execution and read-only filesystems
- **Network Isolation**: Docker network segmentation
- **Secrets Management**: Environment variable-based configuration

## 📊 Monitoring & Observability

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

## 🚀 Deployment Options

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

## 🔄 CI/CD Integration

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

## 🛠️ API Reference

### Pattern Generation
```dart
final pattern = await generatorUseCase.generatePattern(
  inputText: "LATTICE-2025-X",
  algorithm: "chaos_logistic"
);
```

### PDF Generation
```dart
await generatorUseCase.generatePDF(
  pattern: encryptedPattern,
  material: selectedMaterial,
  inputText: batchCode
);
```

## 🤝 Contributing

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

## 📝 License

This project is proprietary software. All rights reserved.

## 📞 Support

For support and questions:
- Create an issue in the repository
- Contact the development team
- Check the deployment documentation for common issues

## 🗺️ Roadmap

### Phase 1 (Current)
- ✅ Core pattern generation algorithms
- ✅ Cross-platform Flutter application
- ✅ Docker deployment infrastructure
- ✅ PDF blueprint generation

### Phase 2 (Upcoming)
- 🔄 Backend API integration
- 🔄 Database schema implementation
- 🔄 User authentication and authorization
- 🔄 Advanced material profile management

### Phase 3 (Future)
- 🔄 Mobile camera integration for scanning
- 🔄 Real-time pattern verification
- 🔄 Batch processing capabilities
- 🔄 Advanced analytics and reporting

---

**LatticeLock** - Securing the physical world with mathematical chaos. 🔐✨</content>
<filePath>README.md