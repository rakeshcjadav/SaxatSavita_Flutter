class KiranInfo {
  final int index;
  final String number;
  final String title;
  final int wordCount;
  final String date; // 'DD-MM-YY' ASCII, empty if unknown
  final String place; // first village, empty if unknown
  final List<String> places; // unique villages in sitting order

  KiranInfo({
    required this.index,
    required this.number,
    required this.title,
    required this.wordCount,
    this.date = '',
    this.place = '',
    this.places = const [],
  });

  /// Villages from first sitting to last, e.g. `પીપલાણા → જૂનાગઢ`.
  String get placeLine {
    if (places.isNotEmpty) return places.join(' → ');
    return place;
  }

  bool visitsVillage(String village) =>
      places.contains(village) || (places.isEmpty && place == village);

  factory KiranInfo.fromMap(Map<String, dynamic> map) {
    final String place = (map['place'] as String? ?? '').trim();
    final List<String> places = List<String>.from(
      (map['places'] as List<dynamic>? ?? []).map((e) => e.toString().trim()),
    )..removeWhere((e) => e.isEmpty);
    if (places.isEmpty && place.isNotEmpty) {
      places.add(place);
    }
    return KiranInfo(
      index: map['index'] ?? 0,
      number: map['number'] ?? '',
      title: map['title'] ?? '',
      wordCount: map['word_count'] ?? 0,
      date: map['date'] ?? '',
      place: place.isNotEmpty ? place : (places.isNotEmpty ? places.first : ''),
      places: places,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'index': index,
      'number': number,
      'title': title,
      'word_count': wordCount,
      'date': date,
      'place': place,
      'places': places,
    };
  }
}
