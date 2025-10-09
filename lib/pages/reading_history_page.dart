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

class ReadingHistoryPage extends StatefulWidget {
  const ReadingHistoryPage({super.key});

  @override
  State<ReadingHistoryPage> createState() => _ReadingHistoryPageState();
}

class _ReadingHistoryPageState extends State<ReadingHistoryPage> {
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

  @override
  void initState() {
    super.initState();
    _loadReadingHistory();
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
          if (_filteredHistory.isNotEmpty)
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
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                child: Column(
                  children: [
                    _buildSummarySection(),
                    _buildFilterSection(),
                    Expanded(child: _buildHistoryList()),
                  ],
                ),
              ),
    );
  }

  Widget _buildSummarySection() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            AppLocalizations.of(context)!.totalReadingTime,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            _getTotalReadingTime(),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            '${_filteredHistory.length} ${AppLocalizations.of(context)!.readingSessions}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.filterByDate,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall!.copyWith(fontSize: 18),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.0),
        onTap: () => _navigateToKiran(history.kiranIndex, history.partNumber),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    Bookservice().getPartTitle(context, history.partNumber),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    history.readableDuration,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              Text(
                _getKiranTitle(history),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12.0),
              Row(
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
            ],
          ),
        ),
      ),
    );
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
