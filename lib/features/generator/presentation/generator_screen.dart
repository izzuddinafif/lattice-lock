import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'dart:math' as math;
import '../logic/generator_state.dart';
import '../../../core/models/grid_config.dart';
import '../../material/providers/material_profile_provider.dart';

class GeneratorScreen extends ConsumerStatefulWidget {
  const GeneratorScreen({super.key});

  @override
  ConsumerState<GeneratorScreen> createState() => _GeneratorScreenState();
}

class _GeneratorScreenState extends ConsumerState<GeneratorScreen> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _keyController = TextEditingController();
  
  // Grid controllers

  // PDF generation controllers
  late ScrollController _leftScrollController;
  late ScrollController _rightScrollController;

  // State variables
  String? _selectedProfileId;

  @override
  void initState() {
    super.initState();

    // Initialize scroll controllers
    _leftScrollController = ScrollController();
    _rightScrollController = ScrollController();

    // Load saved data if available
    _loadSavedData();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _keyController.dispose();
    _leftScrollController.dispose();
    _rightScrollController.dispose();
    super.dispose();
  }

  void _loadSavedData() {
    // In a real app, you'd load saved data from secure storage here
    // For now, we'll use defaults
    _inputController.text = '';
    _keyController.text = '';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
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
      },
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
            child: Scrollbar(
              controller: _leftScrollController,
              thumbVisibility: true,
              thickness: 12.0,
              radius: const Radius.circular(6),
              interactive: true,
              child: SingleChildScrollView(
                controller: _leftScrollController,
                padding: const EdgeInsets.all(24),
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 400,
                    maxWidth: 600,
                  ),
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
                  padding: const EdgeInsets.all(24),
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
                    onChanged: (val) {
                      _inputController.text = val;
                      notifier.updateInputText(val);
                    },
                  ),
                  
                  const SizedBox(height: 48), // Increased from 24
                  
                  // Action Buttons
                  _buildSectionCard(
                    title: "Material Profile",
                    icon: Icons.science,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        Consumer(
                          builder: (context, ref, _) {
                            final materialState = ref.watch(materialProfileProvider);
                            final profiles = materialState.profiles;
                            final activeProfile = materialState.activeProfile;

                            // Initialize selected profile ID if not set
                            if (_selectedProfileId == null && activeProfile != null) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                setState(() {
                                  _selectedProfileId = activeProfile.id;
                                });
                              });
                            }

                            if (profiles.isEmpty) {
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: const Text('No profiles available. Please create a profile in the Materials tab.'),
                              );
                            }

                            return DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: 'Select Material Profile',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                prefixIcon: Icon(Icons.layers, color: Colors.blue.shade700),
                              ),
                              initialValue: _selectedProfileId ?? activeProfile?.id,
                              isExpanded: true,
                              items: profiles.map((profile) {
                                return DropdownMenuItem<String>(
                                  value: profile.id,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: profile.isActive ? Colors.green : Colors.grey,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Icon(
                                          profile.isActive ? Icons.check : Icons.help_outline,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          profile.name,
                                          style: const TextStyle(fontSize: 14),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        "${profile.inks.length} inks",
                                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (profileId) {
                                if (kDebugMode) {
                                  print('🔄 [GENERATOR] Material profile changed to: $profileId');
                                  print('🔄 [GENERATOR] Input text: "${_inputController.text}"');
                                  print('🔄 [GENERATOR] Is input not empty: ${_inputController.text.trim().isNotEmpty}');
                                }
                                if (profileId != null) {
                                  setState(() {
                                    _selectedProfileId = profileId;
                                  });

                                  // DON'T call setActiveProfile() here - it's async and causes race condition
                                  // Instead, get the profile directly from the provider's profiles list
                                  final materialState = ref.read(materialProfileProvider);

                                  // Find the profile by ID in the profiles list
                                  final profile = materialState.profiles.firstWhere(
                                    (p) => p.id == profileId,
                                    orElse: () => materialState.activeProfile ?? materialState.profiles.first,
                                  );

                                  final newMaterial = profile.toMaterialProfile();

                                  if (kDebugMode) {
                                    print('🔄 [UI] Retrieved newMaterial: ${newMaterial.name} (${newMaterial.inks.length} inks)');
                                  }

                                  // Auto-regenerate pattern IMMEDIATELY if there's input text
                                  if (_inputController.text.trim().isNotEmpty) {
                                    if (kDebugMode) {
                                      print('🔄 [UI] Triggering IMMEDIATE regeneration...');
                                    }
                                    // DON'T use postFrameCallback - call synchronously to avoid race conditions
                                    ref.read(generatorProvider.notifier).updateMaterial(newMaterial);
                                    ref.read(generatorProvider.notifier).regenerate();
                                  } else {
                                    // Just update material, no regeneration
                                    if (kDebugMode) {
                                      print('⚠️ [GENERATOR] No input text, updating material without regeneration');
                                    }
                                    ref.read(generatorProvider.notifier).updateMaterial(newMaterial);
                                  }

                                  // Now set the active profile in background (doesn't block generation)
                                  ref.read(materialProfileProvider.notifier).setActiveProfile(profileId);
                                }
                              },
                            );
                          },
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
                        // Hybrid Chaotic Encryption (Hash Function)
                        DropdownMenuItem(
                          value: "chaos_logistic", // Keep old value for compatibility
                          child: Row(
                            children: [
                              Icon(Icons.lock_reset, size: 20, color: Colors.blue.shade700),
                              const SizedBox(width: 12),
                              const Expanded(child: Text("Hybrid Chaotic Map")),
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
                  
                  const SizedBox(height: 40),
                  
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
                  
                  // Grid Size Configuration
                  _buildSectionCard(
                    title: "Grid Size Configuration",
                    icon: Icons.grid_4x4,
                    child: DropdownButtonFormField<GridConfig>(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      // ignore: avoid_redundant_argument_values, deprecated_member_use
                      value: state.selectedGridConfig,
                      isExpanded: true,
                      items: GridConfig.presets.map((config) {
                        return DropdownMenuItem(
                          value: config,
                          child: Row(
                            children: [
                              Icon(
                                _getGridSizeIcon(config.useCase),
                                size: 14,
                                color: _getGridSizeColor(config.useCase),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  config.description,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.blue),
                                ),
                                child: Text(
                                  "${config.size}×${config.size}",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          notifier.updateGridConfig(val);
                        }
                      },
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
            child: Scrollbar(
              controller: _rightScrollController,
              thumbVisibility: true,
              thickness: 12.0,
              radius: const Radius.circular(6),
              interactive: true,
              child: SingleChildScrollView(
                controller: _rightScrollController,
                padding: const EdgeInsets.all(32),
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 400,
                    maxWidth: 800,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey[900],
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(-2, 0),
                      ),
                    ],
                  ),
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
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: state.selectedGridConfig.size,
                          crossAxisSpacing: _getGridSpacing(state.selectedGridConfig.size),
                          mainAxisSpacing: _getGridSpacing(state.selectedGridConfig.size),
                        ),
                        itemCount: state.encryptedPattern.isEmpty
                            ? state.selectedGridConfig.totalCells
                            : state.encryptedPattern.length,
                        itemBuilder: (context, index) {
                          final inkId = state.encryptedPattern.isEmpty
                              ? state.selectedMaterial.inks.length - 1
                              : state.encryptedPattern[index];
                          final ink = state.selectedMaterial.inks[inkId.clamp(0, state.selectedMaterial.inks.length - 1)];
                          final shouldShowText = _shouldShowGridText(state.selectedGridConfig.size);

                          return Tooltip(
                            message: "${ink.name} (ID: $inkId)",
                            child: Container(
                              decoration: BoxDecoration(
                                color: ink.visualColor,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  width: 0.3,
                                ),
                              ),
                              child: shouldShowText ? Center(
                                child: Text(
                                  ink.label,
                                  style: TextStyle(
                                    fontSize: _getTextSize(state.selectedGridConfig.size),
                                    fontWeight: FontWeight.bold,
                                    color: ink.visualColor.computeLuminance() > 0.5
                                        ? Colors.black
                                        : Colors.white,
                                  ),
                                ),
                              ) : null,
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
                          "${state.selectedGridConfig.displayName} Grid (${state.selectedGridConfig.totalCells} cells) • ${state.inputText.isNotEmpty ? 'Active' : 'Waiting Input'}",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Color Legend
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.palette, color: Colors.cyanAccent, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              "Ink Colors",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: state.selectedMaterial.inks.asMap().entries.map((entry) {
                            final inkId = entry.key;
                            final ink = entry.value;
                            return _buildInkLegendItem(inkId, ink);
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),  // Close SingleChildScrollView
        ),    // Close Scrollbar
      ),    // Close Expanded (right panel)
        ],  // Close Row children
      ),  // Close Row
    );  // Close Scaffold
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
                      onChanged: (val) {
                        _inputController.text = val;
                        notifier.updateInputText(val);
                      },
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
                    Consumer(
                      builder: (context, ref, _) {
                        final materialState = ref.watch(materialProfileProvider);
                        final profiles = materialState.profiles;
                        final activeProfile = materialState.activeProfile;

                        // Initialize selected profile ID if not set
                        if (_selectedProfileId == null && activeProfile != null) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              setState(() {
                                _selectedProfileId = activeProfile.id;
                              });
                            }
                          });
                        }

                        if (profiles.isEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: const Text('No profiles available. Please create a profile in the Materials tab.'),
                          );
                        }

                        return DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Select Material Profile',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            prefixIcon: Icon(Icons.layers, color: Colors.blue.shade700),
                          ),
                          initialValue: _selectedProfileId ?? activeProfile?.id,
                          isExpanded: true,
                          items: profiles.map((profile) {
                            return DropdownMenuItem<String>(
                              value: profile.id,
                              child: Row(
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: profile.isActive ? Colors.green : Colors.grey,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Icon(
                                      profile.isActive ? Icons.check : Icons.help_outline,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      profile.name,
                                      style: const TextStyle(fontSize: 14),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    "${profile.inks.length} inks",
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (profileId) {
                            if (kDebugMode) {
                              print('🔄 [GENERATOR] Material profile changed to: $profileId');
                              print('🔄 [GENERATOR] Input text: "${_inputController.text}"');
                              print('🔄 [GENERATOR] Is input not empty: ${_inputController.text.trim().isNotEmpty}');
                            }
                            if (profileId != null) {
                              setState(() {
                                _selectedProfileId = profileId;
                              });

                              // DON'T call setActiveProfile() here - it's async and causes race condition
                              // Instead, get the profile directly from the provider's profiles list
                              final materialState = ref.read(materialProfileProvider);

                              // Find the profile by ID in the profiles list
                              final profile = materialState.profiles.firstWhere(
                                (p) => p.id == profileId,
                                orElse: () => materialState.activeProfile ?? materialState.profiles.first,
                              );

                              final newMaterial = profile.toMaterialProfile();

                              if (kDebugMode) {
                                print('🔄 [UI] Retrieved newMaterial: ${newMaterial.name} (${newMaterial.inks.length} inks)');
                              }

                              // Auto-regenerate pattern IMMEDIATELY if there's input text
                              if (_inputController.text.trim().isNotEmpty) {
                                if (kDebugMode) {
                                  print('🔄 [UI] Triggering IMMEDIATE regeneration...');
                                }
                                // DON'T use postFrameCallback - call synchronously to avoid race conditions
                                ref.read(generatorProvider.notifier).updateMaterial(newMaterial);
                                ref.read(generatorProvider.notifier).regenerate();
                              } else {
                                // Just update material, no regeneration
                                if (kDebugMode) {
                                  print('⚠️ [GENERATOR] No input text, updating material without regeneration');
                                }
                                ref.read(generatorProvider.notifier).updateMaterial(newMaterial);
                              }

                              // Now set the active profile in background (doesn't block generation)
                              ref.read(materialProfileProvider.notifier).setActiveProfile(profileId);
                            }
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    // Ink Color Legend
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.palette, color: Colors.blue.shade700),
                              const SizedBox(width: 8),
                              Text(
                                "Ink Color Legend",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "(Hidden for small grids)",
                                style: TextStyle(fontSize: 11, color: Colors.grey[600], fontStyle: FontStyle.italic),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: state.selectedMaterial.inks.asMap().entries.map((entry) {
                              // final index = entry.key; // Unused but kept for potential future use
                              final ink = entry.value;
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: ink.visualColor,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.5),
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "${ink.label} (${ink.name})",
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Grid Size Configuration
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.grid_4x4, color: Colors.blue.shade700),
                        const SizedBox(width: 12),
                        Text(
                          "Grid Size Configuration",
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
                          Icon(Icons.grid_on, color: Colors.blue.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${state.selectedGridConfig.size}×${state.selectedGridConfig.size} Grid",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Text(
                                  state.selectedGridConfig.description,
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<GridConfig>(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      // ignore: avoid_redundant_argument_values, deprecated_member_use
                      value: state.selectedGridConfig,
                      isExpanded: true,
                      items: GridConfig.presets.map((config) {
                        return DropdownMenuItem<GridConfig>(
                          value: config,
                          child: Row(
                            children: [
                              Icon(
                                Icons.grid_4x4,
                                size: 18,
                                color: Colors.blue.shade700,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  config.displayName,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "${config.size}",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (GridConfig? newValue) {
                        if (newValue != null) {
                          notifier.updateGridConfig(newValue);
                        }
                      },
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
                        // Hybrid Chaotic Encryption (Hash Function)
                        DropdownMenuItem(
                          value: "chaos_logistic", // Keep old value for compatibility
                          child: Row(
                            children: [
                              Icon(Icons.lock_reset, size: 20, color: Colors.blue.shade700),
                              const SizedBox(width: 12),
                              const Expanded(child: Text("Hybrid Chaotic Map")),
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
                          // Calculate optimal cell size for square grid with mobile optimization
                          final availableWidth = constraints.maxWidth;
                          final availableHeight = constraints.maxHeight;
                          final screenWidth = MediaQuery.of(context).size.width;
                          final gridSize = state.selectedGridConfig.size;

                          // Mobile-responsive minimum cell size
                          final minCellSize = screenWidth < 600
                              ? (gridSize > 12 ? 15.0 : 25.0) // Smaller min for very large grids on mobile
                              : (gridSize > 16 ? 18.0 : 30.0); // Larger minimum for desktop

                          // Account for spacing (gridSize-1)px total for both vertical and horizontal
                          final totalSpacing = (gridSize - 1).toDouble();
                          final usableSpace = math.min(availableWidth, availableHeight) - totalSpacing;
                          final cellSize = usableSpace / gridSize;

                          // Ensure minimum comfortable size for mobile touch and readability
                          final finalCellSize = math.max(cellSize, minCellSize);

                          // Limit maximum size for very large grids to prevent overflow
                          final maxContainerSize = screenWidth < 600
                              ? screenWidth * 0.8   // Use 80% of screen width on mobile
                              : math.min(availableWidth, availableHeight) * 0.9; // 90% on desktop

                          final finalContainerSize = math.min(
                            finalCellSize * gridSize + totalSpacing,
                            maxContainerSize
                          );

                          return SizedBox(
                            width: finalContainerSize,
                            height: finalContainerSize,
                            child: GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: gridSize,
                                crossAxisSpacing: 1,
                                mainAxisSpacing: 1,
                                childAspectRatio: 1,
                              ),
                              itemCount: state.encryptedPattern.isEmpty 
                                  ? state.selectedGridConfig.totalCells 
                                  : state.encryptedPattern.length,
                              itemBuilder: (context, index) {
                                final inkId = state.encryptedPattern.isEmpty
                                    ? state.selectedMaterial.inks.length - 1
                                    : state.encryptedPattern[index];
                                final ink = state.selectedMaterial.inks[inkId.clamp(0, state.selectedMaterial.inks.length - 1)];

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
                                      child: _shouldShowGridText(gridSize)
                                          ? FittedBox(
                                              fit: BoxFit.scaleDown,
                                              alignment: Alignment.center,
                                              child: Text(
                                                ink.label,
                                                style: TextStyle(
                                                  fontSize: math.min(finalCellSize * 0.25, 8.0), // Much smaller scaled font
                                                  fontWeight: FontWeight.bold,
                                                  color: ink.visualColor.computeLuminance() > 0.5
                                                      ? Colors.black
                                                      : Colors.white,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            )
                                          : const SizedBox(), // Hide text for large grids
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
                      "${state.selectedGridConfig.displayName} Grid • ${state.inputText.isNotEmpty ? 'Active' : 'Waiting Input'}",
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

  IconData _getGridSizeIcon(String useCase) {
    switch (useCase.toLowerCase()) {
      case 'poc':
      case 'demo':
        return Icons.speed;
      case 'education':
      case 'testing':
        return Icons.school;
      case 'advanced':
        return Icons.trending_up;
      case 'production':
      case 'enterprise':
        return Icons.business;
      case 'professional':
        return Icons.work;
      case 'research':
      case 'scientific':
        return Icons.science;
      case 'industrial':
        return Icons.factory;
      case 'high security':
        return Icons.security;
      default:
        return Icons.grid_4x4;
    }
  }

  Color _getGridSizeColor(String useCase) {
    switch (useCase.toLowerCase()) {
      case 'poc':
      case 'demo':
        return Colors.green;
      case 'education':
      case 'testing':
        return Colors.blue;
      case 'advanced':
        return Colors.orange;
      case 'production':
      case 'enterprise':
        return Colors.purple;
      case 'professional':
        return Colors.indigo;
      case 'research':
      case 'scientific':
        return Colors.teal;
      case 'industrial':
        return Colors.grey;
      case 'high security':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  /// Build individual ink legend item
  Widget _buildInkLegendItem(int inkId, dynamic ink) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ink.visualColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ink.visualColor,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Color square
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: ink.visualColor,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Text label
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                ink.label,
                style: TextStyle(
                  color: ink.visualColor.computeLuminance() > 0.5
                      ? Colors.black
                      : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'ID: $inkId',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Determines whether text should be shown in grid cells
  bool _shouldShowGridText(int gridSize) {
    // Hide text for large grids to prevent clutter
    if (gridSize >= 16) return false;

    // Hide text for medium grids on web/desktop
    if (kIsWeb && gridSize >= 10) return false;

    return true;
  }

  /// Calculate appropriate text size based on grid size
  double _getTextSize(int gridSize) {
    switch (gridSize) {
      case 4:
      case 6:
        return 12.0;
      case 8:
        return 10.0;
      case 10:
      case 12:
        return 8.0;
      case 16:
        return 6.0;
      default:
        return 8.0; // Default for unknown grid sizes
    }
  }

  /// Calculate appropriate grid spacing based on grid size
  double _getGridSpacing(int gridSize) {
    switch (gridSize) {
      case 4:
      case 6:
        return 2.0;
      case 8:
        return 1.5;
      case 10:
      case 12:
        return 1.0;
      case 16:
      case 20:
      case 24:
      case 32:
        return 0.5;
      default:
        return 1.0; // Default spacing
    }
  }
}