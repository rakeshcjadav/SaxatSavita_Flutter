import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:saxatsavita_flutter/models/daily_quiz_model.dart';
import 'package:saxatsavita_flutter/quiz/daily_quiz_question_selection.dart';
import 'package:saxatsavita_flutter/quiz/quiz_option_distinctness.dart';

/// Dated packs users see from 24 October 2026 through the last scheduled file.
void main() {
  test('future daily packs stay distinct and keep their marked answer', () {
    final start = DateTime(2026, 10, 24);
    final end = DateTime(2026, 11, 30);
    final packs = <String, List<DailyQuizQuestion>>{};
    for (
      var day = start;
      !day.isAfter(end);
      day = day.add(const Duration(days: 1))
    ) {
      final name =
          '${day.year.toString().padLeft(4, '0')}-'
          '${day.month.toString().padLeft(2, '0')}/'
          '${day.day.toString().padLeft(2, '0')}.json';
      final file = File('scripts/daily_quizzes/$name');
      expect(file.existsSync(), isTrue, reason: 'missing $name');
      final raw = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final questions = [
        for (final item in raw['questions'] as List)
          DailyQuizQuestion.fromMap(Map<String, dynamic>.from(item as Map)),
      ];
      expect(questions, hasLength(5), reason: name);
      packs[name] = questions;
    }
    expect(packs, hasLength(38));

    final bank =
        jsonDecode(File('scripts/daily_quizzes/_bank.json').readAsStringSync())
            as Map<String, dynamic>;
    final alternates = [
      for (final pack in bank['packs'] as List)
        for (final item in (pack as Map)['questions'] as List)
          DailyQuizQuestion.fromMap(Map<String, dynamic>.from(item as Map)),
    ];

    final asks = RegExp(r'(શું|કોણ|કોન|ક્યારે|ક્યાં|કેમ|કેવ|કય|\?)');
    for (final entry in packs.entries) {
      for (final question in entry.value) {
        expect(
          question.prompt.trim().length,
          greaterThan(8),
          reason: entry.key,
        );
        expect(asks.hasMatch(question.prompt), isTrue, reason: question.prompt);
        expect(
          question.options,
          hasLength(DailyQuizQuestionSelection.optionCount),
        );
        expect(question.correctIndex, inInclusiveRange(0, 3));
        expect(
          question.options
              .where(
                (option) => option == question.options[question.correctIndex],
              )
              .length,
          1,
          reason: question.prompt,
        );
        expect(question.options, isNot(contains(question.prompt)));
        expect(
          QuizOptionDistinctness.isDistinctSet(question.options),
          isTrue,
          reason: '${entry.key} ${question.prompt}',
        );
      }

      final selected = DailyQuizQuestionSelection.select(
        preferred: entry.value,
        alternates: alternates,
      );
      expect(
        selected.map((question) => question.id),
        entry.value.map((question) => question.id),
        reason: '${entry.key} was rewritten by selection',
      );
      for (var i = 0; i < entry.value.length; i++) {
        expect(selected[i].options, entry.value[i].options);
        expect(selected[i].correctIndex, entry.value[i].correctIndex);
      }
    }

    String marked(String file, String prompt) {
      final question = packs[file]!.singleWhere(
        (item) => item.prompt == prompt,
      );
      return question.options[question.correctIndex];
    }

    expect(
      marked('2026-10/25.json', 'ગૃહસ્થ નિયમ રાખે તો શું?'),
      'ગૃહસ્થ નિયમ રાખે તો કલ્યાણ',
    );
    expect(
      marked('2026-10/26.json', 'સ્વભાવનો નાશ કરે તો શું?'),
      'સ્વભાવને નાશ કરે તો સ્વામિનારાયણ ગણાય',
    );
    expect(
      marked('2026-10/27.json', 'સર્વદેશી સમજણનું મૂળ તત્ત્વ શું?'),
      'જગતનો ઘાટ મટ્યો તે ભગવાન; કામક્રોધના મૂળ ઉખેડ્યા એવા ગુરુ',
    );
    expect(
      marked('2026-10/31.json', 'દૃષ્ટા - દૃશ્ય — શું સમજવું?'),
      'દૃષ્ટાની નજર દૃશ્યથી પાછી વળે તો સુખ',
    );
    expect(
      marked('2026-11/02.json', 'પાછીવૃત્તિ વિષે શું કહેવાયું?'),
      'પાછી વૃત્તિએ એક થઈ જાય',
    );
    expect(
      marked('2026-11/08.json', 'સાચા ભાવથી નામ લે તો શું?'),
      'સાચા ભાવથી નામ લે તો અનંત જન્મની ગ્રંથિ ટળે',
    );
    expect(
      marked('2026-11/09.json', 'કામ નાશ કરવા વિષે શું સિદ્ધાંત છે?'),
      'સત્પુરુષનો વિચારે કામ હઠે',
    );
    expect(
      marked('2026-11/10.json', 'મોટી સેવા કોને કહેવાય?'),
      'ભગવાનના ગમતામાં રહેવું એ જ મોટી સેવા',
    );
    expect(
      marked('2026-11/12.json', 'એકાંતિક ધર્મ કોને કહેવાય?'),
      'સ્વામિનારાયણે રોપેલા પાંચ પગ એ જ એકાંતિક ધર્મ',
    );
    expect(
      marked('2026-11/13.json', 'મન જીત્યું એટલે શું?'),
      'સ્થૂળ-સૂક્ષ્મ નોખાં પડે',
    );
    expect(
      packs['2026-11/13.json']!
          .singleWhere((item) => item.prompt == 'મન જીત્યું એટલે શું?')
          .options
          .any((option) => option.contains('જગત જીત્યું')),
      isFalse,
    );
    expect(
      marked('2026-11/20.json', 'ભગવાનના સ્વરુપ અંગે શું નિર્ણય કરવો?'),
      'વિવેક હોય તો ભગવાનનું સ્વરૂપ',
    );
    expect(
      marked('2026-11/23.json', 'ભગવાનની મોટ્યપ જાણવાનું મૂળ તત્ત્વ શું?'),
      'સર્વોપરિ, અસંગી, સમર્થ, સ્વતંત્ર; અગમ સુગમ થયા',
    );
  });
}
