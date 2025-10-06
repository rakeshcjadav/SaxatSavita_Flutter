import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saxatsavita_flutter/components/appbar.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';
import 'package:saxatsavita_flutter/models/kiraninfo_model.dart';
import 'package:saxatsavita_flutter/models/kiranuserinfo_model.dart';
import 'package:saxatsavita_flutter/pages/kiranreadpage.dart';
import 'package:saxatsavita_flutter/services/kiranlistservice.dart';
import 'package:saxatsavita_flutter/services/utils.dart';

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
  bool _isLoading = false;
  bool _hasSearched = false;
  Timer? _debounceTimer;

  final KiranListService _kiranListService = KiranListService();
  final List<int> _availableParts = [1, 2, 3, 4, 5];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadAllParts();
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
        _performSearch(_searchController.text.trim());
      } else {
        setState(() {
          _searchResults.clear();
          _hasSearched = false;
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
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Search error: $e');
    }
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
              partNumber: result.partNumber.toString(),
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
            padding: const EdgeInsets.all(16.0),
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
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      return Center(
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
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.try_different_keywords,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Text(
                AppLocalizations.of(
                  context,
                )!.results_found(_searchResults.length),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: _searchResults.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final result = _searchResults[index];
              return _buildSearchResultCard(result);
            },
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
                      'Part ${result.partNumber}',
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
              Text(
                '${result.kiranInfo.number} ${result.kiranInfo.title}',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                result.snippet.replaceAll('**', ''),
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
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
}
