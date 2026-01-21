import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import '../models/custom_ink_profile.dart';
import '../models/ink_profile.dart';
import '../providers/ink_configuration_provider.dart';
import '../providers/material_profile_provider.dart';

/// Screen for configuring custom material profiles - 3 Color System
class InkConfigurationScreen extends ConsumerStatefulWidget {
  final String? profileId;

  const InkConfigurationScreen({
    super.key,
    this.profileId,
  });

  @override
  ConsumerState<InkConfigurationScreen> createState() =>
      _InkConfigurationScreenState();
}

class _InkConfigurationScreenState
    extends ConsumerState<InkConfigurationScreen> {
  final TextEditingController _profileNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    if (widget.profileId != null) {
      // Load existing profile
      final profileState = ref.read(materialProfileProvider);
      final profile = profileState.profiles
          .where((p) => p.id == widget.profileId)
          .firstOrNull;

      if (profile != null) {
        _profileNameController.text = profile.name;
        // Delay provider modification until after widget tree is built
        Future.microtask(() {
          ref.read(inkConfigurationProvider.notifier)
              .initializeFromProfile(profile);
        });
      }
    } else {
      // Check if there's unsaved configuration
      final config = ref.read(inkConfigurationProvider);
      if (config.inks.isEmpty) {
        // Delay provider modification until after widget tree is built
        // Initialize with 3 inks (fixed 3-color system)
        Future.microtask(() {
          ref.read(inkConfigurationProvider.notifier).setInkCount(3);
        });
      }
    }
  }

  @override
  void dispose() {
    _profileNameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final config = ref.read(inkConfigurationProvider);
    final notifier = ref.read(inkConfigurationProvider.notifier);

    // Validate configuration
    if (!config.isValid) {
      final error = notifier.getValidationError();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Configuration is invalid')),
      );
      return;
    }

    // Validate profile name
    final profileName = _profileNameController.text.trim();
    if (profileName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a profile name')),
      );
      return;
    }

    // Create or update profile
    final profile = CustomMaterialProfile()
      ..id = widget.profileId ?? 'profile_${DateTime.now().millisecondsSinceEpoch}'
      ..name = profileName
      ..inks = List.from(config.inks)
      ..createdAt = DateTime.now()
      ..modifiedAt = DateTime.now()
      ..isActive = false;

    final profileNotifier = ref.read(materialProfileProvider.notifier);

    try {
      if (widget.profileId != null) {
        await profileNotifier.updateProfile(profile);
      } else {
        await profileNotifier.createProfile(profile);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: $e')),
        );
      }
    }
  }

  void _showColorPicker(int index) {
    final config = ref.read(inkConfigurationProvider);
    final ink = config.inks[index];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pick color for ${ink.name}'),
        content: SizedBox(
          width: 320,
          height: 500,
          child: ColorPicker(
              color: ink.color,
              onColorChanged: (Color color) {
                ref.read(inkConfigurationProvider.notifier).updateInkColor(index, color);
              },
              width: 40,
              height: 40,
              borderRadius: 4,
              heading: const Text('Select color'),
              subheading: const Text('Select shade'),
              pickersEnabled: const <ColorPickerType, bool>{
                ColorPickerType.both: false,
                ColorPickerType.primary: true,
                ColorPickerType.accent: false,
                ColorPickerType.wheel: true,
              },
            ),
          ),
          actions: [
            TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showRoleSelector(int index) {
    final config = ref.read(inkConfigurationProvider);
    final ink = config.inks[index];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Ink Role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: InkRole.values.map((role) {
            return RadioListTile<InkRole>(
              title: Text(_getRoleDisplayName(role)),
              subtitle: Text(_getRoleDescription(role)),
              value: role,
              groupValue: ink.role,
              onChanged: (InkRole? value) {
                if (value != null) {
                  ref.read(inkConfigurationProvider.notifier).updateInkRole(index, value);
                  Navigator.of(context).pop();
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  String _getRoleDisplayName(InkRole role) {
    switch (role) {
      case InkRole.dataHigh:
        return 'Data High (75°C)';
      case InkRole.dataLow:
        return 'Data Low (55°C)';
      case InkRole.fake:
        return 'Protected/Fake';
      case InkRole.metadata:
        return 'Metadata/Marker';
    }
  }

  String _getRoleDescription(InkRole role) {
    switch (role) {
      case InkRole.dataHigh:
        return 'Reactive at 75°C - for critical data';
      case InkRole.dataLow:
        return 'Reactive at 55°C - for standard data';
      case InkRole.fake:
        return 'Protected ink - for security patterns';
      case InkRole.metadata:
        return 'Marker ink - for metadata and labels';
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(inkConfigurationProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.profileId != null ? 'Edit Profile' : 'New Profile'),
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Name
          TextField(
            controller: _profileNameController,
            decoration: const InputDecoration(
              labelText: 'Profile Name',
              hintText: 'e.g., My Custom Material Set',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),

          // Fixed 3-color system info
          Text(
            'Number of Inks: 3 (Fixed)',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'The system uses a fixed 3-color configuration for deterministic pattern generation.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),

          // Validation Error
          if (!config.isValid && config.validationError != null)
        Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      config.validationError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Ink Configuration List
          Text(
            'Ink Configuration',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          ...List.generate(config.inks.length, (index) {
            final ink = config.inks[index];
            return _InkConfigurationCard(
              index: index,
              ink: ink,
              onNameChanged: (name) {
                ref.read(inkConfigurationProvider.notifier).updateInkName(index, name);
              },
              onCodeChanged: (code) {
                ref.read(inkConfigurationProvider.notifier).updateInkCode(index, code);
              },
              onColorTap: () => _showColorPicker(index),
              onRoleTap: () => _showRoleSelector(index),
            );
          }),
        ],
      ),
    );
  }
}

/// Widget for individual ink configuration card
class _InkConfigurationCard extends StatelessWidget {
  final int index;
  final CustomInkDefinition ink;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onCodeChanged;
  final VoidCallback onColorTap;
  final VoidCallback onRoleTap;

  const _InkConfigurationCard({
    required this.index,
    required this.ink,
    required this.onNameChanged,
    required this.onCodeChanged,
    required this.onColorTap,
    required this.onRoleTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Ink ${index + 1}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: ink.color,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onColorTap,
                      borderRadius: BorderRadius.circular(8),
                      child: const Icon(Icons.edit, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: ink.name,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g., 75°C Reactive',
                border: OutlineInputBorder(),
              ),
              onChanged: onNameChanged,
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: ink.code,
              decoration: const InputDecoration(
                labelText: 'Code (max 5 chars)',
                hintText: 'e.g., 75R',
                border: OutlineInputBorder(),
                counterText: '',
              ),
              maxLength: 5,
              onChanged: onCodeChanged,
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: onRoleTap,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
                child: Row(
                  children: [
                    Icon(_getRoleIcon(ink.role), size: 20),
                    const SizedBox(width: 12),
                    Text(_getRoleDisplayName(ink.role)),
                    const Spacer(),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getRoleIcon(InkRole role) {
    switch (role) {
      case InkRole.dataHigh:
        return Icons.thermostat;
      case InkRole.dataLow:
        return Icons.ac_unit;
      case InkRole.fake:
        return Icons.security;
      case InkRole.metadata:
        return Icons.label;
    }
  }

  String _getRoleDisplayName(InkRole role) {
    switch (role) {
      case InkRole.dataHigh:
        return 'Data High (75°C)';
      case InkRole.dataLow:
        return 'Data Low (55°C)';
      case InkRole.fake:
        return 'Protected/Fake';
      case InkRole.metadata:
        return 'Metadata/Marker';
    }
  }
}
