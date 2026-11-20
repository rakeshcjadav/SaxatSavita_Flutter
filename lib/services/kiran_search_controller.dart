import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// One search hit in the kiran title or body.
class KiranSearchHit {
  const KiranSearchHit({
    required this.start,
    required this.end,
    this.inTitle = false,
  });

  final int start;
  final int end;
  final bool inTitle;

  bool overlaps(KiranSearchHit other) => start < other.end && other.start < end;
}

/// Manages search state, highlighting, and match navigation for [KiranReadPage].
class KiranSearchController {
  KiranSearchController({
    required ScrollController scrollController,
    required VoidCallback onStateChanged,
  }) : _scrollController = scrollController,
       _onStateChanged = onStateChanged,
       _textController = TextEditingController(),
       _focusNode = FocusNode();

  final ScrollController _scrollController;
  final VoidCallback _onStateChanged;
  final TextEditingController _textController;
  final FocusNode _focusNode;

  bool _isActive = false;
  bool _contentReady = false;
  bool _needsInitialScroll = false;
  bool _refreshScheduled = false;
  bool _scrollOnRefresh = false;
  String _title = '';
  String _body = '';
  List<KiranSearchHit> _hits = [];
  int _currentMatchIndex = -1;

  TextEditingController get textController => _textController;
  FocusNode get focusNode => _focusNode;
  bool get isActive => _isActive;
  bool get contentReady => _contentReady;
  int get matchCount => _hits.length;
  int get currentMatchIndex => _currentMatchIndex;
  String get plainText => _body;

  bool get currentHitInTitle {
    final hit = _currentHit;
    return hit != null && hit.inTitle;
  }

  KiranSearchHit? get _currentHit {
    if (_currentMatchIndex < 0 || _currentMatchIndex >= _hits.length) {
      return null;
    }
    return _hits[_currentMatchIndex];
  }

  /// Stores the heading shown above the kiran so title matches can be cycled.
  void setTitle(String title) {
    if (title == _title) return;
    _title = title;
    if (_isActive) _rebuildHits(resetIndex: false);
  }

  /// Call with the plain text of the kiran body whenever HTML is loaded.
  void setContent(String plainText) {
    final becameReady = !_contentReady;
    _contentReady = true;
    if (plainText == _body) {
      if (becameReady && _isActive && _textController.text.trim().isNotEmpty) {
        _needsInitialScroll = false;
        _scheduleRefresh(scroll: _hits.isNotEmpty);
      }
      return;
    }
    final hadBody = _body.isNotEmpty;
    _body = plainText;
    if (!_isActive || _textController.text.trim().isEmpty) return;
    _rebuildHits(resetIndex: !hadBody);
    if (_needsInitialScroll) {
      _needsInitialScroll = false;
      _scheduleRefresh(scroll: _hits.isNotEmpty);
    } else {
      _scheduleRefresh(scroll: false);
    }
  }

  /// Opens search for [query] without notifying listeners.
  /// Safe to call from [State.initState].
  void armQuery(String query) {
    _textController.text = query;
    _isActive = true;
    _needsInitialScroll = query.trim().isNotEmpty;
    _rebuildHits(resetIndex: true);
  }

  void open() {
    _isActive = true;
    _rebuildHits(resetIndex: true);
    _onStateChanged();
  }

  void close() {
    _isActive = false;
    _needsInitialScroll = false;
    _textController.clear();
    _hits = [];
    _currentMatchIndex = -1;
    _onStateChanged();
  }

  void performSearch(String query) {
    if (_textController.text != query) {
      _textController.text = query;
    }
    _rebuildHits(resetIndex: true);
    _onStateChanged();
  }

  void previousMatch() {
    if (_hits.isEmpty) return;
    HapticFeedback.selectionClick();
    _currentMatchIndex = (_currentMatchIndex - 1 + _hits.length) % _hits.length;
    scrollToMatch();
  }

  void nextMatch() {
    if (_hits.isEmpty) return;
    HapticFeedback.selectionClick();
    _currentMatchIndex = (_currentMatchIndex + 1) % _hits.length;
    scrollToMatch();
  }

  void scrollToMatch() {
    _onStateChanged();
    _scrollWhenReady();
  }

