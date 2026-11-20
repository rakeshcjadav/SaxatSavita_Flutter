import 'package:flutter_test/flutter_test.dart';
import 'package:saxatsavita_flutter/models/saved_suvichar.dart';
import 'package:saxatsavita_flutter/services/saved_suvichar_filter.dart';

SavedSuvichar _item({
  required String id,
  required DateTime updatedAt,
  String quote = 'quote',
  String author = 'Rakesh',
  int partNumber = 2,
  int templateIndex = 8,
}) {
  return SavedSuvichar(
    id: id,
    createdAt: updatedAt,
    updatedAt: updatedAt,
    quote: quote,
    author: author,
    partNumber: partNumber,
    templateIndex: templateIndex,
  );
}

void main() {
  final now = DateTime(2026, 11, 20, 15);
  final items = [
    _item(
      id: 'today',
      updatedAt: DateTime(2026, 11, 20, 9),
      quote: 'ઉઠો જાગો',
      author: 'Rakesh Jadav',
      partNumber: -1,
      templateIndex: 8,
    ),
    _item(
      id: 'week',
      updatedAt: DateTime(2026, 11, 17, 9),
      quote: 'શાંતિ',
      author: 'જોગીસ્વામી',
      partNumber: 2,
      templateIndex: 10,
    ),
    _item(
      id: 'month',
      updatedAt: DateTime(2026, 11, 1, 9),
      quote: 'કરુણા',
      author: '',
      partNumber: 3,
      templateIndex: 8,
    ),
    _item(
      id: 'old',
      updatedAt: DateTime(2026, 9, 1, 9),
      quote: 'જૂનો વિચાર',
      author: 'Rakesh Jadav',
      partNumber: 2,
      templateIndex: 0,
    ),
  ];

  List<String> ids(SuvicharQuery query) {
    return applySuvicharQuery(
      items,
      query,
      now: now,
    ).map((item) => item.id).toList();
  }

  test('search matches quote or author', () {
    expect(ids(const SuvicharQuery(text: 'જાગો')), ['today']);
    expect(ids(const SuvicharQuery(text: 'rakesh')), ['today', 'old']);
    expect(ids(const SuvicharQuery(text: 'શાંતિ')), ['week']);
  });

  test('filters by author, part, and template together', () {
    expect(
      ids(
        const SuvicharQuery(
          authors: {'જોગીસ્વામી'},
          parts: {2},
          templates: {10},
        ),
      ),
      ['week'],
    );
    expect(ids(const SuvicharQuery(authors: {''})), ['month']);
    expect(ids(const SuvicharQuery(parts: {-1})), ['today']);
  });

  test('filters by date presets', () {
    expect(ids(const SuvicharQuery(date: SuvicharDateFilter.today)), ['today']);
    expect(ids(const SuvicharQuery(date: SuvicharDateFilter.thisWeek)), [
      'today',
      'week',
    ]);
    expect(ids(const SuvicharQuery(date: SuvicharDateFilter.last30Days)), [
      'today',
      'week',
      'month',
    ]);
  });

  test('custom range is inclusive and order does not matter', () {
    expect(
      ids(
        SuvicharQuery(
          date: SuvicharDateFilter.custom,
          from: DateTime(2026, 11, 1),
          to: DateTime(2026, 11, 17),
        ),
      ),
      ['week', 'month'],
    );
    expect(
      ids(
        SuvicharQuery(
          date: SuvicharDateFilter.custom,
          from: DateTime(2026, 11, 17),
          to: DateTime(2026, 11, 1),
        ),
      ),
      ['week', 'month'],
    );
  });
}
