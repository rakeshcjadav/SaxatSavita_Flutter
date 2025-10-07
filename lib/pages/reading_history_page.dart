import 'package:flutter/material.dart';
import 'package:saxatsavita_flutter/components/appbar.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';
import 'package:saxatsavita_flutter/models/kiraninfo_model.dart';
import 'package:saxatsavita_flutter/models/reading_history_model.dart';
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
  List<String> _availableCategories = [];
  String? _selectedCategory;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReadingHistory();
  }

  Future<void> _loadReadingHistory() async {
    setState(() => _isLoading = true);

    try {
      // TODO: Load reading history from your data source
      // For now, I'll create some sample data to demonstrate the UI
      _allHistory = _generateSampleData();

      _availableCategories =
          _allHistory.map((h) => h.category).toSet().toList()..sort();

      _applyFilters();
    } catch (e) {
      // Handle error
      debugPrint('Error loading reading history: $e');
      _allHistory = [];
      _filteredHistory = [];
    }

    setState(() => _isLoading = false);
  }

  // TODO: Replace with actual data loading
  List<ReadingHistory> _generateSampleData() {
    return [
      ReadingHistory(
        category: 'Daily Reading',
        durationSeconds: 1820, // 30 minutes
        kiranIndex: 1,
        partNumber: 1,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      ReadingHistory(
        category: 'Daily Reading',
        durationSeconds: 34, // 30 minutes
        kiranIndex: 1,
        partNumber: 1,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      ReadingHistory(
        category: 'Daily Reading',
        durationSeconds: 3600, // 1 hour
        kiranIndex: 175,
        partNumber: 2,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      ReadingHistory(
        category: 'Morning Reading',
        durationSeconds: 17, // 15 minutes
        kiranIndex: 400,
        partNumber: 3,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
    ];
  }

  void _applyFilters() {
    _filteredHistory =
        _allHistory.where((history) {
          if (_selectedCategory != null &&
              history.category != _selectedCategory) {
            return false;
          }
          return true;
        }).toList();

    // Sort by date (newest first)
    _filteredHistory.sort((a, b) => b.createdAt.compareTo(a.createdAt));
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

    for (final history in _filteredHistory) {
      final key = history.formattedDate;
      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(history);
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
        title: AppLocalizations.of(context)!.readingHistoryTitle,
        actionItems: [],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                child: Column(
                  children: [
                    _buildSummarySection(),
                    Expanded(child: _buildHistoryList()),
                  ],
                ),
              ),
    );
  }

  Widget _buildSummarySection() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.totalReadingTime,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            _getTotalReadingTime(),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            '${_filteredHistory.length} ${AppLocalizations.of(context)!.readingSessions}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ],
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (index > 0) const SizedBox(height: 24.0),
            Text(
              dateKey,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12.0),
            ...historyList.map((history) => _buildHistoryCard(history)),
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
                    Bookservice().getPartTitle(history.partNumber),
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
                    '${history.createdAt.hour.toString().padLeft(2, '0')}:${history.createdAt.minute.toString().padLeft(2, '0')}',
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
