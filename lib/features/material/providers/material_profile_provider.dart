import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/custom_ink_profile.dart';
import '../data/material_profile_repository.dart';

/// Provider for the material profile repository
final materialProfileRepositoryProvider =
    Provider<MaterialProfileRepository>((ref) {
  final repository = MaterialProfileRepository();
  ref.onDispose(() => repository.close());
  return repository;
});

/// State class for material profiles
class MaterialProfileState {
  final List<CustomMaterialProfile> profiles;
  final CustomMaterialProfile? activeProfile;
  final bool isLoading;
  final String? error;

  const MaterialProfileState({
    this.profiles = const [],
    this.activeProfile,
    this.isLoading = false,
    this.error,
  });

  MaterialProfileState copyWith({
    List<CustomMaterialProfile>? profiles,
    CustomMaterialProfile? activeProfile,
    bool? isLoading,
    String? error,
  }) {
    return MaterialProfileState(
      profiles: profiles ?? this.profiles,
      activeProfile: activeProfile ?? this.activeProfile,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Notifier for managing material profiles
class MaterialProfileNotifier extends StateNotifier<MaterialProfileState> {
  final MaterialProfileRepository _repository;

  MaterialProfileNotifier(this._repository)
      : super(const MaterialProfileState()) {
    _loadProfiles();
  }

  /// Load all profiles from storage
  Future<void> _loadProfiles() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final profiles = await _repository.getAllProfiles();
      final activeProfile = await _repository.getActiveProfile();

      state = state.copyWith(
        profiles: profiles,
        activeProfile: activeProfile,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load profiles: $e',
      );
    }
  }

  /// Refresh profiles from storage
  Future<void> refresh() async {
    await _loadProfiles();
  }

  /// Create a new profile
  Future<void> createProfile(CustomMaterialProfile profile) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _repository.saveProfile(profile);
      await _loadProfiles();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create profile: $e',
      );
    }
  }

  /// Update an existing profile
  Future<void> updateProfile(CustomMaterialProfile profile) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _repository.saveProfile(profile);
      await _loadProfiles();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update profile: $e',
      );
    }
  }

  /// Delete a profile
  Future<void> deleteProfile(String profileId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final success = await _repository.deleteProfile(profileId);
      if (!success) {
        state = state.copyWith(
          isLoading: false,
          error: 'Cannot delete standard profile',
        );
        return;
      }

      await _loadProfiles();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete profile: $e',
      );
    }
  }

  /// Set a profile as active
  Future<void> setActiveProfile(String profileId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _repository.setActiveProfile(profileId);
      await _loadProfiles();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to set active profile: $e',
      );
    }
  }

  /// Duplicate a profile
  Future<CustomMaterialProfile> duplicateProfile(
    String sourceId,
    String newName,
  ) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final newId = 'profile_${DateTime.now().millisecondsSinceEpoch}';
      final duplicated = await _repository.duplicateProfile(
        sourceId,
        newId,
        newName,
      );

      await _loadProfiles();
      return duplicated;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to duplicate profile: $e',
      );
      rethrow;
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for material profile state
final materialProfileProvider =
    StateNotifierProvider<MaterialProfileNotifier, MaterialProfileState>((ref) {
  final repository = ref.watch(materialProfileRepositoryProvider);
  return MaterialProfileNotifier(repository);
});

