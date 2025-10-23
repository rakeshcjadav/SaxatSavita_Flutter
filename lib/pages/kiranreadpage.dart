import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:saxatsavita_flutter/components/appbar.dart';
import 'package:saxatsavita_flutter/components/custom_html_widget.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';
import 'package:saxatsavita_flutter/models/kiraninfo_model.dart';
import 'package:saxatsavita_flutter/models/kiranuserinfo_model.dart';
import 'package:saxatsavita_flutter/models/reading_history_model.dart';
import 'package:saxatsavita_flutter/pages/quotes_image_generator_page.dart';
import 'package:saxatsavita_flutter/services/reading_history_service.dart';
import 'package:saxatsavita_flutter/pages/settingspage.dart';
import 'package:saxatsavita_flutter/pages/simple_note_editor_page.dart';
import 'package:saxatsavita_flutter/pages/note_editor_page.dart';
import 'package:saxatsavita_flutter/services/utils.dart';
import 'package:saxatsavita_flutter/models/inspirational_quote_model.dart';
import 'package:saxatsavita_flutter/services/analytics_service.dart';

class KiranReadPage extends StatefulWidget {
  const KiranReadPage({
    super.key,
    required this.partNumber,
    required this.kiranInfo,
    required this.kiranUserInfo,
  });
  final String partNumber;
  final KiranInfo kiranInfo;
  final KiranUserInfo kiranUserInfo;

  @override
  State<KiranReadPage> createState() => _KiranReadPageState();
}

