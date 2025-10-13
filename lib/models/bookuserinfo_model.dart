class Bookmark {
  final int kiranIndex;
  final DateTime createdAt;

  Bookmark({required this.kiranIndex, required this.createdAt});

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      kiranIndex: json['kiranIndex'] ?? 1,
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'kiranIndex': kiranIndex, 'createdAt': createdAt.toIso8601String()};
  }
}

class BookUserInfo {
  final String id;
  final int partNumber;
  int bookmarkKiranIndex; // Keep for backward compatibility
  List<Bookmark> bookmarks; // New queue of bookmarks (max 5)
  DateTime? updatedAt;

  BookUserInfo({
    required this.id,
    required this.partNumber,
    required this.bookmarkKiranIndex,
    List<Bookmark>? bookmarks,
    this.updatedAt,
  }) : bookmarks = bookmarks ?? [];

  // Get the most recent bookmark
  Bookmark? get latestBookmark {
    if (bookmarks.isEmpty) return null;
    return bookmarks.first;
  }

  // Add a new bookmark to the queue (max 5)
  void addBookmark(int kiranIndex) {
    // Remove existing bookmark with same kiranIndex if it exists
    bookmarks.removeWhere((bookmark) => bookmark.kiranIndex == kiranIndex);

    // Add new bookmark at the beginning
    bookmarks.insert(
      0,
      Bookmark(kiranIndex: kiranIndex, createdAt: DateTime.now()),
    );

    // Keep only the latest 5 bookmarks
    if (bookmarks.length > 5) {
      bookmarks = bookmarks.take(5).toList();
    }

    // Update the legacy field for backward compatibility
    bookmarkKiranIndex = kiranIndex;
    updatedAt = DateTime.now();
  }

  // Remove a specific bookmark
  void removeBookmark(int kiranIndex) {
    bookmarks.removeWhere((bookmark) => bookmark.kiranIndex == kiranIndex);

    // Update legacy field to the latest bookmark or default to 1
    if (bookmarks.isNotEmpty) {
      bookmarkKiranIndex = bookmarks.first.kiranIndex;
    } else {
      bookmarkKiranIndex = 1;
    }
    updatedAt = DateTime.now();
  }

  // Check if a kiran is bookmarked
  bool isKiranBookmarked(int kiranIndex) {
    return bookmarks.any((bookmark) => bookmark.kiranIndex == kiranIndex);
  }

  factory BookUserInfo.fromJson(Map<String, dynamic> json) {
    List<Bookmark> bookmarks = [];
    if (json['bookmarks'] != null) {
      bookmarks =
          (json['bookmarks'] as List)
              .map((bookmarkJson) => Bookmark.fromJson(bookmarkJson))
              .toList();
    }

    return BookUserInfo(
      id: json['id'] ?? '',
      partNumber: json['partNumber'] ?? 0,
      bookmarkKiranIndex: json['bookmarkKiranIndex'] ?? 1,
      bookmarks: bookmarks,
      updatedAt:
          json['updatedAt'] != null
              ? DateTime.tryParse(json['updatedAt'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'partNumber': partNumber,
      'bookmarkKiranIndex': bookmarkKiranIndex,
      'bookmarks': bookmarks.map((bookmark) => bookmark.toJson()).toList(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
