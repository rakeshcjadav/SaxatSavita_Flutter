class KiranInfo {
  final int index;
  final String number;
  final String title;
  final int wordCount;

  KiranInfo({
    required this.index,
    required this.number,
    required this.title,
    required this.wordCount,
  });

  factory KiranInfo.fromMap(Map<String, dynamic> map) {
    return KiranInfo(
      index: map['index'],
      number: map['number'],
      title: map['title'],
      wordCount: map['word_count'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'index': index,
      'number': number,
      'title': title,
      'word_count': wordCount,
    };
  }
}
