# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

LatticeLock is a Flutter application that generates secure spatial patterns for physical security tags using chaos-based pattern generation algorithms. The app creates 3×3 to 8×8 grid patterns from batch codes/serial numbers using temperature-reactive inks for anti-counterfeiting protection.

**Core Purpose**: Manufacturing control and anti-counterfeiting (NOT encryption/encryption)
- Patterns serve as deposition maps for inkjet printing of perovskite quantum dot tags
- Physical material properties provide security through authenticity verification
- Scanner module verifies printed tags against stored patterns

**Tech Stack**: Flutter 3.9+, Dart, FastAPI (Python backend), OpenCV (scanner), SQLite, Docker
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

# Run development server (scanner + PDF generation)
uvicorn main:app --reload --host 0.0.0.0 --port 8000

# Database initialization (SQLite)
python -c "from database.models import Base, engine; Base.metadata.create_all(engine)"

# Run tests (if available)
pytest
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
│   ├── models/                        # Shared data models
│   │   ├── grid_config.dart           # Grid configuration (3×3 to 8×8)
│   │   ├── pattern_history_entry.dart # History record model
│   │   └── signed_pattern.dart        # Pattern with digital signature
│   └── services/                      # Core services
│       ├── fastapi_pdf_service.dart   # PDF generation via FastAPI backend
│       ├── history_service.dart       # Pattern history management
│       ├── pdf_download.dart          # PDF download (mobile/desktop)
│       ├── pdf_download_web.dart      # PDF download (web)
│       ├── native_crypto_service.dart # Platform native encryption
│       ├── hive_storage_service.dart  # Mobile storage (Hive)
│       └── indexeddb_storage_service.dart # Web storage (IndexedDB)
└── features/                          # Feature modules
    ├── pattern/                       # Pattern generation algorithms
    │   ├── domain/
    │   │   └── pattern_generation_strategy.dart # Abstract pattern generation interface
    │   └── data/
    │       ├── hybrid/
    │       │   ├── diffusion_stage.dart      # Hybrid chaotic diffusion
    │       │   ├── permutation_stage.dart    # Hybrid chaotic permutation
    │       │   ├── substitution_stage.dart   # Hybrid chaotic substitution
    │       │   └── hybrid_chaotic_pattern.dart # Complete hybrid pattern
    │       └── hash/
    │           └── sha256_hash_strategy.dart
    ├── scanner/                       # Image scanner & verification
    │   ├── domain/
    │   │   └── scanner_use_case.dart  # Scanner business logic
    │   ├── logic/
    │   │   └── scanner_state.dart     # Scanner UI state
    │   └── presentation/
    │       └── scanner_screen.dart    # Scanner UI
    ├── signature/                     # Digital signatures
    │   ├── domain/
    │   │   ├── signature_service.dart        # Signature service interface
    │   │   └── secure_pattern_generator.dart # Secure pattern generation
    └── material/                      # Material/ink profile management
        ├── models/
        │   ├── ink_profile.dart       # Ink configuration model
        │   └── custom_ink_profile.dart # Custom ink profiles (Hive)
        └── presentation/
            └── ink_configuration_screen.dart
