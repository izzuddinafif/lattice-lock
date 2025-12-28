# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

LatticeLock is a Flutter application that generates secure encryption patterns for physical security tags using chaos-based cryptography algorithms. The app creates 8×8 grid patterns from batch codes/serial numbers using temperature-reactive inks for anti-counterfeiting protection.

**Tech Stack**: Flutter 3.9+, Dart, FastAPI (Python backend), PostgreSQL, Redis, Docker
**Platforms**: Web, Android, iOS, Windows, macOS, Linux

## Essential Commands

### Flutter Development

```bash
# Install dependencies
flutter pub get

# Run on web (development with local backend)
flutter run -d web-server --dart-define-from-file=lib/.env.dev

# Run on web (production with remote backend)
flutter run -d web-server --dart-define-from-file=lib/.env.prod

# Run tests
flutter test

# Run single test file
flutter test test/widget_test.dart

# Run tests with coverage
flutter test --coverage

# Analyze code
flutter analyze

# Format code
flutter format .

# Build for production
flutter build web --release                    # Web
flutter build apk --release                    # Android APK
flutter build ios --release                    # iOS
flutter build windows --release                # Windows
flutter build macos --release                  # macOS
flutter build linux --release                  # Linux
```

### Backend Development (FastAPI/Python)

```bash
cd backend

# Install dependencies
pip install -r requirements.txt

# Run development server
uvicorn main:app --reload --host 0.0.0.0 --port 8000

# Run backend tests
python test_api.py

# Debug PDF generation
python debug_pdf.py
```

### Docker Deployment

```bash
# Development deployment (core services)
docker-compose up -d

# Production deployment with SSL
docker-compose --profile production up -d

# With monitoring stack
docker-compose --profile monitoring up -d

# Scale web application
docker-compose up -d --scale latticelock-web=3

# View logs
docker-compose logs -f latticelock-web
docker-compose logs -f  # All services

# Rebuild specific service
docker-compose build latticelock-web
docker-compose up -d --no-deps latticelock-web  # Zero downtime
```

### Environment Configuration

The `PDF_API_BASE_URL` environment variable controls the FastAPI backend endpoint:

- **Development** (`lib/.env.dev`): `http://localhost:8001`
- **Production** (`lib/.env.prod`): `https://api.latticelock.com`

Custom environment:
```bash
flutter run -d web-server --dart-define=PDF_API_BASE_URL=http://your-api-url.com
```

## Architecture Overview

### Frontend Structure (Clean Architecture + Feature-First)

```
lib/
├── main.dart                          # App entry point, provider setup
├── core/                              # Cross-cutting concerns
│   ├── constants/                     # App-wide constants
│   ├── models/                        # Shared data models (GridConfig, PatternHistoryEntry)
│   ├── services/                      # Core services
│   │   ├── fastapi_pdf_service.dart   # PDF generation via FastAPI backend
│   │   ├── history_service.dart       # Pattern history management
│   │   ├── native_crypto_service.dart # Platform native encryption
│   │   ├── hive_storage_service.dart  # Mobile storage (Hive)
│   │   └── indexeddb_storage_service.dart # Web storage (IndexedDB)
│   └── utils/                         # Utilities (data converter, platform detector)
└── features/                          # Feature modules
    ├── encryption/                    # Chaos-based cryptography algorithms
    │   ├── domain/
    │   │   └── encryption_strategy.dart     # Abstract strategy interface
    │   └── data/
    │       ├── chaos_strategy.dart          # Logistic map: x = r*x*(1-x)
    │       ├── tent_map_strategy.dart       # Tent map algorithm
    │       ├── arnolds_cat_map_strategy.dart # 2D chaotic transformation
    │       └── hash/
    │           └── sha256_hash_strategy.dart
    ├── generator/                     # Pattern generation feature
    │   ├── domain/
    │   │   └── generator_use_case.dart      # Core business logic (encryption → pattern → PDF)
    │   ├── logic/
    │   │   ├── generator_state.dart         # UI state management (Riverpod)
    │   │   └── history_state.dart          # History UI state
    │   └── presentation/
    │       ├── generator_screen.dart        # Main generator UI
    │       └── history_screen.dart          # Pattern history UI
    └── material/                      # Material/ink profile management
        ├── models/
        │   ├── ink_profile.dart             # Ink configuration model
        │   └── custom_ink_profile.dart      # Custom ink profiles (Hive)
        ├── data/
        │   └── material_profile_repository.dart
        ├── providers/
        │   ├── ink_configuration_provider.dart
        │   └── material_profile_provider.dart
        └── presentation/
            ├── ink_configuration_screen.dart
            └── profile_list_screen.dart
```

