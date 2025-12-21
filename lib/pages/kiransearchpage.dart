import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saxatsavita_flutter/models/reading_event_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saxatsavita_flutter/components/appbar.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';
import 'package:saxatsavita_flutter/models/kiraninfo_model.dart';
import 'package:saxatsavita_flutter/models/kiranuserinfo_model.dart';
import 'package:saxatsavita_flutter/pages/kiranreadpage.dart';
import 'package:saxatsavita_flutter/services/bookservice.dart';
import 'package:saxatsavita_flutter/services/kiranlistservice.dart';
import 'package:saxatsavita_flutter/services/utils.dart';
import 'package:saxatsavita_flutter/services/analytics_service.dart';

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
  final double relevanceScore;

  SearchResult({
    required this.kiranInfo,
    required this.partNumber,
    required this.snippet,
    this.isContentMatch = false,
    this.relevanceScore = 0.0,
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

  /// Calculate relevance score for a text against the search query
  /// Higher scores indicate better matches
  double _calculateRelevanceScore(String text, String query) {
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();

    // Base score
    double score = 0.0;

    // 1. Exact match gets highest score
    if (lowerText == lowerQuery) {
      return 100.0;
    }

    // 2. Exact phrase match gets very high score
    if (lowerText.contains(lowerQuery)) {
      score += 150.0;

      // Bonus for match at the beginning
      if (lowerText.startsWith(lowerQuery)) {
        score += 15.0;
      }

      // Bonus for match as whole words
      final regex = RegExp(r'\b' + RegExp.escape(lowerQuery) + r'\b');
      if (regex.hasMatch(lowerText)) {
        score += 10.0;
      }

      return score;
    }

    // 3. Multi-word matching
    final queryWords =
        lowerQuery
            .split(RegExp(r'\s+'))
            .where((word) => word.trim().isNotEmpty)
            .toList();

    if (queryWords.isEmpty) return 0.0;

    int matchedWords = 0;
    double wordScore = 0.0;

    for (final word in queryWords) {
      if (lowerText.contains(word)) {
        matchedWords++;
        wordScore += 20.0; // Base score per matched word

        // Bonus for word at beginning of text
        if (lowerText.startsWith(word)) {
          wordScore += 10.0;
        }

        // Bonus for whole word match
        final wordRegex = RegExp(r'\b' + RegExp.escape(word) + r'\b');
        if (wordRegex.hasMatch(lowerText)) {
          wordScore += 5.0;
        }

        // Bonus for adjacent words (check if current word appears near previous matched words)
        for (final otherWord in queryWords) {
          if (otherWord != word && lowerText.contains(otherWord)) {
            final wordIndex = lowerText.indexOf(word);
            final otherIndex = lowerText.indexOf(otherWord, wordIndex + 1);
            final distance = (wordIndex - otherIndex).abs();

            // Bonus for words that appear close to each other
            if (distance <= 20) {
              // Within 20 characters
              wordScore += 3.0;
            }
          }
        }
      }
    }

    // Calculate final score based on matched words ratio
    final matchRatio = matchedWords / queryWords.length;
    score = wordScore * matchRatio;

    // Bonus for matching all words
    if (matchedWords == queryWords.length) {
      score += 15.0;
    }

    // Length penalty - shorter text with same matches is more relevant
    //final lengthPenalty = (lowerText.length / 100.0).clamp(0.0, 10.0);
    //score = (score - lengthPenalty).clamp(0.0, double.infinity);

    return score;
  }

  /// Calculate relevance score for content matches
  Future<double> _calculateContentRelevance(
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

      // Remove HTML tags for relevance calculation
      final plainContent = content.replaceAll(RegExp(r'<[^>]*>'), '');

      return _calculateRelevanceScore(plainContent, query);
    } catch (e) {
      debugPrint(
        'Error calculating content relevance for kiran $kiranIndex: $e',
      );
      return 0.0;
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
            // Search in title - support both exact match and multi-word match
            bool titleMatches = false;
            String titleSnippet = '';

            if (_matchesMultiWord(kiranInfo.title.toLowerCase(), lowerQuery) ||
                kiranInfo.number.toLowerCase().contains(lowerQuery)) {
              titleMatches = true;
              titleSnippet = _highlightMultiWordMatch(kiranInfo.title, query);
            }

            if (titleMatches) {
              final titleRelevance = _calculateRelevanceScore(
                '${kiranInfo.number} ${kiranInfo.title}',
                query,
              );
              results.add(
                SearchResult(
                  kiranInfo: kiranInfo,
                  partNumber: partNumber,
                  snippet: titleSnippet,
                  isContentMatch: false,
                  relevanceScore:
                      titleRelevance + 10.0, // Bonus for title matches
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
              // Calculate relevance for content (we'll need to pass the original content)
              final contentRelevance = await _calculateContentRelevance(
                partNumber,
                kiranInfo.index,
                query,
              );
              results.add(
                SearchResult(
                  kiranInfo: kiranInfo,
                  partNumber: partNumber,
                  snippet: contentSnippet,
                  isContentMatch: true,
                  relevanceScore: contentRelevance,
                ),
              );
            }
          }
        }
      }

      // Sort results by relevance score (highest first)
      results.sort((a, b) {
        // Primary sort: by relevance score (descending)
        final scoreComparison = b.relevanceScore.compareTo(a.relevanceScore);
        if (scoreComparison != 0) {
          return scoreComparison;
        }

        // Secondary sort: title matches before content matches
        if (a.isContentMatch != b.isContentMatch) {
          return a.isContentMatch ? 1 : -1;
        }

        // Tertiary sort: by kiran index
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

      // Track search analytics
      await AnalyticsService().logSearch(
        query: query,
        resultsCount: results.length,
        category: 'kiran_search',
      );
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

      // Try exact match first
      int index = lowerContent.indexOf(lowerQuery);

      // If no exact match, try multi-word match
      if (index == -1 && _matchesMultiWord(lowerContent, lowerQuery)) {
        // Find the first word of the query to get a starting position
        final queryWords = lowerQuery.split(RegExp(r'\s+'));
        if (queryWords.isNotEmpty) {
          index = lowerContent.indexOf(queryWords.first);
        }
      }

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

        return _highlightMultiWordMatch(snippet, query);
      }
    } catch (e) {
      debugPrint('Error searching content for kiran $kiranIndex: $e');
    }
    return '';
  }

  /// Checks if the text matches all words in the query, even if they're not adjacent
  bool _matchesMultiWord(String text, String query) {
    // Split query into individual words, removing extra spaces
    final queryWords =
        query
            .split(RegExp(r'\s+'))
            .where((word) => word.trim().isNotEmpty)
            .toList();

    if (queryWords.isEmpty) return false;

    // Check if all query words are present in the text
    for (final word in queryWords) {
      if (!text.contains(word.toLowerCase())) {
        return false;
      }
    }

    return true;
  }

  /// Highlights all matching words in the text, even if they're not adjacent
  String _highlightMultiWordMatch(String text, String query) {
    if (query.trim().isEmpty) return text;

    // Split query into individual words
    final queryWords =
        query
            .split(RegExp(r'\s+'))
            .where((word) => word.trim().isNotEmpty)
            .map((word) => word.toLowerCase())
            .toList();

    if (queryWords.isEmpty) return text;

    String result = text;

    // Highlight each word individually
    for (final word in queryWords) {
      // Create a case-insensitive regex for the word
      final regex = RegExp(RegExp.escape(word), caseSensitive: false);
      result = result.replaceAllMapped(regex, (match) {
        return '**${match.group(0)}**';
      });
    }

    return result;
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

    // If user is not logged in ask to login
    if (FirebaseAuth.instance.currentUser == null) {
      // Show dialog
      Utils.showLoginWarningDialog(context);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => KiranReadPage(
              partNumber: "part${result.partNumber}",
              kiranInfo: result.kiranInfo,
              kiranUserInfo: kiranUserInfo,
              searchQuery: _searchController.text.trim(),
              readingMode: ReadingMode.browse,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(
        context,
        title: AppLocalizations.of(context)!.search,
        actionItems: [ActionOptions.settings],
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
                                AppLocalizations.of(context)!.recent_searches,
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
                                  AppLocalizations.of(context)!.clear,
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
                        // Scrollable search history list
                        ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxHeight:
                                200, // Limit height to make it scrollable
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              children: List.generate(
                                _searchHistoryService.searchHistory.length,
                                (index) {
                                  final historyItem =
                                      _searchHistoryService
                                          .searchHistory[index];
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
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color:
                                                    Theme.of(context)
                                                        .colorScheme
                                                        .primaryContainer,
                                                borderRadius:
                                                    BorderRadius.circular(10),
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
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],

                // Collapsible Filters Section
                _buildFilterChips(),
              ],
            ),
          ),

          // Search Results
          Expanded(child: _buildSearchResults()),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return ExpansionTile(
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
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (_getActiveFiltersCount() > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_getActiveFiltersCount()}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
          Icon(_isFiltersExpanded ? Icons.expand_less : Icons.expand_more),
        ],
      ),
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Match Type Filters
              Row(
                children: [
                  Text(
                    '${AppLocalizations.of(context)!.match_type} : ',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  FilterChip(
                    selected: _showTitleMatches,
                    onSelected: (_) => _toggleMatchTypeFilter(false),
                    label: Text(AppLocalizations.of(context)!.title_match),
                    labelStyle: Theme.of(
                      context,
                    ).textTheme.labelSmall!.copyWith(
                      color:
                          _showTitleMatches
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onSurface,
                    ),
                    avatar:
                        _showTitleMatches
                            ? const Icon(Icons.check)
                            : const Icon(Icons.title),
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    selectedColor:
                        Theme.of(context).colorScheme.primaryContainer,
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    selected: _showContentMatches,
                    onSelected: (_) => _toggleMatchTypeFilter(true),
                    label: Text(AppLocalizations.of(context)!.content_match),
                    labelStyle: Theme.of(
                      context,
                    ).textTheme.labelSmall!.copyWith(
                      color:
                          _showContentMatches
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onSurface,
                    ),
                    avatar:
                        _showContentMatches
                            ? const Icon(Icons.check)
                            : const Icon(Icons.article),
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    selectedColor:
                        Theme.of(context).colorScheme.primaryContainer,
                  ),
                ],
              ),

              // Part Filters
              Text(
                '${AppLocalizations.of(context)!.book_parts}: ',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    _availableParts.map((partNumber) {
                      final isSelected = _selectedParts.contains(partNumber);
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
                                  ? Utils.getPartColor(partNumber, context)
                                  : Utils.getPartAccentColor(
                                    partNumber,
                                    context,
                                  ),
                        ),
                        avatar:
                            isSelected
                                ? const Icon(Icons.check)
                                : const Icon(Icons.book),
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        selectedColor: Utils.getPartAccentColor(
                          partNumber,
                          context,
                        ),
                      );
                    }).toList(),
              ),
            ],
          ),
        ),
      ],
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
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.enter_keywords,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                textAlign: TextAlign.center,
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
                primary: true,
                itemCount: _filteredResults.length,
                separatorBuilder: (context, index) => const SizedBox(height: 0),
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
    final partColor = Utils.getPartColor(result.partNumber, context);
    final accentColor = Utils.getPartAccentColor(result.partNumber, context);

    return Card(
      elevation: 2,
      color: partColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: accentColor.withOpacity(0.3), width: 1),
      ),
      child: InkWell(
        onTap: () => _navigateToKiran(result),
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.2),
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
                      color: accentColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: accentColor.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      Bookservice().getPartTitle(context, result.partNumber),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: accentColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    result.isContentMatch ? Icons.article : Icons.title,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary.withAlpha(127),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    result.isContentMatch
                        ? AppLocalizations.of(context)!.content_match
                        : AppLocalizations.of(context)!.title_match,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withAlpha(127),
                    ),
                  ),
                ],
              ),
            ),
            ColoredBox(
              color: accentColor.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  top: 8.0,
                  bottom: 16.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    result.isContentMatch
                        ? Text(
                          '${result.kiranInfo.number} ${result.kiranInfo.title}',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        )
                        : _buildHighlightedTitle(
                          '${result.kiranInfo.number} ${result.snippet}',
                        ),
                    const SizedBox(height: 8),
                    _buildHighlightedSnippet(result.snippet),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.timer, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          Utils.getEstimatedReadingTime(
                            result.kiranInfo.wordCount,
                          ),
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                        ),
                        const Spacer(),
                        Text(
                          result.relevanceScore.toString(),
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
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

  Widget _buildHighlightedTitle(String highlightedSnippet) {
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
