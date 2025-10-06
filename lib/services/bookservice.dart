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

  List<Bookpartmodel>? _bookparts;
  List<Bookpartmodel>? get bookparts => _bookparts;

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

  String getPartTitle(int partNumber) {
    try {
      return _bookparts!
          .firstWhere((part) => part.partNumber == partNumber)
          .displayname;
    } catch (e) {
      return "Part $partNumber";
    }
  }

  Future<List<Bookpartmodel>> loadBook(
    BuildContext context,
    String bookName,
  ) async {
    if (_bookparts != null) {
      return _bookparts!;
    } else {
      _bookparts = await readBookparts(context, bookName);
      if (Bookservice().bookparts != null) {
        List<Bookpartmodel> bookparts = Bookservice().bookparts!;
        for (int i = 0; i < bookparts.length; i++) {
          KiranListService().loadPart('saxatsavita', bookparts[i].id);
        }
      }
      _meanings = await loadMeanings(bookName);
      return _bookparts!;
    }
  }

  Future<List<Bookpartmodel>> readBookparts(
    BuildContext context,
    String bookName,
  ) async {
    debugPrint("Loading book parts for $bookName");
    final Locale locale = Localizations.localeOf(context);
    final String filename =
        'assets/book/${bookName}_${locale.languageCode}.json';
    String jsondata;
    try {
      jsondata = await rootBundle.loadString(filename);
    } catch (e) {
      debugPrint(
        "Error loading localized book parts: $e. Falling back to English.",
      );
      // Fallback to English if localized file not found
      final String fallbackFilename = 'assets/book/${bookName}_en.json';
      jsondata = await rootBundle.loadString(fallbackFilename);
    }
    final list = json.decode(jsondata) as List<dynamic>;

    List<Bookpartmodel> bookparts =
        list.map((e) => Bookpartmodel.fromJson(e)).toList();

    _bookUserInfoList =
        bookparts
            .map(
              (part) => BookUserInfo(
                id: part.id,
                partNumber: part.partNumber,
                bookmarkKiranIndex: part.startKiranIndex,
              ),
            )
            .toList();

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
