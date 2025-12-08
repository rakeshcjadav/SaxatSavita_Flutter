import 'package:flutter/material.dart';
import 'package:saxatsavita_flutter/services/reading_history_migration_service.dart';

/// Debug page to test migration with any user ID
/// This allows you to mimic another user's data on your device
class DebugMigrationWithUserIdPage extends StatefulWidget {
  const DebugMigrationWithUserIdPage({super.key});

  @override
  State<DebugMigrationWithUserIdPage> createState() =>
      _DebugMigrationWithUserIdPageState();
}

class _DebugMigrationWithUserIdPageState
    extends State<DebugMigrationWithUserIdPage> {
  final TextEditingController _userIdController = TextEditingController();
  final ReadingHistoryMigrationService _migrationService =
      ReadingHistoryMigrationService();

  bool _isLoading = false;
  String? _statusMessage;
  int? _legacyDataCount;
  Map<String, dynamic>? _migrationStatus;
  MigrationResult? _migrationResult;
  double _progress = 0.0;
  String _progressText = '';

  @override
  void dispose() {
    _userIdController.dispose();
    super.dispose();
  }

  Future<void> _checkUserData() async {
    final userId = _userIdController.text.trim();
    if (userId.isEmpty) {
      _showError('Please enter a user ID');
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = null;
      _legacyDataCount = null;
      _migrationStatus = null;
      _migrationResult = null;
    });

    try {
      // Check legacy data count
      final count = await _migrationService.debugGetLegacyDataCount(userId);

      // Get migration status
      final status = await _migrationService.debugGetMigrationStatus(userId);

      setState(() {
        _legacyDataCount = count;
        _migrationStatus = status;
        _statusMessage = 'User data loaded successfully';
      });
    } catch (e) {
      _showError('Error checking user data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _runMigration() async {
    final userId = _userIdController.text.trim();
    if (userId.isEmpty) {
      _showError('Please enter a user ID');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Migration'),
            content: Text(
              'This will migrate data for user:\n$userId\n\n'
              'Legacy entries: $_legacyDataCount\n\n'
              'Continue?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Migrate'),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
      _statusMessage = 'Starting migration...';
      _migrationResult = null;
      _progress = 0.0;
      _progressText = '0 / $_legacyDataCount';
    });

    try {
      final result = await _migrationService.debugMigrateSpecificUser(
        userId,
        onProgress: (current, total) {
          final progressValue = current / total;
          setState(() {
            _progress = progressValue;
            _progressText = '$current / $total';
            _statusMessage = 'Migrating: $current of $total entries...';
          });
        },
      );

      setState(() {
        _migrationResult = result;
        _statusMessage = result.message;
      });

      // Refresh data after migration
      await _checkUserData();
    } catch (e) {
      _showError('Migration failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    setState(() {
      _statusMessage = message;
      _isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Debug: Migrate User Data')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'How to Debug Migration Issues',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '1. Get the problematic user\'s Firebase UID\n'
                      '2. Paste it in the field below\n'
                      '3. Click "Check User Data" to see their legacy data\n'
                      '4. Click "Run Migration" to test migration on your device\n'
                      '5. Watch the logs in debug console for detailed progress',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // User ID Input
            TextField(
              controller: _userIdController,
              decoration: InputDecoration(
                labelText: 'User ID (Firebase UID)',
                hintText: 'Enter user ID to test migration',
                border: const OutlineInputBorder(),
                suffixIcon:
                    _userIdController.text.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _userIdController.clear();
                            setState(() {
                              _legacyDataCount = null;
                              _migrationStatus = null;
                              _migrationResult = null;
                            });
                          },
                        )
                        : null,
              ),
              onChanged: (value) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _checkUserData,
                    icon: const Icon(Icons.search),
                    label: const Text('Check User Data'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        (_isLoading || _legacyDataCount == null)
                            ? null
                            : _runMigration,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Run Migration'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Loading Indicator
            if (_isLoading) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              if (_progressText.isNotEmpty)
                Text(
                  _progressText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              const SizedBox(height: 16),
            ],

            // Status Message
            if (_statusMessage != null) ...[
              Card(
                color:
                    _migrationResult?.success == true
                        ? Colors.green.shade50
                        : _migrationResult?.success == false
                        ? Colors.red.shade50
                        : Colors.grey.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _statusMessage!,
                    style: TextStyle(
                      color:
                          _migrationResult?.success == true
                              ? Colors.green.shade700
                              : _migrationResult?.success == false
                              ? Colors.red.shade700
                              : Colors.black87,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Legacy Data Info
            if (_legacyDataCount != null) ...[
              _buildInfoCard('Legacy Data', [
                _InfoRow('Total Entries', '$_legacyDataCount'),
                if (_legacyDataCount! > 0)
                  _InfoRow('Status', 'Has legacy data to migrate'),
                if (_legacyDataCount == 0)
                  _InfoRow('Status', 'No legacy data found'),
              ]),
              const SizedBox(height: 16),
            ],

            // Migration Status
            if (_migrationStatus != null) ...[
              _buildInfoCard('Migration Status in Firebase', [
                if (_migrationStatus!['reading_history'] != null) ...[
                  _InfoRow(
                    'Status',
                    _migrationStatus!['reading_history']['status'] ?? 'N/A',
                  ),
                  if (_migrationStatus!['reading_history']['message'] != null)
                    _InfoRow(
                      'Message',
                      _migrationStatus!['reading_history']['message'],
                    ),
                  if (_migrationStatus!['reading_history']['migratedCount'] !=
                      null)
                    _InfoRow(
                      'Migrated Count',
                      '${_migrationStatus!['reading_history']['migratedCount']}',
                    ),
                ] else
                  const _InfoRow('Status', 'No migration record found'),
              ]),
              const SizedBox(height: 16),
            ],

            // Migration Result
            if (_migrationResult != null) ...[
              _buildInfoCard('Migration Result', [
                _InfoRow(
                  'Success',
                  _migrationResult!.success ? '✅ Yes' : '❌ No',
                ),
                _InfoRow('Migrated', '${_migrationResult!.migratedCount}'),
                _InfoRow('Skipped', '${_migrationResult!.skippedCount}'),
                _InfoRow('Errors', '${_migrationResult!.errorCount}'),
                if (_migrationResult!.errors.isNotEmpty) ...[
                  const Divider(),
                  const Text(
                    'Errors:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ..._migrationResult!.errors.map((error) => Text('• $error')),
                ],
              ]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }
}
