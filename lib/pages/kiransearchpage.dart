import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saxatsavita_flutter/components/appbar.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';
import 'package:saxatsavita_flutter/models/kiraninfo_model.dart';
import 'package:saxatsavita_flutter/models/kiranuserinfo_model.dart';
import 'package:saxatsavita_flutter/pages/kiranreadpage.dart';
import 'package:saxatsavita_flutter/services/bookservice.dart';
import 'package:saxatsavita_flutter/services/kiranlistservice.dart';
import 'package:saxatsavita_flutter/services/utils.dart';

// Simple search history storage service
class SearchHistoryService {
  static final SearchHistoryService _instance =
      SearchHistoryService._internal();
  factory SearchHistoryService() => _instance;
  SearchHistoryService._internal();

  static const int _maxHistoryItems = 10;

  List<Map<String, dynamic>> _searchHistory = [];

  List<Map<String, dynamic>> get searchHistory =>
      List.unmodifiable(_searchHistory);

  Future<void> loadSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedHistoryJson = prefs.getString('search_history');

      if (savedHistoryJson != null && savedHistoryJson.isNotEmpty) {
        final List<dynamic> decodedData = jsonDecode(savedHistoryJson);
        _searchHistory = decodedData.cast<Map<String, dynamic>>();

        // Validate data integrity and remove any invalid entries
        _searchHistory =
            _searchHistory.where((item) {
              return item.containsKey('query') &&
                  item.containsKey('count') &&
                  item.containsKey('lastUsed') &&
                  item['query'] is String &&
                  item['count'] is int &&
                  item['lastUsed'] is int;
            }).toList();

        debugPrint(
          'Search history loaded from storage: ${_searchHistory.length} items',
        );
      } else {
        _searchHistory = [];
        debugPrint('No saved search history found, starting fresh');
      }
    } catch (e) {
      debugPrint('Error loading search history: $e');
      _searchHistory = [];
    }
  }

  Future<void> saveSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = jsonEncode(_searchHistory);
      await prefs.setString('search_history', jsonData);

      debugPrint(
        'Search history saved to persistent storage: ${_searchHistory.length} items',
      );
    } catch (e) {
      debugPrint('Error saving search history: $e');
    }
  }

  void addSearchQuery(String query) {
    if (query.trim().isEmpty) return;

    final trimmedQuery = query.trim();
    final lowerQuery = trimmedQuery.toLowerCase();

    // Find if query already exists
    int existingIndex = _searchHistory.indexWhere(
      (item) => (item['query'] as String).toLowerCase() == lowerQuery,
    );

    if (existingIndex >= 0) {
      // Update existing entry: increment count and move to top
      final existingItem = _searchHistory.removeAt(existingIndex);
      existingItem['count'] = (existingItem['count'] as int) + 1;
      existingItem['lastUsed'] = DateTime.now().millisecondsSinceEpoch;
      _searchHistory.insert(0, existingItem);
    } else {
      // Add new entry at the beginning
      _searchHistory.insert(0, {
        'query': trimmedQuery,
        'count': 1,
        'lastUsed': DateTime.now().millisecondsSinceEpoch,
      });
    }

    // Keep only the latest items
    if (_searchHistory.length > _maxHistoryItems) {
      _searchHistory = _searchHistory.take(_maxHistoryItems).toList();
    }

    // Save to persistent storage
    saveSearchHistory();

    debugPrint(
      'Search history updated: ${_searchHistory.map((item) => "${item['query']} (${item['count']}x)").toList()}',
    );
  }

  void clearHistory() {
    _searchHistory.clear();
    saveSearchHistory();
    debugPrint('Search history cleared');
  }

  Map<String, dynamic>? getQueryStats(String query) {
    final lowerQuery = query.toLowerCase();
    try {
      return _searchHistory.firstWhere(
        (item) => (item['query'] as String).toLowerCase() == lowerQuery,
      );
    } catch (e) {
      return null;
    }
  }

  List<String> getMostSearchedQueries({int limit = 5}) {
    final sortedHistory = List<Map<String, dynamic>>.from(_searchHistory);
    sortedHistory.sort(
      (a, b) => (b['count'] as int).compareTo(a['count'] as int),
    );
    return sortedHistory
        .take(limit)
        .map((item) => item['query'] as String)
        .toList();
  }

  List<String> getRecentQueries({int limit = 5}) {
    return _searchHistory
        .take(limit)
        .map((item) => item['query'] as String)
        .toList();
  }

  int get totalSearches =>
      _searchHistory.fold(0, (sum, item) => sum + (item['count'] as int));

  bool hasSearched(String query) {
    return getQueryStats(query) != null;
  }
}

