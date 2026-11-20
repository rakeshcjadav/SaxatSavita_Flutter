import 'dart:math';

class SavedSuvicharSticker {
  final String assetPath;
  final double dx;
  final double dy;
  final double size;
  final double rotation;

  const SavedSuvicharSticker({
    required this.assetPath,
    required this.dx,
    required this.dy,
    this.size = 60,
    this.rotation = 0,
  });

  factory SavedSuvicharSticker.fromJson(Map<String, dynamic> json) {
    return SavedSuvicharSticker(
      assetPath: json['assetPath'] as String? ?? '',
      dx: (json['dx'] as num?)?.toDouble() ?? 0,
      dy: (json['dy'] as num?)?.toDouble() ?? 0,
      size: (json['size'] as num?)?.toDouble() ?? 60,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'assetPath': assetPath,
      'dx': dx,
      'dy': dy,
      'size': size,
      'rotation': rotation,
    };
  }

  @override
  bool operator ==(Object other) {
    return other is SavedSuvicharSticker &&
        other.assetPath == assetPath &&
        other.dx == dx &&
        other.dy == dy &&
        other.size == size &&
        other.rotation == rotation;
  }

  @override
  int get hashCode => Object.hash(assetPath, dx, dy, size, rotation);
}

class SavedSuvichar {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String quote;
  final String author;
  final int partNumber;
  final int kiranIndex;
  final int templateIndex;
  final String gradientKey;
  final int customGradientStart;
  final int customGradientEnd;
  final double fontSize;
  final double authorFontSize;
  final double imageWidth;
  final bool isQuoteBold;
  final bool isQuoteItalic;
  final bool isAuthorBold;
  final bool isAuthorItalic;
  final int? quoteTextColor;
  final int? authorTextColor;
  final Map<int, int> wordColors;
  final bool showUserAvatar;
  final bool showUserName;
  final String fontFamily;
  final List<SavedSuvicharSticker> stickers;

  const SavedSuvichar({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.quote,
    this.author = '',
    this.partNumber = -1,
    this.kiranIndex = -1,
    this.templateIndex = 8,
    this.gradientKey = 'orange',
    this.customGradientStart = 0xFFE64A19,
    this.customGradientEnd = 0xFFFFA726,
    this.fontSize = 24,
    this.authorFontSize = 16,
    this.imageWidth = 370,
    this.isQuoteBold = true,
    this.isQuoteItalic = false,
    this.isAuthorBold = false,
    this.isAuthorItalic = true,
    this.quoteTextColor,
    this.authorTextColor,
    this.wordColors = const {},
    this.showUserAvatar = false,
    this.showUserName = false,
    this.fontFamily = 'NotoSansGujarati',
    this.stickers = const [],
  });

