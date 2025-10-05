class BookUserInfo {
  final String id;
  final int partNumber;
  int bookmarkKiranIndex;
  DateTime? updatedAt;

  BookUserInfo({
    required this.id,
    required this.partNumber,
    required this.bookmarkKiranIndex,
    this.updatedAt,
  });
}
