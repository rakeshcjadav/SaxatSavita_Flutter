import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:saxatsavita_flutter/components/appbar.dart';
import 'package:saxatsavita_flutter/components/custom_html_widget.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';
import 'package:saxatsavita_flutter/models/kiraninfo_model.dart';
import 'package:saxatsavita_flutter/models/kiranuserinfo_model.dart';
import 'package:saxatsavita_flutter/pages/settingspage.dart';
import 'package:saxatsavita_flutter/services/utils.dart';

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
  String _elapsed = "00:00";
  bool _isTimerPaused = false;

  // Auto-scroll variables
  bool _isAutoScrolling = false;
  Timer? _autoScrollTimer;
  double _contentHeight = 0;
  int _estimatedReadingSeconds = 0;
  bool _isInitialized = false;

  bool _hasDataChanged = false;
  bool _isFinishButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _futureKiranContent = _loadKiranContent();
    _stopwatch.start();

    // Add observer to detect app lifecycle changes
    WidgetsBinding.instance.addObserver(this);

    _startTimer();

    // Note: Initial scroll position and listener will be set after content loads

    // Timer is now handled in _startTimer() method
  }

  @override
  void dispose() {
    // Remove observer
    WidgetsBinding.instance.removeObserver(this);

    // Stop and cleanup timers
    _stopwatch.stop();
    _timer?.cancel();
    _timer = null;

    // Stop auto-scroll and cleanup
    _isAutoScrolling = false;
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;

    // Dispose scroll controller
    _scrollController.dispose();

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
        setState(() {
          _updateElapsedTime();
        });
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
    _elapsed =
        "${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";

    // Check if 80% of estimated reading time has elapsed
    if (_estimatedReadingSeconds > 0 && !_isFinishButtonEnabled) {
      final requiredSeconds = (_estimatedReadingSeconds * 0.8).round();
      if (seconds >= requiredSeconds) {
        setState(() {
          _isFinishButtonEnabled = true;
        });
      }
    }
  }

  String _getTimeUntilButtonEnabled() {
    if (_estimatedReadingSeconds <= 0) return '';

    final requiredSeconds = (_estimatedReadingSeconds * 0.8).round();
    final elapsedSeconds = _stopwatch.elapsed.inSeconds;
    final remainingSeconds = requiredSeconds - elapsedSeconds;

    if (remainingSeconds <= 0) return '';

    final minutes = remainingSeconds ~/ 60;
    final secs = remainingSeconds % 60;

    if (minutes > 0) {
      return 'Button available in ${minutes}m ${secs}s';
    } else {
      return 'Button available in ${secs}s';
    }
  }

  void _setInitialScrollPosition() {
    if (mounted &&
        _scrollController.hasClients &&
        widget.kiranUserInfo.progress > 0) {
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
    // Calculate estimated reading time in seconds
    _estimatedReadingSeconds = Utils.getEstimatedReadingSeconds(
      widget.kiranInfo.wordCount,
    );

    // Check if button should already be enabled (for cases where user has already spent time reading)
    if (_estimatedReadingSeconds > 0 &&
        _stopwatch.elapsed.inSeconds >=
            (_estimatedReadingSeconds * 0.8).round()) {
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
              Utils.updateKiranUserInfo(widget.kiranUserInfo);
              _hasDataChanged = true;
            }
          }
        }
      });
    }
  }

  void _startAutoScroll() {
    if (_contentHeight <= 0 || _estimatedReadingSeconds <= 0) return;

    if (mounted) {
      setState(() {
        _isAutoScrolling = true;
      });
    }

    // Calculate scroll speed (pixels per second)
    final scrollSpeed = _contentHeight / _estimatedReadingSeconds;

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

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _isAutoScrolling = false;

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
    } else {
      _startAutoScroll();
    }
  }

  Future<Map<String, dynamic>> _loadKiranContent() async {
    final path =
        'assets/book/saxatsavita/${widget.partNumber}/kiran_${widget.kiranInfo.index}.json';
    final jsonString = await rootBundle.loadString(path);
    return json.decode(jsonString);
  }

  String getKiranContent(Map<String, dynamic> contentData) {
    return '<header>${AppLocalizations.of(context)!.kiran_start}</header>'
        '${contentData['main']['content'] ?? ''}'
        '<p><footer>${contentData['main']['footer'] ?? ''}</footer></p>';
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
                    : Icons.bookmark_border,
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
                                htmlContent: getKiranContent(contentData),
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
                                          ? () {
                                            if (mounted) {
                                              setState(() {
                                                widget.kiranUserInfo.progress =
                                                    100;
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
                                              });
                                            }
                                            if (mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    AppLocalizations.of(
                                                      context,
                                                    )!.kiran_read_finished,
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
      ),
    );
  }

  Widget _showTimeWarning() {
    // Show remaining time until button is enabled
    if (!_isFinishButtonEnabled && _estimatedReadingSeconds > 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timer_outlined, size: 16, color: Colors.orange),
            const SizedBox(width: 4),
            Text(
              _getTimeUntilButtonEnabled(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.orange,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
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
              onPressed: _toggleAutoScroll,
              icon: Icon(
                _isAutoScrolling ? Icons.pause : Icons.play_arrow,
                color: _isAutoScrolling ? Colors.amber : null,
              ),
              tooltip:
                  _isAutoScrolling ? 'Pause Auto-scroll' : 'Start Auto-scroll',
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
                  Text(
                    _elapsed,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      fontSize: 13,
                      color: _isTimerPaused ? Colors.orange : null,
                    ),
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
