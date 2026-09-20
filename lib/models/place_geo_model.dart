class PlaceGeo {
  final String id;
  final List<String> names;
  final String en;
  final String district;
  final String region;
  final double lat;
  final double lng;

  const PlaceGeo({
    required this.id,
    required this.names,
    required this.en,
    required this.district,
    required this.region,
    required this.lat,
    required this.lng,
  });

  String get displayName => names.isNotEmpty ? names.first : en;

  bool get isSaurashtra => region == 'saurashtra';

  bool matches(String name) => names.contains(name.trim());

  factory PlaceGeo.fromMap(Map<String, dynamic> map) {
    final names =
        (map['names'] as List<dynamic>? ?? [])
            .map((item) => item.toString().trim())
            .where((item) => item.isNotEmpty)
            .toList();
    return PlaceGeo(
      id: (map['id'] as String? ?? '').trim(),
      names: names,
      en: (map['en'] as String? ?? '').trim(),
      district: (map['district'] as String? ?? '').trim(),
      region: (map['region'] as String? ?? 'saurashtra').trim(),
      lat: (map['lat'] as num?)?.toDouble() ?? 0,
      lng: (map['lng'] as num?)?.toDouble() ?? 0,
    );
  }
}
