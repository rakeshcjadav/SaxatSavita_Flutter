import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:saxatsavita_flutter/models/appsettings.dart';

/// Manages all Text-to-Speech logic for a kiran reading session.
///
/// The page constructs one of these lazily on first TTS action, passes in the
/// [ScrollController] and three callbacks, then delegates every TTS operation
/// to this controller. The controller owns all TTS state; the page reads
/// [isSpeaking] and [isPaused] via callbacks and for UI rendering.
class KiranTtsController {
  KiranTtsController({
    required this.scrollController,
    required this.onStateChanged,
    required this.onComplete,
    required this.onScrollDrivingChanged,
  });

  final ScrollController scrollController;

  /// Called whenever [isSpeaking] or [isPaused] change so the page can setState.
  final VoidCallback onStateChanged;

  /// Called when all chunks have finished speaking (e.g. page pauses its timer).
  final VoidCallback onComplete;

  /// Called with `true` when TTS starts driving scroll, `false` when it stops.
  final void Function(bool) onScrollDrivingChanged;

  // ── Internal state ───────────────────────────────────────────────────────

  FlutterTts? _tts;
  bool _isSpeaking = false;
  bool _isPaused = false;
  final List<String> _chunks = [];
  int _currentChunk = 0;
  List<double> _scrollTargets = [];
  bool _disposed = false;

  // ── Public read-only state ───────────────────────────────────────────────

  bool get isSpeaking => _isSpeaking;
  bool get isPaused => _isPaused;

  // ── Lifecycle ────────────────────────────────────────────────────────────

