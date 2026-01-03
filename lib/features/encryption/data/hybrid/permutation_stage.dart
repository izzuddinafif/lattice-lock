/// Permutation Stage using Arnold's Cat Map
///
/// Stage 1 of Hybrid Chaotic Encryption
/// Scrambles spatial positions of values in 8x8 grid
/// Reversible: determinant = 1 ensures bijective property
class PermutationStage {
  static const int gridSize = 8;

  /// Apply Arnold's Cat Map permutation for specified iterations
  /// [x'] = [1 1][x] mod 8
  /// [y']   [1 2][y]
  List<List<int>> permute(List<List<int>> grid, int iterations) {
    var result = _copyGrid(grid);

    for (int i = 0; i < iterations; i++) {
      result = _arnoldCatMap(result);
    }

    return result;
  }

  /// Inverse Arnold's Cat Map permutation
  /// [x] = [2 -1][x'] mod 8
  /// [y]   [-1 1][y']
  List<List<int>> invert(List<List<int>> grid, int iterations) {
    var result = _copyGrid(grid);

    for (int i = 0; i < iterations; i++) {
      result = _arnoldCatMapInverse(result);
    }

    return result;
  }

  /// Apply single Arnold's Cat Map transformation
  List<List<int>> _arnoldCatMap(List<List<int>> grid) {
    var newGrid = List.generate(
      gridSize,
      (_) => List.filled(gridSize, 0),
    );

    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        int newX = (x + y) % gridSize;
        int newY = (x + 2 * y) % gridSize;
        newGrid[newY][newX] = grid[y][x];
      }
    }

    return newGrid;
  }

  /// Apply inverse Arnold's Cat Map transformation
  List<List<int>> _arnoldCatMapInverse(List<List<int>> grid) {
    var newGrid = List.generate(
      gridSize,
      (_) => List.filled(gridSize, 0),
    );

    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        int newX = (2 * x - y) % gridSize;
        int newY = (-x + y) % gridSize;

        // Handle negative modulo
        if (newX < 0) newX += gridSize;
        if (newY < 0) newY += gridSize;

        newGrid[newY][newX] = grid[y][x];
      }
    }

    return newGrid;
  }

  /// Create deep copy of grid
  List<List<int>> _copyGrid(List<List<int>> grid) {
    return grid.map((row) => List<int>.from(row)).toList();
  }

  /// Get the period of Arnold's Cat Map for 8x8 grid
  /// After 48 iterations, the grid returns to original state
  static int get period => 48;
}
