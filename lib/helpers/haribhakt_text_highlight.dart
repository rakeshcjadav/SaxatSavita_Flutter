/// Finds haribhakt names in kiran HTML and wraps them for highlighting.
class HaribhaktTextHighlight {
  static const defaultCurrentColor = '#6A1B9A';
  static const defaultOtherColor = '#0277BD';

  static const _gujLetter = '\u0A80-\u0AFF';

  static String wrap({
    required String html,
    required List<String> names,
    String? focusedName,
    String currentColor = defaultCurrentColor,
    String otherColor = defaultOtherColor,
  }) {
    final unique = _uniqueNames(names);
    if (html.isEmpty || unique.isEmpty) return html;

    final plain = stripTags(html);
    final matches = findMatches(plain, unique);
    if (matches.isEmpty) return html;

    return _wrapRanges(
      html,
      matches,
      focusedName: focusedName?.trim(),
      currentColor: currentColor,
      otherColor: otherColor,
    );
  }

  static int? firstOffset(String plainText, String name) {
    final trimmed = name.trim();
    if (plainText.isEmpty || trimmed.isEmpty) return null;
    final match = patternForName(trimmed).firstMatch(plainText);
    return match?.start;
  }

  static List<HaribhaktNameHit> findMatches(String plainText, List<String> names) {
    final unique = _uniqueNames(names);
    if (plainText.isEmpty || unique.isEmpty) return const [];

    unique.sort((a, b) {
      final byLength = b.length.compareTo(a.length);
      return byLength != 0 ? byLength : a.compareTo(b);
    });

    final hits = <HaribhaktNameHit>[];
    for (final name in unique) {
      for (final match in patternForName(name).allMatches(plainText)) {
        final hit = HaribhaktNameHit(
          start: match.start,
          end: match.end,
          name: name,
        );
        if (hits.any((existing) => existing.overlaps(hit))) continue;
        hits.add(hit);
      }
    }
    hits.sort((a, b) => a.start.compareTo(b.start));
    return hits;
  }

  static RegExp patternForName(String name) {
    final tokens =
        name.trim().split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    if (tokens.isEmpty) return RegExp(r'(?!)');

    final parts = <String>[];
    for (var i = 0; i < tokens.length; i++) {
      var part = _honorificPattern(tokens[i]);
      if (i == tokens.length - 1) {
        part = '$part[$_gujLetter]*';
      }
      parts.add(part);
    }
    return RegExp(
      '(?<![$_gujLetter])${parts.join(r'\s+')}',
      unicode: true,
    );
  }

  static String stripTags(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>', multiLine: true), '');
  }

  static List<String> _uniqueNames(List<String> names) {
    final seen = <String>{};
    final out = <String>[];
    for (final name in names) {
      final trimmed = name.trim();
      if (trimmed.isEmpty || !seen.add(trimmed)) continue;
      out.add(trimmed);
    }
    return out;
  }

  static String _honorificPattern(String token) {
    var escaped = RegExp.escape(token);
    escaped = escaped.replaceAllMapped(
      RegExp('ભાઈ|ભાઇ'),
      (_) => '(?:ભાઈ|ભાઇ)',
    );
    escaped = escaped.replaceAllMapped(
      RegExp('બાઈ|બાઇ'),
      (_) => '(?:બાઈ|બાઇ)',
    );
    return escaped;
  }

  static bool _isCurrent(HaribhaktNameHit hit, String? focusedName) {
    if (focusedName == null || focusedName.isEmpty) return false;
    return hit.name == focusedName ||
        hit.name.startsWith('$focusedName ') ||
        focusedName.startsWith('${hit.name} ');
  }

  static String _wrapRanges(
    String html,
    List<HaribhaktNameHit> matches, {
    required String? focusedName,
    required String currentColor,
    required String otherColor,
  }) {
    final buffer = StringBuffer();
    var plainPos = 0;
    var matchIndex = 0;
    var inAnchor = false;

    for (var i = 0; i < html.length; i++) {
      final char = html[i];
      if (char == '<') {
        final tagEnd = html.indexOf('>', i);
        if (tagEnd != -1) {
          final tag = html.substring(i, tagEnd + 1);
          final lower = tag.toLowerCase();
          if (lower.startsWith('<a ') || lower == '<a>') {
            inAnchor = true;
          } else if (lower.startsWith('</a')) {
            inAnchor = false;
          }
          buffer.write(tag);
          i = tagEnd;
          continue;
        }
      }

      if (matchIndex < matches.length) {
        final match = matches[matchIndex];
        if (plainPos == match.start) {
          if (inAnchor) {
            matchIndex++;
          } else {
            final isCurrent = _isCurrent(match, focusedName);
            buffer.write(
              _openTag(
                isCurrent,
                currentColor: currentColor,
                otherColor: otherColor,
              ),
            );

            final matchLength = match.end - match.start;
            var charsWritten = 0;
            var j = i;
            while (charsWritten < matchLength && j < html.length) {
              final c = html[j];
              if (c == '<') {
                final tagEnd = html.indexOf('>', j);
                if (tagEnd != -1) {
                  buffer.write(html.substring(j, tagEnd + 1));
                  j = tagEnd + 1;
                  continue;
                }
              }
              buffer.write(c);
              charsWritten++;
              j++;
            }

            buffer.write(_closeTag());
            i = j - 1;
            plainPos += matchLength;
            matchIndex++;
            continue;
          }
        }
      }

      buffer.write(char);
      plainPos++;
    }

    return buffer.toString();
  }

  static String _openTag(
    bool isCurrent, {
    required String currentColor,
    required String otherColor,
  }) {
    final color = isCurrent ? currentColor : otherColor;
    final kind = isCurrent ? 'current' : 'other';
    return '<b data-haribhakt="$kind" style="color: $color; font-weight: 700;">';
  }

  static String _closeTag() => '</b>';
}

class HaribhaktNameHit {
  const HaribhaktNameHit({
    required this.start,
    required this.end,
    required this.name,
  });

  final int start;
  final int end;
  final String name;

  bool overlaps(HaribhaktNameHit other) =>
      start < other.end && other.start < end;
}
