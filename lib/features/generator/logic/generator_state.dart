import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:math';
import '../domain/generator_use_case.dart';
import '../../material/models/ink_profile.dart';
import '../../material/providers/material_profile_provider.dart';
import '../../../core/models/grid_config.dart';

class GeneratorState {
  final String inputText;
  final String selectedAlgorithm;
  final MaterialProfile selectedMaterial;
  final GridConfig selectedGridConfig;
  final List<int> encryptedPattern;
  final bool isGenerating;
  final String? error;

  GeneratorState({
    required this.inputText,
    required this.selectedAlgorithm,
    required this.selectedMaterial,
    required this.selectedGridConfig,
    required this.encryptedPattern,
    required this.isGenerating,
    this.error,
  });

  GeneratorState copyWith({
    String? inputText,
    String? selectedAlgorithm,
    MaterialProfile? selectedMaterial,
    GridConfig? selectedGridConfig,
    List<int>? encryptedPattern,
    bool? isGenerating,
    String? error,
  }) {
    return GeneratorState(
      inputText: inputText ?? this.inputText,
      selectedAlgorithm: selectedAlgorithm ?? this.selectedAlgorithm,
      selectedMaterial: selectedMaterial ?? this.selectedMaterial,
      selectedGridConfig: selectedGridConfig ?? this.selectedGridConfig,
      encryptedPattern: encryptedPattern ?? this.encryptedPattern,
      isGenerating: isGenerating ?? this.isGenerating,
      error: error,
    );
  }
}

class GeneratorNotifier extends AsyncNotifier<GeneratorState> {
  GeneratorUseCase? _generatorUseCase;
  Timer? _debounceTimer;
  bool _disposed = false;

  @override
  GeneratorState build() {
    // Initialize use case only once
    _generatorUseCase ??= GeneratorUseCase();

    // Set up cleanup for timer when notifier is disposed
    ref.onDispose(() {
      _disposed = true;
      _debounceTimer?.cancel();
    });

    // Find default 8x8 grid config from presets
    final defaultGridConfig = GridConfig.presets.firstWhere(
      (config) => config.size == 8,
      orElse: () => GridConfig.presets.first, // Fallback to 2x2 if 8x8 not found
    );

    // CRITICAL: Don't read materialProfileProvider here - it might not be loaded yet
    // The provider loads asynchronously from Hive, so activeProfile could be null
    // Start with standard set, then initializeAsync() will load the saved profile
    final initialState = GeneratorState(
      inputText: '',
      selectedAlgorithm: 'chaos_logistic',
      selectedMaterial: MaterialProfile.standardSet, // Start with default
      selectedGridConfig: defaultGridConfig,
      encryptedPattern: [],
      isGenerating: false,
    );

    // Load saved material profile asynchronously after provider is ready
    _initializeFromSavedState();

    return initialState;
  }

  Future<void> _initializeFromSavedState() async {
    // Wait for Hive to finish loading - retry up to 10 times with 200ms delay
    for (int i = 0; i < 10; i++) {
      await Future.delayed(const Duration(milliseconds: 200));

      final materialProfileState = ref.read(materialProfileProvider);

      // Check if profiles have loaded (not empty list)
      if (materialProfileState.profiles.isNotEmpty) {
        if (materialProfileState.activeProfile != null) {
          final savedMaterial = materialProfileState.activeProfile!.toMaterialProfile();

          // Update state with saved material profile
          state = AsyncValue.data(state.value!.copyWith(
            selectedMaterial: savedMaterial,
          ));
          return;
        } else {
          return;
        }
      }
    }
  }

