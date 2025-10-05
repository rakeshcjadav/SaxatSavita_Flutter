import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:saxatsavita_flutter/components/appbar.dart';
import 'package:saxatsavita_flutter/components/customHtmlWidget.dart';
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

  bool _hasFavoriteChanged = false;
  bool _hasBookmarkChanged = false;

  @override
  void initState() {
    super.initState();
    _futureKiranContent = _loadKiranContent();
    _stopwatch.start();

    // Add observer to detect app lifecycle changes
    WidgetsBinding.instance.addObserver(this);

    _startTimer();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        final seconds = _stopwatch.elapsed.inSeconds;
        final minutes = seconds ~/ 60;
        final secs = seconds % 60;
        _elapsed =
            "${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
      });
    });
  }

  @override
  void dispose() {
    // Remove observer
    WidgetsBinding.instance.removeObserver(this);
    _stopwatch.stop();
    _timer?.cancel();
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
          Navigator.of(context).pop(_hasFavoriteChanged || _hasBookmarkChanged);
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
                setState(() {
                  widget.kiranUserInfo.isFavourite =
                      widget.kiranUserInfo.isFavourite == 0 ? 1 : 0;
                  Utils.updateKiranUserInfo(widget.kiranUserInfo);
                  _hasFavoriteChanged = true;
                });
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
                setState(() {
                  Utils.setBookmark(widget.kiranUserInfo);
                  _hasBookmarkChanged = true;
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
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainer.withOpacity(1.0),
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
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 2.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.timer,
                            color: Colors.grey.withOpacity(0.3),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context)!.time_to_read(
                              Utils.getEstimatedReadingTime(
                                widget.kiranInfo.wordCount,
                              ),
                            ),
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall!.copyWith(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    // Add timer display here
                    Padding(
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
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall!.copyWith(
                              fontSize: 13,
                              color: _isTimerPaused ? Colors.orange : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainer.withOpacity(1.0),
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
}
