import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saxatsavita_flutter/services/kiran_search_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  KiranSearchController buildController() {
    final controller = KiranSearchController(
      scrollController: ScrollController(),
      onStateChanged: () {},
    );
    addTearDown(controller.dispose);
    return controller;
  }

  test('finds each word even when a sentence break separates them', () {
    const text = 'શુદ્ધ આવ્યું. પછી ચૈતન્ય અને ફરી શુદ્ધ.';
    final hits = KiranSearchController.findHits(text, 'ચૈતન્ય શુદ્ધ');

    expect(hits, hasLength(3));
    expect(hits.map((hit) => text.substring(hit.start, hit.end)).toList(), [
      'શુદ્ધ',
      'ચૈતન્ય',
      'શુદ્ધ',
    ]);
  });

  test('keeps the longer word when a shorter query word sits inside it', () {
    const text = 'બ્રહ્મ અને બ્રહ્મરૂપ';
    final hits = KiranSearchController.findHits(text, 'બ્રહ્મ બ્રહ્મરૂપ');

    expect(hits, hasLength(2));
    expect(text.substring(hits[0].start, hits[0].end), 'બ્રહ્મ');
    expect(text.substring(hits[1].start, hits[1].end), 'બ્રહ્મરૂપ');
  });

  test('highlights every body hit and marks the current one', () {
    const html = '<p>શુદ્ધ આવ્યું. પછી <b>ચૈતન્ય</b>.</p>';
    final controller = buildController();
    controller.setContent(KiranSearchController.getPlainText(html));
    controller.performSearch('શુદ્ધ ચૈતન્ય');

    final highlighted = controller.getHighlightedContentForTextSpan(html);

    expect(highlighted, contains('>શુદ્ધ</mark>'));
    expect(highlighted, contains('>ચૈતન્ય</mark>'));
    expect(
      highlighted.indexOf('data-current="true"'),
      lessThan(highlighted.indexOf('data-current="false"')),
    );
  });

  test('cycles through title hits and then body hits', () {
    const html = '<p>શુદ્ધ ચૈતન્ય શુદ્ધ</p>';
    final controller = buildController();
    controller.setTitle('શુદ્ધ સ્વરૂપ');
    controller.setContent(KiranSearchController.getPlainText(html));
    controller.performSearch('શુદ્ધ');

    expect(controller.matchCount, 3);
    expect(controller.currentHitInTitle, isTrue);

    controller.nextMatch();
    expect(controller.currentHitInTitle, isFalse);
    expect(controller.currentMatchIndex, 1);

    final highlighted = controller.getHighlightedContent(html);
    expect(highlighted, contains('data-current="true"'));
    expect(highlighted, contains('>શુદ્ધ</mark>'));
    expect(
      highlighted.indexOf('data-current="true"'),
      lessThan(highlighted.indexOf('data-current="false"')),
    );

    controller.nextMatch();
    controller.nextMatch();
    expect(controller.currentMatchIndex, 0);
    expect(controller.currentHitInTitle, isTrue);
  });

  test('highlights a linked word without breaking the anchor', () {
    const html = '<p>જુઓ <a href="dict:શુદ્ધ">શુદ્ધ</a> શબ્દ.</p>';
    final controller = buildController();
    controller.setContent(KiranSearchController.getPlainText(html));
    controller.performSearch('શુદ્ધ');

    expect(
      controller.getHighlightedContent(html),
      contains('<a href="dict:શુદ્ધ"><mark data-current="true"'),
    );
  });
}