  void updateInputText(String text) {
    state = AsyncValue.data(state.value!.copyWith(inputText: text));

    // Debounce pattern generation to avoid excessive calls during typing
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (!_disposed) {
        _generatePattern();
      }
    });
  }

  // Immediate regeneration without debounce (for material profile changes)
  void regenerate() {
    _debounceTimer?.cancel();
    _generatePattern();
  }

  void updateAlgorithm(String algorithm) {
    // CRITICAL: Clear the pattern when algorithm changes to prevent mismatches
    // Different algorithms produce different patterns for the same input
    state = AsyncValue.data(state.value!.copyWith(
      selectedAlgorithm: algorithm,
      encryptedPattern: [], // Clear pattern before regeneration
    ));
    _generatePattern();
  }

  void updateMaterial(MaterialProfile material) {
    // CRITICAL: Clear the pattern when material changes to prevent mismatches
    // Different ink count means pattern values become invalid (e.g., ink ID 4 exists in 5-ink but not 3-ink)
    state = AsyncValue.data(state.value!.copyWith(
      selectedMaterial: material,
      encryptedPattern: [], // Always clear pattern when material changes
    ));

    // Don't call _generatePattern() here - let the UI call regenerate() to avoid race conditions
  }

  void updateGridConfig(GridConfig gridConfig) {
    // CRITICAL: Clear the pattern when grid size changes to prevent mismatches
    // If input is empty, old pattern stays but grid config changes -> state desync
    state = AsyncValue.data(state.value!.copyWith(
      selectedGridConfig: gridConfig,
      encryptedPattern: [], // Always clear pattern when grid changes
    ));

    _generatePattern();
  }

  Future<void> _generatePattern() async {
    final currentState = state.value!;

    if (currentState.inputText.isEmpty) {
      state = AsyncValue.data(currentState.copyWith(encryptedPattern: [], error: null));
      return;
    }

    state = AsyncValue.data(currentState.copyWith(isGenerating: true, error: null));

    try {
      // Get the number of inks from the selected material
      final numInks = currentState.selectedMaterial.inks.length;

      final pattern = await _generatorUseCase!.generatePattern(
        inputText: currentState.inputText,
        algorithm: currentState.selectedAlgorithm,
        gridSize: currentState.selectedGridConfig.size, // Pass configurable grid size
        numInks: numInks, // Pass dynamic ink count from material
      );

      state = AsyncValue.data(currentState.copyWith(
        encryptedPattern: pattern,
        isGenerating: false,
        error: null,
      ));
    } catch (e) {
      state = AsyncValue.data(currentState.copyWith(
        encryptedPattern: [],
        isGenerating: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> generatePDF() async {
    final currentState = state.value!;

    // Calculate actual grid size from pattern length
    final patternLength = currentState.encryptedPattern.length;
    final actualGridSize = patternLength > 0 ? sqrt(patternLength).round() : 0;
    final configGridSize = currentState.selectedGridConfig.size;

    if (currentState.encryptedPattern.isEmpty) {
      state = AsyncValue.data(currentState.copyWith(error: 'No pattern to generate PDF'));
      return;
    }

    // Validate pattern forms a perfect square grid
    if (actualGridSize * actualGridSize != patternLength) {
      state = AsyncValue.data(currentState.copyWith(
        error: 'Invalid pattern: $patternLength cells does not form a square grid (expected ${actualGridSize * actualGridSize} for $actualGridSize×$actualGridSize)'
      ));
      return;
    }

    if (actualGridSize < 2 || actualGridSize > 32) {
      state = AsyncValue.data(currentState.copyWith(
        error: 'Invalid grid size: $actualGridSize (must be between 2 and 32)'
      ));
      return;
    }

    state = AsyncValue.data(currentState.copyWith(isGenerating: true));

    try {
      // Use actual grid size from pattern to avoid 422 errors
      await _generatorUseCase!.generatePDF(
        pattern: currentState.encryptedPattern,
        material: currentState.selectedMaterial,
        inputText: currentState.inputText,
        gridSize: actualGridSize > 0 ? actualGridSize : configGridSize, // Use actual grid size if available
      );

      state = AsyncValue.data(currentState.copyWith(
        isGenerating: false,
        error: null,
      ));
    } catch (e) {
      state = AsyncValue.data(currentState.copyWith(
        isGenerating: false,
        error: 'Failed to generate PDF: ${e.toString()}',
      ));
    }
  }

  // Note: Riverpod 3.0+ AsyncNotifier doesn't have dispose() override
  // Timer cleanup is handled automatically by the framework
  // If manual cleanup is needed, use a ref.onDispose() callback instead
}

// Provider - Updated for Riverpod 3.0
final generatorProvider = AsyncNotifierProvider<GeneratorNotifier, GeneratorState>(() {
  return GeneratorNotifier();
});