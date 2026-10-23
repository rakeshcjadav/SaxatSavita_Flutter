import 'package:saxatsavita_flutter/models/daily_quiz_model.dart';
import 'package:saxatsavita_flutter/quiz/quiz_option_distinctness.dart';

/// Chooses daily-quiz questions whose correct answer and three wrong answers
/// do not paraphrase each other.
///
/// A question that already has four distinct choices is kept as authored.
/// Otherwise wrong answers that repeat the correct line, or each other, are
/// replaced from other choices in the pool. If three distinct wrong answers
/// cannot be found, the question is skipped and a later question is used.
class DailyQuizQuestionSelection {
  static const optionCount = 4;

  static List<DailyQuizQuestion> select({
    required List<DailyQuizQuestion> preferred,
    List<DailyQuizQuestion> alternates = const [],
    List<String>? distractorPool,
    int count = 5,
  }) {
    if (count <= 0) return const [];
    final pool = distractorPool ?? _wrongAnswers([...preferred, ...alternates]);
    final chosen = <DailyQuizQuestion>[];
    final used = <String>{};

    void take(DailyQuizQuestion question) {
      if (question.id.isEmpty || !used.add(question.id)) return;
      chosen.add(question);
    }

    for (final question in preferred) {
      if (chosen.length >= count) break;
      if (_ready(question)) {
        take(question);
        continue;
      }
      final repaired = repair(question, pool);
      if (repaired != null) take(repaired);
    }

    for (final question in alternates) {
      if (chosen.length >= count) break;
      if (_ready(question)) take(question);
    }
    for (final question in alternates) {
      if (chosen.length >= count) break;
      if (used.contains(question.id)) continue;
      final repaired = repair(question, pool);
      if (repaired != null) take(repaired);
    }
    return chosen;
  }

  /// Returns [question] when its choices are already distinct. Otherwise
  /// rebuilds four choices with the same correct answer, or null when that
  /// is not possible.
  static DailyQuizQuestion? repair(
    DailyQuizQuestion question,
    List<String> distractorPool,
  ) {
    if (_ready(question)) return question;
    final correct = _correctText(question);
    if (correct.isEmpty) return null;

    final kept = <String>[];
    for (var i = 0; i < question.options.length; i++) {
      if (i == question.correctIndex) continue;
      final option = question.options[i].trim();
      if (option.isEmpty) continue;
      if (QuizOptionDistinctness.tooSimilar(option, correct)) continue;
      if (kept.any((item) => QuizOptionDistinctness.tooSimilar(item, option))) {
        continue;
      }
      kept.add(option);
      if (kept.length == optionCount - 1) break;
    }

    if (kept.length < optionCount - 1) {
      final ranked = List<String>.from(distractorPool)..sort((a, b) {
        final byRank = _rank(question.id, a).compareTo(_rank(question.id, b));
        if (byRank != 0) return byRank;
        return a.compareTo(b);
      });
      for (final candidate in ranked) {
        if (kept.length == optionCount - 1) break;
        final option = candidate.trim();
        if (option.isEmpty) continue;
        if (QuizOptionDistinctness.tooSimilar(option, correct)) continue;
        if (kept.any(
          (item) => QuizOptionDistinctness.tooSimilar(item, option),
        )) {
          continue;
        }
        kept.add(option);
      }
    }
    if (kept.length < optionCount - 1) return null;

    var correctIndex = question.correctIndex;
    if (correctIndex < 0 || correctIndex >= optionCount) correctIndex = 0;
    final options = List<String>.filled(optionCount, '');
    options[correctIndex] = correct;
    var distractor = 0;
    for (var i = 0; i < optionCount; i++) {
      if (i == correctIndex) continue;
      options[i] = kept[distractor];
      distractor += 1;
    }
    if (!QuizOptionDistinctness.isDistinctSet(options)) return null;
    return DailyQuizQuestion(
      id: question.id,
      prompt: question.prompt,
      options: options,
      correctIndex: correctIndex,
      explanation: question.explanation,
      part: question.part,
      kiranIndex: question.kiranIndex,
    );
  }

  static bool _ready(DailyQuizQuestion question) {
    return question.correctIndex >= 0 &&
        question.correctIndex < question.options.length &&
        QuizOptionDistinctness.isDistinctSet(question.options);
  }

  static String _correctText(DailyQuizQuestion question) {
    if (question.correctIndex < 0 ||
        question.correctIndex >= question.options.length) {
      return '';
    }
    return question.options[question.correctIndex].trim();
  }

  static List<String> _wrongAnswers(List<DailyQuizQuestion> questions) {
    final correctTexts = <String>{
      for (final question in questions) _correctText(question),
    }..remove('');
    final pool = <String>[];
    final seen = <String>{};
    for (final question in questions) {
      for (var i = 0; i < question.options.length; i++) {
        if (i == question.correctIndex) continue;
        final option = question.options[i].trim();
        if (option.isEmpty || !seen.add(option)) continue;
        if (correctTexts.contains(option)) continue;
        pool.add(option);
      }
    }
    return pool;
  }

  static int _rank(String questionId, String text) {
    var hash = 0x811c9dc5;
    for (final code in '$questionId\n$text'.codeUnits) {
      hash ^= code;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}
