import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/custom_ink_profile.dart';
import '../models/ink_profile.dart';
import 'material_profile_provider.dart';

/// Configuration state for editing inks
class InkConfigurationState {
  final int inkCount;
  final List<CustomInkDefinition> inks;
  final bool isValid;
  final String? validationError;

  const InkConfigurationState({
    required this.inkCount,
    required this.inks,
    this.isValid = true,
    this.validationError,
  });

  InkConfigurationState copyWith({
    int? inkCount,
    List<CustomInkDefinition>? inks,
    bool? isValid,
    String? validationError,
  }) {
    return InkConfigurationState(
      inkCount: inkCount ?? this.inkCount,
      inks: inks ?? this.inks,
      isValid: isValid ?? this.isValid,
      validationError: validationError ?? this.validationError,
    );
  }
}

/// Notifier for managing ink configuration
class InkConfigurationNotifier extends StateNotifier<InkConfigurationState> {
  InkConfigurationNotifier() : super(const InkConfigurationState(
        inkCount: 5,
        inks: [],
      ));

  /// Initialize with inks from a profile
  void initializeFromProfile(CustomMaterialProfile profile) {
    state = InkConfigurationState(
      inkCount: profile.inks.length,
      inks: List.from(profile.inks),
      isValid: _validateInks(profile.inks),
    );
  }

  /// Set the number of inks (generates default inks)
  void setInkCount(int count) {
    if (count < 3 || count > 10) {
      state = state.copyWith(
        isValid: false,
        validationError: 'Ink count must be between 3 and 10',
      );
      return;
    }

    final currentInks = state.inks;
    final newInks = <CustomInkDefinition>[];

    for (int i = 0; i < count; i++) {
      if (i < currentInks.length) {
        // Keep existing ink
        newInks.add(currentInks[i]);
      } else {
        // Create new default ink
        newInks.add(_createDefaultInk(i));
      }
    }

    state = state.copyWith(
      inkCount: count,
      inks: newInks,
      isValid: _validateInks(newInks),
      validationError: null,
    );
  }

  /// Update a specific ink
  void updateInk(int index, CustomInkDefinition updatedInk) {
    if (index < 0 || index >= state.inks.length) {
      return;
    }

    final newInks = List<CustomInkDefinition>.from(state.inks);
    newInks[index] = updatedInk;

    state = state.copyWith(
      inks: newInks,
      isValid: _validateInks(newInks),
    );
  }

  /// Update ink name
  void updateInkName(int index, String name) {
    final ink = state.inks[index];
    updateInk(index, ink.copyWith(name: name));
  }

  /// Update ink code
  void updateInkCode(int index, String code) {
    final ink = state.inks[index];
    updateInk(index, ink.copyWith(code: code));
  }

  /// Update ink color
  void updateInkColor(int index, Color color) {
    final ink = state.inks[index];
    updateInk(index, ink.copyWith(color: color));
  }

  /// Update ink role
  void updateInkRole(int index, InkRole role) {
    final ink = state.inks[index];
    updateInk(index, ink.copyWith(role: role));
  }

  /// Reorder inks
  void reorderInks(int oldIndex, int newIndex) {
    if (oldIndex < 0 ||
        oldIndex >= state.inks.length ||
        newIndex < 0 ||
        newIndex >= state.inks.length) {
      return;
    }

    final newInks = List<CustomInkDefinition>.from(state.inks);
    final ink = newInks.removeAt(oldIndex);
    newInks.insert(newIndex, ink);

    // Update ink IDs to maintain order
    for (int i = 0; i < newInks.length; i++) {
      final baseId = newInks[i].id.split('_').last;
      newInks[i] = newInks[i].copyWith(id: 'ink_$i');
    }

    state = state.copyWith(inks: newInks);
  }

  /// Validate all inks
  bool _validateInks(List<CustomInkDefinition> inks) {
    if (inks.length < 3 || inks.length > 10) {
      return false;
    }

    // Check for required fields and uniqueness
    final codes = <String>{};
    for (final ink in inks) {
      if (ink.name.trim().isEmpty) {
        state = state.copyWith(
          validationError: 'All inks must have a name',
        );
        return false;
      }

      if (ink.code.trim().isEmpty) {
        state = state.copyWith(
          validationError: 'All inks must have a code',
        );
        return false;
      }

      if (ink.code.length > 5) {
        state = state.copyWith(
          validationError: 'Ink code cannot exceed 5 characters',
        );
        return false;
      }

      if (codes.contains(ink.code.toLowerCase())) {
        state = state.copyWith(
          validationError: 'Ink codes must be unique',
        );
        return false;
      }

      codes.add(ink.code.toLowerCase());
    }

    return true;
  }

  /// Create a default ink with standard colors
  CustomInkDefinition _createDefaultInk(int index) {
    // Use a variety of colors for default inks
    final defaultColors = [
      const Color(0xFF00E5FF), // Cyan
      const Color(0xFF00BCD4), // Cyan Dark
      const Color(0xFF1DE9B6), // Teal Accent
      const Color(0xFF009688), // Teal
      const Color(0xFF2196F3), // Blue
      const Color(0xFF4CAF50), // Green
      const Color(0xFFFF9800), // Orange
      const Color(0xFFE91E63), // Pink
      const Color(0xFF9C27B0), // Purple
      const Color(0xFFF44336), // Red
    ];

    return CustomInkDefinition()
      ..id = 'ink_$index'
      ..name = 'Ink ${index + 1}'
      ..code = '${(index + 1) * 10}R'
      ..color = defaultColors[index % defaultColors.length]
      ..role = InkRole.dataHigh
      ..hexValue = defaultColors[index % defaultColors.length].value;
  }

  /// Get validation error message
  String? getValidationError() {
    return state.validationError;
  }

  /// Check if configuration is valid
  bool get isValid => state.isValid;

  /// Reset to default state
  void reset() {
    state = const InkConfigurationState(
      inkCount: 5,
      inks: [],
    );
  }
}

/// Provider for ink configuration
final inkConfigurationProvider =
    StateNotifierProvider<InkConfigurationNotifier, InkConfigurationState>((ref) {
  return InkConfigurationNotifier();
});

/// Provider that combines profile and ink configuration
class CombinedInkConfig {
  final CustomMaterialProfile? activeProfile;
  final InkConfigurationState config;

  const CombinedInkConfig({
    required this.activeProfile,
    required this.config,
  });

  /// Check if the configuration matches the active profile
  bool get isModified {
    if (activeProfile == null) return false;
    if (activeProfile!.inks.length != config.inks.length) return true;

    for (int i = 0; i < config.inks.length; i++) {
      final profileInk = activeProfile!.inks[i];
      final configInk = config.inks[i];

      if (profileInk.name != configInk.name ||
          profileInk.code != configInk.code ||
          profileInk.color.value != configInk.color.value) {
        return true;
      }
    }

    return false;
  }
}

/// Provider for combined ink configuration
final combinedInkConfigProvider = Provider<CombinedInkConfig>((ref) {
  final profileState = ref.watch(materialProfileProvider);
  final inkConfig = ref.watch(inkConfigurationProvider);

  return CombinedInkConfig(
    activeProfile: profileState.activeProfile,
    config: inkConfig,
  );
});
