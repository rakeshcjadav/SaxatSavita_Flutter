import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:saxatsavita_flutter/components/appbar.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';
import 'package:saxatsavita_flutter/models/kiranuserinfo_model.dart';
import 'package:saxatsavita_flutter/models/kiraninfo_model.dart';
import 'package:saxatsavita_flutter/pages/kiranreadpage.dart';
import 'package:saxatsavita_flutter/pages/note_editor_page.dart';
import 'package:saxatsavita_flutter/services/bookservice.dart';
import 'package:saxatsavita_flutter/services/kiranlistservice.dart';
import 'package:saxatsavita_flutter/services/kiranuser_service.dart';
import 'package:saxatsavita_flutter/services/utils.dart';

class NoteItem {
  final KiranUserInfo kiranUserInfo;
  final KiranInfo kiranInfo;
  final int partNumber;
  final String noteContent;
  final String plainTextPreview;
  final DateTime lastModified;

  NoteItem({
    required this.kiranUserInfo,
    required this.kiranInfo,
    required this.partNumber,
    required this.noteContent,
    required this.plainTextPreview,
    required this.lastModified,
  });
}

// Sort options
enum SortOption { dateModified, partNumber, noteLength }

class NoteListPage extends StatefulWidget {
  const NoteListPage({super.key});

  @override
  State<NoteListPage> createState() => _NoteListPageState();
}

class _NoteListPageState extends State<NoteListPage> {
  final TextEditingController _searchController = TextEditingController();
  final KiranListService _kiranListService = KiranListService();

  List<NoteItem> _allNotes = [];
  List<NoteItem> _filteredNotes = [];
  bool _isLoading = true;
  String _searchQuery = '';

  // Filter states
  final Set<int> _selectedParts = {1, 2, 3, 4, 5};
  bool _showFilters = false;