```

### Key Architectural Patterns

**1. Strategy Pattern (Pattern Generation)**
- `PatternGenerationStrategy` interface defines `generatePattern(String input, int length, [int numInks]) → List<int>`
- Purpose: Manufacturing control (NOT encryption) - creates deposition maps for inkjet printing
- Implementations: `HybridChaoticPattern` (diffusion + permutation + substitution)
- All algorithms output ink IDs (0 to numInks-1) for material deposition
- Deterministic: Same input always produces identical pattern
- NOT reversible - pattern is for manufacturing, not secrecy

**2. Scanner Pattern (Image Analysis)**
- `ScannerUseCase` handles image upload and pattern verification
- Backend uses Hough transform for grid line detection (PRIMARY method for grids < 6×6 or < 50 components)
- Centroid-based fallback for dense grids (6×6 to 8×8)
- Supports variable grid sizes: 3×3, 4×4, 5×5, 6×6, 7×7, 8×8
- K-means color clustering with duplicate detection and merging
- Subset color matching: scanned patterns can use fewer colors than material profile defines

**3. Digital Signatures (Security)**
- `SignatureService` interface for pattern signing and verification
- `HmacSignatureService` implementation using HMAC-SHA256
- Shared secret key model (symmetric)
- Constant-time comparison to prevent timing attacks
- Used for pattern authenticity verification

**4. Service Abstraction (PDF Generation)**
- `PDFService` interface with FastAPI backend implementation
- Backend endpoint: `POST /generate-pdf` → returns base64-encoded PDF
- ReportLab generates professional PDFs with CMYK color matching
- Platform-specific download: `pdf_download.dart` (mobile/desktop), `pdf_download_web.dart` (web)

**5. Storage Strategy (Platform-Aware)**
- Web: `IndexedDBStorageService` (browser persistence via IndexedDB)
- Mobile/Desktop: `HiveStorageService` (local Hive database)
- `HistoryService` abstracts storage behind unified API

**6. State Management (Riverpod)**
- Providers defined in feature modules
- UI state classes: `GeneratorState`, `HistoryState`, `ScannerState`
- Riverpod `AsyncValue` for loading/error states

### Backend Architecture (FastAPI)

```
backend/
├── main.py                 # FastAPI app setup, CORS, routes, scanner, PDF generation
├── database/               # SQLite database module
│   ├── __init__.py
│   ├── models.py           # SQLAlchemy ORM models
│   ├── repository.py       # Database repository pattern
│   └── database.py         # Database initialization and session management
├── requirements.txt        # Python dependencies (fastapi, uvicorn, opencv-python, reportlab, sqlalchemy, pydantic)
└── .venv/                  # Virtual environment
```

**FastAPI Endpoints:**

**Pattern Generation & Storage:**
- `POST /generate-pdf`: Accepts `PDFMetadata` JSON, returns base64-encoded PDF
- ReportLab generates professional PDFs with CMYK color matching
- Color mapping: Ink IDs 0-4 map to Flutter colors (cyanAccent, cyan, tealAccent, teal, blue)

**Scanner & Verification:**
- `POST /analyze-image`: Upload scanned tag image, extract pattern using Hough transform
  - Returns: pattern (list of ink IDs), extracted_colors (RGB grid), grid_detected (bool)
- `POST /verify-pattern`: Verify scanned pattern against database
  - Accepts: pattern (list), algorithm (string), extracted_colors (optional 3D RGB array)
  - Returns: matches (exact patterns), partial_matches, confidence score
  - Supports subset color matching (scanned can use fewer colors than stored)
- `GET /material-profile`: Get material profile configuration

**Scanner Algorithm (main.py lines 1003-1168):**
1. **Hough Transform (PRIMARY)**: Used when grid < 6×6 OR component count < 50
   - Edge detection → HoughLinesP → Line classification (horizontal/vertical)
   - Line clustering to merge segments
   - Grid size calculated from line spacing (not component count)
   - Supports 3×3 to 8×8 grids

2. **Centroid-Based (FALLBACK)**: Used for dense grids (6×6 to 8×8 with 50+ components)
   - Connected components analysis
   - Y-position clustering into rows
   - Evenly-spaced column generation

3. **Color Clustering**:
   - K-means clustering (k=2 to 5) with silhouette score optimization
   - Duplicate cluster detection: merges clusters within 5 RGB units
   - Background/grid line filtering (white, dark, low saturation)
   - Minimum 2 colors (changed from 3)

### Data Flow

**Pattern Generation Flow:**
```
User Input (batch code)
  ↓
GeneratorUseCase.generatePattern()
  ↓
PatternGenerationStrategy.generatePattern() → List<int> (9 to 64 values, 0-4)
  ↓
Grid visualization (UI) - 3×3 to 8×8 configurable
  ↓
FastApiPDFService.generatePDF(metadata)
  ↓
POST to http://localhost:8000/generate-pdf
  ↓
Backend: ReportLab generates PDF with CMYK colors
  ↓
Response: base64 PDF bytes
  ↓
Platform-specific download (pdf_download.dart or pdf_download_web.dart)
```

**Scanner Verification Flow:**
```
User uploads/tag image
  ↓
ScannerUseCase.analyzeImage()
  ↓
POST /analyze-image with image file
  ↓
Backend: OpenCV image processing
  - Hough transform grid detection (if < 6×6 or < 50 components)
  - Centroid-based fallback (if 6×6 to 8×8 and dense)
  - K-means color clustering (2-5 colors)
  - Duplicate cluster merging
  ↓
Returns: pattern (ink IDs), extracted_colors (RGB grid), grid_detected
  ↓
ScannerUseCase.verifyPattern()
  ↓
POST /verify-pattern with pattern + colors
  ↓
Backend: Database query + subset color matching
  ↓
Returns: matches, partial_matches, confidence
  ↓
UI displays verification result
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

### Pattern Generation Constraints
- **Grid Size**: Supports 3×3 to 8×8 grids (configurable, not fixed to 8×8)
- **Minimum Colors**: 2 colors minimum (changed from 3)
- **Pattern Purpose**: Manufacturing control for inkjet printing (NOT encryption)
- **Reversibility**: NOT required - patterns are deposition maps, not secret data

### Scanner Detection Heuristics
- **Hough Transform PRIMARY**: Used when `estimated_grid < 6×6` OR `component_count < 50`
  - Best for: Sparse grids with few colors (3×3, 4×4, 5×5)
  - Grid size calculated from line spacing (not component count)
- **Centroid-Based FALLBACK**: Used for dense grids (6×6 to 8×8 with 50+ components)
  - Connected components merge same-color cells
  - Component count less reliable for sparse grids

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
- Development: Uses `http://localhost:8000` for local backend testing (scanner + PDF)
- Production: Uses `https://api.latticelock.com` for deployed backend
- Never hardcode API URLs in Dart code

