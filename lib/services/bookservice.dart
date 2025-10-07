import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:saxatsavita_flutter/models/bookuserinfo_model.dart';
import 'dart:convert';
import '../models/bookpart_model.dart';
import 'kiranlistservice.dart';
import '../models/meanings_model.dart';

class Bookservice {
  static final Bookservice _instance = Bookservice._internal();
  factory Bookservice() => _instance;
  Bookservice._internal();

  final Map<String, List<Bookpartmodel>> _bookPartsByLanguage = {};

  List<BookUserInfo>? _bookUserInfoList = [];
  List<BookUserInfo>? get bookUserInfoList => _bookUserInfoList;

  set bookUserInfoList(List<BookUserInfo>? list) {
    _bookUserInfoList = list;
  }

  MeaningsModel? _meanings;
  MeaningsModel? get meanings => _meanings;

  BookUserInfo getBookUserInfo(int partNumber) {
    return _bookUserInfoList!.firstWhere(
      (info) => info.partNumber == partNumber,
      orElse:
          () => BookUserInfo(
            id: "Unknown",
            partNumber: partNumber,
            bookmarkKiranIndex: 1,
          ),
    );
  }

  MeaningItem? getMeaning(String key) {
    String word = key.replaceAll("dict:", "");
    if (_meanings == null) {
      return null;
    }
    return _meanings!.list.firstWhere(
      (item) => item.word == word,
      orElse:
          () => MeaningItem(
            index: -1,
            word: word,
            meaning: 'No meaning found',
            count: 0,
            kirans: [],
          ),
    );
  }

  Future<List<Bookpartmodel>>? getBookParts(BuildContext context) {
    try {
      final locale = Localizations.localeOf(context);
      if (_bookPartsByLanguage[locale.languageCode] == null) {
        return Future.value(_bookPartsByLanguage['en']);
      } else {
        return Future.value(_bookPartsByLanguage[locale.languageCode]);
      }
    } catch (e) {
      return Future.value(_bookPartsByLanguage['en']);
    }
  }

  int getStartKiranIndex(int partNumber) {
    try {
      return _bookPartsByLanguage['en']!
          .firstWhere((part) => part.partNumber == partNumber)
          .startKiranIndex;
    } catch (e) {
      return 1;
    }
  }

  String getPartTitle(BuildContext context, int partNumber) {
    try {
      final locale = Localizations.localeOf(context);
      List<Bookpartmodel>? bookparts =
          _bookPartsByLanguage[locale.languageCode];
      return bookparts!
          .firstWhere((part) => part.partNumber == partNumber)
          .displayname;
    } catch (e) {
      return "Part $partNumber";
    }
  }

  void loadBook(String bookName) async {
    if (_bookPartsByLanguage.isNotEmpty) {
      return;
    } else {
      String jsondata = await readBook(bookName);
      List<Bookpartmodel>? bookparts = await readBookparts(jsondata, 'en');
      _bookPartsByLanguage['en'] = bookparts;
      bookparts = await readBookparts(jsondata, 'gu');
      _bookPartsByLanguage['gu'] = bookparts;
      bookUserInfoList =
          bookparts
              .map(
                (part) => BookUserInfo(
                  id: part.id,
                  partNumber: part.partNumber,
                  bookmarkKiranIndex: part.startKiranIndex,
                ),
              )
              .toList();

      if (bookparts.isNotEmpty) {
        for (int i = 0; i < bookparts.length; i++) {
          KiranListService().loadPart('saxatsavita', bookparts[i].id);
        }
      }
      _meanings = await loadMeanings(bookName);
    }
  }

  Future<List<Bookpartmodel>> readBookparts(
    String jsondata,
    String languageCode,
  ) async {
    final list = json.decode(jsondata) as List<dynamic>;
    List<Bookpartmodel> bookparts =
        list.map((e) {
          final Map<String, dynamic> item = e as Map<String, dynamic>;

          // Extract localized strings, fallback to English if current language not available
          String displayname =
              item['displayname'][languageCode] ??
              item['displayname']['en'] ??
              'Unknown';
          String range =
              item['range'][languageCode] ?? item['range']['en'] ?? 'Unknown';

          // Create a flattened JSON object for Bookpartmodel.fromJson
          final Map<String, dynamic> flattenedItem = {
            'id': item['id'],
            'partNumber': item['partNumber'],
            'displayname': displayname,
            'image': item['image'],
            'range': range,
            'startKiranIndex': item['startKiranIndex'],
            'endKiranIndex': item['endKiranIndex'],
          };

          return Bookpartmodel.fromJson(flattenedItem);
        }).toList();

    for (var part in bookparts) {
      debugPrint(
        "Initialized Bookpartmodel: partNumber=${part.partNumber}, "
        "displayname=${part.displayname}, range=${part.range}, "
        "startKiranIndex=${part.startKiranIndex}, endKiranIndex=${part.endKiranIndex}",
      );
    }

    for (var info in _bookUserInfoList!) {
      debugPrint(
        "Initialized BookUserInfo: partNumber=${info.partNumber}, "
        "bookmarkKiranIndex=${info.bookmarkKiranIndex}",
      );
    }

    return bookparts;
  }

  Future<String> readBook(String bookName) async {
    debugPrint("Loading book parts for $bookName");
    final String filename = 'assets/book/$bookName.json';

    String jsondata;
    try {
      jsondata = await rootBundle.loadString(filename);
    } catch (e) {
      debugPrint("Error loading book parts: $e");
      rethrow;
    }
    return jsondata;
  }

  Future<MeaningsModel?> loadMeanings(String bookName) async {
    debugPrint("Loading meanings for $bookName");
    final String filename = 'assets/book/$bookName/meanings/meanings.json';
    try {
      final jsondata = await rootBundle.loadString(filename);
      final Map<String, dynamic> map = json.decode(jsondata);
      return MeaningsModel.fromMap(map);
    } catch (e) {
      debugPrint("Error loading meanings: $e");
      return null;
    }
  }
}