  void _scrollWhenReady([int attempt = 0]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final waitingForLayout =
          !_scrollController.hasClients ||
          (_scrollController.position.maxScrollExtent <= 0 && attempt < 8);
      if (waitingForLayout && attempt < 12) {
        _scrollWhenReady(attempt + 1);
        return;
      }
      performScrollToMatch();
    });
  }

  void performScrollToMatch() {
    final hit = _currentHit;
    if (hit == null) return;
    scrollToPlainOffset(hit.inTitle ? 0 : hit.start);
  }

  void scrollToPlainOffset(int matchPosition) {
    if (!_scrollController.hasClients) return;

    try {
      final plainText = _body;
      if (plainText.isEmpty) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
        );
        return;
      }

      final safePosition = matchPosition.clamp(0, plainText.length);
      final matchRatio = safePosition / plainText.length;
      final maxScrollExtent = _scrollController.position.maxScrollExtent;
      final viewportHeight = _scrollController.position.viewportDimension;
      final targetScrollOffset =
          (maxScrollExtent * matchRatio) - (viewportHeight * 0.2);
      final clampedOffset = targetScrollOffset.clamp(0.0, maxScrollExtent);

      _scrollController.animateTo(
        clampedOffset,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } catch (e) {
      debugPrint('Error scrolling to match: $e');
    }
  }

  void _scheduleRefresh({required bool scroll}) {
    _scrollOnRefresh = _scrollOnRefresh || scroll;
    if (_refreshScheduled) return;
    _refreshScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final shouldScroll = _scrollOnRefresh;
      _refreshScheduled = false;
      _scrollOnRefresh = false;
      _onStateChanged();
      if (shouldScroll) _scrollWhenReady();
    });
  }

  void _rebuildHits({required bool resetIndex}) {
    final query = _textController.text;
    final next = <KiranSearchHit>[
      ...findHits(_title, query).map(
        (hit) => KiranSearchHit(start: hit.start, end: hit.end, inTitle: true),
      ),
      ...findHits(_body, query),
    ];
    _hits = next;
    if (_hits.isEmpty) {
      _currentMatchIndex = -1;
    } else if (resetIndex ||
        _currentMatchIndex < 0 ||
        _currentMatchIndex >= _hits.length) {
      _currentMatchIndex = 0;
    }
  }

  /// Every non-overlapping occurrence of each word in [query].
  /// Longer words keep the range when a shorter word sits inside them.
  static List<KiranSearchHit> findHits(String text, String query) {
    final words =
        query
            .trim()
            .split(RegExp(r'\s+'))
            .where((word) => word.isNotEmpty)
            .toList();
    if (text.isEmpty || words.isEmpty) return const [];

    words.sort((a, b) => b.length.compareTo(a.length));
    final claimed = <KiranSearchHit>[];
    for (final word in words) {
      final pattern = RegExp(RegExp.escape(word), caseSensitive: false);
      for (final match in pattern.allMatches(text)) {
        final hit = KiranSearchHit(start: match.start, end: match.end);
        if (claimed.any(hit.overlaps)) continue;
        claimed.add(hit);
      }
    }
    claimed.sort((a, b) => a.start.compareTo(b.start));
    return claimed;
  }

  static String getPlainText(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>', multiLine: true), '');
  }

  String getHighlightedContent(String html) => _highlightHtml(html);

  String getHighlightedContentForTextSpan(String content) =>
      _highlightHtml(content);

  String _highlightHtml(String html) {
    if (_textController.text.trim().isEmpty || _hits.isEmpty) return html;

    final bodyHits = <KiranSearchHit>[];
    int? currentBodyIndex;
    for (var i = 0; i < _hits.length; i++) {
      final hit = _hits[i];
      if (hit.inTitle) continue;
      if (i == _currentMatchIndex) currentBodyIndex = bodyHits.length;
      bodyHits.add(hit);
    }
    if (bodyHits.isEmpty) return html;
    return wrapHtml(html, bodyHits, currentHitIndex: currentBodyIndex);
  }

  static String wrapHtml(
    String html,
    List<KiranSearchHit> hits, {
    int? currentHitIndex,
  }) {
    if (hits.isEmpty) return html;

    final buffer = StringBuffer();
    var plainPos = 0;
    var matchIndex = 0;
    var i = 0;

    while (i < html.length) {
      final char = html[i];
      if (char == '<') {
        final tagEnd = html.indexOf('>', i);
        if (tagEnd != -1) {
          buffer.write(html.substring(i, tagEnd + 1));
          i = tagEnd + 1;
          continue;
        }
      }

      while (matchIndex < hits.length && plainPos > hits[matchIndex].start) {
        matchIndex++;
      }

      if (matchIndex < hits.length && plainPos == hits[matchIndex].start) {
        final hit = hits[matchIndex];
        final isCurrent = matchIndex == currentHitIndex;
        buffer.write(_markOpen(isCurrent));

        final matchLength = hit.end - hit.start;
        var written = 0;
        while (written < matchLength && i < html.length) {
          final c = html[i];
          if (c == '<') {
            final tagEnd = html.indexOf('>', i);
            if (tagEnd != -1) {
              buffer.write(html.substring(i, tagEnd + 1));
              i = tagEnd + 1;
              continue;
            }
          }
          buffer.write(c);
          written++;
          i++;
        }

        buffer.write('</mark>');
        plainPos += matchLength;
        matchIndex++;
        continue;
      }

      buffer.write(char);
      plainPos++;
      i++;
    }

    return buffer.toString();
  }

  static String _markOpen(bool isCurrent) {
    final background = isCurrent ? '#FF9800' : '#FFEB3B';
    return '<mark data-current="$isCurrent" style="background-color: $background; color: #000000;">';
  }

  bool isCurrentTitleHit(int start) {
    final hit = _currentHit;
    return hit != null && hit.inTitle && hit.start == start;
  }

  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
  }
}
