class BookUserInfo {
  final String id;
  final int partNumber;
  int bookmarkKiranIndex;
  DateTime? updatedAt;

  BookUserInfo({
    required this.id,
    required this.partNumber,
    required this.bookmarkKiranIndex,
    this.updatedAt,
  });

  factory BookUserInfo.fromJson(Map<String, dynamic> json) {
    return BookUserInfo(
      id: json['id'] ?? '',
      partNumber: json['partNumber'] ?? 0,
      bookmarkKiranIndex: json['bookmarkKiranIndex'] ?? 1,
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
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
