import 'package:flutter/material.dart';
import 'package:saxatsavita_flutter/components/appbar.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';
import 'package:saxatsavita_flutter/models/kiraninfo_model.dart';
import 'package:saxatsavita_flutter/models/reading_history_model.dart';
import 'package:saxatsavita_flutter/services/reading_history_service.dart';
import 'package:saxatsavita_flutter/services/bookservice.dart';
import 'package:saxatsavita_flutter/services/kiranlistservice.dart';
import 'package:saxatsavita_flutter/services/kiranuser_service.dart';
import 'package:saxatsavita_flutter/pages/kiranreadpage.dart';
import 'package:saxatsavita_flutter/services/utils.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class ReadingHistoryPage extends StatefulWidget {
  const ReadingHistoryPage({super.key});

  @override
  State<ReadingHistoryPage> createState() => _ReadingHistoryPageState();
}

class _ReadingHistoryPageState extends State<ReadingHistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final KiranListService _kiranListService = KiranListService();

  List<ReadingHistory> _allHistory = [];
  List<ReadingHistory> _filteredHistory = [];
  String? _selectedCategory;
  bool _isLoading = true;

  // Track expanded state for each date group
  final Map<String, bool> _expandedSections = {};

  // Date filtering
  int? _selectedYear;
  int? _selectedMonth;
  List<int> _availableYears = [];
  List<int> _availableMonths = [];

  // Chart selection
  int _selectedChartTab = 0;

  List<String> get _chartTabs => [
    AppLocalizations.of(context)!.dailyChart,
    AppLocalizations.of(context)!.weeklyChart,
    AppLocalizations.of(context)!.partsChart,
    AppLocalizations.of(context)!.durationChart,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadReadingHistoryFromFirebaseAndStorage();
  }

  /// Load reading history from Firebase first, then from local storage
  Future<void> _loadReadingHistoryFromFirebaseAndStorage() async {
    if (!ReadingHistoryService().hasLoadedReadingHistory) {
      try {
        // Load reading history from Firebase (on-demand)
        await Utils.loadReadingHistoryFromFirebase();
        debugPrint('Reading history loaded from Firebase on-demand');
      } catch (e) {
        debugPrint('Error loading reading history from Firebase: $e');
      }
    }

    // Load from local storage (which now has Firebase data if available)
    await _loadReadingHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReadingHistory() async {
    setState(() => _isLoading = true);

    try {
      // Load reading history from SharedPreferences
      _allHistory = await _loadReadingHistoryFromStorage();

      /*
      // If no real data exists, add some sample data for demonstration
      if (_allHistory.isEmpty) {
        _allHistory = _generateSampleData();
      }*/

      // Extract available years and months
      _extractAvailableDates();

      _applyFilters();
    } catch (e) {
      // Handle error
      debugPrint('Error loading reading history: $e');
      _allHistory = [];
      _filteredHistory = [];
    }

    setState(() => _isLoading = false);
  }

  // Load actual reading history from SharedPreferences
  Future<List<ReadingHistory>> _loadReadingHistoryFromStorage() async {
    try {
      final history = await ReadingHistoryService.loadReadingHistory();

      // Debug: Print date information for timezone troubleshooting
      if (history.isNotEmpty) {
        debugPrint('📅 Loading ${history.length} history items');
        for (int i = 0; i < history.length && i < 3; i++) {
          final item = history[i];
          debugPrint(
            '📅 Item $i: createdAt=${item.createdAt}, formattedDate="${item.formattedDate}"',
          );
        }

        // Check for grouping
        final grouped = <String, int>{};
        for (final item in history) {
          final key = item.formattedDate;
          grouped[key] = (grouped[key] ?? 0) + 1;
        }
        debugPrint('📅 Grouped by date: $grouped');
      }

      return history;
    } catch (e) {
      debugPrint('Error loading reading history: $e');
      return [];
    }
  }

  void _extractAvailableDates() {
    final years = <int>{};
    final months = <int>{};

    for (final history in _allHistory) {
      years.add(history.createdAt.year);
      months.add(history.createdAt.month);
    }

    _availableYears =
        years.toList()..sort((a, b) => b.compareTo(a)); // Newest first
    _availableMonths = months.toList()..sort();
  }

  void _applyFilters() {
    _filteredHistory =
        _allHistory.where((history) {
          // Category filter
          if (_selectedCategory != null &&
              history.category != _selectedCategory) {
            return false;
          }

          // Year filter
          if (_selectedYear != null &&
              history.createdAt.year != _selectedYear) {
            return false;
          }

          // Month filter
          if (_selectedMonth != null &&
              history.createdAt.month != _selectedMonth) {
            return false;
          }

          return true;
        }).toList();

    // Sort by date (newest first)
    _filteredHistory.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Initialize expanded states for new date groups
    final dateKeys = _filteredHistory.map((h) => h.formattedDate).toSet();
    for (final key in dateKeys) {
      _expandedSections.putIfAbsent(key, () => true); // Default to expanded
    }
  }

  String _getTotalReadingTime() {
    final totalSeconds = _filteredHistory.fold<int>(
      0,
      (sum, history) => sum + history.durationSeconds,
    );

    final duration = Duration(seconds: totalSeconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  Map<String, List<ReadingHistory>> _groupHistoryByDate() {
    final Map<String, List<ReadingHistory>> grouped = {};

    // Sort history by date (newest first)
    final sortedHistory = List<ReadingHistory>.from(_filteredHistory)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    for (final history in sortedHistory) {
      final key = history.formattedDate;
      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(history);
    }

    // Sort each group by time (newest first within each day)
    for (final key in grouped.keys) {
      grouped[key]!.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return grouped;
  }

  Future<void> _navigateToKiran(int kiranIndex, int partNumber) async {
    await _kiranListService.loadPart('saxatsavita', 'part$partNumber');
    final kiranList = _kiranListService.getKiranListFromPartNumber(partNumber);

    if (kiranList != null && mounted) {
      final kiranInfo = kiranList.list.firstWhere(
        (k) => k.index == kiranIndex,
        orElse: () => kiranList.list.first,
      );

      final kiranUserInfo = KiranUserService().getKiranUserInfo(kiranIndex);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => KiranReadPage(
                kiranInfo: kiranInfo,
                partNumber: 'part$partNumber',
                kiranUserInfo: kiranUserInfo,
              ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(
        context,
        title: AppLocalizations.of(context)!.reading_history,
        actionItems: [ActionOptions.settings],
        extraActions: [
          if (_filteredHistory.isNotEmpty && _tabController.index == 0)
            IconButton(
              icon: Icon(
                _areAllExpanded() ? Icons.unfold_less : Icons.unfold_more,
              ),
              onPressed: _toggleAllSections,
              tooltip:
                  _areAllExpanded()
                      ? AppLocalizations.of(context)!.collapseAll
                      : AppLocalizations.of(context)!.expandAll,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.history),
              text: AppLocalizations.of(context)!.reading,
            ),
            Tab(
              icon: const Icon(Icons.analytics),
              text: AppLocalizations.of(context)!.analytics,
            ),
          ],
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                child: Column(
                  children: [
                    _buildSummarySection(),
                    _buildFilterSection(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [_buildHistoryTab(), _buildAnalyticsTab()],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildSummarySection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.history,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 8.0),
              Text(
                _getTotalReadingTime(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Icon(
                Icons.import_contacts,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 8.0),
              Text(
                '${_filteredHistory.length} ${AppLocalizations.of(context)!.readingSessions}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.filterByDate,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (_selectedYear != null || _selectedMonth != null) ...[
                const SizedBox(height: 12.0),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.2),
                    ),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Row(
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedYear = null;
                            _selectedMonth = null;
                            _applyFilters();
                          });
                        },
                        icon: const Icon(Icons.clear),
                        label: Text(
                          AppLocalizations.of(context)!.clearFilters,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall!.copyWith(fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12.0),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _selectedYear,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.year,
                    border: const OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 8.0,
                    ),
                    labelStyle: Theme.of(
                      context,
                    ).textTheme.bodyMedium!.copyWith(fontSize: 18),
                  ),
                  items: [
                    DropdownMenuItem<int>(
                      value: null,
                      child: Text(
                        AppLocalizations.of(context)!.allYears,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium!.copyWith(fontSize: 18),
                      ),
                    ),
                    ..._availableYears.map(
                      (year) => DropdownMenuItem<int>(
                        value: year,
                        child: Text(
                          year.toString(),
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium!.copyWith(fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedYear = value;
                      _applyFilters();
                    });
                  },
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _selectedMonth,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.month,
                    border: const OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 8.0,
                    ),
                    labelStyle: Theme.of(
                      context,
                    ).textTheme.bodyMedium!.copyWith(fontSize: 18),
                  ),
                  items: [
                    DropdownMenuItem<int>(
                      value: null,
                      child: Text(
                        AppLocalizations.of(context)!.allMonths,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium!.copyWith(fontSize: 18),
                      ),
                    ),
                    ..._availableMonths.map(
                      (month) => DropdownMenuItem<int>(
                        value: month,
                        child: Text(
                          _getMonthName(month),
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium!.copyWith(fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedMonth = value;
                      _applyFilters();
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return Column(children: [Expanded(child: _buildHistoryList())]);
  }

  Widget _buildAnalyticsTab() {
    if (_filteredHistory.isEmpty) {
      return _buildEmptyAnalyticsState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          _buildChartTabs(),
          const SizedBox(height: 8),
          _buildSelectedChart(),
        ],
      ),
    );
  }

  Widget _buildEmptyAnalyticsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 80.0,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 24.0),
            Text(
              AppLocalizations.of(context)!.noAnalyticsAvailable,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12.0),
            Text(
              AppLocalizations.of(context)!.startReadingForAnalytics,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    if (_filteredHistory.isEmpty) {
      return _buildEmptyState();
    }

    final groupedHistory = _groupHistoryByDate();

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: groupedHistory.length,
      itemBuilder: (context, index) {
        final dateKey = groupedHistory.keys.elementAt(index);
        final historyList = groupedHistory[dateKey]!;
        final isExpanded = _expandedSections[dateKey] ?? true;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (index > 0) const SizedBox(height: 24.0),
            InkWell(
              borderRadius: BorderRadius.circular(8.0),
              onTap: () {
                setState(() {
                  _expandedSections[dateKey] = !isExpanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 4.0,
                ),
                child: Row(
                  children: [
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8.0),
                    Text(
                      dateKey,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 2.0,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Text(
                        '${historyList.length}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                children: [
                  const SizedBox(height: 12.0),
                  ...historyList.map((history) => _buildHistoryCard(history)),
                ],
              ),
              crossFadeState:
                  isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHistoryCard(ReadingHistory history) {
    final partColor = Utils.getPartColor(history.partNumber, context);
    final accentColor = Utils.getPartAccentColor(history.partNumber, context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      color: partColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: BorderSide(color: accentColor.withOpacity(0.3), width: 1.0),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8.0),
        onTap: () => _navigateToKiran(history.kiranIndex, history.partNumber),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.2),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8.0),
                  topRight: Radius.circular(8.0),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: accentColor.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            Bookservice().getPartTitle(
                              context,
                              history.partNumber,
                            ),
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              color: accentColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    history.readableDuration,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  PopupMenuButton(
                    icon: Icon(Icons.more_vert),
                    itemBuilder:
                        (context) => [
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete,
                                  size: 18,
                                  color: Colors.red.shade300,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.deleteReadingHistory,
                                  style: TextStyle(color: Colors.red.shade300),
                                ),
                              ],
                            ),
                          ),
                        ],
                    onSelected: (value) {
                      switch (value) {
                        case 'delete':
                          _showDeleteConfirmation(history);
                          break;
                      }
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                top: 16.0,
                bottom: 16.0,
              ),
              child: Text(
                _getKiranTitle(history),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                bottom: 16.0,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16.0,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4.0),
                  Text(
                    AppLocalizations.of(
                      context,
                    )!.time_format(history.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16.0,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmation(ReadingHistory history) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.deleteReadingHistory),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context)!.confirmDeleteReadingHistory),
              const SizedBox(height: 12.0),
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Bookservice().getPartTitle(context, history.partNumber),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _getKiranTitle(history),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '${AppLocalizations.of(context)!.duration}: ${history.readableDuration}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      AppLocalizations.of(
                        context,
                      )!.last_read(history.createdAt, history.createdAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              child: Text(AppLocalizations.of(context)!.delete),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      await _deleteReadingHistory(history);
    }
  }

  Future<void> _deleteReadingHistory(ReadingHistory history) async {
    try {
      final success = await ReadingHistoryService.deleteReadingHistory(history);
      if (success && mounted) {
        // Remove from local lists and refresh UI
        setState(() {
          _allHistory.remove(history);
          _filteredHistory.remove(history);
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.readingHistoryDeleted),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      } else if (mounted) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorDeletingHistory),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.error}: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  // Chart Data Models
  Widget _buildChartTabs() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text(
              AppLocalizations.of(context)!.analytics,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children:
                          _chartTabs.asMap().entries.map((entry) {
                            final index = entry.key;
                            final title = entry.value;
                            final isSelected = _selectedChartTab == index;

                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: FilterChip(
                                label: Text(title),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _selectedChartTab = index;
                                    });
                                  }
                                },
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedChart() {
    switch (_selectedChartTab) {
      case 0:
        return _buildDailyReadingChart();
      case 1:
        return _buildWeeklyReadingChart();
      case 2:
        return _buildPartsDistributionChart();
      case 3:
        return _buildDurationAnalysisChart();
      default:
        return _buildDailyReadingChart();
    }
  }

  Widget _buildDailyReadingChart() {
    final dailyData = _getDailyReadingData();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.dailyReadingMinutes,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Column(
              children: [
                Text(
                  AppLocalizations.of(context)!.dailyChartDescription,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timeline,
                        size: 12,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Latest ← • → 30 days back',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Scrollbar(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  height: 200,
                  width: dailyData.length < 7 ? 300 : dailyData.length * 50.0,
                  child: LineChart(
                    LineChartData(
                      // Define chart boundaries to prevent overshooting
                      minX: 0,
                      maxX: (dailyData.length - 1).toDouble(),
                      minY: 0,
                      maxY:
                          dailyData.isEmpty
                              ? 1
                              : dailyData
                                      .map((e) => e.minutes)
                                      .reduce((a, b) => a > b ? a : b) *
                                  1.1,

                      // Clip data to prevent overshooting
                      clipData: FlClipData.all(),

                      gridData: const FlGridData(show: true),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            interval:
                                null, // Let fl_chart auto-calculate intervals
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${value.toInt()}${AppLocalizations.of(context)!.chartMinutesLabel.substring(0, 2)}',
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize:
                                40, // Increased to accommodate longer labels
                            interval:
                                1, // Always check every point, but conditionally show labels
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index >= 0 && index < dailyData.length) {
                                final date = dailyData[index].date;
                                final hasData = dailyData[index].minutes > 0;

                                // Always show most recent date with data and Today/Yesterday
                                final isMostRecentWithData = _isMostRecentDate(
                                  date,
                                  dailyData,
                                );
                                if (isMostRecentWithData ||
                                    _isToday(date) ||
                                    _isYesterday(date)) {
                                  final label =
                                      isMostRecentWithData && !_isToday(date)
                                          ? _getMostRecentDateLabel(
                                            date,
                                            hasData,
                                          )
                                          : _getIntuitiveDateLabel(date);
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      label,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 9,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                }

                                // For other dates, show selectively based on chart density
                                final shouldShow =
                                    dailyData.length > 20
                                        ? index % 7 ==
                                            0 // Show every 7th for very crowded
                                        : dailyData.length > 10
                                        ? index % 3 ==
                                            0 // Show every 3rd for moderately crowded
                                        : true; // Show all for sparse charts

                                // Always show first (Today) and last (30 days ago) positions
                                if (shouldShow ||
                                    index == 0 ||
                                    index == dailyData.length - 1) {
                                  final label = _getIntuitiveDateLabel(date);
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      label,
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.7),
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                  );
                                }
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.outline.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots:
                              dailyData.asMap().entries.map((entry) {
                                return FlSpot(
                                  entry.key.toDouble(),
                                  entry.value.minutes,
                                );
                              }).toList(),
                          isCurved: true,
                          curveSmoothness:
                              0.3, // Control curve smoothness to prevent overshooting
                          color: Theme.of(context).colorScheme.primary,
                          barWidth: 3,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              // Make "Today" dot more prominent (now at index 0 - left side)
                              final isToday = index == 0;
                              return FlDotCirclePainter(
                                radius: isToday ? 6 : 4,
                                color:
                                    isToday
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.primary
                                            .withValues(alpha: 0.8),
                                strokeWidth: isToday ? 3 : 2,
                                strokeColor:
                                    Theme.of(context).colorScheme.surface,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.1),
                          ),
                          // Prevent line from going outside chart bounds
                          preventCurveOverShooting: true,
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
    );
  }

  Widget _buildWeeklyReadingChart() {
    final weeklyData = _getWeeklyReadingData();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.weeklyReadingHours,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Column(
              children: [
                Text(
                  AppLocalizations.of(context)!.weeklyChartDescription,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_view_week,
                        size: 12,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Latest ← • → 12 weeks back',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  // Define chart boundaries
                  minY: 0,
                  maxY:
                      weeklyData.isEmpty
                          ? 1
                          : weeklyData
                                  .map((e) => e.hours)
                                  .reduce((a, b) => a > b ? a : b) *
                              1.2,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final isMostRecent = _isMostRecentWeek(
                          groupIndex,
                          weeklyData,
                        );
                        final weekLabel =
                            isMostRecent
                                ? 'Latest'
                                : 'Week ${weeklyData[groupIndex].weekNumber}';
                        return BarTooltipItem(
                          '$weekLabel: ${weeklyData[groupIndex].hours.toStringAsFixed(1)} ${AppLocalizations.of(context)!.chartHoursLabel}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: null, // Let fl_chart auto-calculate intervals
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}${AppLocalizations.of(context)!.chartHoursLabel.substring(0, 1)}',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40, // Increased for better labels
                        interval: 1, // Check every bar
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < weeklyData.length) {
                            final isMostRecent = _isMostRecentWeek(
                              index,
                              weeklyData,
                            );
                            final hasData = weeklyData[index].hours > 0;
                            final label = _getMostRecentWeekLabel(
                              weeklyData[index].weekNumber,
                              isMostRecent && hasData,
                            );

                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                label,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 9,
                                  color:
                                      isMostRecent && hasData
                                          ? Theme.of(
                                            context,
                                          ).colorScheme.primary
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.7),
                                  fontWeight:
                                      isMostRecent && hasData
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  barGroups:
                      weeklyData.asMap().entries.map((entry) {
                        final isMostRecent = _isMostRecentWeek(
                          entry.key,
                          weeklyData,
                        );
                        final hasData = entry.value.hours > 0;
                        return BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: entry.value.hours,
                              color:
                                  isMostRecent && hasData
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.primary
                                          .withValues(alpha: 0.8),
                              width:
                                  isMostRecent && hasData
                                      ? 24
                                      : 20, // Make most recent week with data slightly wider
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartsDistributionChart() {
    final partsData = _getPartsDistributionData();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.readingDistributionByParts,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.partsChartDescription,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: PieChart(
                      PieChartData(
                        sections:
                            partsData.asMap().entries.map((entry) {
                              final index = entry.key;
                              final data = entry.value;
                              final colors = [
                                Utils.getPartAccentColor(
                                  1,
                                  context,
                                  forceColorfulStyle: true,
                                ),
                                Utils.getPartAccentColor(
                                  2,
                                  context,
                                  forceColorfulStyle: true,
                                ),
                                Utils.getPartAccentColor(
                                  3,
                                  context,
                                  forceColorfulStyle: true,
                                ),
                                Utils.getPartAccentColor(
                                  4,
                                  context,
                                  forceColorfulStyle: true,
                                ),
                                Utils.getPartAccentColor(
                                  5,
                                  context,
                                  forceColorfulStyle: true,
                                ),
                              ];

                              return PieChartSectionData(
                                value: data.percentage,
                                title: '${data.percentage.toStringAsFixed(1)}%',
                                color: colors[index % colors.length],
                                radius: 60,
                                titleStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              );
                            }).toList(),
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:
                          partsData.asMap().entries.map((entry) {
                            final index = entry.key;
                            final data = entry.value;
                            final colors = [
                              Utils.getPartAccentColor(
                                1,
                                context,
                                forceColorfulStyle: true,
                              ),
                              Utils.getPartAccentColor(
                                2,
                                context,
                                forceColorfulStyle: true,
                              ),
                              Utils.getPartAccentColor(
                                3,
                                context,
                                forceColorfulStyle: true,
                              ),
                              Utils.getPartAccentColor(
                                4,
                                context,
                                forceColorfulStyle: true,
                              ),
                              Utils.getPartAccentColor(
                                5,
                                context,
                                forceColorfulStyle: true,
                              ),
                            ];

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 2.0,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: colors[index % colors.length],
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Part ${data.partNumber}',
                                      style: const TextStyle(fontSize: 11),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationAnalysisChart() {
    final durationData = _getDurationAnalysisData();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.readingSessionDurationAnalysis,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.durationChartDescription,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY:
                      durationData.isEmpty
                          ? 1
                          : durationData
                                  .map((e) => e.count.toDouble())
                                  .reduce((a, b) => a > b ? a : b) *
                              1.2,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${durationData[groupIndex].count} ${AppLocalizations.of(context)!.chartSessionsLabel}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < durationData.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                durationData[index].range,
                                style: const TextStyle(fontSize: 9),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  barGroups:
                      durationData.asMap().entries.map((entry) {
                        return BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: entry.value.count.toDouble(),
                              color: Theme.of(context).colorScheme.secondary,
                              width: 20,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Data Models for Charts
  List<DailyReadingData> _getDailyReadingData() {
    final Map<DateTime, double> dailyMinutes = {};

    // Accumulate reading minutes by date
    for (final history in _filteredHistory) {
      final date = DateTime(
        history.createdAt.year,
        history.createdAt.month,
        history.createdAt.day,
      );
      dailyMinutes[date] =
          (dailyMinutes[date] ?? 0) + (history.durationSeconds / 60);
    }

    // Find the most recent day with actual reading data
    final today = DateTime.now();
    DateTime? mostRecentDate;

    if (dailyMinutes.isNotEmpty) {
      // Get the most recent date from actual reading history
      mostRecentDate = dailyMinutes.keys.reduce((a, b) => a.isAfter(b) ? a : b);
    }

    // Use most recent reading date or today if no data exists
    final startDate = mostRecentDate ?? today;
    final normalizedStartDate = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );

    final List<DailyReadingData> result = [];

    for (int i = 0; i < 30; i++) {
      final date = normalizedStartDate.subtract(
        Duration(days: i),
      ); // Start from most recent and go backwards
      final minutes = dailyMinutes[date] ?? 0.0;
      result.add(DailyReadingData(date, minutes));
    }

    // Debug: Uncomment to verify the progression
    // debugPrint('Chart progression check:');
    // debugPrint(
    //   'Index 0 (left): ${result.first.date} - ${_getIntuitiveDateLabel(result.first.date)}',
    // );
    // debugPrint(
    //   'Index ${result.length - 1} (right): ${result.last.date} - ${_getIntuitiveDateLabel(result.last.date)}',
    // );

    return result;
  }

  List<WeeklyReadingData> _getWeeklyReadingData() {
    final Map<int, double> weeklyHours = {};

    // Accumulate reading hours by week number
    for (final history in _filteredHistory) {
      final weekNumber = _getWeekNumber(history.createdAt);
      weeklyHours[weekNumber] =
          (weeklyHours[weekNumber] ?? 0) + (history.durationSeconds / 3600);
    }

    // Find the most recent week with actual reading data
    int? mostRecentWeekNumber;
    if (weeklyHours.isNotEmpty) {
      mostRecentWeekNumber = weeklyHours.keys.reduce((a, b) => a > b ? a : b);
    }

    // Use most recent week with data or current week if no data exists
    final currentWeekNumber = _getWeekNumber(DateTime.now());
    final startWeekNumber = mostRecentWeekNumber ?? currentWeekNumber;

    final List<WeeklyReadingData> result = [];

    for (int i = 0; i < 12; i++) {
      // Calculate week number by going backwards from start week
      final weekNumber = startWeekNumber - i;
      final hours = weeklyHours[weekNumber] ?? 0.0;
      result.add(WeeklyReadingData(weekNumber, hours));
    }

    // Debug: Uncomment to verify the weekly progression
    // debugPrint('Weekly chart progression check:');
    // debugPrint('Index 0 (left): Week ${result.first.weekNumber} - This week');
    // debugPrint('Index ${result.length - 1} (right): Week ${result.last.weekNumber} - 12 weeks ago');

    return result;
  }

  List<PartDistributionData> _getPartsDistributionData() {
    final Map<int, int> partCounts = {};

    for (final history in _filteredHistory) {
      partCounts[history.partNumber] =
          (partCounts[history.partNumber] ?? 0) + 1;
    }

    final totalSessions = _filteredHistory.length;

    return partCounts.entries.map((entry) {
        final percentage = (entry.value / totalSessions) * 100;
        return PartDistributionData(entry.key, percentage);
      }).toList()
      ..sort((a, b) => a.partNumber.compareTo(b.partNumber));
  }

  List<DurationAnalysisData> _getDurationAnalysisData() {
    final Map<String, int> durationRanges = {
      '0-5m': 0,
      '5-15m': 0,
      '15-30m': 0,
      '30-60m': 0,
      '60m+': 0,
    };

    for (final history in _filteredHistory) {
      final minutes = history.durationSeconds / 60;

      if (minutes <= 5) {
        durationRanges['0-5m'] = durationRanges['0-5m']! + 1;
      } else if (minutes <= 15) {
        durationRanges['5-15m'] = durationRanges['5-15m']! + 1;
      } else if (minutes <= 30) {
        durationRanges['15-30m'] = durationRanges['15-30m']! + 1;
      } else if (minutes <= 60) {
        durationRanges['30-60m'] = durationRanges['30-60m']! + 1;
      } else {
        durationRanges['60m+'] = durationRanges['60m+']! + 1;
      }
    }

    return durationRanges.entries
        .map((entry) => DurationAnalysisData(entry.key, entry.value))
        .toList();
  }

  int _getWeekNumber(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    final daysDifference = date.difference(startOfYear).inDays;
    return (daysDifference / 7).ceil();
  }

  String _getKiranTitle(ReadingHistory history) {
    final KiranInfo kiranInfo = KiranListService().getKiranInfo(
      history.partNumber,
      history.kiranIndex,
    );
    return '${kiranInfo.number} ${kiranInfo.title}';
    //final kiranUserInfo = KiranListService().getKiranList(history.partNumber).list. (history.kiranIndex);
    //return kiranUserInfo?.title ?? 'Kiran ${history.kiranIndex}';
  }

  bool _areAllExpanded() {
    if (_expandedSections.isEmpty) return true;
    return _expandedSections.values.every((expanded) => expanded);
  }

  void _toggleAllSections() {
    setState(() {
      final shouldExpand = !_areAllExpanded();
      for (final key in _expandedSections.keys) {
        _expandedSections[key] = shouldExpand;
      }
    });
  }

  String _getMonthName(int month) {
    final localizations = AppLocalizations.of(context)!;

    switch (month) {
      case 1:
        return localizations.january;
      case 2:
        return localizations.february;
      case 3:
        return localizations.march;
      case 4:
        return localizations.april;
      case 5:
        return localizations.may;
      case 6:
        return localizations.june;
      case 7:
        return localizations.july;
      case 8:
        return localizations.august;
      case 9:
        return localizations.september;
      case 10:
        return localizations.october;
      case 11:
        return localizations.november;
      case 12:
        return localizations.december;
      default:
        return month.toString();
    }
  }

  // Helper methods for intuitive date labels
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  String _getIntuitiveDateLabel(DateTime date) {
    if (_isToday(date)) {
      return AppLocalizations.of(context)!.today;
    } else if (_isYesterday(date)) {
      return AppLocalizations.of(context)!.yesterday;
    } else {
      final now = DateTime.now();
      final difference = now.difference(date).inDays;

      if (difference <= 7) {
        // Show day of week for last 7 days
        return DateFormat('EEE').format(date); // Mon, Tue, etc.
      } else if (difference <= 30) {
        // Show short date for last 30 days
        return DateFormat('dd/MM').format(date);
      } else {
        // Show month/year for older dates
        return DateFormat('MM/yy').format(date);
      }
    }
  }

  // Get context-aware label for the most recent data
  String _getMostRecentDateLabel(DateTime date, bool hasData) {
    if (!hasData) {
      return _getIntuitiveDateLabel(date);
    }

    if (_isToday(date)) {
      return 'Latest (${AppLocalizations.of(context)!.today})';
    } else if (_isYesterday(date)) {
      return 'Latest (${AppLocalizations.of(context)!.yesterday})';
    } else {
      final now = DateTime.now();
      final difference = now.difference(date).inDays;

      if (difference <= 7) {
        return 'Latest (${DateFormat('EEE').format(date)})';
      } else {
        return 'Latest (${DateFormat('dd/MM').format(date)})';
      }
    }
  }

  bool _isMostRecentDate(DateTime date, List<DailyReadingData> dailyData) {
    if (dailyData.isEmpty) return false;
    return dailyData.first.date.isAtSameMomentAs(date) &&
        dailyData.first.minutes > 0;
  }

  bool _isMostRecentWeek(int weekNumber, List<WeeklyReadingData> weeklyData) {
    if (weeklyData.isEmpty) return false;
    return weeklyData.first.weekNumber == weekNumber &&
        weeklyData.first.hours > 0;
  }

  String _getMostRecentWeekLabel(int weekNumber, bool hasData) {
    final currentWeekNumber = _getWeekNumber(DateTime.now());

    if (!hasData) {
      return weekNumber == currentWeekNumber ? 'This\nweek' : 'W$weekNumber';
    }

    if (weekNumber == currentWeekNumber) {
      return 'Latest\n(This week)';
    } else if (weekNumber == currentWeekNumber - 1) {
      return 'Latest\n(Last week)';
    } else {
      return 'Latest\n(W$weekNumber)';
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 80.0,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 24.0),
            Text(
              AppLocalizations.of(context)!.noReadingHistory,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12.0),
            Text(
              AppLocalizations.of(context)!.startReadingMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Chart Data Model Classes
class DailyReadingData {
  final DateTime date;
  final double minutes;

  DailyReadingData(this.date, this.minutes);
}

class WeeklyReadingData {
  final int weekNumber;
  final double hours;

  WeeklyReadingData(this.weekNumber, this.hours);
}

class PartDistributionData {
  final int partNumber;
  final double percentage;

  PartDistributionData(this.partNumber, this.percentage);
}

class DurationAnalysisData {
  final String range;
  final int count;

  DurationAnalysisData(this.range, this.count);
}
