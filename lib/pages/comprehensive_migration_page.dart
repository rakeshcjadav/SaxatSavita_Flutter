import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:saxatsavita_flutter/services/reading_history_migration_service.dart';
import 'package:saxatsavita_flutter/services/kiranuser_info_migration_service.dart';
import 'package:saxatsavita_flutter/components/appbar.dart';

class ComprehensiveMigrationPage extends StatefulWidget {
  const ComprehensiveMigrationPage({super.key});

  @override
  State<ComprehensiveMigrationPage> createState() =>
      _ComprehensiveMigrationPageState();
}

class _ComprehensiveMigrationPageState extends State<ComprehensiveMigrationPage>
    with SingleTickerProviderStateMixin {
  final ReadingHistoryMigrationService _readingHistoryMigrationService =
      ReadingHistoryMigrationService();
  final KiranUserInfoMigrationService _kiranUserInfoMigrationService =
      KiranUserInfoMigrationService();

  late TabController _tabController;

  bool _isLoading = false;

  // Reading History Migration
  bool _hasReadingHistoryMigrated = false;
  MigrationPreview? _readingHistoryPreview;
  MigrationResult? _readingHistoryResult;

  // KiranUserInfo Migration
  bool _hasKiranUserInfoMigrated = false;
  KiranUserInfoMigrationPreview? _kiranUserInfoPreview;
  KiranUserInfoMigrationResult? _kiranUserInfoResult;

  double _progress = 0.0;
  String _currentMigration = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPreviews();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPreviews() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Load both previews in parallel
      final futures = await Future.wait([
        _readingHistoryMigrationService.getMigrationPreview(user.uid),
        _kiranUserInfoMigrationService.getKiranUserInfoMigrationPreview(
          user.uid,
        ),
      ]);

      setState(() {
        _readingHistoryPreview = futures[0] as MigrationPreview;
        _kiranUserInfoPreview = futures[1] as KiranUserInfoMigrationPreview;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading preview: $e')));
      }
    }
  }

  Future<void> _runReadingHistoryMigration() async {
    if (_hasReadingHistoryMigrated) return;

    setState(() {
      _isLoading = true;
      _progress = 0.0;
      _currentMigration = 'Reading History';
    });

    try {
      final result = await _readingHistoryMigrationService
          .autoMigrateCurrentUser(
            onProgress: (current, total) {
              setState(() {
                _progress = current / total;
              });
            },
          );

      setState(() {
        _readingHistoryResult = result;
        _hasReadingHistoryMigrated = true;
        _isLoading = false;
        _currentMigration = '';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _currentMigration = '';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reading History migration failed: $e')),
        );
      }
    }
  }

  Future<void> _runKiranUserInfoMigration() async {
    if (_hasKiranUserInfoMigrated) return;

    setState(() {
      _isLoading = true;
      _progress = 0.0;
      _currentMigration = 'Kiran User Info';
    });

    try {
      final result = await _kiranUserInfoMigrationService
          .autoMigrateCurrentUserKiranUserInfo(
            onProgress: (current, total) {
              setState(() {
                _progress = current / total;
              });
            },
          );

      setState(() {
        _kiranUserInfoResult = result;
        _hasKiranUserInfoMigrated = true;
        _isLoading = false;
        _currentMigration = '';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _currentMigration = '';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('KiranUserInfo migration failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: buildAppBar(context, title: 'Data Migration', actionItems: []),
        body: const Center(child: Text('Please log in to migrate your data')),
      );
    }

    return Scaffold(
      appBar: buildAppBar(
        context,
        title: 'Legacy Data Migration',
        actionItems: [],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Reading History', icon: Icon(Icons.history)),
            Tab(text: 'Kiran Progress', icon: Icon(Icons.bookmark)),
          ],
        ),
      ),
      body:
          _isLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      _currentMigration.isEmpty
                          ? 'Loading...'
                          : 'Migrating $_currentMigration... ${(_progress * 100).toInt()}%',
                    ),
                    if (_progress > 0)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: LinearProgressIndicator(value: _progress),
                      ),
                  ],
                ),
              )
              : Column(
                children: [
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildReadingHistoryTab(),
                        _buildKiranUserInfoTab(),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildReadingHistoryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildReadingHistoryPreviewCard(),
          const SizedBox(height: 16),
          if (_readingHistoryResult != null) _buildReadingHistoryResultCard(),
          if (_readingHistoryResult != null) const SizedBox(height: 16),
          _buildReadingHistoryActionCard(),
        ],
      ),
    );
  }

  Widget _buildKiranUserInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildKiranUserInfoPreviewCard(),
          const SizedBox(height: 16),
          if (_kiranUserInfoResult != null) _buildKiranUserInfoResultCard(),
          if (_kiranUserInfoResult != null) const SizedBox(height: 16),
          _buildKiranUserInfoActionCard(),
        ],
      ),
    );
  }

  // Reading History Cards
  Widget _buildReadingHistoryPreviewCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.preview,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Reading History Preview',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_readingHistoryPreview == null)
              const Text('Loading preview...')
            else if (_readingHistoryPreview!.totalLegacyEntries == 0)
              const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text('No legacy reading history found'),
                ],
              )
            else ...[
              _buildPreviewItem(
                'Total Legacy Entries',
                '${_readingHistoryPreview!.totalLegacyEntries}',
              ),
              _buildPreviewItem(
                'New Entries to Migrate',
                '${_readingHistoryPreview!.newEntriesToMigrate}',
              ),
              _buildPreviewItem(
                'Duplicates Found',
                '${_readingHistoryPreview!.duplicatesFound}',
              ),
              _buildPreviewItem(
                'Total Reading Time',
                _readingHistoryPreview!.totalReadingTime,
              ),
              _buildPreviewItem(
                'Unique Kirans Read',
                '${_readingHistoryPreview!.uniqueKiransRead}',
              ),
              if (_readingHistoryPreview!.dateRange != null)
                _buildPreviewItem(
                  'Date Range',
                  _readingHistoryPreview!.dateRange!.formattedRange,
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReadingHistoryResultCard() {
    return Card(
      color:
          _readingHistoryResult!.success
              ? Colors.green.shade50
              : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _readingHistoryResult!.success
                      ? Icons.check_circle
                      : Icons.error,
                  color:
                      _readingHistoryResult!.success
                          ? Colors.green
                          : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Reading History Migration Result',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(_readingHistoryResult!.message),
            const SizedBox(height: 8),
            _buildPreviewItem(
              'Migrated',
              '${_readingHistoryResult!.migratedCount}',
            ),
            _buildPreviewItem(
              'Skipped',
              '${_readingHistoryResult!.skippedCount}',
            ),
            _buildPreviewItem('Errors', '${_readingHistoryResult!.errorCount}'),
          ],
        ),
      ),
    );
  }

  Widget _buildReadingHistoryActionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.play_arrow,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Reading History Actions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_readingHistoryPreview?.hasDataToMigrate == true &&
                !_hasReadingHistoryMigrated) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _runReadingHistoryMigration,
                  child: const Text('Migrate Reading History'),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This will migrate your legacy reading history data.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ] else if (_hasReadingHistoryMigrated) ...[
              const Row(
                children: [
                  Icon(Icons.check, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Reading History migration completed!'),
                ],
              ),
            ] else ...[
              const Row(
                children: [
                  Icon(Icons.info, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('No reading history migration needed'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // KiranUserInfo Cards
  Widget _buildKiranUserInfoPreviewCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.preview,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Kiran Progress Preview',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_kiranUserInfoPreview == null)
              const Text('Loading preview...')
            else if (_kiranUserInfoPreview!.totalLegacyEntries == 0)
              const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text('No legacy Kiran progress found'),
                ],
              )
            else ...[
              _buildPreviewItem(
                'Total Kirans',
                '${_kiranUserInfoPreview!.totalLegacyEntries}',
              ),
              _buildPreviewItem(
                'New Entries to Migrate',
                '${_kiranUserInfoPreview!.newEntriesToMigrate}',
              ),
              _buildPreviewItem(
                'Favourite Kirans',
                '${_kiranUserInfoPreview!.favouriteKirans}',
              ),
              _buildPreviewItem(
                'Completed Kirans',
                '${_kiranUserInfoPreview!.completedKirans}',
              ),
              _buildPreviewItem(
                'Kirans with Notes',
                '${_kiranUserInfoPreview!.kiransWithNotes}',
              ),
              _buildPreviewItem(
                'Average Progress',
                '${_kiranUserInfoPreview!.averageProgress}%',
              ),
              const SizedBox(height: 8),
              const Text(
                'Entries by Part:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ..._kiranUserInfoPreview!.entriesByPart.entries.map(
                (entry) => _buildPreviewItem(
                  'Part ${entry.key}',
                  '${entry.value} Kirans',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildKiranUserInfoResultCard() {
    return Card(
      color:
          _kiranUserInfoResult!.success
              ? Colors.green.shade50
              : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _kiranUserInfoResult!.success
                      ? Icons.check_circle
                      : Icons.error,
                  color:
                      _kiranUserInfoResult!.success ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Kiran Progress Migration Result',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(_kiranUserInfoResult!.message),
            const SizedBox(height: 8),
            _buildPreviewItem(
              'Migrated',
              '${_kiranUserInfoResult!.migratedCount}',
            ),
            _buildPreviewItem(
              'Skipped',
              '${_kiranUserInfoResult!.skippedCount}',
            ),
            _buildPreviewItem('Errors', '${_kiranUserInfoResult!.errorCount}'),
          ],
        ),
      ),
    );
  }

  Widget _buildKiranUserInfoActionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.play_arrow,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Kiran Progress Actions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_kiranUserInfoPreview?.hasDataToMigrate == true &&
                !_hasKiranUserInfoMigrated) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _runKiranUserInfoMigration,
                  child: const Text('Migrate Kiran Progress'),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This will migrate your Kiran progress, favourites, and notes.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ] else if (_hasKiranUserInfoMigrated) ...[
              const Row(
                children: [
                  Icon(Icons.check, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Kiran progress migration completed!'),
                ],
              ),
            ] else ...[
              const Row(
                children: [
                  Icon(Icons.info, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('No Kiran progress migration needed'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Helper method
  Widget _buildPreviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
