import 'package:hive_flutter/hive_flutter.dart';
import '../models/custom_ink_profile.dart';

/// Repository for managing custom material profiles
class MaterialProfileRepository {
  static const String _boxName = 'materialProfiles';
  static const String _standardProfileId = 'standard';

  Box<CustomMaterialProfile>? _profileBox;
  bool _isInitialized = false;

  /// Ensure the repository is initialized before use
  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;

    if (!Hive.isBoxOpen(_boxName)) {
      _profileBox = await Hive.openBox<CustomMaterialProfile>(_boxName);
    } else {
      _profileBox = Hive.box<CustomMaterialProfile>(_boxName);
    }

    _isInitialized = true;

    // Ensure standard profile exists
    await _ensureStandardProfile();
  }

  /// Initialize the repository and open Hive box
  Future<void> init() async {
    await _ensureInitialized();
  }

  /// Ensure the standard profile is created on first launch
  Future<void> _ensureStandardProfile() async {
    if (!_profileBox!.containsKey(_standardProfileId)) {
      final standardProfile = CustomMaterialProfile.createStandardProfile();
      await _profileBox!.put(_standardProfileId, standardProfile);
    }
  }

  /// Get all profiles
  Future<List<CustomMaterialProfile>> getAllProfiles() async {
    await _ensureInitialized();
    return _profileBox!.values.toList();
  }

  /// Get a specific profile by ID
  Future<CustomMaterialProfile?> getProfile(String id) async {
    await _ensureInitialized();
    return _profileBox!.get(id);
  }

  /// Get the currently active profile
  Future<CustomMaterialProfile?> getActiveProfile() async {
    await _ensureInitialized();
    final profiles = _profileBox!.values.toList();
    return profiles.cast<CustomMaterialProfile?>().firstWhere(
      (p) => p?.isActive == true,
      orElse: () => null,
    );
  }

  /// Set a profile as active (deactivates all others)
  Future<void> setActiveProfile(String profileId) async {
    await _ensureInitialized();

    // Deactivate all profiles
    final profiles = _profileBox!.values.toList();
    for (final profile in profiles) {
      if (profile.id != profileId && profile.isActive) {
        profile.isActive = false;
        await _profileBox!.put(profile.id, profile);
      }
    }

    // Activate the target profile
    final targetProfile = _profileBox!.get(profileId);
    if (targetProfile != null) {
      targetProfile.isActive = true;
      targetProfile.modifiedAt = DateTime.now();
      await _profileBox!.put(profileId, targetProfile);
    }
  }

  /// Save a new profile or update existing
  Future<void> saveProfile(CustomMaterialProfile profile) async {
    await _ensureInitialized();

    profile.modifiedAt = DateTime.now();

    // If this is the first profile, make it active
    if (_profileBox!.isEmpty) {
      profile.isActive = true;
    }

    await _profileBox!.put(profile.id, profile);
  }

  /// Delete a profile (except standard profile)
  Future<bool> deleteProfile(String profileId) async {
    await _ensureInitialized();

    // Cannot delete standard profile
    if (profileId == _standardProfileId) {
      return false;
    }

    final profile = _profileBox!.get(profileId);
    if (profile == null) {
      return false;
    }

    // If deleting active profile, activate standard
    if (profile.isActive) {
      await setActiveProfile(_standardProfileId);
    }

    await _profileBox!.delete(profileId);
    return true;
  }

  /// Duplicate a profile with a new ID
  Future<CustomMaterialProfile> duplicateProfile(
    String sourceProfileId,
    String newProfileId,
    String newProfileName,
  ) async {
    await _ensureInitialized();

    final sourceProfile = _profileBox!.get(sourceProfileId);
    if (sourceProfile == null) {
      throw Exception('Source profile not found: $sourceProfileId');
    }

    final duplicatedProfile = CustomMaterialProfile()
      ..id = newProfileId
      ..name = newProfileName
      ..isActive = false
      ..createdAt = DateTime.now()
      ..modifiedAt = DateTime.now();

    // Deep copy the inks
    duplicatedProfile.inks = sourceProfile.inks.map((ink) {
      return ink.copyWith()
        ..id = '${newProfileId}_${ink.id}';
    }).toList();

    await saveProfile(duplicatedProfile);
    return duplicatedProfile;
  }

  /// Update a specific ink in a profile
  Future<void> updateInk(
    String profileId,
    CustomInkDefinition updatedInk,
  ) async {
    final profile = await getProfile(profileId);
    if (profile == null) {
      throw Exception('Profile not found: $profileId');
    }

    final inkIndex = profile.inks.indexWhere((ink) => ink.id == updatedInk.id);
    if (inkIndex == -1) {
      throw Exception('Ink not found: ${updatedInk.id}');
    }

    profile.inks[inkIndex] = updatedInk;
    profile.modifiedAt = DateTime.now();
    await saveProfile(profile);
  }

  /// Add a new ink to a profile
  Future<void> addInk(String profileId, CustomInkDefinition newInk) async {
    final profile = await getProfile(profileId);
    if (profile == null) {
      throw Exception('Profile not found: $profileId');
    }

    profile.inks.add(newInk);
    profile.modifiedAt = DateTime.now();
    await saveProfile(profile);
  }

  /// Remove an ink from a profile
  Future<void> removeInk(String profileId, String inkId) async {
    final profile = await getProfile(profileId);
    if (profile == null) {
      throw Exception('Profile not found: $profileId');
    }

    // Don't allow removing all inks (minimum 3)
    if (profile.inks.length <= 3) {
      throw Exception('Cannot remove ink: minimum 3 inks required');
    }

    profile.inks.removeWhere((ink) => ink.id == inkId);
    profile.modifiedAt = DateTime.now();
    await saveProfile(profile);
  }

  /// Get total number of profiles
  Future<int> getProfileCount() async {
    await _ensureInitialized();
    return _profileBox!.length;
  }

  /// Clear all custom profiles (except standard)
  Future<void> clearCustomProfiles() async {
    final profiles = await getAllProfiles();
    for (final profile in profiles) {
      if (profile.id != _standardProfileId) {
        await deleteProfile(profile.id);
      }
    }
  }

  /// Close the repository
  Future<void> close() async {
    if (_profileBox != null && _profileBox!.isOpen) {
      await _profileBox!.close();
    }
  }
}
