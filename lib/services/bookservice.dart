import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:saxatsavita_flutter/models/bookuserinfo_model.dart';
import 'dart:convert';
import '../models/bookpart_model.dart';
import 'kiranlistservice.dart';

class Bookservice {
  static final Bookservice _instance = Bookservice._internal();
  factory Bookservice() => _instance;
  Bookservice._internal();

  List<Bookpartmodel>? _bookparts;
  List<Bookpartmodel>? get bookparts => _bookparts;

  List<BookUserInfo>? _bookUserInfoList = [];
  List<BookUserInfo>? get bookUserInfoList => _bookUserInfoList;

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
    final jsondata = await rootBundle.loadString(filename);
    final list = json.decode(jsondata) as List<dynamic>;

    List<Bookpartmodel> bookparts =
        list.map((e) => Bookpartmodel.fromJson(e)).toList();

    _bookUserInfoList =
        bookparts
            .map(
              (part) => BookUserInfo(
                id: part.id,
                partNumber: part.partNumber,
                bookmarkKiranIndex: 1,
              ),
            )
            .toList();

    return bookparts;
  }
}
