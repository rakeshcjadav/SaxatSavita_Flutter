class InfoContentModel {
  final String key;
  final String title;
  final String content;

  InfoContentModel({
    required this.key,
    required this.title,
    required this.content,
  });

  factory InfoContentModel.fromMap(Map<String, dynamic> map) {
    return InfoContentModel(
      key: map['key'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
    );
  }
}
