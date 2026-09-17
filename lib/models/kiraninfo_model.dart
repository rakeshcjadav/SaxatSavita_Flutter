class KiranHaribhakt {
  final String name;
  final String role; // host | reader

  const KiranHaribhakt({required this.name, required this.role});

  bool get isHost => role == 'host';

  factory KiranHaribhakt.fromMap(Map<String, dynamic> map) {
    return KiranHaribhakt(
      name: (map['name'] as String? ?? '').trim(),
      role: (map['role'] as String? ?? 'reader').trim(),
    );
  }

  Map<String, dynamic> toMap() => {'name': name, 'role': role};
}

class KiranInfo {
  final int index;
  final String number;
  final String title;
  final int wordCount;
  final String date; // 'DD-MM-YY' ASCII, empty if unknown
  final String place; // first village, empty if unknown
  final List<String> places; // unique villages in sitting order
  final List<KiranHaribhakt> haribhakts;

  KiranInfo({
    required this.index,
    required this.number,
    required this.title,
    required this.wordCount,
    this.date = '',
    this.place = '',
    this.places = const [],
    this.haribhakts = const [],
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
    final List<KiranHaribhakt> haribhakts =
        (map['haribhakts'] as List<dynamic>? ?? [])
            .whereType<Map>()
            .map(
              (item) => KiranHaribhakt.fromMap(Map<String, dynamic>.from(item)),
            )
            .where((item) => item.name.isNotEmpty)
            .toList();
    return KiranInfo(
      index: map['index'] ?? 0,
      number: map['number'] ?? '',
      title: map['title'] ?? '',
      wordCount: map['word_count'] ?? 0,
      date: map['date'] ?? '',
      place: place.isNotEmpty ? place : (places.isNotEmpty ? places.first : ''),
      places: places,
      haribhakts: haribhakts,
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
      'haribhakts': haribhakts.map((item) => item.toMap()).toList(),
    };
  }
}
