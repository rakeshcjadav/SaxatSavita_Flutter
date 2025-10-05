class Range {
  final int lower;
  final int upper;
  Range(this.lower, this.upper);
}

class KiranUserInfo {
  final int kiranIndex;
  final int listIndex;
  final int partNumber;
  int isFavourite;
  int readCount;
  String? note;
  int progress;
  DateTime? updatedAt;

  KiranUserInfo({
    required this.kiranIndex,
    required this.listIndex,
    required this.partNumber,
    this.isFavourite = 0,
    this.readCount = 0,
    this.note,
    this.progress = 0,
    this.updatedAt,
  });

  String get notes => note ?? '';

  void toggleFavourite() {
    isFavourite = isFavourite == 1 ? 0 : 1;
    updatedAt = DateTime.now();
  }

  factory KiranUserInfo.fromJson(Map<String, dynamic> json) {
    return KiranUserInfo(
      kiranIndex: json['kiranIndex'] ?? 0,
      listIndex: json['listIndex'] ?? 0,
      partNumber: json['partNumber'] ?? 0,
      isFavourite: json['isFavourite'] ?? 0,
      readCount: json['readCount'] ?? 0,
      note: json['note'],
      progress: json['progress'] ?? 0,
      updatedAt:
          json['updatedAt'] != null
              ? DateTime.tryParse(json['updatedAt'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'kiranIndex': kiranIndex,
      'listIndex': listIndex,
      'partNumber': partNumber,
      'isFavourite': isFavourite,
      'readCount': readCount,
      'note': note,
      'progress': progress,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
