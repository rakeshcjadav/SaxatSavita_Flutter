class InfoContentModel {
  final String title;
  final String content;

  InfoContentModel({required this.title, required this.content});

  factory InfoContentModel.fromMap(Map<String, dynamic> map) {
    return InfoContentModel(
      title: map['title'] as String,
      content: map['content'] as String,
    );
  }
}