### Key Architectural Patterns

**1. Strategy Pattern (Encryption)**
- `EncryptionStrategy` interface defines `encrypt(String input, int length) → List<int>`
- Implementations: ChaosLogisticStrategy, TentMapStrategy, ArnoldsCatMapStrategy
- All algorithms output ink IDs (0-4) for the 5 material types

**2. Use Case Pattern (Generator)**
- `GeneratorUseCase` orchestrates the core workflow:
  1. Accepts batch code input
  2. Applies encryption strategy to generate 64-value pattern (8×8 grid)
  3. Generates PDF via `FastApiPDFService`
  4. Stores pattern in history via `HistoryService`
- Native crypto fallback: Uses platform native encryption when available, falls back to chaos algorithms

**3. Service Abstraction (PDF Generation)**
- `PDFService` interface with two implementations:
  - `FastApiPDFService`: Calls FastAPI backend for professional ReportLab PDFs
  - Backend endpoint: `POST /generate-pdf` → returns base64 PDF
- Platform-specific download/sharing logic (web: `dart:html`, mobile: `path_provider`)

**4. Storage Strategy (Platform-Aware)**
- Web: `IndexedDBStorageService` (browser persistence)
- Mobile/Desktop: `HiveStorageService` (local Hive database)
- `HistoryService` abstracts storage behind unified API

**5. State Management (Riverpod)**
- Providers defined in feature modules: `generatorUseCaseProvider`, `historyServiceProvider`
- UI state classes: `GeneratorState`, `HistoryState`
- Riverpod `AsyncValue` for loading/error states

### Backend Architecture (FastAPI)

```
backend/
├── main.py                 # FastAPI app setup, CORS, routes
├── app.py                  # Alternative entry point
├── requirements.txt        # Python dependencies (fastapi, uvicorn, reportlab, pydantic)
├── test_api.py            # API integration tests
└── debug_pdf.py           # PDF generation debugging utility
```

**FastAPI Endpoint:**
- `POST /generate-pdf`: Accepts `PDFMetadata` JSON, returns base64-encoded PDF
- ReportLab generates professional PDFs with exact Flutter UI colors (CMYK color matching)
- Color mapping: Ink IDs 0-4 map to Flutter colors (cyanAccent, cyan, tealAccent, teal, blue)

### Data Flow

**Pattern Generation Flow:**
```
User Input (batch code)
  ↓
GeneratorUseCase.generatePattern()
  ↓
EncryptionStrategy.encrypt() → List<int> (64 values, 0-4)
  ↓
Grid visualization (UI)
  ↓
FastApiPDFService.generatePDF(metadata)
  ↓
POST to http://localhost:8001/generate-pdf
  ↓
Backend: ReportLab generates PDF with CMYK colors
  ↓
Response: base64 PDF bytes
  ↓
Download/Share (platform-specific)
```

**History Storage Flow:**
```
Pattern generated
  ↓
HistoryService.savePattern()
  ↓
Platform detection (kIsWeb check)
  ↓
IndexedDBStorageService (web) OR HiveStorageService (mobile)
  ↓
PatternHistoryEntry stored with metadata
```

## Important Constraints & Requirements

### Color Matching (Critical)
The Flutter UI and backend PDF must use **identical colors**:

