import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../domain/scanner_use_case.dart';

/// Scanner state
class ScannerState {
  final bool isLoading;
  final bool hasImage;
  final Uint8List? imageBytes;
  final String? imagePath;
  final ImageAnalysisResult? analysisResult;
  final ScannerVerificationResult? verificationResult;
  final String? errorMessage;

  const ScannerState({
    this.isLoading = false,
    this.hasImage = false,
    this.imageBytes,
    this.imagePath,
    this.analysisResult,
    this.verificationResult,
    this.errorMessage,
  });

  ScannerState copyWith({
    bool? isLoading,
    bool? hasImage,
    Uint8List? imageBytes,
    String? imagePath,
    ImageAnalysisResult? analysisResult,
    ScannerVerificationResult? verificationResult,
    String? errorMessage,
  }) {
    return ScannerState(
      isLoading: isLoading ?? this.isLoading,
      hasImage: hasImage ?? this.hasImage,
      imageBytes: imageBytes ?? this.imageBytes,
      imagePath: imagePath ?? this.imagePath,
      analysisResult: analysisResult ?? this.analysisResult,
      verificationResult: verificationResult ?? this.verificationResult,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Scanner state notifier
class ScannerStateNotifier extends StateNotifier<ScannerState> {
  final ScannerUseCase _scannerUseCase;
  final ImagePicker _imagePicker;

  ScannerStateNotifier({
    required ScannerUseCase scannerUseCase,
    required ImagePicker imagePicker,
  })  : _scannerUseCase = scannerUseCase,
        _imagePicker = imagePicker,
        super(const ScannerState());

  /// Pick image from gallery
  Future<void> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        state = state.copyWith(
          hasImage: true,
          imageBytes: bytes,
          imagePath: image.path,
          errorMessage: null,
          analysisResult: null,
          verificationResult: null,
        );
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to pick image: $e',
      );
    }
  }

  /// Capture image from camera
  Future<void> captureImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        state = state.copyWith(
          hasImage: true,
          imageBytes: bytes,
          imagePath: image.path,
          errorMessage: null,
          analysisResult: null,
          verificationResult: null,
        );
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to capture image: $e',
      );
    }
  }

  /// Analyze uploaded image
  Future<void> analyzeImage() async {
    if (state.imageBytes == null) {
      state = state.copyWith(
        errorMessage: 'No image to analyze',
      );
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _scannerUseCase.analyzeImage(state.imageBytes!);
      state = state.copyWith(
        isLoading: false,
        analysisResult: result,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Verify extracted pattern
  Future<void> verifyPattern({String algorithm = 'auto-detect'}) async {
    if (state.analysisResult == null || !state.analysisResult!.success) {
      state = state.copyWith(
        errorMessage: 'No valid pattern to verify',
      );
      return;
    }

    debugPrint('=== SCANNER STATE: VERIFYING ===');
    debugPrint('Pattern: ${state.analysisResult!.pattern}');
    debugPrint('Extracted colors: ${state.analysisResult!.extractedColors.length} rows');
    debugPrint('Algorithm: $algorithm');

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _scannerUseCase.verifyPattern(
        state.analysisResult!.pattern,
        algorithm: algorithm,
        extractedColors: state.analysisResult!.extractedColors,
      );

      debugPrint('Verification result found: ${result.found}');
      debugPrint('Verification matches: ${result.matches.length}');

      state = state.copyWith(
        isLoading: false,
        verificationResult: result,
      );
    } catch (e) {
      debugPrint('Verification error: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Clear current state
  void clear() {
    state = const ScannerState();
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// Scanner use case provider
final scannerUseCaseProvider = Provider<ScannerUseCase>((ref) {
  return ScannerUseCase();
});

/// Image picker provider
final imagePickerProvider = Provider<ImagePicker>((ref) {
  return ImagePicker();
});

/// Scanner state provider
final scannerStateProvider =
    StateNotifierProvider<ScannerStateNotifier, ScannerState>((ref) {
  final scannerUseCase = ref.watch(scannerUseCaseProvider);
  final imagePicker = ref.watch(imagePickerProvider);

  return ScannerStateNotifier(
    scannerUseCase: scannerUseCase,
    imagePicker: imagePicker,
  );
});
