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

class _HistoryScreenState extends ConsumerState<HistoryScreen>
    with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  String _selectedAlgorithm = 'All';
  String _selectedMaterial = 'All';
  DateTimeRange? _dateRange;
  bool _hasLoadedInitially = false;
  DateTime? _lastReloadTime;

  // Mapping from algorithm keys to friendly names (must match encryption strategy names)
  static const Map<String, String> _algorithmNames = {
    'chaos_logistic': 'Chaos Logistic',
    'chaos_tent': 'Tent Map (Chaos)',
    'chaos_arnolds_cat': "Arnold's Cat Map",
  };

  // Reverse mapping for display
  String _getAlgorithmFriendlyName(String key) {
    return _algorithmNames[key] ?? key;
  }

  @override
  void initState() {
    super.initState();
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
    // Only reload when app is resumed and at least 1 second has passed since last reload
    if (state == AppLifecycleState.resumed) {
      final now = DateTime.now();
      if (_lastReloadTime == null ||
          now.difference(_lastReloadTime!).inSeconds >= 1) {
        _lastReloadTime = now;
        ref.read(historyProvider.notifier).loadHistory();
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload when navigating back to this screen, with debounce
    if (_hasLoadedInitially) {
      final now = DateTime.now();
      if (_lastReloadTime == null ||
          now.difference(_lastReloadTime!).inSeconds >= 1) {
        _lastReloadTime = now;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(historyProvider.notifier).loadHistory();
        });
      }
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

  Widget _buildBody(
    BuildContext context,
    HistoryState historyState,
    HistoryNotifier notifier,
  ) {
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
            Text(
              'Error loading history: ${historyState.error}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => notifier.loadHistory(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return _buildResponsiveLayout(
      context,
      historyState.filteredEntries,
      notifier,
    );
  }

  Widget _buildResponsiveLayout(
    BuildContext context,
    List<PatternHistoryEntry> entries,
    HistoryNotifier notifier,
  ) {
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
                    borderSide: BorderSide(
                      color: Colors.blue.shade300,
                      width: 2,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.blue.shade300,
                      width: 2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.blue.shade500,
                      width: 3,
                    ),
                  ),
                  labelText: "Search History",
                  labelStyle: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                  ),
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
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
                ),
                style: const TextStyle(fontSize: 16),
                onChanged: (val) => notifier.updateSearchQuery(val),
              ),
            ),

            // Active Filters
            if (_hasActiveFilters())
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Wrap(
                  spacing: 8,
                  children: [
                    if (_selectedAlgorithm != 'All')
                      _buildFilterChip(
                        'Algorithm: ${_getAlgorithmFriendlyName(_selectedAlgorithm)}',
                        () => _clearFilters(notifier),
                      ),
                    if (_selectedMaterial != 'All')
                      _buildFilterChip(
                        'Material: $_selectedMaterial',
                        () => _clearFilters(notifier),
                      ),
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
          Icon(Icons.history, size: 80, color: Colors.grey.shade400),
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
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    List<PatternHistoryEntry> entries,
    HistoryNotifier notifier,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.85, // Taller cards for full pattern visibility
        ),
        itemCount: entries.length,
        itemBuilder: (context, index) => _buildHistoryCard(
          context,
          entries[index],
          notifier,
          isDesktop: true,
        ),
      ),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    List<PatternHistoryEntry> entries,
    HistoryNotifier notifier,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView.builder(
        itemCount: entries.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildHistoryCard(
            context,
            entries[index],
            notifier,
            isDesktop: false,
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(
    BuildContext context,
    PatternHistoryEntry entry,
    HistoryNotifier notifier, {
    required bool isDesktop,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showEntryDetails(context, entry),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: isDesktop
              ? Column(
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
                          child: const Icon(
                            Icons.grid_view,
                            size: 20,
                            color: Colors.cyan,
                          ),
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
                                DateFormat(
                                  'MMM dd, yyyy HH:mm',
                                ).format(entry.timestamp),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) =>
                              _handleMenuAction(value, entry, notifier),
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
                                  Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      entry.algorithm,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      entry.materialProfile,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Pattern preview
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child:
                            entry.pattern.isNotEmpty &&
                                entry.pattern[0].isNotEmpty
                            ? GridView.builder(
                                padding: const EdgeInsets.all(4),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: _getGridSize(
                                        entry.pattern,
                                      ),
                                      crossAxisSpacing: 1,
                                      mainAxisSpacing: 1,
                                      childAspectRatio: 1.0,
                                    ),
                                itemCount:
                                    entry.pattern.length *
                                    entry.pattern[0].length,
                                itemBuilder: (context, index) {
                                  final row =
                                      entry.pattern[index ~/
                                          _getGridSize(entry.pattern)];
                                  final col =
                                      index % _getGridSize(entry.pattern);
                                  final inkId = row.length > col ? row[col] : 0;
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: _getPatternColor(inkId, entry),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.3,
                                        ),
                                        width: 0.5,
                                      ),
                                    ),
                                  );
                                },
                              )
                            : const Center(child: Text('No pattern data')),
                      ),
                    ),
                  ],
                )
              : Column(
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
                          child: const Icon(
                            Icons.grid_view,
                            size: 20,
                            color: Colors.cyan,
                          ),
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
                                DateFormat(
                                  'MMM dd, yyyy HH:mm',
                                ).format(entry.timestamp),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) =>
                              _handleMenuAction(value, entry, notifier),
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
                                  Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      entry.algorithm,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      entry.materialProfile,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Pattern preview (use fixed height for ListView compatibility)
                    Container(
                      height: 350, // Increased height for better visibility
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child:
                          entry.pattern.isNotEmpty &&
                              entry.pattern[0].isNotEmpty
                          ? GridView.builder(
                              padding: const EdgeInsets.all(4),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: _getGridSize(entry.pattern),
                                    crossAxisSpacing: 1,
                                    mainAxisSpacing: 1,
                                    childAspectRatio: 1.0,
                                  ),
                              itemCount:
                                  entry.pattern.length *
                                  entry.pattern[0].length,
                              itemBuilder: (context, index) {
                                final row =
                                    entry.pattern[index ~/
                                        _getGridSize(entry.pattern)];
                                final col = index % _getGridSize(entry.pattern);
                                final inkId = row.length > col ? row[col] : 0;
                                return Container(
                                  decoration: BoxDecoration(
                                    color: _getPatternColor(inkId, entry),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.3,
                                      ),
                                      width: 0.5,
                                    ),
                                  ),
                                );
                              },
                            )
                          : const Center(child: Text('No pattern data')),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  int _getGridSize(List<List<int>> pattern) {
    return pattern.isNotEmpty ? pattern.length : 8;
  }

  Color _getPatternColor(int inkId, PatternHistoryEntry entry) {
    // Try to get actual material colors from metadata
    if (entry.metadata.containsKey('materialColors')) {
      final materialColors =
          entry.metadata['materialColors'] as Map<dynamic, dynamic>?;
      if (materialColors != null && materialColors.containsKey(inkId)) {
        final rgb = materialColors[inkId] as Map<dynamic, dynamic>;
        final r = (rgb['r'] as num).toInt();
        final g = (rgb['g'] as num).toInt();
        final b = (rgb['b'] as num).toInt();
        return Color.fromARGB(255, r, g, b);
      }
    }

    // Fallback to hardcoded colors if material colors not available
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.cyan,
      Colors.pink,
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
                  items:
                      [
                            'All',
                            'chaos_logistic',
                            'chaos_tent',
                            'chaos_arnolds_cat',
                          ]
                          .map(
                            (algo) => DropdownMenuItem(
                              value: algo,
                              child: Text(_getAlgorithmFriendlyName(algo)),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    setState(() => _selectedAlgorithm = value!);
                  },
                ),
                const SizedBox(height: 16),
                const Text('Material Profile:'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedMaterial,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All')),
                    DropdownMenuItem(
                      value: 'Standard Set',
                      child: Text('Standard Set'),
                    ),
                    DropdownMenuItem(value: 'Custom', child: Text('Custom')),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedMaterial = value!);
                  },
                ),
                const SizedBox(height: 16),
                const Text('Date Range:'),
                const SizedBox(height: 8),
                ListTile(
                  title: Text(
                    _dateRange == null
                        ? 'Select Date Range'
                        : '${DateFormat('MMM d').format(_dateRange!.start)} - ${DateFormat('MMM d').format(_dateRange!.end)}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final range = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 365),
                      ),
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
      algorithm: _selectedAlgorithm == 'All'
          ? null
          : _getAlgorithmFriendlyName(_selectedAlgorithm),
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
        content: SizedBox(
          width: 500,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Algorithm: ${entry.algorithm}'),
              Text('Material: ${entry.materialProfile}'),
              Text(
                'Generated: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(entry.timestamp)}',
              ),
              const SizedBox(height: 16),
              const Text('Pattern Preview:'),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 500),
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        entry.pattern.isNotEmpty && entry.pattern[0].isNotEmpty
                        ? GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: _getGridSize(entry.pattern),
                                  crossAxisSpacing: 1,
                                  mainAxisSpacing: 1,
                                  childAspectRatio: 1.0,
                                ),
                            itemCount:
                                entry.pattern.length * entry.pattern[0].length,
                            itemBuilder: (context, index) {
                              final row =
                                  entry.pattern[index ~/
                                      _getGridSize(entry.pattern)];
                              final col = index % _getGridSize(entry.pattern);
                              final inkId = row.length > col ? row[col] : 0;
                              return Container(
                                decoration: BoxDecoration(
                                  color: _getPatternColor(inkId, entry),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    width: 0.5,
                                  ),
                                ),
                              );
                            },
                          )
                        : const Center(child: Text('No pattern data')),
                  ),
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
                Text(
                  'Entries This Month: ${statistics['entriesThisMonth'] ?? 0}',
                ),
                Text(
                  'Entries This Year: ${statistics['entriesThisYear'] ?? 0}',
                ),
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

  void _handleMenuAction(
    String action,
    PatternHistoryEntry entry,
    HistoryNotifier notifier,
  ) {
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

  void _showDeleteConfirmation(
    PatternHistoryEntry entry,
    HistoryNotifier notifier,
  ) {
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
