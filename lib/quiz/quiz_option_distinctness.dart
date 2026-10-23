/// Lexical distinctness for Gujarati and English quiz choices.
///
/// Dated daily-quiz options are often other lines from the same teaching.
/// Those lines repeat the same claim with a particle, a suffix, or a shorter
/// wording. This check treats that as one choice, while a single substituted
/// content word (મોક્ષ / બંધન, જ્ઞાની / અજ્ઞાની, two different years) stays
/// distinct. It does not use a model; script variants such as ZWJ/ZWNJ are
/// folded so they are not treated as a different answer.
class QuizOptionDistinctness {
  static bool tooSimilar(String a, String b) {
    final left = _normalize(a);
    final right = _normalize(b);
    if (left.isEmpty || right.isEmpty) return left == right;
    if (left == right) return true;

    final compactLeft = left.replaceAll(' ', '');
    final compactRight = right.replaceAll(' ', '');
    if (compactLeft == compactRight) return true;

    final leftTokens = _tokens(left);
    final rightTokens = _tokens(right);
    if (leftTokens.isEmpty || rightTokens.isEmpty) {
      return _compactContained(compactLeft, compactRight);
    }

    final aligned = _align(leftTokens, rightTokens);
    // One content word swapped (મોક્ષ / બંધન) is a real contrast.
    if (aligned.onlyLeft.length == 1 &&
        aligned.onlyRight.length == 1 &&
        aligned.shared.isNotEmpty) {
      return false;
    }
    if (aligned.shared.isNotEmpty &&
        aligned.onlyLeft.isEmpty &&
        aligned.onlyRight.isEmpty) {
      return true;
    }

    final shorterCount =
        leftTokens.length <= rightTokens.length
            ? leftTokens.length
            : rightTokens.length;
    final shorterOnly =
        leftTokens.length <= rightTokens.length
            ? aligned.onlyLeft
            : aligned.onlyRight;
    if (shorterCount >= 2 && shorterOnly.isEmpty) return true;

    final inter = aligned.shared.length;
    final union = inter + aligned.onlyLeft.length + aligned.onlyRight.length;
    if (inter >= 2 && union > 0 && inter / union >= 0.62) return true;
    if (inter >= 2 && shorterCount >= 3 && inter / shorterCount >= 0.8) {
      return true;
    }
    if (_compactContained(compactLeft, compactRight)) return true;
    if (_sharesPhrase(leftTokens, rightTokens, shorterCount)) return true;
    return _dice(compactLeft, compactRight) >= 0.72;
  }

  /// Four non-empty choices with no near-duplicate pair.
  static bool isDistinctSet(List<String> options) {
    if (options.length != 4) return false;
    for (final option in options) {
      if (option.trim().isEmpty) return false;
    }
    for (var i = 0; i < options.length; i++) {
      for (var j = i + 1; j < options.length; j++) {
        if (tooSimilar(options[i], options[j])) return false;
      }
    }
    return true;
  }

  static bool _compactContained(String left, String right) {
    final shorter = left.length <= right.length ? left : right;
    final longer = left.length <= right.length ? right : left;
    if (shorter.length < 12) return false;
    if (!longer.contains(shorter)) return false;
    return shorter.length / longer.length >= 0.62;
  }

  static bool _sharesPhrase(
    List<String> left,
    List<String> right,
    int shorterCount,
  ) {
    if (shorterCount == 0) return false;
    for (final length in const [4, 3, 2]) {
      final common = _phrases(
        left,
        length,
      ).intersection(_phrases(right, length));
      if (common.isEmpty) continue;
      final longest = common.reduce(
        (a, b) =>
            a.replaceAll(' ', '').length >= b.replaceAll(' ', '').length
                ? a
                : b,
      );
      final chars = longest.replaceAll(' ', '').length;
      final fraction = length / shorterCount;
      if (length >= 4) return true;
      if (length == 3 && fraction >= 0.5) return true;
      if (length == 2 && fraction >= 0.67 && chars >= 8) return true;
    }
    return false;
  }

  static Set<String> _phrases(List<String> tokens, int length) {
    final phrases = <String>{};
    for (var i = 0; i <= tokens.length - length; i++) {
      phrases.add(tokens.sublist(i, i + length).join(' '));
    }
    return phrases;
  }

  static double _dice(String left, String right) {
    if (left.length < 18 || right.length < 18) return 0;
    final leftGrams = _grams(left);
    final rightGrams = _grams(right);
    if (leftGrams.isEmpty || rightGrams.isEmpty) return 0;
    var shared = 0;
    for (final gram in leftGrams) {
      if (rightGrams.contains(gram)) shared += 1;
    }
    return 2 * shared / (leftGrams.length + rightGrams.length);
  }

  static Set<String> _grams(String text) {
    final grams = <String>{};
    for (var i = 0; i <= text.length - 3; i++) {
      grams.add(text.substring(i, i + 3));
    }
    return grams;
  }

