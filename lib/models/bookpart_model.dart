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
}