  SortOption _currentSort = SortOption.dateModified;
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadAllNotes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim().toLowerCase();
      _applyFiltersAndSort();
    });
  }

  Future<void> _loadAllNotes() async {
    setState(() => _isLoading = true);

    try {
      final allNotes = <NoteItem>[];

      // Load all parts
      for (int partNumber = 1; partNumber <= 5; partNumber++) {
        await _kiranListService.loadPart('saxatsavita', 'part$partNumber');
        final kiranList = _kiranListService.getKiranListFromPartNumber(
          partNumber,
        );

        if (kiranList != null) {
          for (final kiranInfo in kiranList.list) {
            final kiranUserInfo = KiranUserService().getKiranUserInfo(
              kiranInfo.index,
            );

            // Check if this kiran has notes
            if (kiranUserInfo.note != null && kiranUserInfo.note!.isNotEmpty) {
              String plainTextPreview = '';

              try {
                // Try to parse as Quill Delta JSON
                // First check if the note string is valid JSON
                final noteContent = kiranUserInfo.note!.trim();
                if (noteContent.isEmpty) {
                  plainTextPreview = '';
                } else {
                  final deltaJson = jsonDecode(noteContent);
                  List<dynamic>? ops;

                  if (deltaJson is Map && deltaJson.containsKey('ops')) {
                    // Standard Quill Delta format: {"ops": [...]}
                    ops = deltaJson['ops'] as List;
                  } else if (deltaJson is List) {
                    // Direct ops array format: [...]
                    ops = deltaJson;
                  }

                  if (ops != null) {
                    // Extract plain text from Quill Delta operations
                    final textBuffer = StringBuffer();
                    for (final op in ops) {
                      if (op is Map && op.containsKey('insert')) {
                        final insert = op['insert'];
                        if (insert is String) {
                          textBuffer.write(insert);
                        }
                      }
                    }
                    plainTextPreview = textBuffer.toString().trim();
                  }
                }
              } catch (e) {
                // If not valid JSON, treat as plain text
                plainTextPreview = kiranUserInfo.note!.trim();
              }

              if (plainTextPreview.isNotEmpty) {
                allNotes.add(
                  NoteItem(
                    kiranUserInfo: kiranUserInfo,
                    kiranInfo: kiranInfo,
                    partNumber: partNumber,
                    noteContent: kiranUserInfo.note!,
                    plainTextPreview: plainTextPreview,
                    lastModified: kiranUserInfo.updatedAt!,
                  ),
                );
              }
            }
          }
        }
      }

      setState(() {
        _allNotes = allNotes;
        _applyFiltersAndSort();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading notes: $e');
      setState(() => _isLoading = false);
    }
  }

  void _applyFiltersAndSort() {
    // Apply filters
    _filteredNotes =
        _allNotes.where((note) {
          // Part filter
          if (!_selectedParts.contains(note.partNumber)) return false;

          // Search filter
          if (_searchQuery.isNotEmpty) {
            final searchInTitle = note.kiranInfo.title.toLowerCase().contains(
              _searchQuery,
            );
            final searchInContent = note.plainTextPreview
                .toLowerCase()
                .contains(_searchQuery);
            if (!searchInTitle && !searchInContent) return false;
          }

          return true;
        }).toList();

    // Apply sorting
    _filteredNotes.sort((a, b) {
      int comparison = 0;

      switch (_currentSort) {
        case SortOption.dateModified:
          comparison = a.lastModified.compareTo(b.lastModified);
          break;
        case SortOption.partNumber:
          comparison = a.partNumber.compareTo(b.partNumber);
          if (comparison == 0) {
            comparison = a.kiranInfo.index.compareTo(b.kiranInfo.index);
          }
          break;
        case SortOption.noteLength:
          comparison = a.plainTextPreview.length.compareTo(
            b.plainTextPreview.length,
          );
          break;
      }

      return _sortAscending ? comparison : -comparison;
    });
  }

  void _togglePartFilter(int partNumber) {
    setState(() {
      if (_selectedParts.contains(partNumber)) {
        _selectedParts.remove(partNumber);
      } else {
        _selectedParts.add(partNumber);
      }
      _applyFiltersAndSort();
    });
  }

  void _changeSortOption(SortOption newSort) {
    setState(() {
      if (_currentSort == newSort) {
        _sortAscending = !_sortAscending;
      } else {
        _currentSort = newSort;
        _sortAscending = false;
      }
      _applyFiltersAndSort();
    });
  }

  Future<void> _editNote(NoteItem noteItem) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => NoteEditorPage(
              kiranUserInfo: noteItem.kiranUserInfo,
              kiranTitle:
                  '${AppLocalizations.of(context)!.kiran} ${noteItem.kiranInfo.number.replaceAll(".", "")}',
            ),
      ),
    );

    if (result == true) {
      // Reload notes if changes were made
      _loadAllNotes();
    }
  }

  Future<void> _navigateToKiran(NoteItem noteItem) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => KiranReadPage(
              partNumber: 'part${noteItem.partNumber}',
              kiranInfo: noteItem.kiranInfo,
              kiranUserInfo: noteItem.kiranUserInfo,
            ),
      ),
    );
  }

  Future<void> _deleteNote(NoteItem noteItem) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.notes),
            content: Text(AppLocalizations.of(context)!.deleteNoteConfirm),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: Text(AppLocalizations.of(context)!.delete),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        // Clear the note
        final updatedKiranUserInfo = KiranUserInfo(
          partNumber: noteItem.kiranUserInfo.partNumber,
          kiranIndex: noteItem.kiranUserInfo.kiranIndex,
          listIndex: noteItem.kiranUserInfo.listIndex,
          progress: noteItem.kiranUserInfo.progress,
          updatedAt: DateTime.now(),
          isFavourite: noteItem.kiranUserInfo.isFavourite,
          note: '', // Clear the note
        );

        Utils.updateKiranUserInfo(updatedKiranUserInfo);

        // Reload the notes list
        _loadAllNotes();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.noteDeletedSuccess),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.errorDeletingNote(e.toString()),
              ),
            ),
          );
        }
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return AppLocalizations.of(context)!.daysAgo(difference.inDays);
    } else if (difference.inHours > 0) {
      return AppLocalizations.of(context)!.hoursAgo(difference.inHours);
    } else if (difference.inMinutes > 0) {
      return AppLocalizations.of(context)!.minutesAgo(difference.inMinutes);
    } else {
      return AppLocalizations.of(context)!.justNow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(
        context,
        title: AppLocalizations.of(context)!.notes,
        actionItems: [],
        extraActions: [
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_list : Icons.filter_list_off,
            ),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
            tooltip: AppLocalizations.of(context)!.filters,
          ),
          PopupMenuButton<SortOption>(
            icon: Icon(Icons.sort),
            tooltip: AppLocalizations.of(context)!.sortBy,
            onSelected: _changeSortOption,
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    value: SortOption.dateModified,
                    child: Row(
                      children: [
                        Icon(Icons.access_time, size: 18),
                        SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.lastModified,
                          style: Theme.of(
                            context,
                          ).textTheme.titleSmall!.copyWith(
                            color:
                                Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                          ),
                        ),
                        if (_currentSort == SortOption.dateModified) ...[
                          Spacer(),
                          Icon(
                            _sortAscending
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                          ),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: SortOption.partNumber,
                    child: Row(
                      children: [
                        Icon(Icons.book, size: 18),
                        SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.bookPart,
                          style: Theme.of(
                            context,
                          ).textTheme.titleSmall!.copyWith(
                            color:
                                Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                          ),
                        ),
                        if (_currentSort == SortOption.partNumber) ...[
                          Spacer(),
                          Icon(
                            _sortAscending
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                          ),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: SortOption.noteLength,
                    child: Row(
                      children: [
                        Icon(Icons.short_text, size: 18),
                        SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.noteLength,
                          style: Theme.of(
                            context,
                          ).textTheme.titleSmall!.copyWith(
                            color:
                                Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                          ),
                        ),
                        if (_currentSort == SortOption.noteLength) ...[
                          Spacer(),
                          Icon(
                            _sortAscending
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Container(
              padding: const EdgeInsets.all(16.0),
              color: Theme.of(context).colorScheme.surfaceContainer,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.searchNotesHint,
                  prefixIcon: Icon(Icons.search),
                  suffixIcon:
                      _searchController.text.isNotEmpty
                          ? IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                          : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
              ),
            ),

            // Filters Section
            if (_showFilters) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.book, size: 16),
                        SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.bookParts,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children:
                          [1, 2, 3, 4, 5].map((partNumber) {
                            final isSelected = _selectedParts.contains(
                              partNumber,
                            );
                            return FilterChip(
                              selected: isSelected,
                              onSelected: (_) => _togglePartFilter(partNumber),
                              label: Text(
                                Bookservice().getPartTitle(context, partNumber),
                              ),
                              labelStyle: Theme.of(
                                context,
                              ).textTheme.labelSmall!.copyWith(
                                color:
                                    isSelected
                                        ? Theme.of(
                                          context,
                                        ).colorScheme.onPrimary
                                        : Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                              ),
                              avatar:
                                  isSelected
                                      ? Icon(Icons.check, size: 16)
                                      : Icon(Icons.book, size: 16),
                              backgroundColor:
                                  Theme.of(context).colorScheme.surface,
                              selectedColor:
                                  Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer,
                            );
                          }).toList(),
                    ),
                  ],
                ),
              ),
            ],

            // Notes Count Header
            if (!_isLoading) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Text(
                      AppLocalizations.of(
                        context,
                      )!.notesCount(_filteredNotes.length, _allNotes.length),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                    Spacer(),
                    if (_filteredNotes.isNotEmpty) ...[
                      Text(
                        _getSortDescription(),
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // Notes List
            Expanded(child: _buildNotesList()),
          ],
        ),
      ),
    );
  }

  String _getSortDescription() {
    String sortName = '';
    switch (_currentSort) {
      case SortOption.dateModified:
        sortName = AppLocalizations.of(context)!.lastModified;
        break;
      case SortOption.partNumber:
        sortName = AppLocalizations.of(context)!.bookPart;
        break;
      case SortOption.noteLength:
        sortName = AppLocalizations.of(context)!.noteLength;
        break;
    }

    return 'Sorted by $sortName ${_sortAscending ? '↑' : '↓'}';
  }

  Widget _buildNotesList() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_allNotes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.note_add,
              size: 64,
              color: Colors.grey.withValues(alpha: 0.5),
            ),
            SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.noNotesFound,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.startTakingNotes,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_filteredNotes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey.withValues(alpha: 0.5),
            ),
            SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.noMatchingNotes,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.adjustSearchFilters,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAllNotes,
      child: ListView.separated(
        padding: const EdgeInsets.all(16.0),
        itemCount: _filteredNotes.length,
        separatorBuilder: (context, index) => SizedBox(height: 12),
        itemBuilder: (context, index) {
          final noteItem = _filteredNotes[index];
          return _buildNoteCard(noteItem);
        },
      ),
    );
  }

  Widget _buildNoteCard(NoteItem noteItem) {
    final previewText =
        noteItem.plainTextPreview.length > 150
            ? '${noteItem.plainTextPreview.substring(0, 150)}...'
            : noteItem.plainTextPreview;

    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with part info and actions
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    Bookservice().getPartTitle(context, noteItem.partNumber),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${noteItem.kiranInfo.number} ${noteItem.kiranInfo.title}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _formatDateTime(noteItem.lastModified),
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  icon: Icon(Icons.more_vert),
                  itemBuilder:
                      (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit,
                                size: 18,
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer,
                              ),
                              SizedBox(width: 8),
                              Text(
                                AppLocalizations.of(context)!.editNote,
                                style: Theme.of(
                                  context,
                                ).textTheme.titleSmall!.copyWith(
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'view_kiran',
                          child: Row(
                            children: [
                              Icon(
                                Icons.book_online,
                                size: 18,
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer,
                              ),
                              SizedBox(width: 8),
                              Text(
                                AppLocalizations.of(context)!.viewKiran,
                                style: Theme.of(
                                  context,
                                ).textTheme.titleSmall!.copyWith(
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
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
                                AppLocalizations.of(context)!.deleteNote,
                                style: TextStyle(color: Colors.red.shade300),
                              ),
                            ],
                          ),
                        ),
                      ],
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _editNote(noteItem);
                        break;
                      case 'view_kiran':
                        _navigateToKiran(noteItem);
                        break;
                      case 'delete':
                        _deleteNote(noteItem);
                        break;
                    }
                  },
                ),
              ],
            ),
          ),

          // Note content preview
          InkWell(
            onTap: () => _editNote(noteItem),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    previewText,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.short_text, size: 16, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(
                        '${noteItem.plainTextPreview.length} ${AppLocalizations.of(context)!.characters}',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                      Spacer(),
                      Icon(Icons.edit, size: 16, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(
                        'Tap to edit',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
