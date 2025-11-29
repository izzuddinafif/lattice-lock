class AppConstants {
  // Grid Configuration
  static const int gridSize = 8; // 8x8 grid
  static const int totalCells = gridSize * gridSize;
  
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