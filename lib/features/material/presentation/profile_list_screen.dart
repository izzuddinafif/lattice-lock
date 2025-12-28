import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/custom_ink_profile.dart';
import '../providers/material_profile_provider.dart';
import 'ink_configuration_screen.dart';

/// Screen for managing custom material profiles
class ProfileListScreen extends ConsumerWidget {
  const ProfileListScreen({super.key});

  Future<void> _navigateToConfiguration(
    BuildContext context,
    WidgetRef ref,
    String? profileId,
  ) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => InkConfigurationScreen(profileId: profileId),
      ),
    );

    // Refresh after returning from configuration screen
    if (context.mounted && result == true) {
      ref.read(materialProfileProvider.notifier).refresh();
    }
  }

  Future<void> _deleteProfile(
    BuildContext context,
    WidgetRef ref,
    CustomMaterialProfile profile,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Profile'),
        content: Text(
          'Are you sure you want to delete "${profile.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(materialProfileProvider.notifier).deleteProfile(profile.id);
    }
  }

  Future<void> _duplicateProfile(
    BuildContext context,
    WidgetRef ref,
    CustomMaterialProfile profile,
  ) async {
    final controller = TextEditingController(text: '${profile.name} (Copy)');

    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Duplicate Profile'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'New Profile Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Duplicate'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (name != null && name.isNotEmpty && context.mounted) {
      try {
        await ref.read(materialProfileProvider.notifier).duplicateProfile(
              profile.id,
              name,
            );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Profile "$name" created')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to duplicate profile: $e')),
          );
        }
      }
    }
  }

  Future<void> _setActiveProfile(
    BuildContext context,
    WidgetRef ref,
    CustomMaterialProfile profile,
  ) async {
    await ref.read(materialProfileProvider.notifier).setActiveProfile(profile.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${profile.name}" is now active')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(materialProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Material Profiles'),
        automaticallyImplyLeading: false,
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? _buildError(context, state.error!, ref)
              : state.profiles.isEmpty
                  ? _buildEmpty(context)
                  : _buildProfileList(context, state.profiles, ref),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToConfiguration(context, ref, null),
        icon: const Icon(Icons.add),
        label: const Text('New Profile'),
      ),
    );
  }

  Widget _buildError(BuildContext context, String error, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => ref.read(materialProfileProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.palette_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No custom profiles yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first material profile to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileList(
    BuildContext context,
    List<CustomMaterialProfile> profiles,
    WidgetRef ref,
  ) {
    return RefreshIndicator(
      onRefresh: () => ref.read(materialProfileProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: profiles.length,
        itemBuilder: (context, index) {
          final profile = profiles[index];
          return _ProfileCard(
            profile: profile,
            onEdit: () => _navigateToConfiguration(context, ref, profile.id),
            onDelete: () => _deleteProfile(context, ref, profile),
            onDuplicate: () => _duplicateProfile(context, ref, profile),
            onSetActive: () => _setActiveProfile(context, ref, profile),
          );
        },
      ),
    );
  }
}

/// Widget for displaying a single profile card
class _ProfileCard extends ConsumerWidget {
  final CustomMaterialProfile profile;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;
  final VoidCallback onSetActive;

  const _ProfileCard({
    required this.profile,
    required this.onEdit,
    required this.onDelete,
    required this.onDuplicate,
    required this.onSetActive,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = profile.isActive;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isActive ? 4 : 2,
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'ACTIVE',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'INACTIVE',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      profile.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  if (profile.id == 'standard')
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'STANDARD',
                        style: TextStyle(
                          color: Colors.orange.shade900,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.palette,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${profile.inks.length} inks',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Modified ${_formatDate(profile.modifiedAt)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Ink colors preview
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: profile.inks.take(10).map((ink) {
                  return Tooltip(
                    message: '${ink.name} (${ink.code})',
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: ink.color,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              // Action buttons
              Row(
                children: [
                  if (!isActive && profile.id != 'standard')
                    TextButton.icon(
                      onPressed: onSetActive,
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Set Active'),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  const Spacer(),
                  if (profile.id != 'standard')
                    IconButton(
                      onPressed: onDuplicate,
                      icon: const Icon(Icons.copy),
                      tooltip: 'Duplicate',
                    ),
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit),
                    tooltip: 'Edit',
                  ),
                  if (profile.id != 'standard')
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete),
                      tooltip: 'Delete',
                      style: IconButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else {
      return '${(difference.inDays / 30).floor()} months ago';
    }
  }
}
