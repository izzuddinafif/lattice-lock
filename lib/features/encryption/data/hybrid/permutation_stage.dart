/// Permutation Stage using Arnold's Cat Map
///
/// Stage 1 of Hybrid Chaotic Encryption
/// Scrambles spatial positions of values in NxN grid
/// Reversible: determinant = 1 ensures bijective property
class PermutationStage {

  /// Apply Arnold's Cat Map permutation for specified iterations
  /// [x'] = [1 1][x] mod N
  /// [y']   [1 2][y]
  List<List<int>> permute(List<List<int>> grid, int iterations) {
    final size = grid.length;
    var result = _copyGrid(grid);

    for (int i = 0; i < iterations; i++) {
      result = _arnoldCatMap(result);
    }

    return result;
  }

  /// Inverse Arnold's Cat Map permutation
  /// [x] = [2 -1][x'] mod N
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
    final size = grid.length;
    var newGrid = List.generate(
      size,
      (_) => List.filled(size, 0),
    );

    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        int newX = (x + y) % size;
        int newY = (x + 2 * y) % size;
        newGrid[newY][newX] = grid[y][x];
      }
    }

    return newGrid;
  }

  /// Apply inverse Arnold's Cat Map transformation
  List<List<int>> _arnoldCatMapInverse(List<List<int>> grid) {
    final size = grid.length;
    var newGrid = List.generate(
      size,
      (_) => List.filled(size, 0),
    );

    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        int newX = (2 * x - y) % size;
        int newY = (-x + y) % size;

        // Handle negative modulo
        if (newX < 0) newX += size;
        if (newY < 0) newY += size;

        newGrid[newY][newX] = grid[y][x];
      }
    }

    return newGrid;
  }

  /// Create deep copy of grid
  List<List<int>> _copyGrid(List<List<int>> grid) {
    return grid.map((row) => List<int>.from(row)).toList();
  }
}