  void dispose() {
    _disposed = true;
    _tts?.stop();
    _tts = null;
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  Future<void> init() async {
    _tts = FlutterTts();
    final lang = appSettingsNotifier.value.language == 'gu' ? 'gu-IN' : 'en-US';
    await _tts!.setLanguage(lang);
    final savedVoice = appSettingsNotifier.value.ttsVoice;
    if (savedVoice != null && savedVoice.contains('|')) {
      final parts = savedVoice.split('|');
      await _tts!.setVoice({'name': parts[0], 'locale': parts[1]});
    }
    await _tts!.setSpeechRate(appSettingsNotifier.value.ttsSpeechRate);
    await _tts!.setVolume(1.0);
    await _tts!.setPitch(1.0);

    _tts!.setCompletionHandler(() {
      _currentChunk++;
      if (_currentChunk < _chunks.length) {
        // Brief pause between sentences for more natural-sounding speech.
        Future.delayed(const Duration(milliseconds: 300), () {
          if (!_disposed && _isSpeaking && !_isPaused) {
            _speakCurrentChunk();
          }
        });
      } else {
        _isSpeaking = false;
        _isPaused = false;
        _currentChunk = 0;
        if (!_disposed) {
          onScrollDrivingChanged(false);
          onComplete();
          onStateChanged();
        }
      }
    });

    _tts!.setErrorHandler((msg) {
      debugPrint('TTS error: $msg');
      _isSpeaking = false;
      _isPaused = false;
      if (!_disposed) {
        onScrollDrivingChanged(false);
        onStateChanged();
      }
    });
  }

  /// Start reading [content] aloud. Builds the intro chunk from [partNumber],
  /// [kiranNumber] (raw Gujarati numeral string from model), and [kiranTitle].
  /// Chunks are cached — calling [start] again reuses existing chunks.
  Future<void> start({
    required String content,
    required String partNumber,
    required String kiranNumber,
    required String kiranTitle,
  }) async {
    if (_tts == null) await init();

    if (_chunks.isEmpty) {
      _chunks.addAll(prepareChunks(content));
      final partNum = int.tryParse(partNumber.replaceAll('part', '')) ?? 1;
      final partWord = numberToGujarati(partNum);
      final num = kiranNumber.replaceAll('.', '').trim();
      final intro = 'સાક્ષાત્ સવિતા. ભાગ $partWord. કિરણ $num. $kiranTitle.';
      _chunks.insert(0, intro);
    }
    if (_chunks.isEmpty) return;

    _scrollTargets = []; // will be (re)computed on first _speakCurrentChunk
    await _tts!.setSpeechRate(appSettingsNotifier.value.ttsSpeechRate);
    await _tts!.setLanguage(
      appSettingsNotifier.value.language == 'gu' ? 'gu-IN' : 'en-US',
    );
    // Re-apply voice preference on every play (user may have changed it).
    final savedVoice = appSettingsNotifier.value.ttsVoice;
    if (savedVoice != null && savedVoice.contains('|')) {
      final parts = savedVoice.split('|');
      await _tts!.setVoice({'name': parts[0], 'locale': parts[1]});
    }

    _isSpeaking = true;
    _isPaused = false;
    if (!_disposed) {
      onScrollDrivingChanged(true);
      onStateChanged();
    }
    _speakCurrentChunk();
  }

  Future<void> stop() async {
    await _tts?.stop();
    _scrollTargets = [];
    _currentChunk = 0;
    _isSpeaking = false;
    _isPaused = false;
    if (!_disposed) {
      onScrollDrivingChanged(false);
      onStateChanged();
    }
  }

  Future<void> pauseOrResume() async {
    if (_isPaused) {
      await _tts?.setSpeechRate(appSettingsNotifier.value.ttsSpeechRate);
      await _tts?.speak(_chunks[_currentChunk]);
      _isPaused = false;
      if (!_disposed) {
        onScrollDrivingChanged(true);
        onStateChanged();
      }
    } else {
      await _tts?.pause();
      _isPaused = true;
      if (!_disposed) {
        onScrollDrivingChanged(false);
        onStateChanged();
      }
    }
  }

  // ── Private scroll sync ──────────────────────────────────────────────────

  /// Rebuilds char-weighted scroll targets whenever chunks or scroll extent
  /// change. Targets point to the start of each chunk, offset upward by two
  /// line-heights so the spoken sentence is near the top of the viewport.
  void _recomputeScrollTargets() {
    if (_chunks.isEmpty || !scrollController.hasClients) return;
    final maxExtent = scrollController.position.maxScrollExtent;
    if (maxExtent <= 0) return;
    final totalChars = _chunks.fold(0, (s, c) => s + c.length);
    if (totalChars == 0) return;
    final lineHeight = appSettingsNotifier.value.fontSize * 1.5;
    var cumulativeBefore = 0;
    _scrollTargets = List.generate(_chunks.length, (i) {
      final startPos = (cumulativeBefore / totalChars) * maxExtent;
      cumulativeBefore += _chunks[i].length;
      return (startPos - lineHeight * 2.0).clamp(0.0, maxExtent);
    });
  }

  void _speakCurrentChunk() {
    if (_currentChunk >= _chunks.length) return;
    _tts?.speak(_chunks[_currentChunk]);
    if (!scrollController.hasClients) return;
    if (_scrollTargets.length != _chunks.length) _recomputeScrollTargets();
    if (_scrollTargets.isEmpty) return;
    final target = _scrollTargets[_currentChunk];
    final chunkChars = _chunks[_currentChunk].length;
    final rate = appSettingsNotifier.value.ttsSpeechRate.clamp(0.1, 1.0);
    final charsPerSec = 22.0 * (rate / 0.5);
    final estimatedMs = ((chunkChars / charsPerSec) * 1000).round();
    scrollController.animateTo(
      target,
      duration: Duration(milliseconds: estimatedMs.clamp(300, 12000)),
      curve: Curves.linear,
    );
  }

  // ── Static Gujarati text utilities ───────────────────────────────────────
  // Public statics so other classes (e.g. audio code on the page) can reuse.

  static const _gujaratiDigits = {
    '૦': 0, '૧': 1, '૨': 2, '૩': 3, '૪': 4,
    '૫': 5, '૬': 6, '૭': 7, '૮': 8, '૯': 9,
    // Letter lookalikes commonly used as digits in Gujarati manuscripts.
    'ર': 2, // GUJARATI LETTER RA (U+0AB0) written in place of digit ૨
    'પ': 5, // GUJARATI LETTER PA (U+0AAA) written in place of digit ૫
  };

  /// Converts a string of Gujarati (or ASCII) digits to an integer.
  static int parseGujaratiInt(String s) {
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
  static String numberToGujarati(int n) {
    if (n <= 0) return '';
    if (n < _ones.length) return _ones[n];
    if (n < 200) return 'એકસો ${_ones[n - 100]}'.trim();
    return n.toString();
  }

  /// Converts a number to its Gujarati ordinal form (1st, 2nd, …).
  static String ordinalGujarati(int n) {
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
    return '${numberToGujarati(n)}મું';
  }

  /// Converts a 2-digit year (00–99) to a Gujarati century spoken form.
  /// e.g. 75 → "ઓગણીસો પંચોત્તેર" (1975),  05 → "બે હજાર પાંચ" (2005)
  static String yearToGujarati(int yy) {
    if (yy >= 0 && yy <= 30) {
      return yy == 0 ? 'બે હજાર' : 'બે હજાર ${numberToGujarati(yy)}';
    }
    return 'ઓગણીસો ${numberToGujarati(yy)}';
  }

  /// Converts a full 4-digit year to its Gujarati spoken form.
  /// 2000 → "બે હજાર", 2036 → "બે હજાર છત્રીસ", 1980 → "ઓગણીસસો એંસી"
  static String fullYearToGujarati(int yr) {
    if (yr >= 2000 && yr < 2100) {
      final r = yr - 2000;
      return r == 0 ? 'બે હજાર' : 'બે હજાર ${numberToGujarati(r)}';
    }
    final hundreds = yr ~/ 100;
    final remainder = yr % 100;
    final h = numberToGujarati(hundreds);
    final r = numberToGujarati(remainder);
    return r.isEmpty ? '${h}સો' : '${h}સો $r';
  }

  /// Normalizes Gujarati text for more natural TTS output.
  static String normalizeForTts(String text) {
    var t = text;

    // Vachanamrut parenthetical references: (લોયા ૬) → વચનામૃત લોયા નું છઠ્ઠું
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
        if (location == null) return m.group(0)!;
        final n = parseGujaratiInt(m.group(2)!);
        return 'વચનામૃત $location નું ${ordinalGujarati(n)}.';
      },
    );

    t = t.replaceAll(RegExp(r'પૂ\.'), 'પૂજ્ય');
    t = t.replaceAll(RegExp(r'ગુ\.'), 'ગુણાતીતાનંદ');
    t = t.replaceAll(RegExp(r'તા\.'), 'તારીખ');
    t = t.replaceAll(RegExp(r'સં\.'), 'સંવત');
    t = t.replaceAll(RegExp(r'સંવત\u200C'), 'સંવત');
    t = t.replaceAll(RegExp(r'ઈ\.સ\.'), 'ઈસ્વી સન');
    t = t.replaceAll(RegExp(r'વ\.'), 'વર્ષ');

    // Tithi (lunar day) names: સુદ/સુદિ/વદ/વદિ followed by a number.
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
      RegExp(
        r'(સુદ|સુદિ|વદ|વદિ)[-\u2010\s]+([\u0AE6-\u0AEF\u0AB0\u0AAA\d]{1,2})',
      ),
      (m) {
        final n = parseGujaratiInt(m.group(2)!);
        final name = tithiNames[n] ?? numberToGujarati(n);
        return '${m.group(1)} $name';
      },
    );

