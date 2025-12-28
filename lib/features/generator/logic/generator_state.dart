import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../domain/generator_use_case.dart';
import '../../material/models/ink_profile.dart';
import '../../material/models/custom_ink_profile.dart';
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

  @override
  GeneratorState build() {
    // Initialize use case only once
    _generatorUseCase ??= GeneratorUseCase();

    // Set up cleanup for timer when notifier is disposed
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });

    // Find default 8x8 grid config from presets
    final defaultGridConfig = GridConfig.presets.firstWhere(
      (config) => config.size == 8,
      orElse: () => GridConfig.presets.first, // Fallback to 2x2 if 8x8 not found
    );

    // Watch material profile provider for active profile
    final materialProfileState = ref.watch(materialProfileProvider);
    MaterialProfile selectedMaterial;

    if (materialProfileState.activeProfile != null) {
      // Convert custom profile to standard MaterialProfile
      selectedMaterial = materialProfileState.activeProfile!.toMaterialProfile();
    } else {
      // Fallback to standard set if no custom profile is active
      selectedMaterial = MaterialProfile.standardSet;
    }

    return GeneratorState(
      inputText: '',
      selectedAlgorithm: 'chaos_logistic',
      selectedMaterial: selectedMaterial,
      selectedGridConfig: defaultGridConfig, // Use configurable grid instead of hardcoded
      encryptedPattern: [],
      isGenerating: false,
    );
  }

  void updateInputText(String text) {
    state = AsyncValue.data(state.value!.copyWith(inputText: text));
    
    // Debounce pattern generation to avoid excessive calls during typing
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _generatePattern();
    });
  }

  void updateAlgorithm(String algorithm) {
    state = AsyncValue.data(state.value!.copyWith(selectedAlgorithm: algorithm));
    _generatePattern();
  }

  void updateMaterial(MaterialProfile material) {
    state = AsyncValue.data(state.value!.copyWith(selectedMaterial: material));
    _generatePattern();
  }

  void updateGridConfig(GridConfig gridConfig) {
    state = AsyncValue.data(state.value!.copyWith(selectedGridConfig: gridConfig));
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
      final pattern = await _generatorUseCase!.generatePattern(
        inputText: currentState.inputText,
        algorithm: currentState.selectedAlgorithm,
        gridSize: currentState.selectedGridConfig.size, // Pass configurable grid size
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
    
    if (currentState.encryptedPattern.isEmpty) {
      state = AsyncValue.data(currentState.copyWith(error: 'No pattern to generate PDF'));
      return;
    }

    state = AsyncValue.data(currentState.copyWith(isGenerating: true));

    try {
      await _generatorUseCase!.generatePDF(
        pattern: currentState.encryptedPattern,
        material: currentState.selectedMaterial,
        inputText: currentState.inputText,
        gridSize: currentState.selectedGridConfig.size, // Pass configurable grid size
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