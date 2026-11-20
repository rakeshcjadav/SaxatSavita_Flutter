import 'package:flutter_test/flutter_test.dart';
import 'package:saxatsavita_flutter/models/saved_suvichar.dart';
import 'package:saxatsavita_flutter/services/saved_suvichar_sync.dart';

SavedSuvichar _item({
  required String id,
  required DateTime updatedAt,
  String quote = 'આત્મા સાથે જોડાવું',
}) {
  return SavedSuvichar(
    id: id,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: updatedAt,
    quote: quote,
    author: 'જોગીસ્વામી',
    partNumber: 2,
    kiranIndex: 4,
    templateIndex: 8,
    gradientKey: 'custom',
    customGradientStart: 0xFFE64A19,
    customGradientEnd: 0xFFFFA726,
    fontSize: 28,
    authorFontSize: 14,
    imageWidth: 400,
    isQuoteBold: false,
    isQuoteItalic: true,
    isAuthorBold: true,
    isAuthorItalic: false,
    quoteTextColor: 0xFFFFFFFF,
    wordColors: const {0: 0xFFFF0000, 3: 0xFF00FF00},
    showUserAvatar: true,
    showUserName: true,
    stickers: const [
      SavedSuvicharSticker(
        assetPath: 'assets/stickers/om.png',
        dx: 12,
        dy: 18,
        size: 40,
        rotation: 0.5,
      ),
    ],
  );
}

void main() {
  test('json round trip keeps text and template settings', () {
    final original = _item(
      id: 'abc',
      updatedAt: DateTime.utc(2026, 3, 2, 4, 5, 6),
    );

    expect(SavedSuvichar.fromJson(original.toJson()), original);
    expect(
      original.hasSameContent(
        original.copyWith(updatedAt: DateTime.utc(2026, 4, 1)),
      ),
      isTrue,
    );
    expect(
      original.hasSameContent(original.copyWith(quote: 'changed')),
      isFalse,
    );
  });

  test('missing optional fields fall back to defaults', () {
    final restored = SavedSuvichar.fromJson({
      'id': 'bare',
      'createdAt': '2026-01-01T00:00:00.000Z',
      'updatedAt': '2026-01-02T00:00:00.000Z',
      'quote': 'શાંતિ',
    });

    expect(restored.author, isEmpty);
    expect(restored.partNumber, -1);
    expect(restored.kiranIndex, -1);
    expect(restored.templateIndex, 8);
    expect(restored.gradientKey, 'orange');
    expect(restored.quoteTextColor, isNull);
    expect(restored.wordColors, isEmpty);
    expect(restored.stickers, isEmpty);
  });

  test('newer local copy wins and is uploaded', () {
    final older = _item(
      id: 'a',
      updatedAt: DateTime.utc(2026, 1, 1),
      quote: 'old',
    );
    final newer = _item(
      id: 'a',
      updatedAt: DateTime.utc(2026, 2, 1),
      quote: 'new',
    );

    final plan = planSuvicharSync(
      local: [newer],
      remote: [older],
      tombstones: {},
    );

    expect(plan.merged, [newer]);
    expect(plan.toUpload, [newer]);
    expect(plan.tombstonesToRetry, isEmpty);
  });

  test('newer cloud copy is kept and not uploaded', () {
    final local = _item(
      id: 'a',
      updatedAt: DateTime.utc(2026, 1, 1),
      quote: 'local',
    );
    final remote = _item(
      id: 'a',
      updatedAt: DateTime.utc(2026, 2, 1),
      quote: 'cloud',
    );

    final plan = planSuvicharSync(
      local: [local],
      remote: [remote],
      tombstones: {},
    );

    expect(plan.merged.single.quote, 'cloud');
    expect(plan.toUpload, isEmpty);
  });

  test('local-only item is uploaded and cloud-only item is kept', () {
    final localOnly = _item(
      id: 'local',
      updatedAt: DateTime.utc(2026, 1, 2),
      quote: 'local',
    );
    final cloudOnly = _item(
      id: 'cloud',
      updatedAt: DateTime.utc(2026, 1, 3),
      quote: 'cloud',
    );

    final plan = planSuvicharSync(
      local: [localOnly],
      remote: [cloudOnly],
      tombstones: {},
    );

    expect(plan.merged.map((item) => item.id), ['cloud', 'local']);
    expect(plan.toUpload, [localOnly]);
  });

  test('equal timestamps stay on the cloud copy', () {
    final updatedAt = DateTime.utc(2026, 1, 1);
    final local = _item(id: 'a', updatedAt: updatedAt, quote: 'local');
    final remote = _item(id: 'a', updatedAt: updatedAt, quote: 'remote');

    final plan = planSuvicharSync(
      local: [local],
      remote: [remote],
      tombstones: {},
    );

    expect(plan.merged.single.quote, 'remote');
    expect(plan.toUpload, isEmpty);
  });

  test('tombstoned ids are not revived', () {
    final item = _item(id: 'gone', updatedAt: DateTime.utc(2026, 1, 1));

    final plan = planSuvicharSync(
      local: [item],
      remote: [item],
      tombstones: {'gone'},
    );

    expect(plan.merged, isEmpty);
    expect(plan.toUpload, isEmpty);
    expect(plan.tombstonesToRetry, ['gone']);
  });

  test('tombstones already absent from cloud are not retried', () {
    final plan = planSuvicharSync(
      local: const [],
      remote: const [],
      tombstones: {'gone'},
    );

    expect(plan.merged, isEmpty);
    expect(plan.tombstonesToRetry, isEmpty);
  });
}
