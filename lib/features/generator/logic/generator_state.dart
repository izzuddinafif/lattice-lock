import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../domain/generator_use_case.dart';
import '../../material/models/ink_profile.dart';

class GeneratorState {
  final String inputText;
  final String selectedAlgorithm;
  final MaterialProfile selectedMaterial;
  final List<int> encryptedPattern;
  final bool isGenerating;
  final String? error;

  GeneratorState({
    required this.inputText,
    required this.selectedAlgorithm,
    required this.selectedMaterial,
    required this.encryptedPattern,
    required this.isGenerating,
    this.error,
  });

  GeneratorState copyWith({
    String? inputText,
    String? selectedAlgorithm,
    MaterialProfile? selectedMaterial,
    List<int>? encryptedPattern,
    bool? isGenerating,
    String? error,
  }) {
    return GeneratorState(
      inputText: inputText ?? this.inputText,
      selectedAlgorithm: selectedAlgorithm ?? this.selectedAlgorithm,
      selectedMaterial: selectedMaterial ?? this.selectedMaterial,
      encryptedPattern: encryptedPattern ?? this.encryptedPattern,
      isGenerating: isGenerating ?? this.isGenerating,
      error: error,
    );
  }
}

class GeneratorNotifier extends AsyncNotifier<GeneratorState> {
  late final GeneratorUseCase _generatorUseCase;
  Timer? _debounceTimer;

  @override
  GeneratorState build() {
    _generatorUseCase = GeneratorUseCase();

    // Set up cleanup for timer when notifier is disposed
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });

    return GeneratorState(
      inputText: '',
      selectedAlgorithm: 'chaos_logistic',
      selectedMaterial: MaterialProfile.standardSet,
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

  Future<void> _generatePattern() async {
    final currentState = state.value!;

    if (currentState.inputText.isEmpty) {
      state = AsyncValue.data(currentState.copyWith(encryptedPattern: [], error: null));
      return;
    }

    state = AsyncValue.data(currentState.copyWith(isGenerating: true, error: null));

    try {
      final pattern = await _generatorUseCase.generatePattern(
        inputText: currentState.inputText,
        algorithm: currentState.selectedAlgorithm,
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
      await _generatorUseCase.generatePDF(
        pattern: currentState.encryptedPattern,
        material: currentState.selectedMaterial,
        inputText: currentState.inputText,
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