    // Samvat / year number after "સંવત".
    t = t.replaceAllMapped(
      RegExp(
        r'(સંવત)\s+([\u0AE6-\u0AEF\u0AB0][\u0AE6-\u0AEF\u0AB0\u0AAA]{2,3})',
      ),
      (m) {
        final yr = parseGujaratiInt(m.group(2)!);
        return '${m.group(1)} ${fullYearToGujarati(yr)}';
      },
    );

    // Gujarati date pattern: DD-MM-YY or DD-MM-YYYY
    final datePattern = RegExp(
      r'([\u0AE6-\u0AEF\d\u0AB0\u0AAA]{1,2})-([\u0AE6-\u0AEF\d\u0AB0\u0AAA]{1,2})-([\u0AE6-\u0AEF\d\u0AB0\u0AAA]{2,4})',
    );
    t = t.replaceAllMapped(datePattern, (m) {
      final day = parseGujaratiInt(m.group(1)!);
      final month = parseGujaratiInt(m.group(2)!);
      final rawYear = parseGujaratiInt(m.group(3)!);
      final monthName = _months[month] ?? numberToGujarati(month);
      final dayWord = numberToGujarati(day);
      final yearWord =
          m.group(3)!.length <= 2
              ? yearToGujarati(rawYear)
              : fullYearToGujarati(rawYear);
      return '$dayWord, $monthName, $yearWord';
    });

    // Standalone Gujarati 4-digit year surrounded by whitespace.
    final yearPattern = RegExp(
      r'(?<!\S)([\u0AE6-\u0AEF\u0AB0][\u0AE6-\u0AEF\u0AAA\u0AB0]{3})(?!\S)',
    );
    t = t.replaceAllMapped(yearPattern, (m) {
      final yr = parseGujaratiInt(m.group(1)!);
      return fullYearToGujarati(yr);
    });

    return t;
  }

  /// Strips HTML and splits text into sentence-level TTS chunks.
  static List<String> prepareChunks(String html) {
    final withNewlines = html
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</header>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    final stripped = withNewlines.replaceAll(RegExp(r'<[^>]*>'), '');
    final decoded =
        stripped
            .replaceAll('&nbsp;', ' ')
            .replaceAll('&zwj;', '')
            .replaceAll('&zwnj;', '')
            .replaceAll('&shy;', '')
            .replaceAll('&#x200B;', '')
            .replaceAll('&#8203;', '')
            .replaceAll('&#160;', ' ')
            .replaceAll('&amp;', '&')
            .replaceAll('&lt;', '<')
            .replaceAll('&gt;', '>')
            .replaceAll('&quot;', '"')
            .replaceAll('&apos;', "'")
            .replaceAll(RegExp(r'&[a-zA-Z0-9#]+;'), '')
            .replaceAll(RegExp(r'[ \t]+'), ' ')
            .trim();
    final normalized = normalizeForTts(decoded);
    final sentences = <String>[];
    for (final paragraph in normalized.split(RegExp(r'\n+'))) {
      final trimmed = paragraph.trim();
      if (trimmed.isEmpty) continue;
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
}
