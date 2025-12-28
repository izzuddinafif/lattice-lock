# LatticeLock PDF Generation Backend

FastAPI backend with ReportLab for professional PDF generation of LatticeLock security patterns.

## Features

- **Professional PDF Generation**: Uses ReportLab for high-quality PDF output
- **Colored Grid Patterns**: Beautiful colored squares matching the UI design
- **Pydantic Validation**: Robust data validation and type safety
- **CORS Support**: Ready for Flutter web integration
- **API Documentation**: Auto-generated OpenAPI docs at `/docs`
- **Docker Support**: Containerized deployment ready

## Quick Start

### Prerequisites
- Python 3.8+
- pip

### Installation

1. Clone and navigate to the backend directory:
```bash
cd backend
```

2. Install dependencies:
```bash
pip install -r requirements.txt
```

3. Run the server:
```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### Docker Deployment

```bash
# Build the image
docker build -t latticelock-pdf-backend .

# Run the container
docker run -p 8000:8000 latticelock-pdf-backend
```

## API Endpoints

### Generate PDF
```
POST /generate-pdf
Content-Type: application/json

{
  "metadata": {
    "filename": "example.pdf",
    "title": "LatticeLock Pattern",
    "batch_code": "BATCH-001",
    "algorithm": "AES-256",
    "material_profile": "Standard",
    "timestamp": "2024-01-01T12:00:00Z",
    "pattern": [
      [1, 2, 0, 3],
      [4, 0, 2, 1],
      [0, 3, 1, 4],
      [2, 1, 4, 0]
    ],
    "grid_size": 4
  }
}
```

### Response
```json
{
  "success": true,
  "pdf_base64": "JVBERi0xLjcK...",
  "filename": "latticelock_BATCH-001_20240101_120000.pdf",
  "size": 15420,
  "message": "PDF generated successfully"
}
```

## Configuration

Environment variables can be set in `.env`:

- `HOST`: Server host (default: 0.0.0.0)
- `PORT`: Server port (default: 8000)
- `DEBUG`: Debug mode (default: true)
- `LOG_LEVEL`: Logging level (default: INFO)

## PDF Features

- **Professional Typography**: Custom fonts and styling
- **Material Design Colors**: Matching the Flutter app UI
- **Grid Visualization**: Beautiful colored square patterns
- **Metadata Sections**: Batch codes, algorithms, timestamps
- **Security Classification**: Professional document headers/footers

## Development

### API Documentation
- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

### Health Check
```bash
curl http://localhost:8000/health
```

## Color Mapping

| Ink Value | Color | Description |
|-----------|-------|-------------|
| 0 | Light Gray | Clear |
| 1 | Red | Security Level 1 |
| 2 | Blue | Security Level 2 |
| 3 | Green | Security Level 3 |
| 4 | Black | Security Level 4 |
| 5 | Yellow | Security Level 5 |

## Integration with Flutter

The backend is designed to integrate seamlessly with the Flutter LatticeLock app:

1. Flutter sends pattern data as JSON
2. Backend validates and processes the data
3. ReportLab generates a professional PDF
4. PDF is returned as base64 for download/sharing

## Error Handling

The API provides comprehensive error responses with detailed messages for troubleshooting.

## Performance

- Asynchronous processing for non-blocking operations
- Efficient PDF generation with buffered output
- Configurable timeouts and resource limits