  static _Alignment _align(List<String> left, List<String> right) {
    final used = List<bool>.filled(right.length, false);
    final shared = <String>[];
    final onlyLeft = <String>[];
    for (final token in left) {
      var found = -1;
      for (var i = 0; i < right.length; i++) {
        if (!used[i] && _sameToken(token, right[i])) {
          found = i;
          break;
        }
      }
      if (found < 0) {
        onlyLeft.add(token);
      } else {
        used[found] = true;
        shared.add(token);
      }
    }
    final onlyRight = <String>[
      for (var i = 0; i < right.length; i++)
        if (!used[i]) right[i],
    ];
    return _Alignment(shared, onlyLeft, onlyRight);
  }

  /// Gender or number ending only. A leading અ (જ્ઞાની / અજ્ઞાની) stays different.
  static bool _sameToken(String a, String b) {
    if (a == b) return true;
    // ૨૦૩૧ and ૨૦૩૨ differ by one digit; that is a different year, not a spelling.
    if (_digits.hasMatch(a) || _digits.hasMatch(b)) return false;
    if ((a.length - b.length).abs() > 1) return false;
    if (a.length < 4 || b.length < 4) return false;
    if (a.length == b.length) {
      var diffAt = -1;
      for (var i = 0; i < a.length; i++) {
        if (a.codeUnitAt(i) != b.codeUnitAt(i)) {
          if (diffAt != -1) return false;
          diffAt = i;
        }
      }
      return diffAt > 0;
    }
    final shorter = a.length < b.length ? a : b;
    final longer = a.length < b.length ? b : a;
    return longer.startsWith(shorter);
  }

  static String _normalize(String text) {
    final buffer = StringBuffer();
    for (final rune in text.runes) {
      if (rune == 0x200b ||
          rune == 0x200c ||
          rune == 0x200d ||
          rune == 0xfeff ||
          rune == 0x00ad) {
        continue;
      }
      if (rune == 0x00a0) {
        buffer.write(' ');
        continue;
      }
      buffer.writeCharCode(rune);
    }
    var normalized = buffer.toString().toLowerCase();
    normalized = normalized.replaceAll(_hyphens, ' ');
    normalized = normalized.replaceAll(_punctuation, ' ');
    return normalized.replaceAll(_whitespace, ' ').trim();
  }

  static List<String> _tokens(String normalized) {
    final tokens = <String>[];
    for (final raw in normalized.split(' ')) {
      if (raw.isEmpty) continue;
      final token = _stem(raw);
      if (token.isEmpty || _stopwords.contains(token)) continue;
      final numeric = _digits.hasMatch(token);
      if (token.length < 2 && !numeric) continue;
      tokens.add(token);
    }
    return tokens;
  }

  static String _stem(String token) {
    for (final suffix in _suffixes) {
      if (token.endsWith(suffix) && token.length - suffix.length >= 3) {
        return token.substring(0, token.length - suffix.length);
      }
    }
    return token;
  }

  static final _hyphens = RegExp(r'[-–—_+|/]+');
  static final _punctuation = RegExp(
    r'''[.,;:!?…"'“”‘’()\[\]{}<>«»\\@#$%^&*=~`।]+''',
  );
  static final _whitespace = RegExp(r'\s+');
  static final _digits = RegExp(r'^[0-9૦-૯]+$');

  static const _suffixes = [
    'માંથી',
    'વાળું',
    'વાળો',
    'વાળી',
    'વાળા',
    'નું',
    'નો',
    'ના',
    'ની',
    'ને',
    'માં',
    'થી',
  ];

  static const _stopwords = {
    'અને',
    'તો',
    'ન',
    'નહીં',
    'નથી',
    'એ',
    'છે',
    'છો',
    'છું',
    'નું',
    'નો',
    'ના',
    'ની',
    'ને',
    'માં',
    'થી',
    'પણ',
    'જ',
    'એટલે',
    'શું',
    'કે',
    'તે',
    'તેઓ',
    'આ',
    'એક',
    'બે',
    'વિષે',
    'અંગે',
    'થાય',
    'થયો',
    'થઈ',
    'થયું',
    'થયા',
    'થયે',
    'થશે',
    'થતું',
    'થતી',
    'થતા',
    'હોય',
    'હતા',
    'હતી',
    'હતો',
    'તોય',
    'તોપણ',
    'વિના',
    'સાથે',
    'પર',
    'માટે',
    'કરવો',
    'કરે',
    'કહ્યું',
    'કહેવાય',
    'એવો',
    'એવી',
    'એવું',
    'જેવો',
    'જેવી',
    'જેવું',
    'તેવો',
    'તેવી',
    'તેમ',
    'ય',
    'જો',
    'ત્યારે',
    'પછી',
    'પહેલાં',
    'બંને',
    'કોઈ',
    'કોણ',
    'તેને',
    'તેમાં',
    'એમ',
    'આમ',
    'ત્યાં',
    'અહીં',
    'જેમ',
    'એટલામાં',
    'જાય',
    'આવે',
    'the',
    'a',
    'an',
    'of',
    'and',
    'or',
    'to',
    'in',
    'is',
    'are',
    'was',
    'be',
    'it',
    'that',
    'this',
    'for',
    'with',
    'on',
    'as',
    'by',
    'at',
    'from',
  };
}

class _Alignment {
  const _Alignment(this.shared, this.onlyLeft, this.onlyRight);

  final List<String> shared;
  final List<String> onlyLeft;
  final List<String> onlyRight;
}
