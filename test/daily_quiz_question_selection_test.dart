import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:saxatsavita_flutter/models/daily_quiz_model.dart';
import 'package:saxatsavita_flutter/quiz/daily_quiz_question_selection.dart';
import 'package:saxatsavita_flutter/quiz/quiz_option_distinctness.dart';

DailyQuizQuestion _question({
  required String id,
  required List<String> options,
  int correctIndex = 0,
  String prompt = 'પ્રશ્ન',
}) {
  return DailyQuizQuestion(
    id: id,
    prompt: prompt,
    options: options,
    correctIndex: correctIndex,
    part: 1,
    kiranIndex: 1,
  );
}

void main() {
  group('QuizOptionDistinctness', () {
    test('rejects paraphrases and near-duplicate wording', () {
      expect(
        QuizOptionDistinctness.tooSimilar(
          'કળિયુગમાં કીર્તનથી મોક્ષ થાય',
          'કળિયુગમાં કીર્તનથી જ મોક્ષ થઈ જાય',
        ),
        isTrue,
      );
      expect(
        QuizOptionDistinctness.tooSimilar(
          'સમીપે રહ્યા તોય ન દેખાય',
          'સમીપે રહ્યો છું પણ ચિત્તનો નિરોધ થાય એટલે ન દેખાય',
        ),
        isTrue,
      );
      expect(
        QuizOptionDistinctness.tooSimilar(
          'ખરાબ દેશકાળમાં કલ્યાણ સહેલું, સારામાં કઠણ',
          'ખરાબમાં કલ્યાણ સહેલું, સારામાં કઠણ — આર્તવાન-દીન થાવું',
        ),
        isTrue,
      );
      expect(
        QuizOptionDistinctness.tooSimilar(
          'સાધન અને વિશિષ્ટાદ્વૈત બંને થાય',
          'સત્સંગને પર સમજો તો સાધન + વિશિષ્ટાદ્વૈત',
        ),
        isTrue,
      );
      expect(
        QuizOptionDistinctness.tooSimilar(
          'the mind becomes steady',
          'the mind becomes steady.',
        ),
        isTrue,
      );
      expect(
        QuizOptionDistinctness.tooSimilar(
          'નિર્દોષ\u200cબુદ્ધિ એ જ કારણ',
          'નિર્દોષબુદ્ધિ એ જ કારણ',
        ),
        isTrue,
      );
    });

    test('keeps a real contrast and unrelated choices', () {
      expect(
        QuizOptionDistinctness.tooSimilar(
          'કળિયુગમાં કીર્તનથી મોક્ષ થાય',
          'કળિયુગમાં કીર્તનથી બંધન થાય',
        ),
        isFalse,
      );
      expect(
        QuizOptionDistinctness.tooSimilar(
          'લોકમાં પ્રીતિવાળો અધિક, પરલોકમાં જ્ઞાની અધિક',
          'લોકમાં પ્રીતિવાળો અધિક, પરલોકમાં અજ્ઞાની અધિક',
        ),
        isFalse,
      );
      expect(
        QuizOptionDistinctness.tooSimilar(
          'ધર્મ હંમેશાં ભક્તિ કરતાં મોટો',
          'ભક્તિ હંમેશાં ધર્મનો ત્યાગ કરે',
        ),
        isFalse,
      );
      expect(
        QuizOptionDistinctness.tooSimilar('સંવત્ ૨૦૩૧', 'સંવત્ ૨૦૩૨'),
        isFalse,
      );
      expect(
        QuizOptionDistinctness.tooSimilar('gold and women', 'karma and time'),
        isFalse,
      );
      expect(
        QuizOptionDistinctness.isDistinctSet(const [
          'સોનું અને સ્ત્રી',
          'કર્મ અને કાળ',
          'માન અને અપમાન',
          'દેહ અને પ્રદેશ',
        ]),
        isTrue,
      );
    });
  });

  group('DailyQuizQuestionSelection', () {
    final paraphrases = _question(
      id: 'paraphrase',
      prompt: 'પ્રગટ સ્વરુપ — શું સમજવું?',
      options: const [
        'કળિયુગમાં કીર્તનથી મોક્ષ થાય',
        'કળિયુગમાં કીર્તનથી જ મોક્ષ થઈ જાય',
        'કળિયુગમાં કીર્તન વડે મોક્ષ થાય છે',
        'કીર્તનથી કળિયુગમાં મોક્ષ થઈ જાય',
      ],
    );
    final distinct = _question(
      id: 'distinct',
      prompt: 'શુદ્ધ ચૈતન્ય બ્રહ્મને પોતાનું સ્વરૂપ ઓળખાય તો શું બંધન ન કરે?',
      options: const [
        'સોનું અને સ્ત્રી',
        'કર્મ અને કાળ',
        'માન અને અપમાન',
        'દેહ અને પ્રદેશ',
      ],
    );

    test('skips a question that cannot produce distinct distractors', () {
      final selected = DailyQuizQuestionSelection.select(
        preferred: [paraphrases, distinct],
        distractorPool: const [],
      );

      expect(selected.map((question) => question.id), ['distinct']);
      expect(
        QuizOptionDistinctness.isDistinctSet(selected.single.options),
        isTrue,
      );
    });

    test('keeps an already distinct set unchanged', () {
      final selected = DailyQuizQuestionSelection.select(preferred: [distinct]);

      expect(selected, hasLength(1));
      expect(identical(selected.single, distinct), isTrue);
      expect(selected.single.correctIndex, 0);
      expect(selected.single.options, distinct.options);
    });

    test('replaces similar distractors and keeps the one correct answer', () {
      final selected = DailyQuizQuestionSelection.select(
        preferred: [paraphrases],
        alternates: [distinct],
      );

      expect(selected.map((question) => question.id), [
        'paraphrase',
        'distinct',
      ]);
      final repaired = selected.first;
      expect(repaired.options, hasLength(4));
      expect(
        repaired.options[repaired.correctIndex],
        'કળિયુગમાં કીર્તનથી મોક્ષ થાય',
      );
      expect(
        repaired.options.where(
          (option) => option == repaired.options[repaired.correctIndex],
        ),
        hasLength(1),
      );
      expect(QuizOptionDistinctness.isDistinctSet(repaired.options), isTrue);
      expect(repaired.options, isNot(contains('સોનું અને સ્ત્રી')));
      expect(
        repaired.options,
        isNot(contains('કળિયુગમાં કીર્તનથી જ મોક્ષ થઈ જાય')),
      );
    });

    test('23 Oct 2026 choices are four-way distinct after selection', () {
      final today =
          jsonDecode(
                File(
                  'scripts/daily_quizzes/2026-10/23.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      final bank =
          jsonDecode(
                File('scripts/daily_quizzes/_bank.json').readAsStringSync(),
              )
              as Map<String, dynamic>;
      DailyQuizQuestion parse(Map<dynamic, dynamic> raw) {
        return DailyQuizQuestion.fromMap(Map<String, dynamic>.from(raw));
      }

      final preferred = [
        for (final item in today['questions'] as List) parse(item as Map),
      ];
      final alternates = [
        for (final pack in bank['packs'] as List)
          for (final item in (pack as Map)['questions'] as List)
            parse(item as Map),
      ];
      final selected = DailyQuizQuestionSelection.select(
        preferred: preferred,
        alternates: alternates,
      );

      expect(selected, hasLength(5));
      for (final question in selected) {
        expect(question.options, hasLength(4));
        expect(QuizOptionDistinctness.isDistinctSet(question.options), isTrue);
        expect(
          question.options
              .where(
                (option) => option == question.options[question.correctIndex],
              )
              .length,
          1,
        );
      }
      expect(selected.first.id, preferred.first.id);
      expect(selected.first.options, preferred.first.options);
    });
  });
}
