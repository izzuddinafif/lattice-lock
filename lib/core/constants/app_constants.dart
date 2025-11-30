class AppConstants {
  // Grid Configuration
  static const int defaultGridSize = 8; // Default 8x8 grid
  static const int minGridSize = 2; // 2x2 for quick PoC
  static const int maxGridSize = 32; // 32x32 for scientific use
  static const List<int> availableGridSizes = [2, 3, 4, 5, 6, 8, 10, 12, 16, 20, 24, 32];

  // Calculate total cells for a given grid size
  static int getTotalCells(int gridSize) => gridSize * gridSize;

  // Material Configuration
  static const int totalInkTypes = 5;

  // API Configuration (placeholder)
  static const String baseUrl = 'http://localhost:8000/api/v1';
  static const Duration apiTimeout = Duration(seconds: 30);

  // File Storage
  static const String pdfOutputFolder = 'latticelock_blueprints';

  // Color Detection Thresholds (for future implementation)
  static const double colorThreshold = 0.7;

  // Encryption Configuration
  static const String defaultEncryptionAlgorithm = 'chaos_logistic';
}