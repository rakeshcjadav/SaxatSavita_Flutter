class Bookpartmodel {
  final String id;
  final int partNumber;
  final String displayname;
  final String image;
  final String range;

  const Bookpartmodel({
    required this.id,
    required this.partNumber,
    required this.displayname,
    required this.image,
    required this.range,
  });

  factory Bookpartmodel.fromJson(Map<String, dynamic> json) {
    return Bookpartmodel(
      id: json['id'],
      partNumber: json['partNumber'],
      displayname: json['displayname'],
      image: json['image'],
      range: json['range'],
    );
  }

  factory Bookpartmodel.fromMap(Map<String, dynamic> map) {
    return Bookpartmodel(
      id: map['id'] as String,
      partNumber: map['partNumber'] as int,
      displayname: map['displayname'] as String,
      image: map['image'] as String,
      range: map['range'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'partNumber': partNumber,
      'displayname': displayname,
      'image': image,
      'range': range,
    };
  }
}
