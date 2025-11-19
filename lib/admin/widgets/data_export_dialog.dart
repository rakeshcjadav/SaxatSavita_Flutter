import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saxatsavita_flutter/admin/models/admin_user_data.dart';
import 'package:saxatsavita_flutter/admin/services/admin_service.dart';

class DataExportDialog extends StatefulWidget {
  final List<AdminUserData> users;
  final AdminService adminService;

  const DataExportDialog({
    super.key,
    required this.users,
    required this.adminService,
  });

  @override
  State<DataExportDialog> createState() => _DataExportDialogState();
}

class _DataExportDialogState extends State<DataExportDialog> {
  bool _includePersonalData = false;
  bool _includeReadingHistory = true;
  bool _includeAppSettings = false;
  bool _includeDetailedStats = true;
  String _selectedFormat = 'JSON';
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Export Data',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Export summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Export Summary',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Users to export: ${widget.users.length}'),
                  Text(
                    'Total readings: ${widget.users.fold(0, (sum, user) => sum + user.totalReadings)}',
                  ),
                  Text(
                    'Total bookmarks: ${widget.users.fold(0, (sum, user) => sum + user.totalBookmarks)}',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Export options
            Text(
              'Export Options',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            CheckboxListTile(
              title: const Text('Include Personal Data'),
              subtitle: const Text('Email, display name, profile info'),
              value: _includePersonalData,
              onChanged: (value) {
                setState(() {
                  _includePersonalData = value ?? false;
                });
              },
            ),

            CheckboxListTile(
              title: const Text('Include Reading History'),
              subtitle: const Text('Detailed reading records and progress'),
              value: _includeReadingHistory,
              onChanged: (value) {
                setState(() {
                  _includeReadingHistory = value ?? false;
                });
              },
            ),

            CheckboxListTile(
              title: const Text('Include App Settings'),
              subtitle: const Text('User preferences and configurations'),
              value: _includeAppSettings,
              onChanged: (value) {
                setState(() {
                  _includeAppSettings = value ?? false;
                });
              },
            ),

            CheckboxListTile(
              title: const Text('Include Detailed Statistics'),
              subtitle: const Text('Calculated metrics and analytics'),
              value: _includeDetailedStats,
              onChanged: (value) {
                setState(() {
                  _includeDetailedStats = value ?? false;
                });
              },
            ),

            const SizedBox(height: 20),

            // Format selection
            Text(
              'Export Format',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('JSON'),
                    value: 'JSON',
                    groupValue: _selectedFormat,
                    onChanged: (value) {
                      setState(() {
                        _selectedFormat = value ?? 'JSON';
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('CSV'),
                    value: 'CSV',
                    groupValue: _selectedFormat,
                    onChanged: (value) {
                      setState(() {
                        _selectedFormat = value ?? 'JSON';
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isExporting ? null : _exportData,
                  child:
                      _isExporting
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text('Export'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportData() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final exportData = await _prepareExportData();
      String exportString;

      if (_selectedFormat == 'JSON') {
        exportString = const JsonEncoder.withIndent('  ').convert(exportData);
      } else {
        exportString = _convertToCSV(exportData);
      }

      // Copy to clipboard
      await Clipboard.setData(ClipboardData(text: exportString));

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Data exported to clipboard in $_selectedFormat format',
            ),
            action: SnackBarAction(
              label: 'View',
              onPressed: () => _showExportPreview(exportString),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>> _prepareExportData() async {
    final exportData = {
      'exportInfo': {
        'exportDate': DateTime.now().toIso8601String(),
        'totalUsers': widget.users.length,
        'includePersonalData': _includePersonalData,
        'includeReadingHistory': _includeReadingHistory,
        'includeAppSettings': _includeAppSettings,
        'includeDetailedStats': _includeDetailedStats,
        'format': _selectedFormat,
      },
      'users': <Map<String, dynamic>>[],
    };

    if (_includeDetailedStats) {
      try {
        final stats = await widget.adminService.getUserStats();
        exportData['statistics'] = stats;
      } catch (e) {
        debugPrint('Failed to get statistics: $e');
      }
    }

    final usersList = exportData['users'] as List<Map<String, dynamic>>;

    for (final user in widget.users) {
      final userData = <String, dynamic>{};

      // Always include basic identifiers
      userData['userId'] = user.userId;
      userData['totalReadings'] = user.totalReadings;
      userData['totalBookmarks'] = user.totalBookmarks;
      userData['createdAt'] = user.createdAt?.toIso8601String();
      userData['lastActivityDate'] = user.lastActivityDate?.toIso8601String();

      if (_includePersonalData) {
        userData['email'] = user.email;
        userData['displayName'] = user.displayName;
        userData['signInProvider'] = user.signInProvider;
        userData['userProfile'] = user.userProfile;
      }

      if (_includeReadingHistory) {
        userData['readingHistory'] = user.readingHistory;
        userData['bookUserInfo'] = user.bookUserInfo;
        userData['kiranUserInfo'] = user.kiranUserInfo;
        userData['readingPlans'] = user.readingPlans;
      }

      if (_includeAppSettings) {
        userData['appSettings'] = user.appSettings;
      }

      if (_includeDetailedStats) {
        userData['statistics'] = {
          'bookPartsRead': user.bookPartsRead,
          'bookPartsInProgress': user.bookPartsInProgress,
          'overallProgress': user.overallProgress,
          'streakDays': user.streakDays,
          'lastReadingDate': user.lastReadingDate?.toIso8601String(),
          'favoriteBookParts': user.favoriteBookParts,
        };
      }

      usersList.add(userData);
    }

    return exportData;
  }

  String _convertToCSV(Map<String, dynamic> data) {
    final buffer = StringBuffer();
    final users = data['users'] as List<Map<String, dynamic>>;

    if (users.isEmpty) {
      return 'No data to export';
    }

    // Create headers from all possible fields
    final headers = <String>{};
    for (final user in users) {
      _addCsvHeaders(user, headers);
    }

    // Write header row
    buffer.writeln(headers.join(','));

    // Write data rows
    for (final user in users) {
      final row = <String>[];
      for (final header in headers) {
        final value = _getCsvValue(user, header);
        row.add(_escapeCsvValue(value));
      }
      buffer.writeln(row.join(','));
    }

    return buffer.toString();
  }

  void _addCsvHeaders(
    Map<String, dynamic> data,
    Set<String> headers, [
    String prefix = '',
  ]) {
    for (final entry in data.entries) {
      final key = prefix.isEmpty ? entry.key : '${prefix}_${entry.key}';

      if (entry.value is Map<String, dynamic>) {
        _addCsvHeaders(entry.value as Map<String, dynamic>, headers, key);
      } else if (entry.value is List) {
        headers.add('${key}_count');
        // For lists, we'll just add a count field to keep CSV simple
      } else {
        headers.add(key);
      }
    }
  }

  String _getCsvValue(Map<String, dynamic> data, String path) {
    final parts = path.split('_');
    dynamic current = data;

    for (final part in parts) {
      if (current is Map<String, dynamic>) {
        current = current[part];
      } else {
        return '';
      }
    }

    if (current == null) return '';
    if (current is List) return current.length.toString();
    if (current is Map) return current.length.toString();
    return current.toString();
  }

  String _escapeCsvValue(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  void _showExportPreview(String exportString) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height * 0.8,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Export Preview ($_selectedFormat)',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.copy),
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: exportString),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Copied to clipboard'),
                                ),
                              );
                            },
                            tooltip: 'Copy to clipboard',
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: SingleChildScrollView(
                      child: SelectableText(
                        exportString,
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
