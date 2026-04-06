import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:saxatsavita_flutter/helpers/html_to_textspan.dart';
import 'package:saxatsavita_flutter/models/reading_event_model.dart';
import 'package:saxatsavita_flutter/services/kiranlistservice.dart';
import 'package:saxatsavita_flutter/services/kiranuser_service.dart';
import 'package:saxatsavita_flutter/services/reading_event_service.dart';
import 'package:saxatsavita_flutter/services/remote_config_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:saxatsavita_flutter/components/appbar.dart';
import 'package:saxatsavita_flutter/components/custom_html_widget.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';
import 'package:saxatsavita_flutter/models/appsettings.dart';
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
import 'package:saxatsavita_flutter/services/in_app_review_service.dart';

class KiranReadPage extends StatefulWidget {
  const KiranReadPage({
    super.key,
    required this.partNumber,
    required this.kiranInfo,
    required this.kiranUserInfo,
    this.searchQuery,
    this.readingMode = ReadingMode.reading,
    this.existingEvent,
  });
  final String partNumber;
  final KiranInfo kiranInfo;
  final KiranUserInfo kiranUserInfo;
  final String? searchQuery;
  final ReadingMode readingMode;
  final ReadingEvent? existingEvent;

  @override
  State<KiranReadPage> createState() => _KiranReadPageState();
}

