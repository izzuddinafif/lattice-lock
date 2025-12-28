import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/services/history_service.dart';
import '../logic/history_state.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  String _selectedAlgorithm = 'All';
  String _selectedMaterial = 'All';
  DateTimeRange? _dateRange;
  bool _hasLoadedInitially = false;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      print('🔄 [HISTORY SCREEN] initState() called - loading history');
    }
    // Add observer to detect when app resumes
    WidgetsBinding.instance.addObserver(this);
    // Load history when screen is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(historyProvider.notifier).loadHistory();
      _hasLoadedInitially = true;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (kDebugMode) {
      print('🔄 [HISTORY SCREEN] App lifecycle changed: $state');
    }
    // Reload history when app becomes visible again
    if (state == AppLifecycleState.resumed) {
      if (kDebugMode) {
        print('🔄 [HISTORY SCREEN] App resumed - reloading history');
      }
      ref.read(historyProvider.notifier).loadHistory();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload when navigating back to this screen
    if (_hasLoadedInitially) {
      if (kDebugMode) {
        print('🔄 [HISTORY SCREEN] didChangeDependencies - reloading history');
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(historyProvider.notifier).loadHistory();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(historyProvider);
    final notifier = ref.read(historyProvider.notifier);

    if (kDebugMode) {
      print('🎨 [HISTORY SCREEN] build() called - entries: ${historyState.entries.length}, filtered: ${historyState.filteredEntries.length}');
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'PATTERN HISTORY',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Theme.of(context).colorScheme.primary,
        actions: [
          IconButton(
            onPressed: () => _showFilterDialog(context, notifier),
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter History',
          ),
          IconButton(
            onPressed: () => _showStatistics(context),
            icon: const Icon(Icons.analytics),
            tooltip: 'Statistics',
          ),
        ],
      ),
      body: _buildBody(context, historyState, notifier),
    );
  }

  Widget _buildBody(BuildContext context, HistoryState historyState, HistoryNotifier notifier) {
    if (historyState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (historyState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading history: ${historyState.error}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => notifier.loadHistory(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return _buildResponsiveLayout(context, historyState.filteredEntries, notifier);
  }

  Widget _buildResponsiveLayout(BuildContext context, List<PatternHistoryEntry> entries, HistoryNotifier notifier) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1200;

        return Column(
          children: [
            // Search Bar
            Container(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
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
                  labelText: "Search History",
                  labelStyle: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w600),
                  hintText: "Search by batch code, algorithm, or material...",
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
                    child: Icon(Icons.search, color: Colors.blue.shade700),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            notifier.updateSearchQuery('');
                          },
                          icon: const Icon(Icons.clear),
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                ),
                style: const TextStyle(fontSize: 16),
                onChanged: (val) => notifier.updateSearchQuery(val),
              ),
            ),

            // Active Filters
            if (_hasActiveFilters())
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Wrap(
                  spacing: 8,
                  children: [
                    _buildFilterChip('Algorithm: $_selectedAlgorithm', () => _clearFilters(notifier)),
                    if (_selectedMaterial != 'All')
                      _buildFilterChip('Material: $_selectedMaterial', () => _clearFilters(notifier)),
                    if (_dateRange != null)
                      _buildFilterChip(
                        'Date: ${DateFormat('MMM d').format(_dateRange!.start)} - ${DateFormat('MMM d').format(_dateRange!.end)}',
                        () => _clearFilters(notifier),
                      ),
                  ],
                ),
              ),

            const SizedBox(height: 8),

            // History List
            Expanded(
              child: entries.isEmpty
                  ? _buildEmptyState(context)
                  : isDesktop
                      ? _buildDesktopLayout(context, entries, notifier)
                      : _buildMobileLayout(context, entries, notifier),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onDeleted) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: Colors.blue.withValues(alpha: 0.1),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onDeleted,
      deleteIconColor: Colors.blue.shade700,
    );
  }

  bool _hasActiveFilters() {
    return _selectedAlgorithm != 'All' ||
           _selectedMaterial != 'All' ||
           _dateRange != null ||
           _searchController.text.isNotEmpty;
  }

  void _clearFilters(HistoryNotifier notifier) {
    setState(() {
      _selectedAlgorithm = 'All';
      _selectedMaterial = 'All';
      _dateRange = null;
      _searchController.clear();
    });
    notifier.clearFilters();
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No pattern history found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Generate some patterns to see them here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, List<PatternHistoryEntry> entries, HistoryNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
        ),
        itemCount: entries.length,
        itemBuilder: (context, index) => _buildHistoryCard(context, entries[index], notifier, isDesktop: true),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, List<PatternHistoryEntry> entries, HistoryNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView.builder(
        itemCount: entries.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildHistoryCard(context, entries[index], notifier, isDesktop: false),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, PatternHistoryEntry entry, HistoryNotifier notifier, {required bool isDesktop}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showEntryDetails(context, entry),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.cyan.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.grid_view, size: 20, color: Colors.cyan),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.batchCode,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          DateFormat('MMM dd, yyyy HH:mm').format(entry.timestamp),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleMenuAction(value, entry, notifier),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(Icons.visibility),
                            SizedBox(width: 8),
                            Text('View Details'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'regenerate',
                        child: Row(
                          children: [
                            Icon(Icons.refresh),
                            SizedBox(width: 8),
                            Text('Regenerate PDF'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Details
              Row(
                children: [
                  _buildDetailChip('Algorithm', entry.algorithm, Icons.enhanced_encryption),
                  const SizedBox(width: 8),
                  _buildDetailChip('Material', entry.materialProfile, Icons.science),
                ],
              ),

              const SizedBox(height: 8),

              // Pattern preview
              Container(
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: entry.pattern.isNotEmpty
                    ? GridView.builder(
                        padding: const EdgeInsets.all(4),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 8,
                          crossAxisSpacing: 1,
                          mainAxisSpacing: 1,
                        ),
                        itemCount: entry.pattern.length.clamp(0, 64),
                        itemBuilder: (context, index) {
                          final row = entry.pattern[index ~/ 8];
                          final inkId = index < row.length ? row[index % 8] : 0;
                          return Container(
                            decoration: BoxDecoration(
                              color: _getPatternColor(inkId),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        },
                      )
                    : const Center(
                        child: Text('No pattern data'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailChip(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.blue.shade700),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                '$label: $value',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPatternColor(int inkId) {
    final colors = [
      Colors.red, Colors.blue, Colors.green, Colors.yellow,
      Colors.purple, Colors.orange, Colors.cyan, Colors.pink,
    ];
    return colors[inkId % colors.length].withValues(alpha: 0.7);
  }

  void _showFilterDialog(BuildContext context, HistoryNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter History'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Algorithm:'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedAlgorithm,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: ['All', 'chaos_logistic', 'chaos_tent', 'chaos_arnolds_cat']
                      .map((algo) => DropdownMenuItem(value: algo, child: Text(algo)))
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedAlgorithm = value!);
                  },
                ),
                const SizedBox(height: 16),
                const Text('Date Range:'),
                const SizedBox(height: 8),
                ListTile(
                  title: Text(_dateRange == null ? 'Select Date Range' :
                    '${DateFormat('MMM d').format(_dateRange!.start)} - ${DateFormat('MMM d').format(_dateRange!.end)}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final range = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now(),
                    );
                    if (range != null) {
                      setState(() => _dateRange = range);
                    }
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _applyFilters(notifier);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _applyFilters(HistoryNotifier notifier) {
    final filter = HistoryFilter(
      algorithm: _selectedAlgorithm == 'All' ? null : _selectedAlgorithm,
      materialProfile: _selectedMaterial == 'All' ? null : _selectedMaterial,
      startDate: _dateRange?.start,
      endDate: _dateRange?.end,
    );
    notifier.setFilter(filter);
  }

  void _showEntryDetails(BuildContext context, PatternHistoryEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(entry.batchCode),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Algorithm: ${entry.algorithm}'),
              Text('Material: ${entry.materialProfile}'),
              Text('Generated: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(entry.timestamp)}'),
              const SizedBox(height: 16),
              const Text('Pattern Preview:'),
              const SizedBox(height: 8),
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8,
                    crossAxisSpacing: 1,
                    mainAxisSpacing: 1,
                  ),
                  itemCount: entry.pattern.length.clamp(0, 64),
                  itemBuilder: (context, index) {
                    final row = entry.pattern[index ~/ 8];
                    final inkId = index < row.length ? row[index % 8] : 0;
                    return Container(
                      decoration: BoxDecoration(
                        color: _getPatternColor(inkId),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showStatistics(BuildContext context) {
    final statisticsAsync = ref.read(historyProvider.notifier).getStatistics();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('History Statistics'),
        content: FutureBuilder<Map<String, dynamic>>(
          future: statisticsAsync,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }

            final statistics = snapshot.data ?? {};
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Total Entries: ${statistics['totalEntries'] ?? 0}'),
                Text('Entries This Month: ${statistics['entriesThisMonth'] ?? 0}'),
                Text('Entries This Year: ${statistics['entriesThisYear'] ?? 0}'),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action, PatternHistoryEntry entry, HistoryNotifier notifier) {
    switch (action) {
      case 'view':
        _showEntryDetails(context, entry);
        break;
      case 'regenerate':
        // TODO: Implement PDF regeneration
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF regeneration coming soon')),
        );
        break;
      case 'delete':
        _showDeleteConfirmation(entry, notifier);
        break;
    }
  }

  void _showDeleteConfirmation(PatternHistoryEntry entry, HistoryNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: Text('Are you sure you want to delete "${entry.batchCode}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              notifier.deleteEntry(entry.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}