import 'dart:convert';
import 'package:saxatsavita_flutter/models/kiraninfo_model.dart';
import 'package:saxatsavita_flutter/models/kiranlist_model.dart';
import 'package:flutter/services.dart';

class KiranListService {
  static final KiranListService _instance = KiranListService._internal();
  factory KiranListService() => _instance;
  KiranListService._internal();

  Map<String, KiranList>? _mapKiranList;

  KiranList? getKiranList(String part) {
    if (_mapKiranList == null) {
      return null;
    }
    return _mapKiranList![part];
  }

  KiranList? getKiranListFromPartNumber(int partNumber) {
    String part = "part$partNumber";
    if (_mapKiranList == null) {
      return null;
    }
    return _mapKiranList![part];
  }

  Future<void> loadPart(String bookName, String part) async {
    final kiranList = await loadKiranList(bookName, part);
    _mapKiranList ??= {};
    _mapKiranList![kiranList.part] = kiranList;
  }

  Future<KiranList> loadKiranList(String bookName, String partNumber) async {
    //debugPrint("Loading book parts for $bookName - $partNumber");
    final String jsonString = await rootBundle.loadString(
      "assets/book/$bookName/$partNumber/_kirans_.json",
    );
    final Map<String, dynamic> jsonMap = json.decode(jsonString);
    return KiranList.fromMap(jsonMap);
  }

  KiranInfo getKiranInfo(int partNumber, int kiranIndex) {
    KiranList? kiranList = getKiranListFromPartNumber(partNumber);
    if (kiranList == null) {
      return KiranInfo(index: 0, number: '', title: '', wordCount: 0);
    }
    return kiranList.list.firstWhere(
      (kiran) => kiran.index == kiranIndex,
      orElse: () => KiranInfo(index: 0, number: '', title: '', wordCount: 0),
    );
  }

  String getKiranTitle(int partNumber, int kiranIndex) {
    KiranInfo kiranInfo = getKiranInfo(partNumber, kiranIndex);
    return '${kiranInfo.number} ${kiranInfo.title}';
  }

  bool hasPreviousKiran(int partNumber, int kiranIndex) {
    KiranList? kiranList = getKiranListFromPartNumber(partNumber);
    if (kiranList == null) {
      return false;
    }
    return kiranList.list.any((kiran) => kiran.index == kiranIndex - 1);
  }

  bool hasNextKiran(int partNumber, int kiranIndex) {
    KiranList? kiranList = getKiranListFromPartNumber(partNumber);
    if (kiranList == null) {
      return false;
    }
    return kiranList.list.any((kiran) => kiran.index == kiranIndex + 1);
  }
}
