import 'package:saxatsavita_flutter/models/kiraninfo_model.dart';

class KiranList {
  final List<KiranInfo> list;
  final String name;
  final String part;
  late int wordCount;

  KiranList({required this.list, required this.name, required this.part});

  int get totalWordCount => wordCount;

  factory KiranList.fromMap(Map<String, dynamic> map) {
    KiranList kiranList = KiranList(
      list:
          (map['list'] as List?)
              ?.map((item) => KiranInfo.fromMap(item))
              .toList() ??
          [],
      name: map['name'] ?? '',
      part: map['part'] ?? '',
    );
    kiranList.wordCount =
        kiranList.list
            .fold(0, (sum, element) => sum + element.wordCount)
            .toInt();
    return kiranList;
  }

  Map<String, dynamic> toMap() {
    return {
      'list': list.map((item) => item.toMap()).toList(),
      'name': name,
      'part': part,
    };
  }
}
