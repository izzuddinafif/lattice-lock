import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../logic/generator_state.dart';

class GeneratorScreen extends ConsumerWidget {
  const GeneratorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final generatorAsync = ref.watch(generatorProvider);
    final notifier = ref.read(generatorProvider.notifier);

    return generatorAsync.when(
      data: (state) => _buildResponsiveLayout(context, state, notifier),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $error', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => notifier.updateInputText(''),
              child: const Text('Reset'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveLayout(BuildContext context, GeneratorState state, GeneratorNotifier notifier) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1200;

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            title: Text(
              'LATTICELOCK',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                letterSpacing: 3.0,
              ),
            ),
            centerTitle: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            surfaceTintColor: Theme.of(context).colorScheme.primary,
          ),
          body: SafeArea(
            child: isDesktop
              ? _buildDesktopLayout(context, state, notifier)
              : _buildMobileLayout(context, state, notifier),
          ),
        );
      },
    );
  }

  Widget _buildDesktopLayout(BuildContext context, GeneratorState state, GeneratorNotifier notifier) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      body: Row(
        children: [
          // PANEL KIRI: INPUT & KONTROL
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(2, 0),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.qr_code_scanner, size: 32, color: Colors.blue),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Secure Batch Input",
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                            Text(
                              "Enter your secret batch code or serial number",
                              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Input Field
                  TextField(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue.shade300, width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue.shade300, width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue.shade500, width: 3),
                      ),
                      labelText: "Batch Code / Serial Number",
                      labelStyle: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w600),
                      hintText: "e.g., LATTICE-2025-X",
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                          ),
                        ),
                        child: Icon(Icons.key, color: Colors.blue.shade700),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    ),
                    style: const TextStyle(fontSize: 16),
                    onChanged: (val) => notifier.updateInputText(val),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Material Configuration
                  _buildSectionCard(
                    title: "Material Profile",
                    icon: Icons.science,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.layers, color: Colors.blue.shade700),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      state.selectedMaterial.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    Text(
                                      "${state.selectedMaterial.inks.length} ink types configured",
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Algorithm Selection
                  _buildSectionCard(
                    title: "Pattern Generation Algorithm",
                    icon: Icons.enhanced_encryption,
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      // The value parameter is required to control the selected state.
                      // This is not redundant as it manages the dropdown selection state.
                      // Using deprecated value instead of initialValue as this is for state management,
                      // not form initialization in this context.
                      // ignore: avoid_redundant_argument_values, deprecated_member_use
                      value: state.selectedAlgorithm,
                      isExpanded: true,
                      items: [
                        // Chaos Algorithms Category
                        DropdownMenuItem(
                          value: "chaos_logistic",
                          child: Row(
                            children: [
                              Icon(Icons.timeline, size: 20, color: Colors.deepPurple),
                              const SizedBox(width: 12),
                              const Expanded(child: Text("Chaos Logistic Map")),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.deepPurple.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.deepPurple),
                                ),
                                child: const Text("Chaos", style: TextStyle(fontSize: 10, color: Colors.deepPurple)),
                              ),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: "chaos_tent",
                          child: Row(
                            children: [
                              Icon(Icons.show_chart, size: 20, color: Colors.deepOrange),
                              const SizedBox(width: 12),
                              const Expanded(child: Text("Chaos Tent Map")),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.deepOrange.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.deepOrange),
                                ),
                                child: const Text("Chaos", style: TextStyle(fontSize: 10, color: Colors.deepOrange)),
                              ),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: "chaos_arnolds_cat",
                          child: Row(
                            children: [
                              Icon(Icons.grid_4x4, size: 20, color: Colors.teal),
                              const SizedBox(width: 12),
                              const Expanded(child: Text("Arnold's Cat Map")),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.teal.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.teal),
                                ),
                                child: const Text("Chaos", style: TextStyle(fontSize: 10, color: Colors.teal)),
                              ),
                            ],
                          ),
                        ),
                        ],
                      onChanged: (val) {
                        if (val != null) {
                          notifier.updateAlgorithm(val);
                        }
                      },
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Status Indicator
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: state.inputText.isNotEmpty 
                          ? Colors.green.withValues(alpha: 0.1) 
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: state.inputText.isNotEmpty 
                            ? Colors.green 
                            : Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          state.inputText.isNotEmpty ? Icons.check_circle : Icons.info,
                          color: state.inputText.isNotEmpty ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            state.inputText.isNotEmpty 
                                ? "Pattern generated successfully (${state.encryptedPattern.length} cells)"
                                : "Enter batch code to generate encryption pattern",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: state.inputText.isNotEmpty ? Colors.green.shade800 : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // PDF Button
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: state.encryptedPattern.isNotEmpty 
                            ? [Colors.blue.shade800, Colors.blue.shade600]
                            : [Colors.grey.shade400, Colors.grey.shade300],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        if (state.encryptedPattern.isNotEmpty)
                          BoxShadow(
                            color: Colors.blue.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: state.encryptedPattern.isNotEmpty && !state.isGenerating
                            ? () => notifier.generatePDF()
                            : null,
                        child: Center(
                          child: state.isGenerating
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text("Generating...", style: TextStyle(color: Colors.white, fontSize: 16)),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.print, color: Colors.white, size: 24),
                                    const SizedBox(width: 12),
                                    const Text(
                                      "GENERATE BLUEPRINT PDF",
                                      style: TextStyle(
                                        color: Colors.white, 
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Divider visual
          Container(
            width: 2,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.grey.withValues(alpha: 0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // PANEL KANAN: PREVIEW GRID
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(32),
              color: Colors.blueGrey[900],
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Preview Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.grid_view, color: Colors.cyanAccent, size: 28),
                            const SizedBox(width: 12),
                            const Text(
                              "Encryption Pattern Preview",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Visual representation of encrypted data pattern",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.cyanAccent.withValues(alpha: 0.8),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // GRID VISUALIZATION
                  Container(
                    constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      border: Border.all(color: Colors.cyanAccent, width: 3),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyanAccent.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 8,
                          crossAxisSpacing: 1,
                          mainAxisSpacing: 1,
                        ),
                        itemCount: state.encryptedPattern.isEmpty ? 64 : state.encryptedPattern.length,
                        itemBuilder: (context, index) {
                          final inkId = state.encryptedPattern.isEmpty ? 4 : state.encryptedPattern[index];
                          final ink = state.selectedMaterial.inks[inkId];

                          return Tooltip(
                            message: "${ink.name} (ID: $inkId)",
                            child: Container(
                              decoration: BoxDecoration(
                                color: ink.visualColor,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  width: 0.5,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  ink.label,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: ink.visualColor.computeLuminance() > 0.5 
                                        ? Colors.black 
                                        : Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Grid Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.grid_on, color: Colors.white.withValues(alpha: 0.7), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "8×8 Grid (64 cells) • ${state.inputText.isNotEmpty ? 'Active' : 'Waiting Input'}",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, GeneratorState state, GeneratorNotifier notifier) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Input Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "LatticeLock Generator",
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Generate secure encryption patterns for your physical security tags",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 20),
                    
                    // Input Field
                    TextField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.blue.shade300, width: 2),
                        ),
                        labelText: "Batch Code / Serial Number",
                        hintText: "e.g., LATTICE-2025-X",
                        prefixIcon: Icon(Icons.key, color: Colors.blue.shade700),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      ),
                      style: const TextStyle(fontSize: 16),
                      onChanged: (val) => notifier.updateInputText(val),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Material Profile Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.science, color: Colors.blue.shade700),
                        const SizedBox(width: 12),
                        Text(
                          "Material Profile",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.layers, color: Colors.blue.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  state.selectedMaterial.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Text(
                                  "${state.selectedMaterial.inks.length} ink types configured",
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Algorithm Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.enhanced_encryption, color: Colors.blue.shade700),
                        const SizedBox(width: 12),
                        Text(
                          "Pattern Generation Algorithm",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      // The value parameter is required to control the selected state.
                      // This is not redundant as it manages the dropdown selection state.
                      // Using deprecated value instead of initialValue as this is for state management,
                      // not form initialization in this context.
                      // ignore: avoid_redundant_argument_values, deprecated_member_use
                      value: state.selectedAlgorithm,
                      isExpanded: true,
                      items: [
                        // Chaos Algorithms Category
                        DropdownMenuItem(
                          value: "chaos_logistic",
                          child: Row(
                            children: [
                              Icon(Icons.timeline, size: 20, color: Colors.deepPurple),
                              const SizedBox(width: 12),
                              const Expanded(child: Text("Chaos Logistic Map")),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.deepPurple.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.deepPurple),
                                ),
                                child: const Text("Chaos", style: TextStyle(fontSize: 10, color: Colors.deepPurple)),
                              ),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: "chaos_tent",
                          child: Row(
                            children: [
                              Icon(Icons.show_chart, size: 20, color: Colors.deepOrange),
                              const SizedBox(width: 12),
                              const Expanded(child: Text("Chaos Tent Map")),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.deepOrange.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.deepOrange),
                                ),
                                child: const Text("Chaos", style: TextStyle(fontSize: 10, color: Colors.deepOrange)),
                              ),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: "chaos_arnolds_cat",
                          child: Row(
                            children: [
                              Icon(Icons.grid_4x4, size: 20, color: Colors.teal),
                              const SizedBox(width: 12),
                              const Expanded(child: Text("Arnold's Cat Map")),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.teal.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.teal),
                                ),
                                child: const Text("Chaos", style: TextStyle(fontSize: 10, color: Colors.teal)),
                              ),
                            ],
                          ),
                        ),
                        ],
                      onChanged: (val) {
                        if (val != null) {
                          notifier.updateAlgorithm(val);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Pattern Preview Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.grid_view, color: Colors.blue.shade700),
                        const SizedBox(width: 12),
                        Text(
                          "Encryption Pattern Preview",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.width * 0.9, // More space for mobile
                        minHeight: 280.0, // Better minimum height for larger cells
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.cyanAccent, width: 2),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // Calculate optimal cell size for square grid
                          final availableWidth = constraints.maxWidth;
                          final availableHeight = constraints.maxHeight;

                          // Account for spacing (7px total for 8x8 grid: 7 vertical + 7 horizontal)
                          final totalSpacing = 7.0;
                          final usableSpace = math.min(availableWidth, availableHeight) - totalSpacing;
                          final cellSize = usableSpace / 8;

                          // Ensure minimum comfortable size for mobile touch and readability
                          final finalCellSize = math.max(cellSize, 32.0);
                          final finalContainerSize = finalCellSize * 8 + totalSpacing;

                          return SizedBox(
                            width: finalContainerSize,
                            height: finalContainerSize,
                            child: GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 8,
                                crossAxisSpacing: 1,
                                mainAxisSpacing: 1,
                                childAspectRatio: 1,
                              ),
                              itemCount: state.encryptedPattern.isEmpty ? 64 : state.encryptedPattern.length,
                              itemBuilder: (context, index) {
                                final inkId = state.encryptedPattern.isEmpty ? 4 : state.encryptedPattern[index];
                                final ink = state.selectedMaterial.inks[inkId];

                                return Tooltip(
                                  message: "${ink.name} (ID: $inkId)",
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: ink.visualColor,
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Center(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.center,
                                        child: Text(
                                          ink.label,
                                          style: TextStyle(
                                            fontSize: math.min(finalCellSize * 0.35, 14.0), // Scaled font with max limit
                                            fontWeight: FontWeight.bold,
                                            color: ink.visualColor.computeLuminance() > 0.5
                                                ? Colors.black
                                                : Colors.white,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "8×8 Grid • ${state.inputText.isNotEmpty ? 'Active' : 'Waiting Input'}",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Status Indicator
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: state.inputText.isNotEmpty 
                    ? Colors.green.withValues(alpha: 0.1) 
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: state.inputText.isNotEmpty 
                      ? Colors.green 
                      : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    state.inputText.isNotEmpty ? Icons.check_circle : Icons.info,
                    color: state.inputText.isNotEmpty ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      state.inputText.isNotEmpty 
                          ? "Pattern generated successfully (${state.encryptedPattern.length} cells)"
                          : "Enter batch code to generate encryption pattern",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: state.inputText.isNotEmpty ? Colors.green.shade800 : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // PDF Generation Button
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: state.encryptedPattern.isNotEmpty 
                      ? [Colors.blue.shade800, Colors.blue.shade600]
                      : [Colors.grey.shade400, Colors.grey.shade300],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  if (state.encryptedPattern.isNotEmpty)
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: state.encryptedPattern.isNotEmpty && !state.isGenerating
                      ? () => notifier.generatePDF()
                      : null,
                  child: Center(
                    child: state.isGenerating
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text("Generating...", style: TextStyle(color: Colors.white, fontSize: 16)),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.print,
                                color: state.encryptedPattern.isNotEmpty ? Colors.white : Colors.grey.shade600,
                                size: 24
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "GENERATE BLUEPRINT PDF",
                                style: TextStyle(
                                  color: state.encryptedPattern.isNotEmpty ? Colors.white : Colors.grey.shade600,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                        ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: Colors.blue.shade700),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ],
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }
}