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

const _honorificTokens = {'ભાઈ', 'ભાઇ', 'બાપા', 'ભગત', 'બાઈ', 'બાઇ'};

class HaribhaktService {
  static final HaribhaktService _instance = HaribhaktService._internal();
  factory HaribhaktService() => _instance;
  HaribhaktService._internal();

  List<HaribhaktItem> _list = const [];
  Map<String, HaribhaktItem> _byName = const {};
  Map<String, String> _aliasToCanonical = const {};
  Map<String, List<String>> _forms = const {};
  Map<int, int>? _indexToPart;

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
      _aliasToCanonical = Map<String, String>.from(index.aliases);
      final forms = <String, List<String>>{};
      for (final entry in _aliasToCanonical.entries) {
        (forms[entry.value] ??= []).add(entry.key);
      }
      _forms = forms;
    } catch (e) {
      debugPrint('Error loading haribhakts: $e');
      _list = const [];
      _byName = const {};
      _aliasToCanonical = const {};
      _forms = const {};
    }
  }

  HaribhaktItem? findByName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    return _byName[trimmed] ?? _byName[_aliasToCanonical[trimmed]];
  }

  /// Canonical name plus body spellings that map to [name].
  List<String> formsFor(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return const [];
    final canonical = _aliasToCanonical[trimmed] ?? trimmed;
    final extras = _forms[canonical] ?? const [];
    final out = <String>[canonical];
    for (final form in extras) {
      if (form != canonical) out.add(form);
    }
    if (canonical != trimmed && !out.contains(trimmed)) {
      out.add(trimmed);
    }
    return out;
  }

  List<HaribhaktItem> searchNames(String query) {
    final q = query.trim();
    if (q.isEmpty) return _list;
    final exact = <HaribhaktItem>[];
    final starts = <HaribhaktItem>[];
    final contains = <HaribhaktItem>[];
    final skipContains = q.length < 2 || _honorificTokens.contains(q);
    for (final item in _list) {
      if (item.name == q || (_forms[item.name]?.contains(q) ?? false)) {
        exact.add(item);
        continue;
      }
      final names = [item.name, ...?_forms[item.name]];
      if (names.any(
        (name) =>
            name.startsWith(q) ||
            name.split(' ').any((token) => token.startsWith(q)),
      )) {
        starts.add(item);
      } else if (!skipContains &&
          names.any(
            (name) =>
                name.contains(q) ||
                name.split(' ').any(
                  (token) =>
                      !_honorificTokens.contains(token) && token.contains(q),
                ),
          )) {
        contains.add(item);
      }
    }
    return [...exact, ...starts, ...contains];
  }

  int? partNumberFor(int kiranIndex) => _partNumberFor(kiranIndex);

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
    _ensurePartMap();
    return _indexToPart![kiranIndex];
  }

  void _ensurePartMap() {
    if (_indexToPart != null) return;
    final map = <int, int>{};
    final lists = KiranListService();
    for (int partNumber = 1; partNumber <= 5; partNumber++) {
      final list = lists.getKiranListFromPartNumber(partNumber);
      if (list == null) continue;
      for (final kiran in list.list) {
        map[kiran.index] = partNumber;
      }
    }
    _indexToPart = map;
  }
}