class _KiranReadPageState extends State<KiranReadPage>
    with WidgetsBindingObserver {
  late Future<Map<String, dynamic>> _futureKiranContent;
  final ScrollController _scrollController = ScrollController();

  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  bool _isTimerPaused = false;

  // ValueNotifiers to prevent widget rebuilds during timer updates
  final ValueNotifier<String> _elapsedNotifier = ValueNotifier<String>("00:00");
  final ValueNotifier<bool> _isFinishButtonEnabledNotifier =
      ValueNotifier<bool>(false);

  // Auto-scroll variables
  bool _isAutoScrolling = false;
  Timer? _autoScrollTimer;
  Timer? _autoScrollDelayTimer; // Timer for 5-second delay
  double _contentHeight = 0;
  bool _isInitialized = false;

  bool _hasDataChanged = false;
  bool _isFinishButtonEnabled = false;
  int _initialReadingProgress = 0;

  // Reading history tracking
  DateTime? _sessionStartTime;
  String _currentCategory = 'Reading Session';

  // Search functionality state
  bool _isSearchMode = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _currentKiranContent = '';
  List<int> _searchMatches = [];
  int _currentMatchIndex = -1;

  @override
  void initState() {
    super.initState();
    _futureKiranContent = _loadKiranContent();
    _stopwatch.start();

    // Initialize reading session
    _sessionStartTime = DateTime.now();
    _currentCategory = _getCategoryBasedOnTime();

    // Add observer to detect app lifecycle changes
    WidgetsBinding.instance.addObserver(this);

    // Track analytics for reading session start
    AnalyticsService().logScreenView(screenName: 'reading_page');
    AnalyticsService().logStartReading(
      bookName: 'Sakshat Savita',
      chapterName: widget.kiranInfo.title,
      partName: 'Part ${widget.partNumber}',
    );

    _startTimer();
  }

  @override
  void dispose() {
    // Stop stopwatch first to capture correct elapsed time
    _stopwatch.stop();

    // Save reading history if session is long enough
    _saveReadingHistory();

    // Remove observer
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _timer = null;

    // Stop auto-scroll and cleanup
    _isAutoScrolling = false;
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
    _autoScrollDelayTimer?.cancel();
    _autoScrollDelayTimer = null;

    // Dispose scroll controller
    _scrollController.dispose();

    // Dispose ValueNotifiers
    _elapsedNotifier.dispose();
    _isFinishButtonEnabledNotifier.dispose();

    // Dispose search controllers
    _searchController.dispose();
    _searchFocusNode.dispose();

    super.dispose();
  }

  // Handle app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        _pauseTimer();
        break;
      case AppLifecycleState.resumed:
        _resumeTimer();
        break;
      case AppLifecycleState.hidden:
        _pauseTimer();
        break;
    }
  }

  void _startTimer() {
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isTimerPaused && mounted) {
        // Update timer without triggering setState to avoid rebuilding SelectionArea
        _updateElapsedTime();
      }
    });
  }

  void _pauseTimer() {
    if (!_isTimerPaused) {
      _stopwatch.stop();
      _isTimerPaused = true;
      // Also pause auto-scroll when timer is paused
      if (_isAutoScrolling) {
        _stopAutoScroll();
      }
      debugPrint("Timer paused");
    }
  }

  void _resumeTimer() {
    if (_isTimerPaused) {
      _stopwatch.start();
      _isTimerPaused = false;
      debugPrint("Timer resumed");
    }
  }

  void _updateElapsedTime() {
    final seconds = _stopwatch.elapsed.inSeconds;
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    final timeString =
        "${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";

    _elapsedNotifier.value = timeString;

    // Check if 80% of estimated reading time has elapsed
    final estimatedReadingSeconds = Utils.getEstimatedReadingSeconds(
      widget.kiranInfo.wordCount,
    );
    if (estimatedReadingSeconds > 0 && !_isFinishButtonEnabledNotifier.value) {
      final initialProgress = _initialReadingProgress / 100.0;
      if (initialProgress >= 0.8) {
        _isFinishButtonEnabledNotifier.value = true;
        // Only call setState when the button state actually changes
        if (!_isFinishButtonEnabled) {
          setState(() {
            _isFinishButtonEnabled = true;
          });
        }
      }
      final threshold = 0.8 - initialProgress;
      final requiredSeconds = (estimatedReadingSeconds * threshold).round();
      if (seconds >= requiredSeconds) {
        _isFinishButtonEnabledNotifier.value = true;
        // Only call setState when the button state actually changes
        if (!_isFinishButtonEnabled) {
          setState(() {
            _isFinishButtonEnabled = true;
          });
        }
      }
    }
  }

  void _setInitialScrollPosition() {
    if (mounted &&
        _scrollController.hasClients &&
        widget.kiranUserInfo.progress > 0) {
      _initialReadingProgress = widget.kiranUserInfo.progress;
      final maxScrollExtent = _scrollController.position.maxScrollExtent;
      final targetPosition =
          (widget.kiranUserInfo.progress / 100) * maxScrollExtent;

      // Animate to the saved progress position
      _scrollController.animateTo(
        targetPosition,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _initializeAutoScroll() {
    // Check if button should already be enabled (for cases where user has already spent time reading)
    final estimatedReadingSeconds = Utils.getEstimatedReadingSeconds(
      widget.kiranInfo.wordCount,
    );
    if (estimatedReadingSeconds > 0 &&
        _stopwatch.elapsed.inSeconds >=
            (estimatedReadingSeconds * 0.8).round()) {
      _isFinishButtonEnabled = true;
    }

    // Get content height and set up scroll listener
    if (_scrollController.hasClients) {
      _contentHeight = _scrollController.position.maxScrollExtent;

      // Set up scroll listener to update progress during manual scrolling
      _scrollController.addListener(() {
        if (mounted && _scrollController.hasClients && _contentHeight > 0) {
          final currentProgress =
              ((_scrollController.position.pixels / _contentHeight) * 100)
                  .round();
          if (currentProgress != widget.kiranUserInfo.progress) {
            widget.kiranUserInfo.progress = currentProgress;
            widget.kiranUserInfo.updatedAt = DateTime.now();
            // Update periodically, not on every scroll event for performance
            if (currentProgress % 5 == 0) {
              // Update every 5% progress
              //Utils.updateKiranUserInfo(widget.kiranUserInfo);
              _hasDataChanged = true;
            }
          }
        }
      });
    }
  }

  void _startAutoScroll() {
    final estimatedReadingSeconds = Utils.getEstimatedReadingSeconds(
      widget.kiranInfo.wordCount,
    );
    if (_contentHeight <= 0 || estimatedReadingSeconds <= 0) return;

    if (mounted) {
      setState(() {
        _isAutoScrolling = true;
      });

      // Track auto-scroll start analytics
      AnalyticsService().logAutoScroll(
        enabled: true,
        bookName: 'Sakshat Savita',
        chapterName: widget.kiranInfo.title,
      );
    }

    // Calculate scroll speed (pixels per second)
    final scrollSpeed = _contentHeight / estimatedReadingSeconds;

    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 50), (
      timer,
    ) {
      if (!mounted || !_isAutoScrolling || !_scrollController.hasClients) {
        timer.cancel();
        return;
      }

      final currentPosition = _scrollController.position.pixels;
      final newPosition =
          currentPosition + (scrollSpeed * 0.05); // 50ms intervals

      if (newPosition >= _contentHeight) {
        // Reached the end
        if (mounted && _scrollController.hasClients) {
          _scrollController.animateTo(
            _contentHeight,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          );
        }
        _stopAutoScroll();
      } else {
        if (mounted && _scrollController.hasClients) {
          _scrollController.jumpTo(newPosition);
        }
      }
    });
  }

  void closeSearch() {
    _isSearchMode = false;
    if (!_isSearchMode) {
      _searchController.clear();
      _searchMatches.clear();
      _currentMatchIndex = -1;
    }
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollDelayTimer?.cancel(); // Also cancel delay timer
    _autoScrollDelayTimer = null;
    _isAutoScrolling = false;

    debugPrint('Auto-scroll stopped');

    // Track auto-scroll stop analytics
    AnalyticsService().logAutoScroll(
      enabled: false,
      bookName: 'Sakshat Savita',
      chapterName: widget.kiranInfo.title,
    );

    if (mounted) {
      setState(() {
        // Update progress based on current scroll position
        if (_scrollController.hasClients && _contentHeight > 0) {
          widget.kiranUserInfo.progress =
              ((_scrollController.position.pixels / _contentHeight) * 100)
                  .round();
          widget.kiranUserInfo.updatedAt = DateTime.now();
          Utils.updateKiranUserInfo(widget.kiranUserInfo);
          _hasDataChanged = true;
        }
      });
    } else {
      // Still update progress even if not mounted, just don't call setState
      if (_scrollController.hasClients && _contentHeight > 0) {
        widget.kiranUserInfo.progress =
            ((_scrollController.position.pixels / _contentHeight) * 100)
                .round();
        widget.kiranUserInfo.updatedAt = DateTime.now();
        Utils.updateKiranUserInfo(widget.kiranUserInfo);
        _hasDataChanged = true;
      }
    }
  }

  void _toggleAutoScroll() {
    if (_isAutoScrolling) {
      _stopAutoScroll();
    } else if (_autoScrollDelayTimer != null) {
      // Cancel the delay timer if it's running
      _autoScrollDelayTimer?.cancel();
      _autoScrollDelayTimer = null;
      setState(() {}); // Update UI to remove pending state
      debugPrint('Auto-scroll delay cancelled');
    } else {
      // Start 5-second countdown when play button is pressed
      _startAutoScrollWithDelay();
    }
  }

  void _startAutoScrollWithDelay() {
    // Cancel any existing delay timer
    _autoScrollDelayTimer?.cancel();

    // Set to pending state
    setState(() {
      // This will trigger UI to show pending state
    });

    final currentPosition = _scrollController.position.pixels;
    if (currentPosition < 50) {
      // Start 5-second delay timer
      _autoScrollDelayTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) {
          _startAutoScroll();
        }
      });
    } else {
      // Start auto-scroll immediately
      _startAutoScroll();
    }

    debugPrint('Auto-scroll will start in 5 seconds...');
  }

  Future<Map<String, dynamic>> _loadKiranContent() async {
    final path =
        'assets/book/saxatsavita/${widget.partNumber}/kiran_${widget.kiranInfo.index}.json';
    final jsonString = await rootBundle.loadString(path);
    return json.decode(jsonString);
  }

  String getKiranContent(Map<String, dynamic> contentData) {
    final content =
        '<header>${AppLocalizations.of(context)!.kiran_start}</header>'
        '${contentData['main']['content'] ?? ''}'
        '<p><footer>${contentData['main']['footer'] ?? ''}</footer></p>';

    // Cache the content for search functionality
    _currentKiranContent = content;

    return content;
  }

  String _getCategoryBasedOnTime() {
    final now = DateTime.now();
    final hour = now.hour;

    if (hour >= 5 && hour < 12) {
      return 'Morning Reading';
    } else if (hour >= 12 && hour < 17) {
      return 'Afternoon Reading';
    } else if (hour >= 17 && hour < 21) {
      return 'Evening Reading';
    } else {
      return 'Night Reading';
    }
  }

  Future<void> _saveReadingHistory() async {
    if (_sessionStartTime == null) return;

    try {
      // Use stopwatch elapsed time which accounts for pause/resume cycles
      final durationSeconds = _stopwatch.elapsed.inSeconds;

      // Only save if session was longer than 10 seconds
      if (durationSeconds >= 10) {
        final readingHistory = ReadingHistory(
          category: _currentCategory,
          durationSeconds: durationSeconds,
          kiranIndex: widget.kiranInfo.index,
          partNumber: int.parse(widget.partNumber.replaceAll('part', '')),
          createdAt: _sessionStartTime!,
        );

        // Save to SharedPreferences or your preferred storage
        await _saveReadingHistoryToStorage(readingHistory);

        debugPrint('Reading history saved: ${readingHistory.toString()}');
      }
    } catch (e) {
      debugPrint('Error saving reading history: $e');
    }
    _sessionStartTime = null;
  }

  Future<void> _saveReadingHistoryToStorage(ReadingHistory history) async {
    try {
      await ReadingHistoryService.saveReadingHistory(history);
    } catch (e) {
      debugPrint('Error saving to storage: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) {
          Navigator.of(context).pop(_hasDataChanged);
        }
      },
      child: Scaffold(
        appBar: buildAppBar(
          context,
          title:
              '${AppLocalizations.of(context)!.kiran} ${widget.kiranInfo.number.replaceAll(".", "")}',
          actionItems: [ActionOptions.settings],
          extraActions: [
            IconButton(
              icon: Icon(
                widget.kiranUserInfo.isFavourite == 0
                    ? Icons.favorite_border
                    : Icons.favorite,
                color:
                    widget.kiranUserInfo.isFavourite == 0 ? null : Colors.pink,
              ),
              tooltip: AppLocalizations.of(context)!.information,
              onPressed: () {
                if (mounted) {
                  setState(() {
                    widget.kiranUserInfo.isFavourite =
                        widget.kiranUserInfo.isFavourite == 0 ? 1 : 0;
                    Utils.updateKiranUserInfo(widget.kiranUserInfo);
                    _hasDataChanged = true;
                  });
                }
              },
            ),
            IconButton(
              icon: Icon(
                Utils.isBookmarked(widget.kiranUserInfo)
                    ? Icons.bookmark
                    : Icons.bookmark_add,
                color:
                    Utils.isBookmarked(widget.kiranUserInfo)
                        ? Colors.amber
                        : null,
              ),
              tooltip: AppLocalizations.of(context)!.bookmark,
              onPressed: () {
                if (mounted) {
                  setState(() {
                    Utils.setBookmark(widget.kiranUserInfo);
                    _hasDataChanged = true;
                  });
                }
              },
            ),
            IconButton(
              icon: Icon(_isSearchMode ? Icons.close : Icons.search),
              tooltip:
                  _isSearchMode
                      ? AppLocalizations.of(context)!.close_search
                      : AppLocalizations.of(context)!.search_in_kiran,
              onPressed: () {
                setState(() {
                  _isSearchMode = !_isSearchMode;
                  if (!_isSearchMode) {
                    _searchController.clear();
                    _searchMatches.clear();
                    _currentMatchIndex = -1;
                    _resumeTimer();
                  } else {
                    // Auto-focus search input when opening
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _searchFocusNode.requestFocus();
                    });
                    _pauseTimer();
                    _stopAutoScroll();
                  }
                });
              },
            ),
          ],
          onSettingsPressed: () async {
            _pauseTimer();
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            );
            _resumeTimer();
          },
        ),
        body: Padding(
          padding: const EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            top: 0,
            bottom: 16.0,
          ),
          child: Column(
            children: [
              displayExtraInfos(context),
              // Search bar
              if (_isSearchMode) _buildSearchBar(),
              LinearProgressIndicator(
                value: widget.kiranUserInfo.progress.toDouble() / 100.0,
                minHeight: 3,
                borderRadius: BorderRadius.circular(3),
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                ),
              ),
              Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(20.0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4.0,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    '${widget.kiranInfo.number} ${widget.kiranInfo.title}',
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SafeArea(
                  child: FutureBuilder<Map<String, dynamic>>(
                    future: _futureKiranContent,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else if (!snapshot.hasData) {
                        return const Center(child: Text('No content found.'));
                      }
                      final contentData = snapshot.data!;

                      // Initialize auto-scroll and set initial position after content is loaded (only once)
                      if (!_isInitialized) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _initializeAutoScroll();
                          _setInitialScrollPosition();
                          _isInitialized = true;
                        });
                      }
                      return Scrollbar(
                        controller: _scrollController,
                        interactive: true,
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          child: Column(
                            children: [
                              CustomHtmlWidget(
                                htmlContent:
                                    _isSearchMode &&
                                            _searchController.text.isNotEmpty
                                        ? _getHighlightedContent(
                                          getKiranContent(contentData),
                                        )
                                        : getKiranContent(contentData),

                                onAddNote: (selectedText) async {
                                  _pauseTimer();
                                  await _openNoteEditor(
                                    selectedText: selectedText,
                                  );
                                  _resumeTimer();
                                },
                                onCreateQuoteImage: (selectedText) async {
                                  _pauseTimer();
                                  await _openQuoteEditor(
                                    selectedText: selectedText,
                                  );
                                  _resumeTimer();
                                },
                              ),
                              const SizedBox(height: 8.0),
                              Tooltip(
                                message:
                                    _isFinishButtonEnabled
                                        ? AppLocalizations.of(
                                          context,
                                        )!.kiran_read_finished
                                        : 'Complete 80% of estimated reading time to enable',
                                child: ElevatedButton.icon(
                                  onPressed:
                                      _isFinishButtonEnabled
                                          ? () async {
                                            // Store context before async operation
                                            final scaffoldMessenger =
                                                ScaffoldMessenger.of(context);
                                            final localizations =
                                                AppLocalizations.of(context)!;

                                            // Stop stopwatch to capture correct elapsed time
                                            _stopwatch.stop();
                                            _timer?.cancel();

                                            // Save reading history before finishing
                                            await _saveReadingHistory();

                                            // Track reading completion analytics
                                            final readingTimeSeconds =
                                                _stopwatch.elapsed.inSeconds;
                                            await AnalyticsService()
                                                .logCompleteReading(
                                                  bookName: 'Sakshat Savita',
                                                  chapterName:
                                                      widget.kiranInfo.title,
                                                  partName:
                                                      'Part ${widget.partNumber}',
                                                  readingTimeSeconds:
                                                      readingTimeSeconds,
                                                );

                                            if (mounted) {
                                              setState(() {
                                                widget.kiranUserInfo.progress =
                                                    0;
                                                widget
                                                    .kiranUserInfo
                                                    .readCount += 1;
                                                widget.kiranUserInfo.updatedAt =
                                                    DateTime.now();
                                                Utils.updateKiranUserInfo(
                                                  widget.kiranUserInfo,
                                                );
                                                _hasDataChanged = true;
                                                _pauseTimer();
                                                _isFinishButtonEnabled = false;
                                                _isFinishButtonEnabledNotifier
                                                    .value = false;
                                                // Stop auto-scroll if active
                                                if (_isAutoScrolling) {
                                                  _stopAutoScroll();
                                                }
                                                Utils.applyBookmarkToNextKiran(
                                                  widget.kiranUserInfo,
                                                );
                                              });

                                              scaffoldMessenger.showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    localizations
                                                        .kiran_read_finished,
                                                  ),
                                                  duration: const Duration(
                                                    seconds: 2,
                                                  ),
                                                ),
                                              );
                                            }
                                          }
                                          : null,
                                  icon: Icon(
                                    Icons.check_box,
                                    color:
                                        _isFinishButtonEnabled
                                            ? null
                                            : Colors.grey,
                                  ),
                                  label: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.kiran_read_finished,
                                      style: TextStyle(
                                        color:
                                            _isFinishButtonEnabled
                                                ? null
                                                : Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8.0),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            _pauseTimer();
            await _openNoteEditor();
            _resumeTimer();
          },
          child: Icon(Icons.note_add),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
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
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.search_hint,
              prefixIcon: Icon(
                Icons.search,
                color: Theme.of(context).colorScheme.primary,
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_searchController.text.isNotEmpty &&
                      _searchMatches.isNotEmpty) ...[
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_up),
                      onPressed: _currentMatchIndex > 0 ? _previousMatch : null,
                      tooltip: 'Previous match',
                    ),
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down),
                      onPressed:
                          _currentMatchIndex < _searchMatches.length - 1
                              ? _nextMatch
                              : null,
                      tooltip: 'Next match',
                    ),
                  ],
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _performSearch('');
                      },
                    ),
                ],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
            ),
            onChanged: _performSearch,
            textInputAction: TextInputAction.search,
          ),
          if (_searchController.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  _searchMatches.isEmpty
                      ? AppLocalizations.of(context)!.no_match_found
                      : '${_currentMatchIndex + 1} of ${_searchMatches.length}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _performSearch(String query) {
    query = query.trim();
    if (query.isEmpty) {
      setState(() {
        _searchMatches.clear();
        _currentMatchIndex = -1;
      });
      return;
    }

    // Get the plain text content from the HTML
    String plainContent = _currentKiranContent;
    if (plainContent.isEmpty) {
      // Extract from HTML if not already cached
      plainContent = _getPlainTextFromHtml(_currentKiranContent);
    }

    final List<int> matches = [];
    final lowerContent = plainContent.toLowerCase();
    final lowerQuery = query.toLowerCase();

    int index = lowerContent.indexOf(lowerQuery);
    while (index != -1) {
      matches.add(index);
      index = lowerContent.indexOf(lowerQuery, index + 1);
    }

    setState(() {
      _searchMatches = matches;
      _currentMatchIndex = matches.isNotEmpty ? 0 : -1;
    });
  }

  String _getPlainTextFromHtml(String html) {
    // Simple HTML tag removal - could be improved with proper HTML parsing
    return html.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  String _getHighlightedContent(String content) {
    if (_searchController.text.isEmpty || _searchMatches.isEmpty) {
      return content;
    }

    String highlighted = content;
    final query = _searchController.text.trim();
    int matchCounter = 0;

    // Use case-insensitive replacement with HTML highlighting
    highlighted = highlighted.replaceAllMapped(
      RegExp(RegExp.escape(query), caseSensitive: false),
      (match) {
        final isCurrentMatch = matchCounter == _currentMatchIndex;
        final matchId = 'search-match-$matchCounter';
        final highlightClass =
            isCurrentMatch ? 'current-highlight' : 'search-highlight';
        final backgroundColor = isCurrentMatch ? '#ff9800' : '#ffeb3b';

        matchCounter++;

        return '<span id="$matchId" class="$highlightClass" style="background-color: $backgroundColor; color: black; padding: 2px; border-radius: 2px;">${match.group(0)}</span>';
      },
    );

    return highlighted;
  }

  void _previousMatch() {
    if (_currentMatchIndex > 0) {
      // Provide haptic feedback
      HapticFeedback.selectionClick();

      setState(() {
        _currentMatchIndex--;
      });
      _scrollToMatch();
    }
  }

  void _nextMatch() {
    if (_currentMatchIndex < _searchMatches.length - 1) {
      // Provide haptic feedback
      HapticFeedback.selectionClick();

      setState(() {
        _currentMatchIndex++;
      });
      _scrollToMatch();
    }
  }

  void _scrollToMatch() {
    if (_searchMatches.isEmpty || _currentMatchIndex < 0) return;

    // First trigger a rebuild to update highlighting immediately
    setState(() {});

    // Then handle scrolling after the widget rebuilds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performScrollToMatch();
    });
  }

  void _performScrollToMatch() {
    if (!_scrollController.hasClients ||
        _searchMatches.isEmpty ||
        _currentMatchIndex < 0) {
      return;
    }

    try {
      // Get the position of the current match in the text
      final matchPosition = _searchMatches[_currentMatchIndex];
      final plainText = _getPlainTextFromHtml(_currentKiranContent);

      if (plainText.isEmpty || matchPosition >= plainText.length) return;

      // Calculate approximate scroll position based on text position
      final totalTextLength = plainText.length;
      final matchRatio = matchPosition / totalTextLength;

      // Get scroll constraints
      final maxScrollExtent = _scrollController.position.maxScrollExtent;
      final viewportHeight = _scrollController.position.viewportDimension;

      // Calculate target position - aim to put the match in the upper third of the viewport
      final targetScrollOffset =
          (maxScrollExtent * matchRatio) - (viewportHeight * 0.2);
      final clampedOffset = targetScrollOffset.clamp(0.0, maxScrollExtent);

      // Animate to the position
      _scrollController.animateTo(
        clampedOffset,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } catch (e) {
      debugPrint('Error scrolling to match: $e');
    }
  }

  Future<void> _openNoteEditor({String? selectedText}) async {
    debugPrint('Opening note editor with selected text: $selectedText');
    // Store context values before async operations
    final navigator = Navigator.of(context);
    final localizations = AppLocalizations.of(context)!;
    final kiranTitle =
        '${localizations.kiran} ${widget.kiranInfo.number.replaceAll(".", "")}';

    try {
      // Try to use the rich editor first
      final result = await navigator.push(
        MaterialPageRoute(
          builder:
              (_) => NoteEditorPage(
                kiranUserInfo: widget.kiranUserInfo,
                kiranTitle: kiranTitle,
                selectedText: selectedText,
              ),
        ),
      );

      // If notes were modified, update UI
      if (result == true && mounted) {
        setState(() {
          _hasDataChanged = true;
        });
      }
    } catch (e) {
      debugPrint('Error with rich editor, falling back to simple editor: $e');

      // Fallback to simple editor
      final result = await navigator.push(
        MaterialPageRoute(
          builder:
              (_) => SimpleNoteEditorPage(
                kiranUserInfo: widget.kiranUserInfo,
                kiranTitle: kiranTitle,
              ),
        ),
      );

      // If notes were modified, update UI
      if (result == true) {
        setState(() {
          _hasDataChanged = true;
        });
      }
    }
  }

  Future<void> _openQuoteEditor({String? selectedText}) async {
    debugPrint('Opening quote editor with selected text: $selectedText');
    // Store context values before async operations
    final navigator = Navigator.of(context);

    try {
      final InspirationalQuote quote = InspirationalQuote(
        quote: selectedText!,
        author: AppLocalizations.of(context)!.jogi_swami,
        kiranIndex: widget.kiranInfo.index,
        partNumber: int.parse(widget.partNumber.replaceAll('part', '')),
      );
      final result = await navigator.push(
        MaterialPageRoute(
          builder: (_) => QuotesImageGeneratorPage(quote: quote),
        ),
      );

      // If quotes were modified, update UI
      if (result == true && mounted) {
        setState(() {
          _hasDataChanged = true;
        });
      }
    } catch (e) {
      debugPrint('Error opening quote editor: $e');
      // Optionally show a snackbar or dialog to inform the user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(""), // localizations.error_occurred),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Container displayExtraInfos(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        //borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Estimated reading time
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 2.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timer, color: Colors.grey.withValues(alpha: 0.3)),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)!.time_to_read(
                      Utils.getEstimatedReadingTime(widget.kiranInfo.wordCount),
                    ),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall!.copyWith(fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          // Auto-scroll play/pause button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: IconButton(
              onPressed: () {
                closeSearch();
                _toggleAutoScroll();
              },
              icon: Icon(
                _isAutoScrolling
                    ? Icons.pause
                    : (_autoScrollDelayTimer != null
                        ? Icons.schedule
                        : Icons.play_arrow),
                color:
                    _isAutoScrolling
                        ? Colors.amber
                        : (_autoScrollDelayTimer != null
                            ? Colors.orange
                            : null),
              ),
              tooltip:
                  _isAutoScrolling
                      ? 'Pause Auto-scroll'
                      : (_autoScrollDelayTimer != null
                          ? 'Auto-scroll starting in 5 seconds...'
                          : 'Start Auto-scroll'),
              iconSize: 28,
            ),
          ),
          // Timer display
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isTimerPaused
                        ? Icons.pause_circle_outline
                        : Icons.av_timer_outlined,
                    size: 20,
                    color: _isTimerPaused ? Colors.orange : null,
                  ),
                  const SizedBox(width: 8),
                  ValueListenableBuilder<String>(
                    valueListenable: _elapsedNotifier,
                    builder: (context, elapsed, child) {
                      return Text(
                        elapsed,
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          fontSize: 13,
                          color: _isTimerPaused ? Colors.orange : null,
                        ),
                      );
                    },
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
