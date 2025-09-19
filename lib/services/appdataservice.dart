import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/infocontent_model.dart';

class AppDataService {
  static final AppDataService _instance = AppDataService._internal();
  factory AppDataService() => _instance;
  AppDataService._internal();

  Map<String, dynamic>? _data;

  Future<void> loadData(String path) async {
    final jsonString = await rootBundle.loadString(path);
    _data = json.decode(jsonString) as Map<String, dynamic>;
  }

  Map<String, dynamic>? get data => _data;

  dynamic getValue(String key) {
    return _data != null ? _data![key] : null;
  }

  List<InfoContentModel>? _infoContent;

  Future<void> loadInfoContent(String path) async {
    _infoContent = await readInfoData(path);
  }

  Future<List<InfoContentModel>> readInfoData(String path) async {
    final String jsonString = await rootBundle.loadString(path);
    final Map<String, dynamic> jsonMap = json.decode(jsonString);
    final List<dynamic> infoList = jsonMap['infodata'];
    return infoList.map((item) => InfoContentModel.fromMap(item)).toList();
  }

  List<InfoContentModel>? get infoContent => _infoContent;

  InfoContentModel? getInfoValue(String key) {
    if (_infoContent == null) {
      return InfoContentModel(key: '', title: '', content: '');
    }
    return _infoContent!.firstWhere(
      (item) => item.key == key,
      orElse: () => InfoContentModel(key: '', title: '', content: ''),
    );
  }
}
