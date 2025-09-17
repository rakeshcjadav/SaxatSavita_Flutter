import 'dart:convert';
import 'package:flutter/services.dart';

class AppDataService {
  static final AppDataService _instance = AppDataService._internal();
  factory AppDataService() => _instance;
  AppDataService._internal();

  Map<String, dynamic>? _data;

  Future<void> loadJson(String path) async {
    final jsonString = await rootBundle.loadString(path);
    _data = json.decode(jsonString) as Map<String, dynamic>;
  }

  Map<String, dynamic>? get data => _data;

  dynamic getValue(String key) {
    return _data != null ? _data![key] : null;
  }
}