### Scanner-Specific Requirements
- **Minimum Colors**: Scanner requires minimum 2 colors (not 3)
- **Subset Matching**: Scanned patterns can use fewer colors than material profile defines
- **Duplicate Detection**: K-means creates duplicate clusters - backend merges clusters within 5 RGB units
- **Grid Detection**: Hough transform is PRIMARY method, not fallback
- **Confidence Display**: Removed from UI (always 100% during development with same images)

### Cross-Platform Considerations
- **Web**: Uses `dart:html` for PDF downloads, IndexedDB for storage
- **Mobile/Desktop**: Uses `path_provider` for file storage, Hive for database
- Check `kIsWeb` constant for platform-specific logic branching

### Pattern Generation vs Encryption
- **Pattern Generation**: Creates spatial deposition maps for inkjet printing
  - Deterministic (same input = same output)
  - NOT reversible (not required for manufacturing)
  - Output: Ink IDs for material deposition
- **Encryption**: Protects sensitive data (platform native crypto)
  - Reversible (decrypt possible)
  - Used for securing stored patterns
  - NOT used for pattern generation itself

### Digital Signatures
- HMAC-SHA256 for pattern authenticity verification
- Shared secret key model (symmetric cryptography)
- Constant-time comparison prevents timing attacks
- Signatures stored with patterns for verification

### Code Organization Rules
1. **Feature-first structure**: New features go under `lib/features/feature_name/`
2. **Domain layer**: Business logic in `domain/` (use cases, entities)
3. **Data layer**: External dependencies in `data/` (strategies, repositories)
4. **Presentation**: UI in `presentation/` (screens, widgets, state)
5. **Core services**: Shared utilities in `lib/core/services/`

### Testing Strategy
- Unit tests for pattern generation strategies
- Widget tests for Flutter UI components (generator, scanner, history)
- Integration tests for backend endpoints (scanner, PDF generation)
- Use `mockito` for mocking service dependencies
- Test scanner with various grid sizes (3×3 to 8×8) and color counts (2-5)

## Development Workflow

1. **Feature Development**:
   - Create feature directory under `lib/features/`
   - Define domain layer (use cases, entities, interfaces)
   - Implement data layer (strategies, repositories)
   - Build presentation layer (screens, widgets, state)

2. **Backend Integration**:
   - Start FastAPI backend: `cd backend && uvicorn main:app --reload --host 0.0.0.0 --port 8000`
   - Flutter uses `lib/.env.dev` for `http://localhost:8000`
   - Initialize SQLite database: `python -c "from database.models import Base, engine; Base.metadata.create_all(engine)"`
   - Test scanner with `/analyze-image` endpoint
   - Test verification with `/verify-pattern` endpoint

3. **Docker Development**:
   - Main `docker-compose.yaml` for development deployments
   - Check logs: `docker-compose logs -f <service>`
   - Ensure database volume persists between restarts

4. **Code Quality**:
   - Run `flutter analyze` before commits
   - Format with `flutter format .`
   - Ensure all tests pass: `flutter test`

## Key Dependencies

**Frontend (Flutter/Dart)**:
- **flutter_riverpod**: State management (providers, AsyncValue)
- **crypto**: SHA-256 hashing for data integrity
- **http**: HTTP client for FastAPI backend communication
- **pdf**: PDF generation (client-side fallback)
- **printing**: PDF viewing and printing
- **hive**: NoSQL database for mobile/desktop storage
- **flutter_secure_storage**: Encrypted platform storage
- **native_crypto**: Platform native encryption (iOS Keychain, Android Keystore)
- **google_fonts**: Typography
- **image**: Image handling for scanner uploads

**Backend (Python/FastAPI)**:
- **fastapi**: Modern async web framework
- **uvicorn**: ASGI server
- **opencv-python (cv2)**: Computer vision for scanner (Hough transform, color clustering)
- **numpy**: Numerical computing for image processing
- **reportlab**: PDF generation with CMYK color support
- **sqlalchemy**: ORM for SQLite database
- **pydantic**: Data validation and settings

## Common Issues & Solutions

1. **Backend Connection Refused**: Ensure FastAPI backend is running on port 8000 (check `lib/.env.dev`)
2. **Scanner Grid Detection Fails**:
   - Check if image has clear grid lines (Hough transform needs edges)
   - Verify image resolution (minimum 300×300 recommended)
   - Check backend logs for component count and detection method used
3. **Color Clustering Errors**:
   - Minimum 2 colors required (changed from 3)
   - Check if colors are too similar (duplicate detection threshold: 5 RGB units)
   - Verify background/grid line filtering isn't removing all colors
4. **PDF Generation Fails**: Check backend logs at `http://localhost:8000/docs` for API errors
5. **Storage Not Persisting**: Verify platform detection logic (web vs mobile storage service)
6. **Colors Not Matching**: Ensure backend CMYK values match Flutter hex colors exactly
7. **Database Errors**: Initialize SQLite database: `python -c "from database.models import Base, engine; Base.metadata.create_all(engine)"`
8. **Build Fails**: Run `flutter clean && flutter pub get` to clear cache
