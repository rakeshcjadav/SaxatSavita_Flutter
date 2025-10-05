class Bookpartmodel {
  final String id;
  final int partNumber;
  final String displayname;
  final String image;
  final String range;
  final int startKiranIndex;
  final int endKiranIndex;

  const Bookpartmodel({
    required this.id,
    required this.partNumber,
    required this.displayname,
    required this.image,
    required this.range,
    required this.startKiranIndex,
    required this.endKiranIndex,
  });

  factory Bookpartmodel.fromJson(Map<String, dynamic> json) {
    return Bookpartmodel(
      id: json['id'] ?? '',
      partNumber: json['partNumber'] ?? 0,
      displayname: json['displayname'] ?? '',
      image: json['image'] ?? '',
      range: json['range'] ?? '',
      startKiranIndex: json['startKiranIndex'] ?? 0,
      endKiranIndex: json['endKiranIndex'] ?? 0,
    );
  }

  factory Bookpartmodel.fromMap(Map<String, dynamic> map) {
    return Bookpartmodel(
      id: (map['id'] as String?) ?? '',
      partNumber: (map['partNumber'] as int?) ?? 0,
      displayname: (map['displayname'] as String?) ?? '',
      image: (map['image'] as String?) ?? '',
      range: (map['range'] as String?) ?? '',
      startKiranIndex: (map['startKiranIndex'] as int?) ?? 0,
      endKiranIndex: (map['endKiranIndex'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'partNumber': partNumber,
      'displayname': displayname,
      'image': image,
      'range': range,
      'startKiranIndex': startKiranIndex,
      'endKiranIndex': endKiranIndex,
    };
  }
}
