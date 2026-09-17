import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:saxatsavita_flutter/models/haribhakt_model.dart';
import 'package:saxatsavita_flutter/models/kiraninfo_model.dart';
import 'package:saxatsavita_flutter/services/kiranlistservice.dart';

class HaribhaktKiranHit {
  final int kiranIndex;
  final int partNumber;
  final KiranInfo kiranInfo;
  final List<String> names;
  final String role;

  const HaribhaktKiranHit({
    required this.kiranIndex,
    required this.partNumber,
    required this.kiranInfo,
    required this.names,
    required this.role,
  });
}

class HaribhaktService {
  static final HaribhaktService _instance = HaribhaktService._internal();
  factory HaribhaktService() => _instance;
  HaribhaktService._internal();

  List<HaribhaktItem> _list = const [];
  Map<String, HaribhaktItem> _byName = const {};

  List<HaribhaktItem> get list => _list;

  Future<void> load({String bookName = 'saxatsavita'}) async {
    if (_list.isNotEmpty) return;
    final filename = 'assets/book/$bookName/haribhakts/haribhakts.json';
    try {
      final jsondata = await rootBundle.loadString(filename);
      final map = json.decode(jsondata) as Map<String, dynamic>;
      final index = HaribhaktIndex.fromMap(map);
      _list = List<HaribhaktItem>.from(index.list)
        ..sort((a, b) => a.name.compareTo(b.name));
      _byName = {for (final item in _list) item.name: item};
    } catch (e) {
      debugPrint('Error loading haribhakts: $e');
      _list = const [];
      _byName = const {};
    }
  }

  HaribhaktItem? findByName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    return _byName[trimmed];
  }

  List<HaribhaktItem> searchNames(String query) {
    final q = query.trim();
    if (q.isEmpty) return _list;
    final exact = <HaribhaktItem>[];
    final starts = <HaribhaktItem>[];
    final contains = <HaribhaktItem>[];
    for (final item in _list) {
      if (item.name == q) {
        exact.add(item);
      } else if (item.name.startsWith(q) ||
          item.name.split(' ').any((token) => token.startsWith(q))) {
        starts.add(item);
      } else if (q.length >= 4 && item.name.contains(q)) {
        contains.add(item);
      }
    }
    return [...exact, ...starts, ...contains];
  }

  List<HaribhaktKiranHit> searchKirans(String query) {
    final matches = searchNames(query);
    final byIndex = <int, HaribhaktKiranHit>{};
    for (final item in matches) {
      for (final ref in item.kirans) {
        final existing = byIndex[ref.index];
        if (existing == null) {
          final partNumber = _partNumberFor(ref.index);
          if (partNumber == null) continue;
          final kiranInfo = KiranListService().getKiranInfo(
            partNumber,
            ref.index,
          );
          if (kiranInfo.index == 0) continue;
          byIndex[ref.index] = HaribhaktKiranHit(
            kiranIndex: ref.index,
            partNumber: partNumber,
            kiranInfo: kiranInfo,
            names: [item.name],
            role: ref.role,
          );
        } else if (!existing.names.contains(item.name)) {
          existing.names.add(item.name);
        }
      }
    }
    final hits =
        byIndex.values.toList()
          ..sort((a, b) => a.kiranIndex.compareTo(b.kiranIndex));
    return hits;
  }

  int? _partNumberFor(int kiranIndex) {
    final lists = KiranListService();
    for (int partNumber = 1; partNumber <= 5; partNumber++) {
      final list = lists.getKiranListFromPartNumber(partNumber);
      if (list == null) continue;
      if (list.list.any((kiran) => kiran.index == kiranIndex)) {
        return partNumber;
      }
    }
    return null;
  }
}
