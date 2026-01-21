# LatticeLock Pattern Generation & Scanner Backend

FastAPI backend with ReportLab for professional PDF generation and OpenCV for pattern scanning/verification of LatticeLock security tags.

## License

MIT License - See LICENSE file for details

## Features

### PDF Generation
- **Professional PDF Generation**: Uses ReportLab for high-quality PDF output
- **Dynamic Grid Sizes**: Supports 3×3 to 8×8 grid patterns
- **Material Profiles**: Custom color configurations via JSON
- **Colored Grid Patterns**: Beautiful colored squares matching the UI design

### Scanner & Verification
- **Hough Transform Detection**: Accurate grid detection using computer vision
- **Color-Based Pattern Matching**: K-means clustering with duplicate detection
- **Subset Color Matching**: Allows patterns using fewer colors than profile defines
- **OpenCV Integration**: Robust image processing for grid extraction

### Database
- **SQLite Storage**: Pattern and verification history persistence
- **Repository Pattern**: Clean database abstraction layer
- **Schema Migrations**: Database initialization and versioning

### Developer Features
- **Pydantic Validation**: Robust data validation and type safety
- **CORS Support**: Ready for Flutter web integration
- **API Documentation**: Auto-generated OpenAPI docs at `/docs`
- **Docker Support**: Containerized deployment ready

## Quick Start

### Prerequisites
- Python 3.11+
- pip
- OpenCV dependencies (installed via requirements.txt)

### Installation

1. Clone and navigate to the backend directory:
```bash
cd backend
```

2. Install dependencies:
```bash
pip install -r requirements.txt
```

3. Initialize database:
```bash
python -c "from database.models import Base, engine; Base.metadata.create_all(engine)"
```

4. Run the server:
```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### Docker Deployment

```bash
# From project root
docker-compose up -d
```

## API Endpoints

### 1. Generate PDF
```http
POST /generate-pdf
Content-Type: application/json

{
  "metadata": {
    "filename": "blueprint.pdf",
    "title": "LatticeLock Security Tag Blueprint",
    "batch_code": "BATCH-001",
    "algorithm": "Hybrid Chaotic Pattern (Spatial Deposition Map)",
    "material_profile": "Standard Set (Le Chatelier)",
    "timestamp": "2024-01-01T12:00:00Z",
    "pattern": [[1, 0, 0, 2], [0, 0, 0, 0], [0, 1, 0, 2]],
    "grid_size": 4,
    "material_colors": {
      "0": {"r": 0, "g": 229, "b": 255},
      "1": {"r": 0, "g": 188, "b": 212},
      "2": {"r": 29, "g": 233, "b": 182}
    }
  }
}
```

### Response
```json
{
  "success": true,
  "pdf_base64": "JVBERi0xLjcK...",
  "filename": "latticelock_BATCH-001_20240101_120000.pdf",
  "size": 4522,
  "message": "PDF generated successfully"
}
```

### 2. Analyze Image (Scanner)
```http
POST /analyze-image
Content-Type: multipart/form-data