| Ink ID | Flutter UI Color | Hex    | PDF CMYK              |
|--------|------------------|--------|-----------------------|
| 0      | cyanAccent       | #00E5FF | CMYK(0.84, 0, 0.05, 0) |
| 1      | cyan             | #00BCD4 | CMYK(1, 0, 0.12, 0.15) |
| 2      | tealAccent       | #1DE9B6 | CMYK(0.82, 0, 0.35, 0) |
| 3      | teal             | #009688 | CMYK(1, 0, 0.35, 0.24) |
| 4      | blue             | #2196F3 | CMYK(0.79, 0.49, 0, 0) |
| 5      | cyanAccent (default) | #00E5FF | CMYK(0.84, 0, 0.05, 0) |

### Environment-Specific Configuration
- Always use `--dart-define-from-file` for environment-specific builds
- Development: Uses `http://localhost:8001` for local backend testing
- Production: Uses `https://api.latticelock.com` for deployed backend
- Never hardcode API URLs in Dart code

### Cross-Platform Considerations
- **Web**: Uses `dart:html` for PDF downloads, IndexedDB for storage
- **Mobile/Desktop**: Uses `path_provider` for file storage, Hive for database
- Check `kIsWeb` constant for platform-specific logic branching

### Cryptography Security
- Native crypto (`NativeCryptoService`) preferred when available
- Fallback to chaos algorithms for backward compatibility
- Sensitive data must use `encryptSensitiveData()` / `decryptSensitiveData()` methods
- Hash verification (SHA-256) ensures data integrity

### Code Organization Rules
1. **Feature-first structure**: New features go under `lib/features/feature_name/`
2. **Domain layer**: Business logic in `domain/` (use cases, entities)
3. **Data layer**: External dependencies in `data/` (strategies, repositories)
4. **Presentation**: UI in `presentation/` (screens, widgets, state)
5. **Core services**: Shared utilities in `lib/core/services/`

### Testing Strategy
- Unit tests for encryption strategies (chaos algorithms)
- Integration tests for PDF service backend (`backend/test_api.py`)
- Widget tests for Flutter UI components
- Use `mockito` for mocking service dependencies

## Development Workflow

1. **Feature Development**:
   - Create feature directory under `lib/features/`
   - Define domain layer (use case, entities)
   - Implement data layer (strategies, repositories)
   - Build presentation layer (screens, state, providers)

2. **Backend Integration**:
   - Start FastAPI backend: `cd backend && uvicorn main:app --reload`
   - Flutter uses `lib/.env.dev` for `http://localhost:8001`
   - Test API with `backend/test_api.py`

3. **Docker Development**:
   - Use `docker-compose.local.yaml` for local development overrides
   - Main `docker-compose.yaml` for production-like deployments
   - Check logs: `docker-compose logs -f <service>`

4. **Code Quality**:
   - Run `flutter analyze` before commits
   - Format with `flutter format .`
   - Ensure all tests pass: `flutter test`

## Key Dependencies

- **flutter_riverpod**: State management (providers, AsyncValue)
- **crypto**: SHA-256 hashing for data integrity
- **http**: HTTP client for FastAPI backend communication
- **pdf**: PDF generation (client-side fallback)
- **printing**: PDF viewing and printing
- **hive**: NoSQL database for mobile/desktop storage
- **flutter_secure_storage**: Encrypted platform storage
- **native_crypto**: Platform native encryption (iOS Keychain, Android Keystore)
- **google_fonts**: Typography
- **camera**: Future camera integration for pattern scanning

## Common Issues & Solutions

1. **Backend Connection Refused**: Ensure FastAPI backend is running on port 8001 (check `lib/.env.dev`)
2. **PDF Generation Fails**: Check backend logs at `http://localhost:8001/docs` for API errors
3. **Storage Not Persisting**: Verify platform detection logic (web vs mobile storage service)
4. **Colors Not Matching**: Ensure backend CMYK values match Flutter hex colors exactly
5. **Build Fails**: Run `flutter clean && flutter pub get` to clear cache
