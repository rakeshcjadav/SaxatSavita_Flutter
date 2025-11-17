import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:saxatsavita_flutter/admin/widgets/user_detail_dialog.dart';
import 'package:saxatsavita_flutter/admin/widgets/data_export_dialog.dart';
import 'package:saxatsavita_flutter/admin/models/admin_user_data.dart';
import 'package:saxatsavita_flutter/admin/services/admin_service.dart';

class AdminPanelPage extends StatefulWidget {
  const AdminPanelPage({super.key});

  @override
  State<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage> {
  final AdminService _adminService = AdminService();
  final TextEditingController _searchController = TextEditingController();

  List<AdminUserData> _allUsers = [];
  List<AdminUserData> _filteredUsers = [];
  bool _isLoading = true;
  String _error = '';
  String _sortBy = 'email'; // email, lastActivity, createdAt, totalReadings
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
  }

  Future<void> _checkAdminAccess() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Not authenticated');
      }

      // Check if user has admin privileges
      final isAdmin = await _adminService.isUserAdmin(user.email ?? '');
      if (!isAdmin) {
        throw Exception('Access denied - Admin privileges required');
      }

      await _loadUsers();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUsers() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final users = await _adminService.getAllUsers();
      setState(() {
        _allUsers = users;
        _filteredUsers = List.from(users);
        _isLoading = false;
      });

      _sortUsers();
    } catch (e) {
      setState(() {
        _error = 'Error loading users: $e';
        _isLoading = false;
      });
    }
  }

  void _filterUsers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = List.from(_allUsers);
      } else {
        _filteredUsers =
            _allUsers.where((user) {
              return user.email.toLowerCase().contains(query.toLowerCase()) ||
                  user.displayName.toLowerCase().contains(
                    query.toLowerCase(),
                  ) ||
                  user.userId.toLowerCase().contains(query.toLowerCase());
            }).toList();
      }
    });
    _sortUsers();
  }

  void _sortUsers() {
    setState(() {
      _filteredUsers.sort((a, b) {
        dynamic aValue, bValue;

        switch (_sortBy) {
          case 'email':
            aValue = a.email;
            bValue = b.email;
            break;
          case 'lastActivity':
            aValue = a.lastActivityDate;
            bValue = b.lastActivityDate;
            break;
          case 'createdAt':
            aValue = a.createdAt;
            bValue = b.createdAt;
            break;
          case 'totalReadings':
            aValue = a.totalReadings;
            bValue = b.totalReadings;
            break;
          default:
            aValue = a.email;
            bValue = b.email;
        }

        if (aValue == null && bValue == null) return 0;
        if (aValue == null) return _sortAscending ? -1 : 1;
        if (bValue == null) return _sortAscending ? 1 : -1;

        int comparison = aValue.compareTo(bValue);
        return _sortAscending ? comparison : -comparison;
      });
    });
  }

  void _changeSortCriteria(String newSortBy) {
    setState(() {
      if (_sortBy == newSortBy) {
        _sortAscending = !_sortAscending;
      } else {
        _sortBy = newSortBy;
        _sortAscending = true;
      }
    });
    _sortUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saxat Savita - Admin Panel'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadUsers),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _showExportDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Stats Bar
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by email, name, or user ID...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon:
                        _searchController.text.isNotEmpty
                            ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _filterUsers('');
                              },
                            )
                            : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  onChanged: _filterUsers,
                ),

                const SizedBox(height: 12),

                // Stats Row
                if (!_isLoading)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard('Total Users', '${_allUsers.length}'),
                      _buildStatCard(
                        'Active Today',
                        '${_getActiveUsersCount(1)}',
                      ),
                      _buildStatCard(
                        'Active This Week',
                        '${_getActiveUsersCount(7)}',
                      ),
                      _buildStatCard(
                        'Total Readings',
                        '${_getTotalReadings()}',
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Users List
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
                          Text(
                            _error,
                            style: Theme.of(context).textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadUsers,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                    : _buildUsersTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(title, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersTable() {
    if (_filteredUsers.isEmpty) {
      return const Center(child: Text('No users found'));
    }

    return Column(
      children: [
        // Table headers info
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Showing ${_filteredUsers.length} users',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (_filteredUsers.length > 10)
                Text(
                  'Scroll to see more',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        // Scrollable table
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                sortColumnIndex: _getSortColumnIndex(),
                sortAscending: _sortAscending,
                columnSpacing: 24.0,
                horizontalMargin: 12.0,
                columns: [
                  DataColumn(
                    label: const Text('Email'),
                    onSort:
                        (columnIndex, ascending) =>
                            _changeSortCriteria('email'),
                  ),
                  DataColumn(
                    label: const Text('Display Name'),
                    onSort:
                        (columnIndex, ascending) =>
                            _changeSortCriteria('displayName'),
                  ),
                  DataColumn(
                    label: const Text('Created'),
                    onSort:
                        (columnIndex, ascending) =>
                            _changeSortCriteria('createdAt'),
                  ),
                  DataColumn(
                    label: const Text('Last Activity'),
                    onSort:
                        (columnIndex, ascending) =>
                            _changeSortCriteria('lastActivity'),
                  ),
                  DataColumn(
                    label: const Text('Readings'),
                    numeric: true,
                    onSort:
                        (columnIndex, ascending) =>
                            _changeSortCriteria('totalReadings'),
                  ),
                  DataColumn(label: const Text('Provider')),
                  const DataColumn(label: Text('Actions')),
                ],
                rows:
                    _filteredUsers.map((user) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(user.email, overflow: TextOverflow.ellipsis),
                            onTap: () => _showUserDetail(user),
                          ),
                          DataCell(
                            Text(
                              user.displayName.isEmpty
                                  ? 'N/A'
                                  : user.displayName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DataCell(Text(_formatDate(user.createdAt))),
                          DataCell(Text(_formatDate(user.lastActivityDate))),
                          DataCell(Text('${user.totalReadings}')),
                          DataCell(Text(user.signInProvider)),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.visibility, size: 18),
                                  onPressed: () => _showUserDetail(user),
                                  tooltip: 'View Details',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.download, size: 18),
                                  onPressed: () => _exportUserData(user),
                                  tooltip: 'Export User Data',
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  int _getSortColumnIndex() {
    switch (_sortBy) {
      case 'email':
        return 0;
      case 'displayName':
        return 1;
      case 'createdAt':
        return 2;
      case 'lastActivity':
        return 3;
      case 'totalReadings':
        return 4;
      default:
        return 0;
    }
  }

  int _getActiveUsersCount(int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return _allUsers.where((user) {
      return user.lastActivityDate != null &&
          user.lastActivityDate!.isAfter(cutoff);
    }).length;
  }

  int _getTotalReadings() {
    return _allUsers.fold(0, (sum, user) => sum + user.totalReadings);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('MMM dd, yyyy').format(date);
  }

  void _showUserDetail(AdminUserData user) {
    showDialog(
      context: context,
      builder:
          (context) => UserDetailDialog(
            userId: user.userId,
            adminService: _adminService,
          ),
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => DataExportDialog(
            users: _filteredUsers,
            adminService: _adminService,
          ),
    );
  }

  void _exportUserData(AdminUserData user) {
    // TODO: Implement individual user data export
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exporting data for ${user.email}...'),
        action: SnackBarAction(
          label: 'View',
          onPressed: () => _showUserDetail(user),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