scan.jpg (image file)
```

### Response
```json
{
  "success": true,
  "grid_detected": true,
  "pattern": [1, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  "extracted_colors": [[[0, 229, 255], [0, 188, 212], ...]],
  "message": "Successfully extracted 4×4 pattern from image"
}
```

### 3. Verify Pattern
```http
POST /verify-pattern
Content-Type: application/json

{
  "pattern": [1, 0, 0, 2, 0, 0, 0, 0],
  "algorithm": "auto-detect",
  "extracted_colors": [[[0, 229, 255], [0, 188, 212], ...]]
}
```

### Response
```json
{
  "found": true,
  "matches": 1,
  "best_match": {
    "uuid": "pattern-uuid-here",
    "inputText": "BATCH-001",
    "algorithm": "Hybrid Chaotic Pattern",
    "timestamp": "2024-01-01T12:00:00Z",
    "confidence": 1.0
  }
}
```

## Scanner Algorithm

### Grid Detection Strategy

The scanner uses **two-stage detection**:

1. **Hough Transform (PRIMARY)** - For sparse grids or unreliable component counts
   - Triggered when: `grid < 6×6` OR `components < 50`
   - Detects grid lines using edge detection (Canny) + probabilistic Hough transform
   - Calculates grid size from line spacing (more reliable than component count)
   - **Best for:** 3×3, 4×4, 5×5 grids or any grid with merged components

2. **Centroid-Based (FALLBACK)** - For dense grids
   - Triggered when: `grid >= 6×6` AND `components >= 50`
   - Uses connected components to detect cell positions
   - **Best for:** 6×6, 7×7, 8×8 grids with many components

### Color Clustering

```python
# K-means clustering (k=3 for 3-color system)
kmeans = cv2.kmeans(colors, k=3, ...)

# Duplicate detection (merges clusters within 5 RGB units)
for each cluster:
    if abs(rgb1 - rgb2) < 5:
        merge_clusters()

# Filter background/grid line colors
if min_ch > 200 or max_ch < 60:
    filter_as_background()
```

### Subset Color Matching

Patterns can use **fewer colors** than the material profile defines:
- Profile defines 3 colors → Pattern can use 2 or 3
- Verification checks: `scanned_colors ⊆ stored_colors`
- Reduces false negatives for sparse patterns

## Configuration

Environment variables (`.env`):

```bash
HOST=0.0.0.0
PORT=8000
DEBUG=false
LOG_LEVEL=INFO
```

## Color Mapping

The scanner uses K-means clustering with k=3, detecting 3 colors per pattern. Material profiles define custom RGB colors stored as JSON in the database.

| Ink ID | Color Name | Hex | CMYK | Temperature |
|--------|-----------|-----|------|-------------|
| 0 | 75°C Reactive (Data High) | #00E5FF | CMYK(0.84, 0, 0.05, 0) | 75°C |
| 1 | 75°C Protected (Fake) | #00BCD4 | CMYK(1, 0, 0.12, 0.15) | Protected |
| 2 | 55°C Reactive (Data Low) | #1DE9B6 | CMYK(0.82, 0, 0.35, 0) | 55°C |

## Database Schema

### Patterns Table
```sql
- id: Primary key
- uuid: Unique identifier (UUID)
- input_text: Batch code/serial number
- algorithm: Pattern generation algorithm
- pattern: Grid pattern (JSON array)
- grid_size: Grid dimensions (3-8)
- pattern_hash: SHA-256 hash
- material_profile_id: Material profile reference
- material_colors: Color definitions (JSON)
- timestamp: Creation timestamp
- signature: Digital signature (optional)
```

### Pattern Matches Table
```sql
- id: Primary key
- pattern_input_id: Reference to pattern
- matched_pattern_id: Matched pattern reference
- confidence: Match confidence (0.0-1.0)
- algorithm: Algorithm used for matching
- response_time_ms: Verification time
- timestamp: Match timestamp
```

## Development

### API Documentation
- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

### Health Check
```bash
curl http://localhost:8000/health
```

### Database Management
```bash
# Initialize database
python -c "from database.models import Base, engine; Base.metadata.create_all(engine)"

# View database
sqlite3 latticelock.db
.schema patterns
SELECT * FROM patterns LIMIT 5;
```

## Scanner Performance

### Grid Detection Accuracy
- **3×3 grids**: 100% accuracy (Hough transform)
- **5×5 grids**: 100% accuracy (Hough transform)
- **8×8 grids**: 100% accuracy (centroid or Hough based on component count)

### Processing Time
- Small grids (3×3, 4×4): ~2-3 seconds
- Medium grids (5×5, 6×6): ~3-4 seconds
- Large grids (7×7, 8×8): ~4-5 seconds

### Error Handling
The API provides comprehensive error responses:
- **400**: Invalid pattern (wrong dimensions, invalid color IDs)
- **422**: Validation errors (Pydantic schema violations)
- **500**: Server errors (with detailed logging)

## Troubleshooting

### Scanner Issues

**Problem**: Grid size detected incorrectly
- **Solution**: Check lighting, image quality, ensure grid lines are visible
- **Log**: "Using Hough grid line detection FIRST"

**Problem**: Colors not matching
- **Solution**: Verify material_colors JSON format, check RGB values
- **Log**: "INFO: Subset color matching (scanned=2, stored=3)"

**Problem**: K-means creating too many clusters
- **Solution**: Duplicate detection auto-merges within 5 RGB tolerance
- **Log**: "WARNING: Duplicate cluster detected: ID X RGB=... merged with ID Y"

### PDF Generation Issues

**Problem**: Colors don't match UI
- **Solution**: Ensure material_colors passed, not using legacy INK_COLORS
- **Log**: "Material Profile: 3 inks defined"

## Deployment

### Docker Compose (Recommended)
```bash
docker-compose up -d
```

### Environment-Specific Configuration
- Development: `lib/.env.dev` → `http://localhost:8000`
- Production: `lib/.env.prod` → `https://api.latticelock.com`

### Monitoring
- Health checks: `/health` endpoint (every 30s)
- Logs: Configure via `LOG_LEVEL` environment variable
- Database: `latticelock.db` persisted via volume mount

## Architecture

```
FastAPI Backend
├── PDF Generation (ReportLab)
│   ├── Dynamic grid sizes (3×3 to 8×8)
│   ├── Material color profiles
│   └── CMYK color matching
├── Scanner (OpenCV)
│   ├── Image preprocessing
│   ├── Hough transform grid detection
│   ├── K-means color clustering
│   └── Pattern extraction
├── Verification Engine
│   ├── Color matching (subset support)
│   ├── Duplicate cluster handling
│   └── Confidence scoring
└── Database (SQLite)
    ├── Pattern storage
    ├── Match history
    └── Verification logs
```

## Integration with Flutter

1. **Pattern Generation**:
   - Flutter sends pattern data with material colors
   - Backend validates and generates PDF
   - PDF returned as base64 for download

2. **Pattern Verification**:
   - Flutter uploads scanned image
   - Backend extracts pattern and matches against database
   - Returns match results with batch information

3. **Real-time Updates**:
   - CORS-enabled for Flutter web
   - JSON responses for easy parsing
   - Async processing for non-blocking operations
