import 'package:flutter_test/flutter_test.dart';
import 'package:saxatsavita_flutter/helpers/haribhakt_text_highlight.dart';

void main() {
  test('matches honorific spelling and inflected endings', () {
    const text = 'પછી ભગવાનજીભાઇએ વાત કરી.';
    final hits = HaribhaktTextHighlight.findMatches(text, ['ભગવાનજીભાઈ']);
    expect(hits, hasLength(1));
    expect(text.substring(hits.first.start, hits.first.end), 'ભગવાનજીભાઇએ');
  });

  test('keeps the longer name when two names overlap', () {
    const text = 'ભગવાનજીભાઈ માસ્તરે વાંચ્યું.';
    final hits = HaribhaktTextHighlight.findMatches(text, [
      'ભગવાનજીભાઈ',
      'ભગવાનજીભાઈ માસ્તર',
    ]);
    expect(hits, hasLength(1));
    expect(hits.first.name, 'ભગવાનજીભાઈ માસ્તર');
  });

  test('wraps html and marks the focused name', () {
    const html = '<p>નાનુભાઈ રાઠોડે અને ચંદુભાઈ બેઠા.</p>';
    final wrapped = HaribhaktTextHighlight.wrap(
      html: html,
      names: const ['નાનુભાઈ રાઠોડ', 'ચંદુભાઈ'],
      focusedName: 'નાનુભાઈ રાઠોડ',
    );
    expect(
      wrapped,
      contains(
        '<b data-haribhakt="current" style="color: #6A1B9A; font-weight: 700;">નાનુભાઈ રાઠોડે</b>',
      ),
    );
    expect(
      wrapped,
      contains(
        '<b data-haribhakt="other" style="color: #0277BD; font-weight: 700;">ચંદુભાઈ</b>',
      ),
    );
  });

  test('wraps alias body spelling as the listed name', () {
    const html = '<p>પછી જીવન ભગવાનજીની ઘરે બેઠા.</p>';
    final wrapped = HaribhaktTextHighlight.wrap(
      html: html,
      names: const ['જીવનભાઈ'],
      focusedName: 'જીવનભાઈ',
      formsByName: const {
        'જીવનભાઈ': ['જીવનભાઈ', 'જીવન ભગવાનજી'],
      },
    );
    expect(
      wrapped,
      contains(
        '<b data-haribhakt="current" style="color: #6A1B9A; font-weight: 700;">જીવન ભગવાનજીની</b>',
      ),
    );
    expect(
      HaribhaktTextHighlight.firstOffset(
        HaribhaktTextHighlight.stripTags(html),
        'જીવનભાઈ',
        also: const ['જીવન ભગવાનજી'],
      ),
      isNotNull,
    );
  });

  test('matches prefixed alias that lookbehind would otherwise skip', () {
    const text = 'પછી સંતવલ્લભદાસે વાત કરી.';
    final hits = HaribhaktTextHighlight.findMatches(
      text,
      ['વલ્લભદાસ', 'સંતવલ્લભદાસ'],
      owner: const {'સંતવલ્લભદાસ': 'વલ્લભદાસ'},
    );
    expect(hits, hasLength(1));
    expect(hits.first.name, 'વલ્લભદાસ');
    expect(text.substring(hits.first.start, hits.first.end), 'સંતવલ્લભદાસે');
  });

  test('skips names that are already inside links', () {
    const html =
        '<p><a href="dict:x">નાનુભાઈ રાઠોડ</a> પછી નાનુભાઈ રાઠોડ આવ્યા.</p>';
    final wrapped = HaribhaktTextHighlight.wrap(
      html: html,
      names: const ['નાનુભાઈ રાઠોડ'],
      focusedName: 'નાનુભાઈ રાઠોડ',
    );
    expect(wrapped, contains('<a href="dict:x">નાનુભાઈ રાઠોડ</a>'));
    expect(
      wrapped,
      contains(
        '<b data-haribhakt="current" style="color: #6A1B9A; font-weight: 700;">નાનુભાઈ રાઠોડ',
      ),
    );
  });
}
