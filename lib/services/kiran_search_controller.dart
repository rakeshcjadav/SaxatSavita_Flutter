import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Manages all search state, logic, and scroll-to-match behaviour for
/// [KiranReadPage]. The page owns one instance and calls [dispose] when done.
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
  String _currentContent = '';
  List<int> _matches = [];
  int _currentMatchIndex = -1;

  // ── Public accessors ─────────────────────────────────────────────────────

  TextEditingController get textController => _textController;
  FocusNode get focusNode => _focusNode;
  bool get isActive => _isActive;
  int get matchCount => _matches.length;
  int get currentMatchIndex => _currentMatchIndex;

  // ── Content cache ────────────────────────────────────────────────────────

  /// Call this with plain-text content whenever the page loads new HTML so
  /// search positions stay correct.
  void setContent(String plainText) {
    _currentContent = plainText;
  }

  // ── Search lifecycle ─────────────────────────────────────────────────────

  void open() {
    _isActive = true;
    _onStateChanged();
  }

  void close() {
    _isActive = false;
    _textController.clear();
    _matches.clear();
    _currentMatchIndex = -1;
    _onStateChanged();
  }

  // ── Search execution ─────────────────────────────────────────────────────

  void performSearch(String query) {
    query = query.trim();
    if (query.isEmpty) {
      _matches.clear();
      _currentMatchIndex = -1;
      _onStateChanged();
      return;
    }

    final String plainContent = _currentContent;
    final List<int> matches = [];
    final lowerContent = plainContent.toLowerCase();
    final lowerQuery = query.toLowerCase();

    String strQuery = lowerQuery.replaceAll("[-\\[\\]\\+\\*\"\\\\().{}]+", "");
    final List<String> listQuery = strQuery.split(RegExp(r"[ \t]+"));

    final pattern = RegExp(
      listQuery.where((w) => w.isNotEmpty).map(RegExp.escape).join('[^.!?]*'),
      caseSensitive: false,
    );

    for (final match in pattern.allMatches(lowerContent)) {
      matches.add(match.start);
    }

    _matches = matches;
    _currentMatchIndex = matches.isNotEmpty ? 0 : -1;
    _onStateChanged();
  }

  // ── Match navigation ─────────────────────────────────────────────────────

  void previousMatch() {
    if (_currentMatchIndex > 0) {
      HapticFeedback.selectionClick();
      _currentMatchIndex--;
      _onStateChanged();
      scrollToMatch();
    }
  }

  void nextMatch() {
    if (_currentMatchIndex < _matches.length - 1) {
      HapticFeedback.selectionClick();
      _currentMatchIndex++;
      _onStateChanged();
      scrollToMatch();
    }
  }

  /// Triggers a rebuild then scrolls after the frame.
  void scrollToMatch() {
    _onStateChanged();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      performScrollToMatch();
    });
  }

  void performScrollToMatch() {
    if (!_scrollController.hasClients ||
        _matches.isEmpty ||
        _currentMatchIndex < 0) {
      return;
    }

    try {
      final matchPosition = _matches[_currentMatchIndex];
      final plainText = _currentContent;

      if (plainText.isEmpty || matchPosition >= plainText.length) return;

      final totalTextLength = plainText.length;
      final matchRatio = matchPosition / totalTextLength;

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

  // ── Highlight helpers ────────────────────────────────────────────────────

  /// Strips HTML tags and returns plain text. Used to cache content for search
  /// offset calculations.
  static String getPlainText(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>', multiLine: true), '').trim();
  }

  /// Returns [html] with search matches wrapped in `<span>` highlight tags
  /// (used by the CustomHtmlWidget path).
  String getHighlightedContent(String html) {
    if (_textController.text.isEmpty || _matches.isEmpty) {
      return html;
    }

    final String highlighted = html;
    final query = _textController.text.trim();
    String strQuery = query.replaceAll("[-\\[\\]\\+\\*\"\\\\().{}]+", "");
    final List<String> listQuery = strQuery.split(RegExp(r"[ \t]+"));

    final pattern = RegExp(
      listQuery.where((w) => w.isNotEmpty).map(RegExp.escape).join('[^.!?]*'),
      caseSensitive: false,
    );

    final anchorRegExp = RegExp(
      r'(<a\b[^>]*>)',
      caseSensitive: false,
      dotAll: true,
    );
    final anchorMatches = anchorRegExp.allMatches(highlighted).toList();

    final matches = pattern.allMatches(highlighted).toList();
    if (matches.isEmpty) return html;

    final buffer = StringBuffer();
    int lastMatchEnd = 0;
    int matchCounter = 0;

    for (final match in matches) {
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
          buffer.write(highlighted.substring(match.start, match.end));
          lastMatchEnd = match.end;
          isInsideAnchor = true;
          break;
        }
      }

      if (isInsideAnchor) {
        continue;
      }

      final isCurrentMatch = matchCounter == _currentMatchIndex;
      final matchId = 'search-match-$matchCounter';
      final highlightClass =
          isCurrentMatch ? 'current-highlight' : 'search-highlight';
      final backgroundColor = isCurrentMatch ? '#ff9800' : '#ffeb3b';

      buffer.write(
        '<span id="$matchId" class="$highlightClass" style="background-color: $backgroundColor; color: black; padding: 2px; border-radius: 2px;">${match.group(0)}</span>',
      );

      lastMatchEnd = match.end;
      matchCounter++;
    }

    buffer.write(highlighted.substring(lastMatchEnd));
    return buffer.toString();
  }

  /// Returns [content] with search matches wrapped in `<mark>` tags
  /// (used by the HtmlToTextSpan path).
  String getHighlightedContentForTextSpan(String content) {
    if (_textController.text.isEmpty || _matches.isEmpty) {
      return content;
    }

    final query = _textController.text.trim();
    String strQuery = query.replaceAll("[-\\[\\]\\+\\*\"\\\\().{}]+", "");
    final List<String> listQuery = strQuery.split(RegExp(r"[ \t]+"));

    final pattern = RegExp(
      listQuery.where((w) => w.isNotEmpty).map(RegExp.escape).join('[^.!?]*'),
      caseSensitive: false,
    );

    final plainText = getPlainText(content);
    final plainMatches = pattern.allMatches(plainText).toList();
    if (plainMatches.isEmpty) return content;

    final buffer = StringBuffer();
    int plainPos = 0;
    int matchCounter = 0;
    int currentPlainMatchIndex = 0;

    for (int i = 0; i < content.length; i++) {
      final char = content[i];

      if (char == '<') {
        final tagEnd = content.indexOf('>', i);
        if (tagEnd != -1) {
          buffer.write(content.substring(i, tagEnd + 1));
          i = tagEnd;
          continue;
        }
      }

      if (currentPlainMatchIndex < plainMatches.length) {
        final match = plainMatches[currentPlainMatchIndex];

        if (plainPos == match.start) {
          final isCurrentMatch = matchCounter == _currentMatchIndex;
          buffer.write('<mark data-current="$isCurrentMatch">');

          final matchLength = match.end - match.start;
          int charsWritten = 0;
          int j = i;

          while (charsWritten < matchLength && j < content.length) {
            final c = content[j];
            if (c == '<') {
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

  // ── Lifecycle ────────────────────────────────────────────────────────────

  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
  }
}