  factory SavedSuvichar.fromJson(Map<String, dynamic> json) {
    return SavedSuvichar(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      quote: json['quote'] as String? ?? '',
      author: json['author'] as String? ?? '',
      partNumber: (json['partNumber'] as num?)?.toInt() ?? -1,
      kiranIndex: (json['kiranIndex'] as num?)?.toInt() ?? -1,
      templateIndex: (json['templateIndex'] as num?)?.toInt() ?? 8,
      gradientKey: json['gradientKey'] as String? ?? 'orange',
      customGradientStart:
          (json['customGradientStart'] as num?)?.toInt() ?? 0xFFE64A19,
      customGradientEnd:
          (json['customGradientEnd'] as num?)?.toInt() ?? 0xFFFFA726,
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 24,
      authorFontSize: (json['authorFontSize'] as num?)?.toDouble() ?? 16,
      imageWidth: (json['imageWidth'] as num?)?.toDouble() ?? 370,
      isQuoteBold: json['isQuoteBold'] as bool? ?? true,
      isQuoteItalic: json['isQuoteItalic'] as bool? ?? false,
      isAuthorBold: json['isAuthorBold'] as bool? ?? false,
      isAuthorItalic: json['isAuthorItalic'] as bool? ?? true,
      quoteTextColor: (json['quoteTextColor'] as num?)?.toInt(),
      authorTextColor: (json['authorTextColor'] as num?)?.toInt(),
      wordColors: _wordColorsFromJson(json['wordColors']),
      showUserAvatar: json['showUserAvatar'] as bool? ?? false,
      showUserName: json['showUserName'] as bool? ?? false,
      fontFamily: json['fontFamily'] as String? ?? 'NotoSansGujarati',
      stickers: _stickersFromJson(json['stickers']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'quote': quote,
      'author': author,
      'partNumber': partNumber,
      'kiranIndex': kiranIndex,
      'templateIndex': templateIndex,
      'gradientKey': gradientKey,
      'customGradientStart': customGradientStart,
      'customGradientEnd': customGradientEnd,
      'fontSize': fontSize,
      'authorFontSize': authorFontSize,
      'imageWidth': imageWidth,
      'isQuoteBold': isQuoteBold,
      'isQuoteItalic': isQuoteItalic,
      'isAuthorBold': isAuthorBold,
      'isAuthorItalic': isAuthorItalic,
      'quoteTextColor': quoteTextColor,
      'authorTextColor': authorTextColor,
      'wordColors': {
        for (final entry in wordColors.entries) '${entry.key}': entry.value,
      },
      'showUserAvatar': showUserAvatar,
      'showUserName': showUserName,
      'fontFamily': fontFamily,
      'stickers': stickers.map((sticker) => sticker.toJson()).toList(),
    };
  }

  SavedSuvichar copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? quote,
    String? author,
    int? partNumber,
    int? kiranIndex,
    int? templateIndex,
    String? gradientKey,
    int? customGradientStart,
    int? customGradientEnd,
    double? fontSize,
    double? authorFontSize,
    double? imageWidth,
    bool? isQuoteBold,
    bool? isQuoteItalic,
    bool? isAuthorBold,
    bool? isAuthorItalic,
    int? quoteTextColor,
    int? authorTextColor,
    bool clearQuoteTextColor = false,
    bool clearAuthorTextColor = false,
    Map<int, int>? wordColors,
    bool? showUserAvatar,
    bool? showUserName,
    String? fontFamily,
    List<SavedSuvicharSticker>? stickers,
  }) {
    return SavedSuvichar(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      quote: quote ?? this.quote,
      author: author ?? this.author,
      partNumber: partNumber ?? this.partNumber,
      kiranIndex: kiranIndex ?? this.kiranIndex,
      templateIndex: templateIndex ?? this.templateIndex,
      gradientKey: gradientKey ?? this.gradientKey,
      customGradientStart: customGradientStart ?? this.customGradientStart,
      customGradientEnd: customGradientEnd ?? this.customGradientEnd,
      fontSize: fontSize ?? this.fontSize,
      authorFontSize: authorFontSize ?? this.authorFontSize,
      imageWidth: imageWidth ?? this.imageWidth,
      isQuoteBold: isQuoteBold ?? this.isQuoteBold,
      isQuoteItalic: isQuoteItalic ?? this.isQuoteItalic,
      isAuthorBold: isAuthorBold ?? this.isAuthorBold,
      isAuthorItalic: isAuthorItalic ?? this.isAuthorItalic,
      quoteTextColor:
          clearQuoteTextColor ? null : (quoteTextColor ?? this.quoteTextColor),
      authorTextColor:
          clearAuthorTextColor
              ? null
              : (authorTextColor ?? this.authorTextColor),
      wordColors: wordColors ?? this.wordColors,
      showUserAvatar: showUserAvatar ?? this.showUserAvatar,
      showUserName: showUserName ?? this.showUserName,
      fontFamily: fontFamily ?? this.fontFamily,
      stickers: stickers ?? this.stickers,
    );
  }

  /// Content match that ignores save timestamps.
  bool hasSameContent(SavedSuvichar other) {
    return other.id == id &&
        other.quote == quote &&
        other.author == author &&
        other.partNumber == partNumber &&
        other.kiranIndex == kiranIndex &&
        other.templateIndex == templateIndex &&
        other.gradientKey == gradientKey &&
        other.customGradientStart == customGradientStart &&
        other.customGradientEnd == customGradientEnd &&
        other.fontSize == fontSize &&
        other.authorFontSize == authorFontSize &&
        other.imageWidth == imageWidth &&
        other.isQuoteBold == isQuoteBold &&
        other.isQuoteItalic == isQuoteItalic &&
        other.isAuthorBold == isAuthorBold &&
        other.isAuthorItalic == isAuthorItalic &&
        other.quoteTextColor == quoteTextColor &&
        other.authorTextColor == authorTextColor &&
        _mapEquals(other.wordColors, wordColors) &&
        other.showUserAvatar == showUserAvatar &&
        other.showUserName == showUserName &&
        other.fontFamily == fontFamily &&
        _listEquals(other.stickers, stickers);
  }

  @override
  bool operator ==(Object other) {
    return other is SavedSuvichar &&
        other.id == id &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.quote == quote &&
        other.author == author &&
        other.partNumber == partNumber &&
        other.kiranIndex == kiranIndex &&
        other.templateIndex == templateIndex &&
        other.gradientKey == gradientKey &&
        other.customGradientStart == customGradientStart &&
        other.customGradientEnd == customGradientEnd &&
        other.fontSize == fontSize &&
        other.authorFontSize == authorFontSize &&
        other.imageWidth == imageWidth &&
        other.isQuoteBold == isQuoteBold &&
        other.isQuoteItalic == isQuoteItalic &&
        other.isAuthorBold == isAuthorBold &&
        other.isAuthorItalic == isAuthorItalic &&
        other.quoteTextColor == quoteTextColor &&
        other.authorTextColor == authorTextColor &&
        _mapEquals(other.wordColors, wordColors) &&
        other.showUserAvatar == showUserAvatar &&
        other.showUserName == showUserName &&
        other.fontFamily == fontFamily &&
        _listEquals(other.stickers, stickers);
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    quote,
    author,
    partNumber,
    kiranIndex,
    templateIndex,
    gradientKey,
    Object.hashAll(wordColors.entries),
    Object.hashAll(stickers),
  );
}

String newSavedSuvicharId() {
  final now = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
  final salt = Random().nextInt(0x7fffffff).toRadixString(16);
  return '$now$salt';
}

Map<int, int> _wordColorsFromJson(dynamic raw) {
  if (raw is! Map) return {};
  final colors = <int, int>{};
  raw.forEach((key, value) {
    final index = int.tryParse(key.toString());
    final color = value is num ? value.toInt() : int.tryParse('$value');
    if (index != null && color != null) {
      colors[index] = color;
    }
  });
  return colors;
}

List<SavedSuvicharSticker> _stickersFromJson(dynamic raw) {
  if (raw is! List) return [];
  return raw
      .whereType<Map>()
      .map(
        (entry) =>
            SavedSuvicharSticker.fromJson(Map<String, dynamic>.from(entry)),
      )
      .toList();
}

bool _mapEquals(Map<int, int> a, Map<int, int> b) {
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (b[entry.key] != entry.value) return false;
  }
  return true;
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