class _KiranReadPageState extends State<KiranReadPage>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late Future<Map<String, dynamic>> _futureKiranContent;
  Map<String, dynamic>? _kiranContentData; // cached for AppBar info sheet
  final ScrollController _scrollController = ScrollController();

  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  bool _isTimerPaused = false;
  int _initialDurationOffset = 0; // For resumed events

  // ValueNotifiers to prevent widget rebuilds during timer updates
  final ValueNotifier<String> _elapsedNotifier = ValueNotifier<String>("00:00");

  // Auto-scroll variables
  bool _isAutoScrollEnabled = false;
  bool _isAutoScrolling = false;
  Timer? _autoScrollTimer;
  Timer? _autoScrollDelayTimer; // Timer for 5-second delay
  double _contentHeight = 0;
  bool _isInitialized = false;

  // TTS variables
  FlutterTts? _tts;
  bool _isTtsSpeaking = false;
  bool _isTtsPaused = false;
  List<String> _ttsChunks = [];
  int _currentTtsChunk = 0;
  bool _isTtsDrivingScroll = false; // true while TTS is actively driving scroll
  List<double> _ttsScrollTargets = []; // char-weighted scroll position per chunk

  bool _hasDataChanged = false;
  int _initialReadingProgress = 0;

  // Reading history tracking
  DateTime? _sessionStartTime;
  String _currentCategory = 'Reading Session';

  // Reading event tracking
  ReadingEvent? _currentReadingEvent;
  bool _isReadingMode = true; // vs browse mode

  // Search functionality state
  bool _isSearchMode = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _currentKiranContent = '';
  List<int> _searchMatches = [];
  int _currentMatchIndex = -1;

  // Tab controller for the optional TabBar meta layout
  TabController? _metaTabController;

  @override
  void initState() {
    super.initState();
    _futureKiranContent = _loadKiranContent();

    // Initialize tab controller when using the TabBar meta layout
    if (RemoteConfigService().kiranMetaEnabled &&
        RemoteConfigService().kiranMetaAsTabBar) {
      _metaTabController = TabController(length: 2, vsync: this);
    }

    // Set reading mode
    _isReadingMode = widget.readingMode == ReadingMode.reading;

    // Only start tracking in reading mode
    if (_isReadingMode) {
      // If resuming an existing event, track the initial duration offset
      if (widget.existingEvent != null) {
        _initialDurationOffset = widget.existingEvent!.durationSeconds;
      }

      _stopwatch.start();
      _sessionStartTime = DateTime.now();
      _currentCategory = _getCategoryBasedOnTime();
      _startTimer();

      // Initialize or resume reading event
      _initializeReadingEvent();
    }

    // Add observer to detect app lifecycle changes
    WidgetsBinding.instance.addObserver(this);

    // Listen to app settings changes
    appSettingsNotifier.addListener(_updateWakelock);

    // Enable wakelock if setting is turned on
    _updateWakelock();

    // Track analytics for reading session start
    AnalyticsService().logScreenView(screenName: 'reading_page');
    AnalyticsService().logStartReading(
      bookName: 'Sakshat Savita',
      chapterName: widget.kiranInfo.title,
      partName: 'Part ${widget.partNumber}',
    );

    // If searchQuery is provided, open search mode and perform search
    if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
      searchKiranContent(widget.searchQuery!);
    }
  }

  Future<void> searchKiranContent(String query) async {
    await _futureKiranContent.then((contentData) {
      if (mounted) {
        setState(() {
          getKiranContent(contentData);
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _isSearchMode = true;
        _searchController.text = widget.searchQuery!;
        _performSearch(widget.searchQuery!);
        _pauseTimer();
        _performScrollToMatch();
      });
    });
  }

  @override
  void dispose() {
    // Stop stopwatch first to capture correct elapsed time
    _stopwatch.stop();

    _saveReadingEvent();
    // Note: We DO NOT save reading history here automatically
    // History should only be created when user explicitly finishes reading
    // This prevents cluttering history with incomplete sessions

    // Disable wakelock when leaving the page
    WakelockPlus.disable();

    // Remove listeners
    appSettingsNotifier.removeListener(_updateWakelock);

    // Remove observer
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _timer = null;

    // Stop auto-scroll and cleanup
    _isAutoScrollEnabled = false;
    _isAutoScrolling = false;
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
    _autoScrollDelayTimer?.cancel();
    _autoScrollDelayTimer = null;

    // Dispose scroll controller
    _scrollController.dispose();

    // Dispose ValueNotifiers
    _elapsedNotifier.dispose();

    // Dispose search controllers
    _searchController.dispose();
    _searchFocusNode.dispose();

    // Dispose tab controller if used
    _metaTabController?.dispose();

    // Stop and dispose TTS
    _tts?.stop();
    _tts = null;

    super.dispose();
  }

  Future<void> _saveReadingEvent() async {
    // Save final reading event state before exit (in reading mode only)
    // This preserves the event for resume capability
    // Note: History is ONLY created when user explicitly finishes reading (presses finish button)
    if (_isReadingMode && _currentReadingEvent != null) {
      _currentReadingEvent = _currentReadingEvent!.copyWith(
        currentProgress: widget.kiranUserInfo.progress,
        durationSeconds: _stopwatch.elapsed.inSeconds + _initialDurationOffset,
        lastScrollPosition:
            _scrollController.hasClients ? _scrollController.offset : null,
        lastUpdatedAt: DateTime.now(),
      );
      // Fire and forget - don't await in dispose
      await ReadingEventService.saveReadingEvent(_currentReadingEvent!);
    }
    /*
    // Also update and save the kiran user info progress
    if (_scrollController.hasClients && _contentHeight > 0) {
      widget.kiranUserInfo.progress =
          ((_scrollController.position.pixels / _contentHeight) * 100).round();
      widget.kiranUserInfo.updatedAt = DateTime.now();
      Utils.updateKiranUserInfo(widget.kiranUserInfo);
    }*/
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
    // Add initial offset for resumed events
    final seconds = _stopwatch.elapsed.inSeconds + _initialDurationOffset;
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    final timeString =
        "${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";

    _elapsedNotifier.value = timeString;

    // No finish-button gating — button will be enabled always.
  }

  void _updateWakelock() {
    if (appSettingsNotifier.value.keepScreenOn) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }
  }

  void _setInitialScrollPosition() {
    if (mounted &&
        _scrollController.hasClients &&
        widget.kiranUserInfo.progress > 0) {
      _initialReadingProgress = 0;
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
    // No finish-button gating — leave button enabled always.

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

            if (_isReadingMode && _currentReadingEvent != null) {
              _currentReadingEvent = _currentReadingEvent!.copyWith(
                currentProgress: currentProgress,
                durationSeconds:
                    _stopwatch.elapsed.inSeconds + _initialDurationOffset,
                lastUpdatedAt: DateTime.now(),
              );
            }

            // Update periodically, not on every scroll event for performance
            if (currentProgress % 5 == 0) {
              // Update every 5% progress
              //Utils.updateKiranUserInfo(widget.kiranUserInfo);
              _hasDataChanged = true;
              // Reading event will be updated on dispose
            }
          }
        }
      });
    }
  }

  // ── TTS ──────────────────────────────────────────────────────────────────

  Future<void> _initTts() async {
    _tts = FlutterTts();
    final lang = appSettingsNotifier.value.language == 'gu' ? 'gu-IN' : 'en-US';
    await _tts!.setLanguage(lang);
    // Apply saved voice if set
    final savedVoice = appSettingsNotifier.value.ttsVoice;
    if (savedVoice != null && savedVoice.contains('|')) {
      final parts = savedVoice.split('|');
      await _tts!.setVoice({'name': parts[0], 'locale': parts[1]});
    }
    await _tts!.setSpeechRate(appSettingsNotifier.value.ttsSpeechRate);
    await _tts!.setVolume(1.0);
    await _tts!.setPitch(1.0);
    _tts!.setCompletionHandler(() {
      _currentTtsChunk++;
      if (_currentTtsChunk < _ttsChunks.length) {
        // Brief pause between sentences for more natural-sounding speech
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && _isTtsSpeaking && !_isTtsPaused) {
            _speakCurrentChunk();
          }
        });
      } else {
        _isTtsDrivingScroll = false;
        _pauseTimer();
        if (mounted) {
          setState(() {
            _isTtsSpeaking = false;
            _isTtsPaused = false;
            _currentTtsChunk = 0;
          });
        }
      }
    });
    _tts!.setErrorHandler((msg) {
      debugPrint('TTS error: $msg');
      if (mounted) {
        setState(() {
          _isTtsSpeaking = false;
          _isTtsPaused = false;
        });
      }
    });
  }

  // ── Gujarati TTS text normalization ──────────────────────────────────────

  static const _gujaratiDigits = {
    '૦': 0, '૧': 1, '૨': 2, '૩': 3, '૪': 4,
    '૫': 5, '૬': 6, '૭': 7, '૮': 8, '૯': 9,
    // Letter lookalikes commonly used as digits in Gujarati manuscripts
    'ર': 2, // GUJARATI LETTER RA (U+0AB0) written in place of digit ૨
    'પ': 5, // GUJARATI LETTER PA (U+0AAA) written in place of digit ૫
  };

  /// Converts a string of Gujarati (or ASCII) digits to an integer.
  static int _parseGujaratiInt(String s) {
    var result = 0;
    for (final ch in s.runes.map(String.fromCharCode)) {
      final d = _gujaratiDigits[ch] ?? int.tryParse(ch);
      if (d != null) result = result * 10 + d;
    }
    return result;
  }

  static const _ones = [
    '',
    'એક',
    'બે',
    'ત્રણ',
    'ચાર',
    'પાંચ',
    'છ',
    'સાત',
    'આઠ',
    'નવ',
    'દસ',
    'અગિયાર',
    'બાર',
    'તેર',
    'ચૌદ',
    'પંદર',
    'સોળ',
    'સત્તર',
    'અઢાર',
    'ઓગણીસ',
    'વીસ',
    'એકવીસ',
    'બાવીસ',
    'તેવીસ',
    'ચોવીસ',
    'પચ્ચીસ',
    'છવ્વીસ',
    'સત્તાવીસ',
    'અઠ્ઠાવીસ',
    'ઓગણત્રીસ',
    'ત્રીસ',
    'એકત્રીસ',
    'બત્રીસ',
    'તેત્રીસ',
    'ચોત્રીસ',
    'પાંત્રીસ',
    'છત્રીસ',
    'સાડત્રીસ',
    'અડત્રીસ',
    'ઓગણચાળીસ',
    'ચાળીસ',
    'એકતાળીસ',
    'બેતાળીસ',
    'તેતાળીસ',
    'ચુમ્માળીસ',
    'પિસ્તાળીસ',
    'છેતાળીસ',
    'સુડતાળીસ',
    'અડતાળીસ',
    'ઓગણપચાસ',
    'પચાસ',
    'એકાવન',
    'બાવન',
    'ત્રેપન',
    'ચોપન',
    'પંચાવન',
    'છપ્પન',
    'સત્તાવન',
    'અઠ્ઠાવન',
    'ઓગણસાઠ',
    'સાઠ',
    'એકસઠ',
    'બાસઠ',
    'ત્રેસઠ',
    'ચોસઠ',
    'પાંસઠ',
    'છાસઠ',
    'સડસઠ',
    'અડસઠ',
    'ઓગણસિત્તેર',
    'સિત્તેર',
    'એકોત્તેર',
    'બોત્તેર',
    'તોત્તેર',
    'ચુમ્મોત્તેર',
    'પંચોત્તેર',
    'છોત્તેર',
    'સત્ત્યોત્તેર',
    'અઠ્ઠ્યોત્તેર',
    'ઓગણએંસી',
    'એંસી',
    'એક્યાસી',
    'બ્યાસી',
    'ત્ર્યાસી',
    'ચોર્યાસી',
    'પંચ્યાસી',
    'છ્યાસી',
    'સત્યાસી',
    'અઠ્ઠ્યાસી',
    'નેવ્યાસી',
    'નેવું',
    'એકાણું',
    'બાણું',
    'ત્રાણું',
    'ચોર્યાણું',
    'પંચાણું',
    'છ્યાણું',
    'સત્તાણું',
    'અઠ્ઠ્યાણું',
    'નવ્વાણું',
    'સો',
  ];

  static const _months = {
    1: 'જાન્યુઆરી',
    2: 'ફેબ્રુઆરી',
    3: 'માર્ચ',
    4: 'એપ્રિલ',
    5: 'મે',
    6: 'જૂન',
    7: 'જુલાઈ',
    8: 'ઓગસ્ટ',
    9: 'સપ્ટેમ્બર',
    10: 'ઓક્ટોબર',
    11: 'નવેમ્બર',
    12: 'ડિસેમ્બર',
  };

  /// Converts an integer 1–99 to its Gujarati spoken form.
  static String _numberToGujarati(int n) {
    if (n <= 0) return '';
    if (n < _ones.length) return _ones[n];
    if (n < 200) return 'એકસો ${_ones[n - 100]}'.trim();
    return n.toString(); // fallback for large numbers
  }

  /// Converts a number to its Gujarati ordinal form (1st, 2nd, …).
  static String _ordinalGujarati(int n) {
    const ordinals = {
      1: 'પ્રથમ',
      2: 'બીજું',
      3: 'ત્રીજું',
      4: 'ચોથું',
      5: 'પાંચમું',
      6: 'છઠ્ઠું',
      7: 'સાતમું',
      8: 'આઠમું',
      9: 'નવમું',
      10: 'દસમું',
      11: 'અગિયારમું',
      12: 'બારમું',
      13: 'તેરમું',
      14: 'ચૌદમું',
      15: 'પંદરમું',
    };
    if (ordinals.containsKey(n)) return ordinals[n]!;
    return '${_numberToGujarati(n)}મું';
  }

  /// Converts a 2-digit year (00–99) to a Gujarati century spoken form.
  /// e.g. 75 → "ઓગણીસો પંચોત્તેર"  (1975),  05 → "બે હજાર પાંચ" (2005)
  static String _yearToGujarati(int yy) {
    if (yy >= 0 && yy <= 30) {
      // Assume 21st century: 2000–2030
      return yy == 0 ? 'બે હજાર' : 'બે હજાર ${_numberToGujarati(yy)}';
    }
    // Assume 20th century: 1931–1999
    return 'ઓગણીસો ${_numberToGujarati(yy)}';
  }

  /// Converts a full 4-digit year to its Gujarati spoken form.
  /// 2000 → "બે હજાર", 2036 → "બે હજાર છત્રીસ", 1980 → "ઓગણીસસો એંસી"
  static String _fullYearToGujarati(int yr) {
    if (yr >= 2000 && yr < 2100) {
      final r = yr - 2000;
      return r == 0 ? 'બે હજાર' : 'બે હજાર ${_numberToGujarati(r)}';
    }
    // General: e.g. 1980 → ઓગણીસસો (19) + એંસી (80)
    final hundreds = yr ~/ 100;
    final remainder = yr % 100;
    final h = _numberToGujarati(hundreds);
    final r = _numberToGujarati(remainder);
    return r.isEmpty ? '${h}સો' : '${h}સો $r';
  }

  /// Normalizes Gujarati text for more natural TTS output.
  static String _normalizeForTts(String text) {
    var t = text;

    // Vachanamrut parenthetical references: (લોયા ૬) → વચનામૃત લોયા નું છઠ્ઠું
    // Formats seen: (LOCATION NUMBER) and (LOCATIONનું NUMBER)
    // Location words used across all kiran texts:
    const vachanamrutLocations = {
      'પ્રથમ': 'ગઢડા પ્રથમ',
      'પ્રથમનું': 'ગઢડા પ્રથમ',
      'મધ્ય': 'ગઢડા મધ્ય',
      'મધ્યનું': 'ગઢડા મધ્ય',
      'અંત્ય': 'ગઢડા અંત્ય',
      'અંત્યનું': 'ગઢડા અંત્ય',
      'છેલ્લા': 'ગઢડા અંત્ય',
      'છેલ્લાનું': 'ગઢડા અંત્ય',
      'સારંગપુર': 'સારંગપુર',
      'સારંગપુરનું': 'સારંગપુર',
      'કારિયાણી': 'કારિયાણી',
      'કારિયાણીનું': 'કારિયાણી',
      'લોયા': 'લોયા',
      'લોયાનું': 'લોયા',
      'પંચાળા': 'પંચાળા',
      'પંચાળાનું': 'પંચાળા',
      'વરતાલ': 'વરતાલ',
      'વરતાલનું': 'વરતાલ',
      'અમદાવાદ': 'અમદાવાદ',
      'અમદાવાદનું': 'અમદાવાદ',
    };
    t = t.replaceAllMapped(
      RegExp(r'\(([\u0A80-\u0AFF]+)\s+([\u0AE6-\u0AEF\u0AB0\u0AAA\d]{1,3})\)'),
      (m) {
        final word = m.group(1)!;
        final location = vachanamrutLocations[word];
        if (location == null) return m.group(0)!; // not a vachanamrut ref
        final n = _parseGujaratiInt(m.group(2)!);
        return 'વચનામૃત $location નું ${_ordinalGujarati(n)}.';
      },
    );

    // Expand common abbreviations before anything else
    t = t.replaceAll(RegExp(r'પૂ\.'), 'પૂજ્ય');
    t = t.replaceAll(RegExp(r'ગુ\.'), 'ગુણાતીતાનંદ');
    t = t.replaceAll(RegExp(r'તા\.'), 'તારીખ');
    t = t.replaceAll(RegExp(r'સં\.'), 'સંવત');
    t = t.replaceAll(RegExp(r'સંવત્\u200C'), 'સંવત'); // virama + ZWJ
    t = t.replaceAll(RegExp(r'ઈ\.સ\.'), 'ઈસ્વી સન');
    t = t.replaceAll(RegExp(r'વ\.'), 'વર્ષ');

    // Tithi (lunar day) names: સુદ/સુદિ/વદ/વદિ followed by a number
    // e.g. "વદિ-ર" → "વદિ બીજ", "સુદિ-૧૦" → "સુદિ દસમ"
    const tithiNames = {
      1: 'એકમ',
      2: 'બીજ',
      3: 'ત્રીજ',
      4: 'ચોથ',
      5: 'પાંચમ',
      6: 'છઠ',
      7: 'સાતમ',
      8: 'આઠમ',
      9: 'નોમ',
      10: 'દસમ',
      11: 'અગિયારસ',
      12: 'બારસ',
      13: 'તેરસ',
      14: 'ચૌદસ',
      15: 'પૂનમ',
    };
    t = t.replaceAllMapped(
      RegExp(r'(સુદ|સુદિ|વદ|વદિ)[-‐\s]+([\u0AE6-\u0AEF\u0AB0\u0AAA\d]{1,2})'),
      (m) {
        final n = _parseGujaratiInt(m.group(2)!);
        final name = tithiNames[n] ?? _numberToGujarati(n);
        return '${m.group(1)} $name';
      },
    );

    // Samvat / year number after "સંવત": e.g. "સંવત ર૦૩૬ના" → "સંવત બે હજાર છત્રીસ ના"
    // Must run before the date pattern. Matches 3–4 digit-like chars (including ર/પ lookalikes).
    // Gujarati digit + letter lookalike chars: \u0AE6-\u0AEF (digits), \u0AB0 (ર=2), \u0AAA (પ=5)
    t = t.replaceAllMapped(
      RegExp(
        r'(સંવત)\s+([\u0AE6-\u0AEF\u0AB0][\u0AE6-\u0AEF\u0AB0\u0AAA]{2,3})',
      ),
      (m) {
        final yr = _parseGujaratiInt(m.group(2)!);
        return '${m.group(1)} ${_fullYearToGujarati(yr)}';
      },
    );

    // Gujarati date pattern: DD-MM-YY or DD-MM-YYYY
    // Also matches letter lookalikes ર (U+0AB0) and પ (U+0AAA) used as digits in manuscripts
    final datePattern = RegExp(
      r'([\u0AE6-\u0AEF\d\u0AB0\u0AAA]{1,2})-([\u0AE6-\u0AEF\d\u0AB0\u0AAA]{1,2})-([\u0AE6-\u0AEF\d\u0AB0\u0AAA]{2,4})',
    );
    t = t.replaceAllMapped(datePattern, (m) {
      final day = _parseGujaratiInt(m.group(1)!);
      final month = _parseGujaratiInt(m.group(2)!);
      final rawYear = _parseGujaratiInt(m.group(3)!);
      final monthName = _months[month] ?? _numberToGujarati(month);
      final dayWord = _numberToGujarati(day);
      final yearWord =
          m.group(3)!.length <= 2
              ? _yearToGujarati(rawYear)
              : _fullYearToGujarati(rawYear);
      return '$dayWord, $monthName, $yearWord';
    });

    // Standalone Gujarati year like ૨૦૩૧ (4-digit) surrounded by whitespace
    // Also handles ર as first digit (e.g. ર૦૩૬)
    final yearPattern = RegExp(
      r'(?<!\S)([\u0AE6-\u0AEF\u0AB0][\u0AE6-\u0AEF\u0AAA\u0AB0]{3})(?!\S)',
    );
    t = t.replaceAllMapped(yearPattern, (m) {
      final yr = _parseGujaratiInt(m.group(1)!);
      return _fullYearToGujarati(yr);
    });

    return t;
  }

  List<String> _prepareTtsChunks(String html) {
    final withNewlines = html
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</header>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    // Strip all remaining HTML tags
    final stripped = withNewlines.replaceAll(RegExp(r'<[^>]*>'), '');
    // Decode common HTML entities to natural text or whitespace
    final decoded =
        stripped
            .replaceAll('&nbsp;', ' ')
            .replaceAll('&zwj;', '')
            .replaceAll('&zwnj;', '')
            .replaceAll('&shy;', '')
            .replaceAll('&#x200B;', '') // zero-width space
            .replaceAll('&#8203;', '') // zero-width space (decimal)
            .replaceAll('&#160;', ' ') // non-breaking space (decimal)
            .replaceAll('&amp;', '&')
            .replaceAll('&lt;', '<')
            .replaceAll('&gt;', '>')
            .replaceAll('&quot;', '"')
            .replaceAll('&apos;', "'")
            // Collapse any leftover numeric/named entities to empty
            .replaceAll(RegExp(r'&[a-zA-Z0-9#]+;'), '')
            // Collapse multiple spaces/nbsp into one
            .replaceAll(RegExp(r'[ \t]+'), ' ')
            .trim();
    // Apply Gujarati text normalization (abbreviations, dates, numbers)
    final normalized = _normalizeForTts(decoded);
    // Split into sentence-level chunks for more natural pauses.
    // Split on sentence-ending punctuation followed by whitespace or end-of-string.
    // Gujarati danda (।), ?, ! are strong boundaries.
    // Period (.) only when followed by a space + non-digit (to preserve dates/abbreviations).
    final sentences = <String>[];
    for (final paragraph in normalized.split(RegExp(r'\n+'))) {
      final trimmed = paragraph.trim();
      if (trimmed.isEmpty) continue;
      // Split on: danda, ?, ! — or period followed by space+non-digit
      final parts = trimmed
          .splitMapJoin(
            RegExp(r'(?<=[।?!])|(?<=\.(?=\s+[^\d]))'),
            onNonMatch: (s) => s,
            onMatch: (_) => '\n',
          )
          .split('\n');
      for (final part in parts) {
        final s = part.trim();
        if (s.isNotEmpty) sentences.add(s);
      }
    }
    return sentences;
  }

  /// Rebuilds char-weighted scroll targets whenever chunks or scroll extent change.
  /// Targets point to the START of each chunk (not the end), offset upward by
  /// two line-heights so the spoken sentence is near the top of the viewport.
  /// The line-height offset scales with the user's font size so larger fonts
  /// don't push the active sentence off-screen.
  void _recomputeTtsScrollTargets() {
    if (_ttsChunks.isEmpty || !_scrollController.hasClients) return;
    final maxExtent = _scrollController.position.maxScrollExtent;
    if (maxExtent <= 0) return;
    final totalChars = _ttsChunks.fold(0, (s, c) => s + c.length);
    if (totalChars == 0) return;
    // One line-height ≈ fontSize × 1.5 (Flutter default line spacing).
    final lineHeight = appSettingsNotifier.value.fontSize * 1.5;
    var cumulativeBefore = 0;
    _ttsScrollTargets = List.generate(_ttsChunks.length, (i) {
      // Scroll to the START of this chunk, then back up by 2 line-heights for
      // visual breathing room above the sentence being spoken.
      final startPos = (cumulativeBefore / totalChars) * maxExtent;
      cumulativeBefore += _ttsChunks[i].length;
      return (startPos - lineHeight * 2.0).clamp(0.0, maxExtent);
    });
  }

  void _speakCurrentChunk() {
    if (_currentTtsChunk < _ttsChunks.length) {
      _tts?.speak(_ttsChunks[_currentTtsChunk]);
      if (_isTtsDrivingScroll && _scrollController.hasClients) {
        // Lazily build targets on first use or if not yet populated.
        if (_ttsScrollTargets.length != _ttsChunks.length) {
          _recomputeTtsScrollTargets();
        }
        if (_ttsScrollTargets.isNotEmpty) {
          final target = _ttsScrollTargets[_currentTtsChunk];
          // Estimate how long this chunk will take to speak.
          // flutter_tts rate 0.5 ≈ normal speed (~22 Gujarati chars/sec).
          final chunkChars = _ttsChunks[_currentTtsChunk].length;
          final rate = appSettingsNotifier.value.ttsSpeechRate.clamp(0.1, 1.0);
          final charsPerSec = 22.0 * (rate / 0.5);
          final estimatedMs = ((chunkChars / charsPerSec) * 1000).round();
          final duration = Duration(
            milliseconds: estimatedMs.clamp(300, 12000),
          );
          _scrollController.animateTo(
            target,
            duration: duration,
            curve: Curves.linear,
          );
        }
      }
    }
  }

  Future<void> _startTts() async {
    if (_tts == null) await _initTts();
    if (_isAutoScrolling) _stopAutoScroll();
    _isTtsDrivingScroll = true;
    if (_kiranContentData != null && _ttsChunks.isEmpty) {
      _ttsChunks = _prepareTtsChunks(getKiranContent(_kiranContentData!));
      // Prepend an intro chunk: "સાક્ષાત્ સવિતા, ભાગ <part>, કિરણ <number>, <title>"
      final partNum =
          int.tryParse(widget.partNumber.replaceAll('part', '')) ?? 1;
      final partWord = _numberToGujarati(partNum);
      final kiranNumber = widget.kiranInfo.number.replaceAll('.', '').trim();
      final kiranTitle = widget.kiranInfo.title.trim();
      final intro =
          'સાક્ષાત્ સવિતા. ભાગ $partWord. કિરણ $kiranNumber. $kiranTitle.';
      _ttsChunks = [intro, ..._ttsChunks];
    }
    if (_ttsChunks.isEmpty) return;
    _ttsScrollTargets = []; // will be (re)computed on first _speakCurrentChunk
    await _tts!.setSpeechRate(appSettingsNotifier.value.ttsSpeechRate);
    await _tts!.setLanguage(
      appSettingsNotifier.value.language == 'gu' ? 'gu-IN' : 'en-US',
    );
    // Re-apply voice preference on every play (user may have changed it)
    final savedVoice = appSettingsNotifier.value.ttsVoice;
    if (savedVoice != null && savedVoice.contains('|')) {
      final parts = savedVoice.split('|');
      await _tts!.setVoice({'name': parts[0], 'locale': parts[1]});
    }
    if (mounted)
      setState(() {
        _isTtsSpeaking = true;
        _isTtsPaused = false;
      });
    _speakCurrentChunk();
  }

  Future<void> _stopTts() async {
    await _tts?.stop();
    _isTtsDrivingScroll = false;
    _ttsScrollTargets = [];
    if (mounted) {
      setState(() {
        _isTtsSpeaking = false;
        _isTtsPaused = false;
        _currentTtsChunk = 0;
      });
    }
  }

  Future<void> _pauseOrResumeTts() async {
    if (_isTtsPaused) {
      _isTtsDrivingScroll = true;
      await _tts?.setSpeechRate(appSettingsNotifier.value.ttsSpeechRate);
      await _tts?.speak(_ttsChunks[_currentTtsChunk]);
      if (mounted)
        setState(() {
          _isTtsPaused = false;
        });
    } else {
      _isTtsDrivingScroll = false;
      await _tts?.pause();
      if (mounted)
        setState(() {
          _isTtsPaused = true;
        });
    }
  }

  // ─────────────────────────────────────────────────────────────────────────

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
        _isAutoScrollEnabled = false;
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
    _isAutoScrollEnabled = !_isAutoScrollEnabled;
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
        '<p><footer>${contentData['main']['footer'] ?? ''}</footer></p>'
        '<header>${AppLocalizations.of(context)!.kiran_end}</header>';

    // Cache the content for search functionality
    _currentKiranContent = _getPlainTextFromHtml(content);

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

  /// Initialize or resume reading event
  Future<void> _initializeReadingEvent() async {
    try {
      if (widget.existingEvent != null) {
        // Resume existing event
        _currentReadingEvent = widget.existingEvent;
        _initialReadingProgress = _currentReadingEvent!.currentProgress;

        // Initial duration offset is already set in initState
        // Update the timer display immediately
        _updateElapsedTime();

        debugPrint(
          '📖 Resumed reading event: ${_currentReadingEvent!.id} with ${_currentReadingEvent!.formattedDuration}',
        );
      } else {
        // Create new event
        final deviceId = await ReadingEventService.getDeviceId();
        _currentReadingEvent = ReadingEvent.create(
          kiranIndex: widget.kiranInfo.index,
          partNumber: int.parse(widget.partNumber.replaceAll('part', '')),
          deviceId: deviceId,
          category: _currentCategory,
        );
        await ReadingEventService.saveReadingEvent(_currentReadingEvent!);
        debugPrint('📝 Created new reading event: ${_currentReadingEvent!.id}');
      }
    } catch (e) {
      debugPrint('❌ Error initializing reading event: $e');
    }
  }

  /// Update reading event with current progress
  Future<void> _updateReadingEvent() async {
    if (!_isReadingMode || _currentReadingEvent == null) return;

    try {
      _currentReadingEvent = _currentReadingEvent!.copyWith(
        currentProgress: widget.kiranUserInfo.progress,
        durationSeconds: _stopwatch.elapsed.inSeconds + _initialDurationOffset,
        lastScrollPosition:
            _scrollController.hasClients ? _scrollController.offset : null,
        lastUpdatedAt: DateTime.now(),
      );
      await ReadingEventService.saveReadingEvent(_currentReadingEvent!);
      debugPrint(
        '💾 Reading event updated: ${_currentReadingEvent!.currentProgress}%',
      );
    } catch (e) {
      debugPrint('❌ Error updating reading event: $e');
    }
  }

  Future<void> _saveReadingHistory() async {
    if (_sessionStartTime == null) return;

    try {
      // Use stopwatch elapsed time which accounts for pause/resume cycles
      final durationSeconds =
          _stopwatch.elapsed.inSeconds + _initialDurationOffset;

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
            if (RemoteConfigService().kiranMetaEnabled &&
                !RemoteConfigService().kiranMetaAsTabBar)
              IconButton(
                icon: const Icon(Icons.info_outline),
                tooltip: AppLocalizations.of(context)!.kiran_info,
                onPressed: () {
                  if (_kiranContentData != null) {
                    _showKiranInfoSheet(context, _kiranContentData!);
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
            /*IconButton(
              icon: Icon(
                _useCustomHtmlWidget ? Icons.view_agenda : Icons.text_fields,
              ),
              tooltip:
                  _useCustomHtmlWidget
                      ? 'Using CustomHtmlWidget'
                      : 'Using HtmlToTextSpan',
              onPressed: () {
                setState(() {
                  _useCustomHtmlWidget = !_useCustomHtmlWidget;
                });
              },
            ),*/
          ],
          onSettingsPressed: () async {
            _pauseTimer();
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            );
            _resumeTimer();
          },
          bottom:
              RemoteConfigService().kiranMetaEnabled &&
                      RemoteConfigService().kiranMetaAsTabBar
                  ? TabBar(
                    controller: _metaTabController,
                    tabs: [
                      Tab(text: AppLocalizations.of(context)!.kiran),
                      Tab(text: AppLocalizations.of(context)!.kiran_summary),
                    ],
                  )
                  : null,
        ),
        body:
            RemoteConfigService().kiranMetaEnabled &&
                    RemoteConfigService().kiranMetaAsTabBar
                ? TabBarView(
                  controller: _metaTabController,
                  children: [
                    _buildReadingBody(),
                    FutureBuilder<Map<String, dynamic>>(
                      future: _futureKiranContent,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        } else if (snapshot.hasError) {
                          return Center(
                            child: Text('Error: ${snapshot.error}'),
                          );
                        } else if (!snapshot.hasData) {
                          return const Center(child: Text('No content found.'));
                        }
                        final contentData = snapshot.data!;
                        // Ensure cache is populated even if Reading tab was never shown
                        _kiranContentData ??= contentData;
                        return Padding(
                          padding: const EdgeInsets.only(
                            left: 16.0,
                            right: 16.0,
                            top: 0.0,
                            bottom: 16.0,
                          ),
                          child: Scrollbar(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.only(
                                left: 4.0,
                                right: 4.0,
                                top: 16.0,
                                bottom: 0.0,
                              ),
                              child: SafeArea(
                                child: _buildKiranMetaPanel(
                                  contentData,
                                  context,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                )
                : _buildReadingBody(),
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

  /// Builds the main reading body (used directly or as a tab in TabBar layout).
  Widget _buildReadingBody() {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 0,
            bottom: 16.0,
          ),
          child: Column(
            children: [
              if (_isReadingMode) displayExtraInfos(context),
              // Search bar
              if (_isSearchMode) _buildSearchBar(),
              if (_isReadingMode)
                LinearProgressIndicator(
                  value: widget.kiranUserInfo.progress.toDouble() / 100.0,
                  minHeight: 3,
                  borderRadius: BorderRadius.circular(3),
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.5),
                  ),
                ),
              Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(20.0),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4.0,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      '${widget.kiranInfo.number} ${widget.kiranInfo.title}',
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: appSettingsNotifier.value.edgePadding,
                    right: appSettingsNotifier.value.edgePadding,
                    top: 0,
                    bottom: 0.0,
                  ),
                  child: SafeArea(
                    child: FutureBuilder<Map<String, dynamic>>(
                      future: _futureKiranContent,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        } else if (snapshot.hasError) {
                          return Center(
                            child: Text('Error: ${snapshot.error}'),
                          );
                        } else if (!snapshot.hasData) {
                          return const Center(child: Text('No content found.'));
                        }
                        final contentData = snapshot.data!;
                        // Cache for use by AppBar info button / Info tab
                        _kiranContentData ??= contentData;

                        // Initialize auto-scroll and set initial position after content is loaded (only once)
                        if (!_isInitialized) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _initializeAutoScroll();
                            _setInitialScrollPosition();
                            _isInitialized = true;
                          });
                        }
                        return NotificationListener<ScrollNotification>(
                          onNotification: (notification) {
                            if (notification is UserScrollNotification) {
                              // User started scrolling manually
                              if (_isAutoScrollEnabled && _isAutoScrolling) {
                                _stopAutoScroll();
                              }
                            } else if (notification is ScrollEndNotification) {
                              // User stopped scrolling
                              if (_isAutoScrollEnabled &&
                                  !_isAutoScrolling &&
                                  _autoScrollDelayTimer == null) {
                                // Optionally, resume auto-scroll after a short delay
                                Future.delayed(const Duration(seconds: 1), () {
                                  if (mounted &&
                                      !_isAutoScrolling &&
                                      _autoScrollDelayTimer == null) {
                                    _startAutoScrollWithDelay();
                                  }
                                });
                              }
                            }
                            return false;
                          },
                          child: _buildKiranContentWidget(contentData, context),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Previous button (left edge, vertically centered)
        if (appSettingsNotifier.value.showEdgeNavButtons && _hasPreviousKiran())
          Positioned(
            left: 4,
            top: 0,
            bottom: 0,
            child: Center(
              child: _buildEdgeNavButton(
                icon: Icons.arrow_circle_left_outlined,
                onTap: _navigateToPreviousKiran,
              ),
            ),
          ),
        // Next button (right edge, vertically centered)
        if (appSettingsNotifier.value.showEdgeNavButtons && _hasNextKiran())
          Positioned(
            right: 4,
            top: 0,
            bottom: 0,
            child: Center(
              child: _buildEdgeNavButton(
                icon: Icons.arrow_circle_right_outlined,
                onTap: _navigateToNextKiran,
              ),
            ),
          ),
      ],
    );
  }

  /// Builds the meta info panel (place, date, moral, summary) shown above the kiran text.
  Widget _buildKiranMetaPanel(
    Map<String, dynamic> contentData,
    BuildContext context,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final String place =
        (contentData['main']?['place'] as String? ?? '').trim();
    final String date = (contentData['meta']?['date'] as String? ?? '').trim();
    final String moral =
        (contentData['meta']?['moral'] as String? ?? '').trim();
    final String history =
        (contentData['meta']?['history'] as String? ?? '').trim();
    final List<String> summary =
        (contentData['meta']?['summary'] as List<dynamic>? ?? [])
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList();

    final bool hasAnything =
        place.isNotEmpty ||
        date.isNotEmpty ||
        moral.isNotEmpty ||
        history.isNotEmpty ||
        summary.isNotEmpty;

    if (!hasAnything) return const SizedBox.shrink();

    final titleStyle = textTheme.titleMedium!.copyWith(
      color: Theme.of(context).colorScheme.primary,
      overflow: TextOverflow.ellipsis,
    );

    final contentFontSize = appSettingsNotifier.value.fontSize;
    final contentStyle = textTheme.bodyMedium!.copyWith(
      color: colorScheme.primary,
      fontSize: contentFontSize,
    );

    Widget sectionBlock(IconData icon, String label, String value) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 24, color: colorScheme.primary),
              const SizedBox(width: 6),
              Text(label, style: titleStyle),
            ],
          ),
          const SizedBox(height: 4),
          if (value.isNotEmpty)
            RemoteConfigService().useCustomHtmlWidget
                ? CustomHtmlWidget(
                  htmlContent: value,
                  onAddNote: null,
                  onCreateQuoteImage: null,
                  onSingleTap: null,
                )
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: HtmlToTextSpan.convertToWidgets(
                    value,
                    contentStyle,
                    context,
                    textAlign: TextAlign.justify,
                    lineHeight: appSettingsNotifier.value.lineHeight,
                  ),
                ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionBlock(Icons.article, "AI Generated", ""),
        if (place.isNotEmpty)
          sectionBlock(Icons.location_on, l10n.kiran_place, place),
        if (date.isNotEmpty) ...[
          const Divider(height: 16),
          sectionBlock(Icons.calendar_today, l10n.kiran_date, date),
        ],
        if (moral.isNotEmpty) ...[
          const Divider(height: 16),
          sectionBlock(Icons.lightbulb, l10n.kiran_moral, moral),
        ],
        if (history.isNotEmpty) ...[
          const Divider(height: 16),
          sectionBlock(Icons.history_edu, l10n.kiran_history, history),
        ],
        if (summary.isNotEmpty) ...[
          const Divider(height: 16),
          sectionBlock(Icons.format_list_bulleted, l10n.kiran_summary, ''),
          const SizedBox(height: 4),
          ...summary.indexed.map(((int, String) entry) {
            final number = (entry.$1 + 1)
                .toString()
                .replaceAll('0', '૦')
                .replaceAll('1', '૧')
                .replaceAll('2', '૨')
                .replaceAll('3', '૩')
                .replaceAll('4', '૪')
                .replaceAll('5', '૫')
                .replaceAll('6', '૬')
                .replaceAll('7', '૭')
                .replaceAll('8', '૮')
                .replaceAll('9', '૯');
            final bullet = entry.$2;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //CustomHtmlWidget(htmlContent: '<b>$number.</b>'),
                  Expanded(
                    child:
                        RemoteConfigService().useCustomHtmlWidget
                            ? CustomHtmlWidget(
                              htmlContent: '<b>$number.</b> $bullet',
                              onAddNote: null,
                              onCreateQuoteImage: null,
                              onSingleTap: null,
                            )
                            : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: HtmlToTextSpan.convertToWidgets(
                                '<b>$number.</b> $bullet',
                                contentStyle,
                                context,
                                textAlign: TextAlign.justify,
                                lineHeight:
                                    appSettingsNotifier.value.lineHeight,
                              ),
                            ),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  /// Shows the kiran meta info (place, date, moral, summary) in a modal bottom sheet.
  void _showKiranInfoSheet(
    BuildContext context,
    Map<String, dynamic> contentData,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (_, controller) {
            return Column(
              children: [
                const SizedBox(height: 8),
                // drag handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      AppLocalizations.of(context)!.kiran_info,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    controller: controller,
                    padding: EdgeInsets.only(
                      left: 16 + appSettingsNotifier.value.edgePadding,
                      right: 16 + appSettingsNotifier.value.edgePadding,
                      top: 16,
                      bottom: 16,
                    ),
                    child: SafeArea(
                      child: _buildKiranMetaPanel(contentData, context),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Scrollbar _buildKiranContentWidget(
    Map<String, dynamic> contentData,
    BuildContext context,
  ) {
    return Scrollbar(
      controller: _scrollController,
      interactive: true,
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Padding(
          padding: EdgeInsets.only(
            left: RemoteConfigService().useCustomHtmlWidget ? 0.0 : 6.0,
            right: RemoteConfigService().useCustomHtmlWidget ? 0.0 : 6.0,
          ),
          child: Column(
            children: [
              if (!RemoteConfigService().useCustomHtmlWidget)
                ...HtmlToTextSpan.convertToWidgets(
                  _isSearchMode && _searchController.text.isNotEmpty
                      ? _getHighlightedContentForTextSpan(
                        getKiranContent(contentData),
                      )
                      : getKiranContent(contentData),
                  Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: appSettingsNotifier.value.fontSize,
                  ),
                  context,
                  textAlign: TextAlign.justify,
                  lineHeight: appSettingsNotifier.value.lineHeight,
                  onAddNote: (selectedText) async {
                    _pauseTimer();
                    await _openNoteEditor(selectedText: selectedText);
                    _resumeTimer();
                  },
                  onCreateQuoteImage: (selectedText) async {
                    _pauseTimer();
                    await _openQuoteEditor(selectedText: selectedText);
                    _resumeTimer();
                  },
                  onDoubleTap: () {
                    // Toggle edge nav buttons setting
                    if (mounted) {
                      final currentValue =
                          appSettingsNotifier.value.showEdgeNavButtons;
                      appSettingsNotifier.value = copyAppSettings(
                        appSettingsNotifier.value,
                        showEdgeNavButtons: !currentValue,
                      );
                      debugPrint('Edge nav buttons toggled: ${!currentValue}');
                    }
                  },
                ),
              if (RemoteConfigService().useCustomHtmlWidget)
                CustomHtmlWidget(
                  htmlContent:
                      _isSearchMode && _searchController.text.isNotEmpty
                          ? _getHighlightedContent(getKiranContent(contentData))
                          : getKiranContent(contentData),

                  onAddNote: (selectedText) async {
                    _pauseTimer();
                    await _openNoteEditor(selectedText: selectedText);
                    _resumeTimer();
                  },
                  onCreateQuoteImage: (selectedText) async {
                    _pauseTimer();
                    await _openQuoteEditor(selectedText: selectedText);
                    _resumeTimer();
                  },
                  onSingleTap: () {
                    // Toggle edge nav buttons setting
                    if (mounted) {
                      final currentValue =
                          appSettingsNotifier.value.showEdgeNavButtons;
                      appSettingsNotifier.value = copyAppSettings(
                        appSettingsNotifier.value,
                        showEdgeNavButtons: !currentValue,
                      );
                      debugPrint('Edge nav buttons toggled: ${!currentValue}');
                    }
                  },
                ),
              const SizedBox(height: 8.0),
              // Finish button (only in reading mode)
              if (_isReadingMode)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                  onPressed: () async {
                    _onFinishReadingPressed();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      AppLocalizations.of(context)!.kiran_read_finished,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              const SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_hasPreviousKiran()) ...[_buildPreviousKiranButton()],
                  const Spacer(),
                  if (_hasNextKiran()) ...[_buildNextKiranButton()],
                ],
              ),
              const SizedBox(height: 64.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEdgeNavButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(32.0),
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.25),
            size: 32,
          ),
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
            Text(
              _searchMatches.isEmpty
                  ? AppLocalizations.of(context)!.no_match_found
                  : '${_currentMatchIndex + 1} of ${_searchMatches.length}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey),
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

    String strQuery = lowerQuery.replaceAll("[-\\[\\]\\+\\*\"\\\\().{}]+", "");
    List<String> listQuery = strQuery.split(RegExp(r"[ \t]+"));

    final pattern = RegExp(
      listQuery.where((w) => w.isNotEmpty).map(RegExp.escape).join('[^.!?]*'),
      caseSensitive: false,
    );

    Iterable<RegExpMatch> matchesIterable = pattern.allMatches(lowerContent);
    for (RegExpMatch match in matchesIterable) {
      matches.add(match.start);
    }

    setState(() {
      _searchMatches = matches;
      _currentMatchIndex = matches.isNotEmpty ? 0 : -1;
    });
  }

  String _getPlainTextFromHtml(String html) {
    // Simple HTML tag removal - could be improved with proper HTML parsing
    // Remove all HTML tags using regex
    return html.replaceAll(RegExp(r'<[^>]*>', multiLine: true), '').trim();
  }

  String _getHighlightedContent(String content) {
    if (_searchController.text.isEmpty || _searchMatches.isEmpty) {
      return content;
    }

    String highlighted = content;
    final query = _searchController.text.trim();
    String strQuery = query.replaceAll("[-\\[\\]\\+\\*\"\\\\().{}]+", "");
    List<String> listQuery = strQuery.split(RegExp(r"[ \t]+"));

    // Build a pattern that matches any of the words (case-insensitive)
    final pattern = RegExp(
      listQuery.where((w) => w.isNotEmpty).map(RegExp.escape).join('[^.!?]*'),
      caseSensitive: false,
    );

    // Split content into segments outside and inside <a>...</a>
    final anchorRegExp = RegExp(
      r'(<a\b[^>]*>)',
      caseSensitive: false,
      dotAll: true,
    );
    final anchorMatches = anchorRegExp.allMatches(highlighted).toList();

    // Find all matches and store their positions
    final matches = pattern.allMatches(highlighted).toList();
    if (matches.isEmpty) return content;

    // Build the highlighted string
    final buffer = StringBuffer();
    int lastMatchEnd = 0;
    int matchCounter = 0;

    for (final match in matches) {
      // Add text before the match
      buffer.write(highlighted.substring(lastMatchEnd, match.start));

      bool isInsideAnchor = false;
      for (final anchorMatch in anchorMatches) {
        if (match.start >= anchorMatch.start && match.end <= anchorMatch.end) {
          debugPrint(
            'Found match: ${match.group(0)} at ${match.start}-${match.end}',
          );
          debugPrint(
            'Anchor found match: ${anchorMatch.group(0)} at ${anchorMatch.start}-${anchorMatch.end}',
          );
          // Match is inside an anchor tag, skip highlighting
          buffer.write(highlighted.substring(match.start, match.end));
          lastMatchEnd = match.end;
          isInsideAnchor = true;
          break;
        }
      }

      if (isInsideAnchor) {
        continue; // Skip to next match
      }

      final isCurrentMatch = matchCounter == _currentMatchIndex;
      final matchId = 'search-match-$matchCounter';
      final highlightClass =
          isCurrentMatch ? 'current-highlight' : 'search-highlight';
      final backgroundColor = isCurrentMatch ? '#ff9800' : '#ffeb3b';

      // Add the highlighted match
      buffer.write(
        '<span id="$matchId" class="$highlightClass" style="background-color: $backgroundColor; color: black; padding: 2px; border-radius: 2px;">${match.group(0)}</span>',
      );

      lastMatchEnd = match.end;
      matchCounter++;
    }
    // Add any remaining text after the last match
    buffer.write(highlighted.substring(lastMatchEnd));

    return buffer.toString();
  }

  String _getHighlightedContentForTextSpan(String content) {
    if (_searchController.text.isEmpty || _searchMatches.isEmpty) {
      return content;
    }

    final query = _searchController.text.trim();
    String strQuery = query.replaceAll("[-\\[\\]\\+\\*\"\\\\().{}]+", "");
    List<String> listQuery = strQuery.split(RegExp(r"[ \t]+"));

    // Build a pattern that matches any of the words (case-insensitive)
    final pattern = RegExp(
      listQuery.where((w) => w.isNotEmpty).map(RegExp.escape).join('[^.!?]*'),
      caseSensitive: false,
    );

    // Get plain text content for matching (strip HTML tags)
    final plainText = _getPlainTextFromHtml(content);

    // Find all matches in plain text
    final plainMatches = pattern.allMatches(plainText).toList();
    if (plainMatches.isEmpty) return content;

    // Now we need to map plain text positions to HTML positions
    // This is complex, so we'll use a simpler approach:
    // Parse the content and wrap matches with <mark> tags

    final buffer = StringBuffer();
    int plainPos = 0;
    int matchCounter = 0;

    // Track which plain text match we're looking for
    int currentPlainMatchIndex = 0;

    for (int i = 0; i < content.length; i++) {
      final char = content[i];

      // Check if we're at the start of an HTML tag
      if (char == '<') {
        // Find the end of the tag
        final tagEnd = content.indexOf('>', i);
        if (tagEnd != -1) {
          // Add the entire tag to the buffer
          buffer.write(content.substring(i, tagEnd + 1));
          i = tagEnd;
          continue;
        }
      }

      // Check if we're at the start of a match in plain text
      if (currentPlainMatchIndex < plainMatches.length) {
        final match = plainMatches[currentPlainMatchIndex];

        if (plainPos == match.start) {
          // Start of a match
          final isCurrentMatch = matchCounter == _currentMatchIndex;
          buffer.write('<mark data-current="$isCurrentMatch">');

          // Write the matched text
          final matchLength = match.end - match.start;
          int charsWritten = 0;
          int j = i;

          while (charsWritten < matchLength && j < content.length) {
            final c = content[j];
            if (c == '<') {
              // Skip HTML tags within the match
              final tagEnd = content.indexOf('>', j);
              if (tagEnd != -1) {
                buffer.write(content.substring(j, tagEnd + 1));
                j = tagEnd + 1;
                continue;
              }
            }
            buffer.write(c);
            charsWritten++;
            j++;
          }

          buffer.write('</mark>');
          i = j - 1; // -1 because the loop will increment
          plainPos += matchLength;
          currentPlainMatchIndex++;
          matchCounter++;
          continue;
        }
      }

      // Regular character
      buffer.write(char);
      plainPos++;
    }

    return buffer.toString();
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
      final plainText = _currentKiranContent;

      if (plainText.isEmpty || matchPosition >= plainText.length) return;

      // Calculate approximate scroll position based on text position
      final totalTextLength = plainText.length;
      final matchRatio = matchPosition / totalTextLength;

      // Get scroll constraints
      final maxScrollExtent = _scrollController.position.maxScrollExtent;
      final viewportHeight = _scrollController.position.viewportDimension;

      // Calculate target position - aim to put the match in the center of the viewport
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
          // Auto-scroll play/pause button (only in reading mode)
          if (_isReadingMode)
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
          // TTS play/pause and stop buttons (only when TTS is enabled in settings)
          if (_isReadingMode && appSettingsNotifier.value.ttsEnabled) ...[
            IconButton(
              onPressed: () {
                if (_isTtsSpeaking) {
                  _pauseOrResumeTts();
                } else {
                  _startTts();
                }
              },
              icon: Icon(
                _isTtsSpeaking && !_isTtsPaused
                    ? Icons.pause_circle_outline
                    : Icons.play_circle_outline,
                color: _isTtsSpeaking ? Colors.blue : null,
              ),
              tooltip:
                  _isTtsSpeaking
                      ? (_isTtsPaused ? 'Resume' : 'Pause TTS')
                      : 'Read Aloud',
              iconSize: 28,
            ),
            if (_isTtsSpeaking)
              IconButton(
                onPressed: _stopTts,
                icon: const Icon(Icons.stop_circle_outlined, color: Colors.red),
                tooltip: 'Stop TTS',
                iconSize: 28,
              ),
          ],
          // Timer display (only in reading mode)
          if (_isReadingMode)
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
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall!.copyWith(
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

  Future<void> _onFinishReadingPressed() async {
    // Store context before async operation
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final localizations = AppLocalizations.of(context)!;

    // Stop TTS if running
    if (_isTtsSpeaking) await _stopTts();

    // Stop stopwatch to capture correct elapsed time
    _stopwatch.stop();
    _timer?.cancel();

    // Compute total reading duration (including any initial offset)
    final readingTimeSeconds =
        _stopwatch.elapsed.inSeconds + _initialDurationOffset;

    // If the session is too short, discard the reading event and do not
    // convert it to history or increment read counts.
    if (readingTimeSeconds < 15) {
      if (_isReadingMode && _currentReadingEvent != null) {
        try {
          await ReadingEventService.deleteReadingEvent(
            _currentReadingEvent!.id,
          );
          debugPrint(
            '🗑️ Short reading event discarded: ${_currentReadingEvent!.id}',
          );
        } catch (e) {
          debugPrint('❌ Error deleting short reading event: $e');
        }
        _currentReadingEvent = null;
      }

      // Notify analytics minimally (optional) and show a snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.short_reading_session_discarded),
          ),
        );
        // Close the read page and return `false` (no meaningful changes)
        Navigator.of(context).pop(false);
      }

      // Do not proceed to convert or save history nor increment counts
      return;
    }

    // For valid sessions (>= 15s): convert event to history if present
    if (_isReadingMode && _currentReadingEvent != null) {
      _currentReadingEvent!.durationSeconds = readingTimeSeconds;
      debugPrint(
        '📖 Converting reading event to history : ${_currentReadingEvent!.kiranIndex} : ${_currentReadingEvent!.currentProgress} : ${_currentReadingEvent!.durationSeconds}',
      );
      try {
        final history = await ReadingEventService.completeReadingEvent(
          _currentReadingEvent!,
        );
        await ReadingHistoryService.saveReadingHistory(history);
        // Clear the event reference since it's now deleted
        _currentReadingEvent = null;
        debugPrint('✅ Reading event converted to history and deleted');
      } catch (e) {
        debugPrint('❌ Error converting reading event to history: $e');
        // Fall back to regular save
        await _saveReadingHistory();
      }
    } else {
      // Save reading history before finishing (browse mode or no event)
      await _saveReadingHistory();
    }

    // Track reading completion analytics
    await AnalyticsService().logCompleteReading(
      bookName: 'Sakshat Savita',
      chapterName: widget.kiranInfo.title,
      partName: 'Part ${widget.partNumber}',
      readingTimeSeconds: readingTimeSeconds,
    );

    // Increment reading session count for review prompts
    await InAppReviewService().incrementReadingSessionCount();

    if (mounted) {
      setState(() {
        widget.kiranUserInfo.progress = 0;
        widget.kiranUserInfo.readCount += 1;
        widget.kiranUserInfo.updatedAt = DateTime.now();
        Utils.updateKiranUserInfo(widget.kiranUserInfo);
        _hasDataChanged = true;
        _pauseTimer();
        // Stop auto-scroll if active
        if (_isAutoScrolling) {
          _stopAutoScroll();
        }
        _isAutoScrollEnabled = false;
        Utils.applyBookmarkToNextKiran(widget.kiranUserInfo);
      });

      final durationSeconds =
          _currentReadingEvent?.durationSeconds ??
          _stopwatch.elapsed.inSeconds + _initialDurationOffset;
      final minutes = durationSeconds ~/ 60;
      final secs = durationSeconds % 60;
      final timeString =
          "${minutes.toString().padLeft(2, '0')}m:${secs.toString().padLeft(2, '0')}s";

      // Show Dialog and await its dismissal, then close the read page.
      if (mounted) {
        await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(
                localizations.kiran_read_finished_message(
                  widget.kiranUserInfo.readCount,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,

                children: [
                  Text(localizations.word_count(widget.kiranInfo.wordCount)),
                  Text('${localizations.reading_time} : $timeString'),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      // Previous Kiran button
                      if (_hasPreviousKiran()) _buildPreviousKiranButton(),
                      const Spacer(),
                      // Next Kiran button
                      if (_hasNextKiran()) _buildNextKiranButton(),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(localizations.ok),
                ),
              ],
            );
          },
        );

        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              localizations.kiran_read_finished_message(
                widget.kiranUserInfo.readCount,
              ),
            ),
            duration: const Duration(seconds: 2),
          ),
        );

        // Close the read page and return whether data changed
        Navigator.of(context).pop(_hasDataChanged);
      }
    }
  }

  bool _hasPreviousKiran() {
    return KiranListService().hasPreviousKiran(
      widget.kiranUserInfo.partNumber,
      widget.kiranInfo.index,
    );
  }

  bool _hasNextKiran() {
    return KiranListService().hasNextKiran(
      widget.kiranUserInfo.partNumber,
      widget.kiranInfo.index,
    );
  }

  Widget _buildPreviousKiranButton() {
    KiranInfo previousKiranInfo = KiranListService().getKiranInfo(
      widget.kiranUserInfo.partNumber,
      widget.kiranInfo.index - 1,
    );
    String strButtonText =
        '${AppLocalizations.of(context)!.kiran} ${previousKiranInfo.number.replaceAll(".", "")}';
    return GestureDetector(
      onTap: () {
        _navigateToPreviousKiran();
      },
      child: Material(
        elevation: 1.0,
        borderRadius: BorderRadius.circular(20.0),
        child: Container(
          padding: EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.0),
            color: Theme.of(context).colorScheme.surfaceContainer,
          ),
          child: Column(
            children: [
              const Icon(Icons.arrow_back),
              const SizedBox(height: 8),
              Text(
                strButtonText,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToPreviousKiran() async {
    KiranInfo previousKiranInfo = KiranListService().getKiranInfo(
      widget.kiranUserInfo.partNumber,
      widget.kiranInfo.index - 1,
    );

    // Check for existing reading event if in reading mode
    ReadingEvent? existingEvent;
    if (widget.readingMode == ReadingMode.reading) {
      existingEvent = await ReadingEventService.getReadingEventForKiran(
        previousKiranInfo.index,
      );
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (_) => KiranReadPage(
                partNumber: widget.partNumber,
                kiranInfo: previousKiranInfo,
                kiranUserInfo: KiranUserService().getKiranUserInfo(
                  widget.kiranUserInfo.kiranIndex - 1,
                ),
                readingMode: widget.readingMode,
                existingEvent: existingEvent,
              ),
        ),
      );
    }
  }

  Future<void> _navigateToNextKiran() async {
    KiranInfo nextKiranInfo = KiranListService().getKiranInfo(
      widget.kiranUserInfo.partNumber,
      widget.kiranInfo.index + 1,
    );

    // Check for existing reading event if in reading mode
    ReadingEvent? existingEvent;
    if (widget.readingMode == ReadingMode.reading) {
      existingEvent = await ReadingEventService.getReadingEventForKiran(
        nextKiranInfo.index,
      );
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (_) => KiranReadPage(
                partNumber: widget.partNumber,
                kiranInfo: nextKiranInfo,
                kiranUserInfo: KiranUserService().getKiranUserInfo(
                  widget.kiranUserInfo.kiranIndex + 1,
                ),
                readingMode: widget.readingMode,
                existingEvent: existingEvent,
              ),
        ),
      );
    }
  }

  Widget _buildNextKiranButton() {
    KiranInfo nextKiranInfo = KiranListService().getKiranInfo(
      widget.kiranUserInfo.partNumber,
      widget.kiranInfo.index + 1,
    );
    String strButtonText =
        '${AppLocalizations.of(context)!.kiran} ${nextKiranInfo.number.replaceAll(".", "")}';
    return GestureDetector(
      onTap: () {
        _navigateToNextKiran();
      },
      child: Material(
        elevation: 1.0,
        borderRadius: BorderRadius.circular(20.0),
        child: Container(
          padding: EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.0),
            color: Theme.of(context).colorScheme.surfaceContainer,
          ),
          child: Column(
            children: [
              const Icon(Icons.arrow_forward),
              const SizedBox(height: 8),
              Text(
                strButtonText,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
