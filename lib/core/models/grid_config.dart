/// Grid configuration model for dynamic grid sizes
class GridConfig {
  final int size;
  final String displayName;
  final String description;
  final String useCase;

  const GridConfig({
    required this.size,
    required this.displayName,
    required this.description,
    required this.useCase,
  });

  /// Get total number of cells in the grid
  int get totalCells => size * size;

  /// Grid configuration presets for different user needs
  static const List<GridConfig> presets = [
    GridConfig(
      size: 3,
      displayName: '3×3',
      description: 'Simple demonstration',
      useCase: 'Demo',
    ),
    GridConfig(
      size: 4,
      displayName: '4×4',
      description: 'Basic testing',
      useCase: 'Testing',
    ),
    GridConfig(
      size: 5,
      displayName: '5×5',
      description: 'Educational use',
      useCase: 'Education',
    ),
    GridConfig(
      size: 6,
      displayName: '6×6',
      description: 'Enhanced complexity',
      useCase: 'Advanced',
    ),
    GridConfig(
      size: 8,
      displayName: '8×8',
      description: 'Standard security pattern',
      useCase: 'Production',
    ),
  ];

  /// Get recommended grid configs based on use case
  static List<GridConfig> getRecommendedConfigs(String useCase) {
    switch (useCase.toLowerCase()) {
      case 'poc':
      case 'demo':
        return presets.where((config) => config.size <= 3).toList();
      case 'education':
      case 'testing':
        return presets.where((config) => config.size <= 6).toList();
      case 'advanced':
        return presets.where((config) => config.size >= 6 && config.size <= 8).toList();
      case 'professional':
      case 'enterprise':
        return presets.where((config) => config.size >= 8).toList();
      case 'scientific':
      case 'research':
        return presets.where((config) => config.size >= 8).toList();
      default:
        return presets; // Return all if no specific use case
    }
  }

  /// Get grid config by size
  static GridConfig? getBySize(int size) {
    try {
      return presets.firstWhere((config) => config.size == size);
    } catch (e) {
      return null;
    }
  }

  /// Check if grid size is valid
  static bool isValidSize(int size) {
    return size >= 3 && size <= 8 && size == size.round();
  }

  @override
  String toString() {
    return displayName;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GridConfig && runtimeType == other.runtimeType && size == other.size;

  @override
  int get hashCode => size.hashCode;

  /// Find a grid configuration by size
  static GridConfig? findBySize(int size) {
    try {
      return presets.firstWhere((config) => config.size == size);
    } catch (e) {
      return null;
    }
  }
}