import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saxatsavita_flutter/admin/models/admin_user_data.dart';
import 'package:saxatsavita_flutter/admin/services/admin_service.dart';

class UserDetailDialog extends StatefulWidget {
  final String userId;
  final AdminService adminService;

  const UserDetailDialog({
    super.key,
    required this.userId,
    required this.adminService,
  });

  @override
  State<UserDetailDialog> createState() => _UserDetailDialogState();
}

class _UserDetailDialogState extends State<UserDetailDialog> {
  AdminUserData? _userData;
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final userData = await widget.adminService.getUserData(widget.userId);
      setState(() {
        _userData = userData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'User Details',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),

            // Content
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _error.isNotEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(height: 16),
                            Text(_error),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadUserData,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                      : _userData == null
                      ? const Center(child: Text('User not found'))
                      : _buildUserDetails(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserDetails() {
    final user = _userData!;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Basic Info Card
          _buildInfoCard(
            title: 'Basic Information',
            icon: Icons.person,
            children: [
              _buildInfoRow('User ID', user.userId),
              _buildInfoRow('Email', user.email),
              _buildInfoRow(
                'Display Name',
                user.displayName.isEmpty ? 'Not set' : user.displayName,
              ),
              _buildInfoRow('Sign-in Provider', user.signInProvider),
              _buildInfoRow('Created', _formatDateTime(user.createdAt)),
              _buildInfoRow(
                'Last Activity',
                _formatDateTime(user.lastActivityDate),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Statistics Card
          _buildInfoCard(
            title: 'Reading Statistics',
            icon: Icons.analytics,
            children: [
              _buildInfoRow('Total Readings', '${user.totalReadings}'),
              _buildInfoRow('Total Bookmarks', '${user.totalBookmarks}'),
              _buildInfoRow('Book Parts Read', '${user.bookPartsRead}'),
              _buildInfoRow('Parts In Progress', '${user.bookPartsInProgress}'),
              _buildInfoRow(
                'Overall Progress',
                '${(user.overallProgress * 100).toStringAsFixed(1)}%',
              ),
              _buildInfoRow('Reading Streak', '${user.streakDays} days'),
              _buildInfoRow(
                'Last Reading',
                _formatDateTime(user.lastReadingDate),
              ),
              if (user.favoriteBookParts.isNotEmpty)
                _buildInfoRow(
                  'Favorite Parts',
                  user.favoriteBookParts.join(', '),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Book Progress Card
          if (user.bookUserInfo.isNotEmpty)
            _buildInfoCard(
              title: 'Book Progress',
              icon: Icons.book,
              children:
                  user.bookUserInfo
                      .map((book) => _buildBookProgressRow(book))
                      .toList(),
            ),

          const SizedBox(height: 16),

          // App Settings Card
          if (user.appSettings.isNotEmpty)
            _buildInfoCard(
              title: 'App Settings',
              icon: Icons.settings,
              children:
                  user.appSettings.entries
                      .map(
                        (entry) => _buildInfoRow(
                          _formatSettingKey(entry.key),
                          _formatSettingValue(entry.value),
                        ),
                      )
                      .toList(),
            ),

          const SizedBox(height: 16),

          // User Profile Card
          if (user.userProfile.isNotEmpty)
            _buildInfoCard(
              title: 'User Profile',
              icon: Icons.account_circle,
              children:
                  user.userProfile.entries
                      .map(
                        (entry) => _buildInfoRow(
                          _formatSettingKey(entry.key),
                          _formatSettingValue(entry.value),
                        ),
                      )
                      .toList(),
            ),

          const SizedBox(height: 16),

          // Reading Plans Card
          if (user.readingPlans.isNotEmpty)
            _buildInfoCard(
              title: 'Reading Plans (${user.readingPlans.length})',
              icon: Icons.schedule,
              children:
                  user.readingPlans
                      .map((plan) => _buildReadingPlanRow(plan))
                      .toList(),
            ),

          const SizedBox(height: 16),

          // Recent Reading History Card
          if (user.readingHistory.isNotEmpty)
            _buildInfoCard(
              title:
                  'Recent Reading History (${user.readingHistory.length} total)',
              icon: Icons.history,
              children:
                  user.readingHistory
                      .take(10) // Show only last 10 readings
                      .map((reading) => _buildReadingHistoryRow(reading))
                      .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildBookProgressRow(Map<String, dynamic> book) {
    final partNumber = book['partNumber'] ?? 'Unknown';
    final currentKiran = book['currentKiranIndex'] ?? 0;
    final totalKirans = book['totalKirans'] ?? 1;
    final isCompleted = book['isCompleted'] == true;
    final progress = currentKiran / totalKirans;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Part $partNumber',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
              Text(
                isCompleted
                    ? 'Completed'
                    : '$currentKiran / $totalKirans (${(progress * 100).toStringAsFixed(1)}%)',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              isCompleted
                  ? Colors.green
                  : Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadingPlanRow(Map<String, dynamic> plan) {
    final name = plan['name'] ?? 'Unnamed Plan';
    final isActive = plan['isActive'] == true;
    final targetDate = plan['targetDate'];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            isActive ? Icons.play_arrow : Icons.pause,
            size: 16,
            color: isActive ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(name, style: Theme.of(context).textTheme.bodyMedium),
          ),
          if (targetDate != null)
            Text(
              _formatDateTime(_parseFirestoreDate(targetDate)),
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
    );
  }

  Widget _buildReadingHistoryRow(Map<String, dynamic> reading) {
    final partNumber = reading['partNumber'] ?? '';
    final kiranIndex = reading['kiranIndex'] ?? '';
    final dateRead = reading['dateRead'];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Part $partNumber, Kiran $kiranIndex',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            _formatDateTime(_parseFirestoreDate(dateRead)),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Never';
    return DateFormat('MMM dd, yyyy HH:mm').format(dateTime);
  }

  DateTime? _parseFirestoreDate(dynamic date) {
    if (date == null) return null;
    if (date is DateTime) return date;
    if (date.runtimeType.toString() == 'Timestamp') {
      return date.toDate();
    }
    return null;
  }

  String _formatSettingKey(String key) {
    // Convert camelCase to Title Case
    return key
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
        .replaceFirst(RegExp(r'^\s'), '')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  String _formatSettingValue(dynamic value) {
    if (value == null) return 'Not set';
    if (value is bool) return value ? 'Yes' : 'No';
    if (value is DateTime) return _formatDateTime(value);
    if (value is List) return value.join(', ');
    if (value is Map) return value.toString();
    return value.toString();
  }
}
