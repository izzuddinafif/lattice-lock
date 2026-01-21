import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logic/scanner_state.dart';
import '../domain/scanner_use_case.dart';

/// Scanner screen for image upload and pattern verification
class ScannerScreen extends ConsumerWidget {
  const ScannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scannerState = ref.watch(scannerStateProvider);
    final scannerNotifier = ref.read(scannerStateProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pattern Scanner'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image upload section
            _buildImageSection(context, scannerState, scannerNotifier),

            const SizedBox(height: 24),

            // Analyze button
            if (scannerState.hasImage && !scannerState.isLoading) ...[
              ElevatedButton.icon(
                onPressed: () => scannerNotifier.analyzeImage(),
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Analyze Pattern'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Loading indicator
            if (scannerState.isLoading) ...[
              const Center(
                child: CircularProgressIndicator(),
              ),
              const SizedBox(height: 16),
            ],

            // Error message
            if (scannerState.errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        scannerState.errorMessage!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => scannerNotifier.clearError(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Analysis results
            if (scannerState.analysisResult != null &&
                !scannerState.isLoading) ...[
              _buildAnalysisResults(context, scannerState, scannerNotifier),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(
    BuildContext context,
    ScannerState state,
    ScannerStateNotifier notifier,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Upload Pattern Image',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Select an image containing a pattern grid (3×3 to 8×8)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 16),

            // Image preview
            if (state.hasImage && state.imageBytes != null) ...[
              Container(
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    state.imageBytes!,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              Container(
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No image selected',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Image picker buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => notifier.pickImageFromGallery(),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Upload Image'),
                  ),
                ),
              ],
            ),

            if (state.hasImage) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => notifier.clear(),
                icon: const Icon(Icons.clear),
                label: const Text('Clear Image'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisResults(
    BuildContext context,
    ScannerState state,
    ScannerStateNotifier notifier,
  ) {
    final result = state.analysisResult!;

    // DEBUG: Print result data
    debugPrint('=== SCANNER DEBUG ===');
    debugPrint('Success: ${result.success}');
    debugPrint('Pattern length: ${result.pattern.length}');
    debugPrint('Pattern: ${result.pattern}');
    debugPrint('Grid detected: ${result.gridDetected}');
    debugPrint('Message: ${result.message}');
    debugPrint('Has verification result: ${state.verificationResult != null}');
    if (state.verificationResult != null) {
      debugPrint('Found: ${state.verificationResult!.found}');
      debugPrint('Matches count: ${state.verificationResult!.matches.length}');
      for (var match in state.verificationResult!.matches) {
        debugPrint('  Match: ${match.inputText}, algo: ${match.algorithm}, time: ${match.timestamp}');
      }
    }
    debugPrint('====================');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  result.success ? Icons.check_circle : Icons.error,
                  color: result.success ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result.success ? 'Analysis Successful' : 'Analysis Failed',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: result.success ? Colors.green : Colors.orange,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Status message
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: result.gridDetected
                    ? Colors.green.shade50
                    : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    result.gridDetected
                        ? Icons.grid_on
                        : Icons.grid_off_outlined,
                    color: result.gridDetected
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      result.message,
                      style: TextStyle(
                        color: result.gridDetected
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (result.success && result.pattern.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Extracted Pattern',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              _buildPatternGrid(context, result.pattern),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade600, Colors.blue.shade800],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.shade400,
                      offset: Offset(0, 4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () => notifier.verifyPattern(),
                  icon: const Icon(Icons.verified_user, size: 28),
                  label: const Text('VERIFY PATTERN IN DATABASE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],

            // Verification results
            if (state.verificationResult != null) ...[
              const SizedBox(height: 24),
              _buildVerificationResults(context, state.verificationResult!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPatternGrid(BuildContext context, List<int> pattern) {
    // Calculate grid size from pattern length (3x3=9, 4x4=16, ..., 8x8=64)
    final gridSize = pattern.length > 0 ? sqrt(pattern.length).toInt() : 8;

    return Container(
      width: 250,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: gridSize,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: pattern.length,
        itemBuilder: (context, index) {
          final inkId = pattern[index];
          final color = _getInkColor(inkId);
          return Container(
            color: color,
            child: Center(
              child: Text(
                inkId >= 0 ? '$inkId' : '?',
                style: TextStyle(
                  color: inkId >= 0 ? Colors.white : Colors.red.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVerificationResults(
    BuildContext context,
    ScannerVerificationResult result,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: result.found ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: result.found ? Colors.green.shade200 : Colors.orange.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                result.found ? Icons.verified : Icons.search_off,
                color: result.found ? Colors.green.shade700 : Colors.orange.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                result.found ? 'Pattern Found!' : 'No Match Found',
                style: TextStyle(
                  color: result.found ? Colors.green.shade700 : Colors.orange.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          if (result.matches.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Matching Patterns:',
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...result.matches.map((match) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle, size: 20, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                match.inputText,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow('Algorithm', match.algorithm),
                        const SizedBox(height: 4),
                        _buildInfoRow('Timestamp', match.timestamp),
                      ],
                    ),
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Color _getInkColor(int inkId) {
    switch (inkId) {
      case 0:
        return const Color(0xFF00E5FF); // CyanAccent
      case 1:
        return const Color(0xFF00BCD4); // Cyan
      case 2:
        return const Color(0xFF1DE9B6); // TealAccent
      case 3:
        return const Color(0xFF009688); // Teal
      case 4:
        return const Color(0xFF2196F3); // Blue
      default:
        return Colors.grey.shade300; // Unknown
    }
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.grey.shade900,
            ),
          ),
        ),
      ],
    );
  }
}