class SearchResult {
  final KiranInfo kiranInfo;
  final int partNumber;
  final String snippet;
  final bool isContentMatch;

  SearchResult({
    required this.kiranInfo,
    required this.partNumber,
    required this.snippet,
    this.isContentMatch = false,
  });
}

class Kiransearchpage extends StatefulWidget {
  const Kiransearchpage({super.key});

  @override
  State<Kiransearchpage> createState() => _KiransearchpageState();
}

class _KiransearchpageState extends State<Kiransearchpage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<SearchResult> _searchResults = [];
  List<SearchResult> _filteredResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  Timer? _debounceTimer;

  final KiranListService _kiranListService = KiranListService();
  final List<int> _availableParts = [1, 2, 3, 4, 5];

  // Filter state
  Set<int> _selectedParts = {1, 2, 3, 4, 5}; // All parts selected by default
  bool _showTitleMatches = true;
  bool _showContentMatches = true;
  bool _isFiltersExpanded = false; // Collapsible filter state

  // Search history state
  final SearchHistoryService _searchHistoryService = SearchHistoryService();
  bool _showSearchSuggestions = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(() {
      setState(() {
        _showSearchSuggestions =
            _searchFocusNode.hasFocus &&
            _searchController.text.isEmpty &&
            _searchHistoryService.searchHistory.isNotEmpty;
      });
    });
    _loadAllParts();
    _loadSearchHistory();
  }

  Future<void> _loadSearchHistory() async {
    await _searchHistoryService.loadSearchHistory();
    if (mounted) {
      setState(() {
        // Trigger rebuild after loading search history
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (_searchController.text.trim().length >= 2) {
        setState(() {
          _showSearchSuggestions = false;
        });
        _performSearch(_searchController.text.trim());
      } else {
        setState(() {
          _searchResults.clear();
          _filteredResults.clear();
          _hasSearched = false;
          _showSearchSuggestions =
              _searchFocusNode.hasFocus &&
              _searchController.text.isEmpty &&
              _searchHistoryService.searchHistory.isNotEmpty;
        });
      }
    });
  }

  Future<void> _loadAllParts() async {
    try {
      for (int partNumber in _availableParts) {
        await _kiranListService.loadPart('saxatsavita', 'part$partNumber');
      }
    } catch (e) {
      debugPrint('Error loading parts: $e');
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final results = <SearchResult>[];
      final lowerQuery = query.toLowerCase();

      for (int partNumber in _availableParts) {
        final kiranList = _kiranListService.getKiranListFromPartNumber(
          partNumber,
        );
        if (kiranList != null) {
          for (final kiranInfo in kiranList.list) {
            // Search in title
            if (kiranInfo.title.toLowerCase().contains(lowerQuery) ||
                kiranInfo.number.toLowerCase().contains(lowerQuery)) {
              results.add(
                SearchResult(
                  kiranInfo: kiranInfo,
                  partNumber: partNumber,
                  snippet: _highlightMatch(kiranInfo.title, query),
                  isContentMatch: false,
                ),
              );
            }

            // Search in content
            final contentSnippet = await _searchInContent(
              partNumber,
              kiranInfo.index,
              query,
            );
            if (contentSnippet.isNotEmpty) {
              results.add(
                SearchResult(
                  kiranInfo: kiranInfo,
                  partNumber: partNumber,
                  snippet: contentSnippet,
                  isContentMatch: true,
                ),
              );
            }
          }
        }
      }

      // Sort results by relevance (title matches first, then content matches)
      results.sort((a, b) {
        if (a.isContentMatch != b.isContentMatch) {
          return a.isContentMatch ? 1 : -1;
        }
        return a.kiranInfo.index.compareTo(b.kiranInfo.index);
      });

      setState(() {
        _searchResults = results;
        _applyFilters();
        _isLoading = false;

        // Add successful search query to history (if results found)
        if (results.isNotEmpty) {
          _searchHistoryService.addSearchQuery(query);
          // Trigger rebuild to update any UI that depends on search history
          if (mounted) {
            setState(() {});
          }
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Search error: $e');
    }
  }

  void _applyFilters() {
    _filteredResults =
        _searchResults.where((result) {
          // Filter by part number
          if (!_selectedParts.contains(result.partNumber)) {
            return false;
          }

          // Filter by match type
          if (result.isContentMatch && !_showContentMatches) {
            return false;
          }
          if (!result.isContentMatch && !_showTitleMatches) {
            return false;
          }

          return true;
        }).toList();
  }

  void _clearSearchHistory() {
    _searchHistoryService.clearHistory();
    setState(() {
      // Trigger rebuild after clearing history
    });
  }

  void _selectSearchSuggestion(String query) {
    _searchController.text = query;
    setState(() {
      _showSearchSuggestions = false;
    });
    _performSearch(query);
  }

  void _togglePartFilter(int partNumber) {
    setState(() {
      if (_selectedParts.contains(partNumber)) {
        _selectedParts.remove(partNumber);
      } else {
        _selectedParts.add(partNumber);
      }
      _applyFilters();
    });
  }

  void _toggleMatchTypeFilter(bool isContentFilter) {
    setState(() {
      if (isContentFilter) {
        _showContentMatches = !_showContentMatches;
      } else {
        _showTitleMatches = !_showTitleMatches;
      }
      _applyFilters();
    });
  }

  int _getActiveFiltersCount() {
    int count = 0;

    // Count deselected parts
    count += _availableParts.length - _selectedParts.length;

    // Count disabled match type filters
    if (!_showTitleMatches) count++;
    if (!_showContentMatches) count++;

    return count;
  }

  Future<String> _searchInContent(
    int partNumber,
    int kiranIndex,
    String query,
  ) async {
    try {
      final path =
          'assets/book/saxatsavita/part$partNumber/kiran_$kiranIndex.json';
      final jsonString = await rootBundle.loadString(path);
      final contentData = json.decode(jsonString);
      final content = contentData['main']['content'] ?? '';

      // Remove HTML tags for search
      final plainContent = content.replaceAll(RegExp(r'<[^>]*>'), '');
      final lowerContent = plainContent.toLowerCase();
      final lowerQuery = query.toLowerCase();

      final index = lowerContent.indexOf(lowerQuery);
      if (index != -1) {
        // Extract snippet around the match
        const snippetLength = 100;
        final start = (index - snippetLength ~/ 2).clamp(
          0,
          plainContent.length,
        );
        final end = (index + lowerQuery.length + snippetLength ~/ 2).clamp(
          0,
          plainContent.length,
        );
        var snippet = plainContent.substring(start, end).trim();

        if (start > 0) snippet = '...$snippet';
        if (end < plainContent.length) snippet = '$snippet...';

        return _highlightMatch(snippet, query);
      }
    } catch (e) {
      debugPrint('Error searching content for kiran $kiranIndex: $e');
    }
    return '';
  }

  String _highlightMatch(String text, String query) {
    final index = text.toLowerCase().indexOf(query.toLowerCase());
    if (index == -1) return text;

    return '${text.substring(0, index)}**${text.substring(index, index + query.length)}**${text.substring(index + query.length)}';
  }

  void _navigateToKiran(SearchResult result) {
    final kiranUserInfo = KiranUserInfo(
      partNumber: result.partNumber,
      kiranIndex: result.kiranInfo.index,
      listIndex: result.kiranInfo.index,
      progress: 0,
      updatedAt: DateTime.now(),
      isFavourite: 0,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => KiranReadPage(
              partNumber: "part${result.partNumber}",
              kiranInfo: result.kiranInfo,
              kiranUserInfo: kiranUserInfo,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(
        context,
        title: AppLocalizations.of(context)!.menu_five,
        actionItems: [],
      ),
      body: Column(
        children: [
          // Search Box at the top
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4.0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.search_kiranas,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _showSearchSuggestions =
                                    _searchHistoryService
                                        .searchHistory
                                        .isNotEmpty &&
                                    _searchFocusNode.hasFocus;
                              });
                            },
                          ),
                        if (_isLoading)
                          const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                      ],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      _performSearch(value.trim());
                    }
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.search_min_chars,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),

                // Recent Search History Suggestions
                if (_showSearchSuggestions &&
                    _searchHistoryService.searchHistory.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withAlpha(100),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.history,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Recent Searches',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: _clearSearchHistory,
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Clear',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...List.generate(
                          _searchHistoryService.searchHistory.length,
                          (index) {
                            final historyItem =
                                _searchHistoryService.searchHistory[index];
                            final query = historyItem['query'] as String;
                            final count = historyItem['count'] as int;
                            return InkWell(
                              onTap: () => _selectSearchSuggestion(query),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0,
                                  vertical: 8.0,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.search,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        query,
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.bodyMedium,
                                      ),
                                    ),
                                    if (count > 1) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.primaryContainer,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Text(
                                          '${count}x',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall?.copyWith(
                                            color:
                                                Theme.of(context)
                                                    .colorScheme
                                                    .onPrimaryContainer,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    Icon(
                                      Icons.north_west,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],

                // Collapsible Filters Section
                if (_hasSearched && _searchResults.isNotEmpty) ...[
                  ExpansionTile(
                    initiallyExpanded: _isFiltersExpanded,
                    onExpansionChanged: (expanded) {
                      setState(() {
                        _isFiltersExpanded = expanded;
                      });
                    },
                    leading: Icon(
                      Icons.filter_list,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Row(
                      children: [
                        Text(
                          AppLocalizations.of(context)!.filters,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (_getActiveFiltersCount() > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.error,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_getActiveFiltersCount()}',
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onError,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedParts = {1, 2, 3, 4, 5};
                              _showTitleMatches = true;
                              _showContentMatches = true;
                              _applyFilters();
                            });
                          },
                          child: Text(
                            AppLocalizations.of(context)!.clear_all_filters,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Icon(
                          _isFiltersExpanded
                              ? Icons.expand_less
                              : Icons.expand_more,
                        ),
                      ],
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Match Type Filters
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  '${AppLocalizations.of(context)!.match_type} :',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                Expanded(
                                  child: FilterChip(
                                    selected: _showTitleMatches,
                                    onSelected:
                                        (_) => _toggleMatchTypeFilter(false),
                                    label: Text(
                                      AppLocalizations.of(context)!.title_match,
                                    ),
                                    labelStyle:
                                        Theme.of(context).textTheme.bodySmall,
                                    avatar:
                                        _showTitleMatches
                                            ? const Icon(Icons.check)
                                            : const Icon(Icons.title),
                                    backgroundColor:
                                        Theme.of(context).colorScheme.surface,
                                    selectedColor:
                                        Theme.of(
                                          context,
                                        ).colorScheme.primaryContainer,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: FilterChip(
                                    selected: _showContentMatches,
                                    onSelected:
                                        (_) => _toggleMatchTypeFilter(true),
                                    label: Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.content_match,
                                    ),
                                    labelStyle:
                                        Theme.of(context).textTheme.bodySmall,
                                    avatar:
                                        _showContentMatches
                                            ? const Icon(Icons.check)
                                            : const Icon(Icons.article),
                                    backgroundColor:
                                        Theme.of(context).colorScheme.surface,
                                    selectedColor:
                                        Theme.of(
                                          context,
                                        ).colorScheme.primaryContainer,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Part Filters
                            Text(
                              '${AppLocalizations.of(context)!.book_parts}:',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children:
                                  _availableParts.map((partNumber) {
                                    final isSelected = _selectedParts.contains(
                                      partNumber,
                                    );
                                    return FilterChip(
                                      selected: isSelected,
                                      onSelected:
                                          (_) => _togglePartFilter(partNumber),
                                      label: Text(
                                        Bookservice().getPartTitle(partNumber),
                                      ),
                                      labelStyle:
                                          Theme.of(context).textTheme.bodySmall,
                                      avatar:
                                          isSelected
                                              ? const Icon(Icons.check)
                                              : const Icon(Icons.book),
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
                  ),
                ],
              ],
            ),
          ),

          // Search Results
          Expanded(child: _buildSearchResults()),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (!_hasSearched) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search,
                size: 64,
                color: Colors.grey.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.search_all_kiranas,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.enter_keywords,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredResults.isEmpty) {
      if (_searchResults.isEmpty) {
        return Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: Colors.grey.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.no_results_found,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.try_different_keywords,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      } else {
        // Results exist but filtered out
        return Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.filter_list_off,
                    size: 64,
                    color: Colors.grey.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.no_filtered_results,
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.adjust_filters,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Text(
                AppLocalizations.of(context)!.results_filtered(
                  _filteredResults.length,
                  _searchResults.length,
                ),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 8.0),
            child: Scrollbar(
              child: ListView.separated(
                itemCount: _filteredResults.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final result = _filteredResults[index];
                  return _buildSearchResultCard(result);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResultCard(SearchResult result) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _navigateToKiran(result),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                      Bookservice().getPartTitle(result.partNumber),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    result.isContentMatch ? Icons.article : Icons.title,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    result.isContentMatch
                        ? AppLocalizations.of(context)!.content_match
                        : AppLocalizations.of(context)!.title_match,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              result.isContentMatch
                  ? Text(
                    '${result.kiranInfo.number} ${result.kiranInfo.title}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )
                  : _buildHighlightedTitle(
                    '${result.kiranInfo.number} ${result.kiranInfo.title}',
                    result.snippet,
                  ),
              const SizedBox(height: 8),
              _buildHighlightedSnippet(result.snippet),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.timer, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    Utils.getEstimatedReadingTime(result.kiranInfo.wordCount),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHighlightedSnippet(String snippet) {
    final parts = snippet.split('**');
    final spans = <TextSpan>[];

    for (int i = 0; i < parts.length; i++) {
      if (i % 2 == 0) {
        // Normal text
        if (parts[i].isNotEmpty) {
          spans.add(
            TextSpan(
              text: parts[i],
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }
      } else {
        // Highlighted text
        if (parts[i].isNotEmpty) {
          spans.add(
            TextSpan(
              text: parts[i],
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                backgroundColor: Colors.amberAccent.withValues(alpha: 0.6),
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }
      }
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildHighlightedTitle(String title, String highlightedSnippet) {
    // Extract the highlighted part from the snippet for title highlighting
    final parts = highlightedSnippet.split('**');
    final spans = <TextSpan>[];

    for (int i = 0; i < parts.length; i++) {
      if (i % 2 == 0) {
        // Normal text
        if (parts[i].isNotEmpty) {
          spans.add(
            TextSpan(
              text: parts[i],
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          );
        }
      } else {
        // Highlighted text
        if (parts[i].isNotEmpty) {
          spans.add(
            TextSpan(
              text: parts[i],
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              ),
            ),
          );
        }
      }
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
