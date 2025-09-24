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

  factory KiranUserInfo.fromJson(Map<String, dynamic> json) {
    return KiranUserInfo(
      kiranIndex: json['kiranIndex'],
      listIndex: json['listIndex'],
      partNumber: json['partNumber'],
      isFavourite: json['isFavourite'],
      readCount: json['readCount'],
      note: json['note'],
      progress: json['progress'],
      updatedAt: json['updatedAt'],
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
