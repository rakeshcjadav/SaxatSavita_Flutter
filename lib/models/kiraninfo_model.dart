class KiranInfo {
  final int index;
  final String number;
  final String title;
  final int wordCount;
  final String date; // 'DD-MM-YY' ASCII, empty if unknown

  KiranInfo({
    required this.index,
    required this.number,
    required this.title,
    required this.wordCount,
    this.date = '',
  });

  factory KiranInfo.fromMap(Map<String, dynamic> map) {
    return KiranInfo(
      index: map['index'] ?? 0,
      number: map['number'] ?? '',
      title: map['title'] ?? '',
      wordCount: map['word_count'] ?? 0,
      date: map['date'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'index': index,
      'number': number,
      'title': title,
      'word_count': wordCount,
      'date': date,
    };
  }
}
