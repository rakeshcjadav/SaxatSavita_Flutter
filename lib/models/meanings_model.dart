class MeaningsModel {
  final List<MeaningItem> list;

  MeaningsModel({required this.list});

  factory MeaningsModel.fromMap(Map<String, dynamic> map) {
    return MeaningsModel(
      list:
          (map['list'] as List<dynamic>)
              .map((item) => MeaningItem.fromMap(item))
              .toList(),
    );
  }
}

class MeaningItem {
  final int index;
  final String word;
  final String meaning;
  final int count;
  final List<int> kirans;

  MeaningItem({
    required this.index,
    required this.word,
    required this.meaning,
    required this.count,
    required this.kirans,
  });

  factory MeaningItem.fromMap(Map<String, dynamic> map) {
    return MeaningItem(
      index: map['index'] as int,
      word: map['word'] as String,
      meaning: map['meaning'] as String,
      count: map['count'] as int,
      kirans: (map['kirans'] as List<dynamic>).map((e) => e as int).toList(),
    );
  }
}
