import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:saxatsavita_flutter/services/reading_history_migration_service.dart';
import 'package:saxatsavita_flutter/components/appbar.dart';

class MigrationPage extends StatefulWidget {
  const MigrationPage({super.key});

  @override
  State<MigrationPage> createState() => _MigrationPageState();
}

class _MigrationPageState extends State<MigrationPage> {
  final ReadingHistoryMigrationService _readingHistoryMigrationService =
      ReadingHistoryMigrationService();

  bool _isLoading = false;
  bool _hasReadingHistoryMigrated = false;

  // Reading History Migration
  MigrationPreview? _readingHistoryPreview;
  MigrationResult? _readingHistoryResult;

  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final preview = await _readingHistoryMigrationService.getMigrationPreview(
        user.uid,
      );
      setState(() {
        _readingHistoryPreview = preview;
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

  Future<void> _runMigration() async {
    if (_hasReadingHistoryMigrated) return;

    setState(() {
      _isLoading = true;
      _progress = 0.0;
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
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Migration failed: $e')));
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
        title: 'Reading History Migration',
        actionItems: [],
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
                      _progress > 0
                          ? 'Migrating... ${(_progress * 100).toInt()}%'
                          : 'Loading...',
                    ),
                    if (_progress > 0)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: LinearProgressIndicator(value: _progress),
                      ),
                  ],
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPreviewCard(),
                    const SizedBox(height: 16),
                    if (_readingHistoryResult != null) _buildResultCard(),
                    if (_readingHistoryResult != null)
                      const SizedBox(height: 16),
                    _buildActionCard(),
                  ],
                ),
              ),
    );
  }

  Widget _buildPreviewCard() {
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
                  'Migration Preview',
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
                  Text('No legacy data found to migrate'),
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

  Widget _buildResultCard() {
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
                  'Migration Result',
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
            if (_readingHistoryResult!.errors.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Errors:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ..._readingHistoryResult!.errors.map(
                (error) =>
                    Text('• $error', style: const TextStyle(color: Colors.red)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard() {
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
                Text('Actions', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 16),
            if (_readingHistoryPreview?.hasDataToMigrate == true &&
                !_hasReadingHistoryMigrated) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _runMigration,
                  child: const Text('Start Migration'),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This will migrate your legacy reading history to the current format. Duplicates will be skipped.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ] else if (_hasReadingHistoryMigrated) ...[
              const Row(
                children: [
                  Icon(Icons.check, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Migration completed!'),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _hasReadingHistoryMigrated = false;
                      _readingHistoryResult = null;
                    });
                    _loadPreview();
                  },
                  child: const Text('Refresh Preview'),
                ),
              ),
            ] else ...[
              const Row(
                children: [
                  Icon(Icons.info, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('No migration needed'),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _loadPreview,
                  child: const Text('Refresh Preview'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
