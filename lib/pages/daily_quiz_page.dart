import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saxatsavita_flutter/components/appbar.dart';
import 'package:saxatsavita_flutter/helpers/open_kiran.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';
import 'package:saxatsavita_flutter/models/appsettings.dart';
import 'package:saxatsavita_flutter/models/daily_quiz_model.dart';
import 'package:saxatsavita_flutter/services/analytics_service.dart';
import 'package:saxatsavita_flutter/services/daily_quiz_service.dart';
import 'package:saxatsavita_flutter/services/kiranlistservice.dart';
import 'package:saxatsavita_flutter/widgets/quiz_colors.dart';
import 'package:saxatsavita_flutter/widgets/quiz_feedback.dart';
import 'package:saxatsavita_flutter/widgets/quiz_option_tile.dart';

class DailyQuizPage extends StatefulWidget {
  const DailyQuizPage({super.key});

  @override
  State<DailyQuizPage> createState() => _DailyQuizPageState();
}

enum _DailyQuizPhase { intro, playing, result }

class _DailyQuizPageState extends State<DailyQuizPage> {
  final DailyQuizService _quizService = DailyQuizService();
  final KiranListService _kiranListService = KiranListService();
  final Random _random = Random();

  bool _loading = true;
  _DailyQuizPhase _phase = _DailyQuizPhase.intro;
  DailyQuizPack? _pack;
  DailyQuizResult? _existing;
  int _streak = 0;
  int _index = 0;
  int? _selectedDisplay;
  bool _locked = false;
  final List<int> _answers = [];
  List<int> _optionOrder = [];
  DailyQuizResult? _result;
  final Map<String, String> _kiranTitles = {};

  List<DailyQuizQuestion> get _questions => _pack?.scoredQuestions ?? const [];

  @override
  void initState() {
    super.initState();
    AnalyticsService().logScreenView(screenName: 'daily_quiz_page');
    _load();
  }

  Future<void> _load() async {
    final pack = await _quizService.packForToday();
    final existing = await _quizService.resultForToday();
    final streak = await _quizService.currentStreak();
    if (pack != null) {
      await _prefetchKiranTitles(pack);
    }
    if (!mounted) return;
    setState(() {
      _pack = pack;
      _existing = existing;
      _streak = streak;
      _loading = false;
      _result = existing;
    });
  }

  Future<void> _prefetchKiranTitles(DailyQuizPack pack) async {
    final parts = pack.scoredQuestions.map((q) => q.part).toSet();
    for (final part in parts) {
      await _kiranListService.loadPart('saxatsavita', 'part$part');
    }
    for (final question in pack.scoredQuestions) {
      final info = _kiranListService.getKiranInfo(
        question.part,
        question.kiranIndex,
      );
      _kiranTitles[question.id] = '${info.number} ${info.title}'.trim();
    }
  }

  String _kiranHeading(DailyQuizQuestion question) {
    return _kiranTitles[question.id] ?? '';
  }

  List<int> _shuffledOrder(DailyQuizQuestion question) {
    final order = List<int>.generate(question.options.length, (i) => i);
    order.shuffle(_random);
    return order;
  }

  void _start() {
    if (_questions.isEmpty) return;
    setState(() {
      _existing ??= _result;
      _phase = _DailyQuizPhase.playing;
      _index = 0;
      _selectedDisplay = null;
      _locked = false;
      _answers.clear();
      _optionOrder = _shuffledOrder(_questions.first);
    });
  }

  void _select(int displayIndex) {
    if (_locked || _questions.isEmpty) return;
    setState(() {
      _selectedDisplay = displayIndex;
      _locked = true;
      if (_answers.length == _index) {
        _answers.add(_optionOrder[displayIndex]);
      }
    });
  }

  Future<void> _advance() async {
    if (_questions.isEmpty) return;
    if (_index < _questions.length - 1) {
      setState(() {
        _index += 1;
        _selectedDisplay = null;
        _locked = false;
        _optionOrder = _shuffledOrder(_questions[_index]);
      });
      return;
    }
    await _finish();
  }

  Future<void> _finish() async {
    final pack = _pack;
    if (pack == null) return;
    if (_result == null) {
      var correct = 0;
      for (var i = 0; i < _questions.length; i++) {
        if (i < _answers.length && _answers[i] == _questions[i].correctIndex) {
          correct += 1;
        }
      }
      _result = await _quizService.submitAttempt(
        pack: pack,
        score: correct,
        answers: List<int>.from(_answers),
      );
      _streak = await _quizService.currentStreak();
    }
    if (!mounted) return;
    setState(() => _phase = _DailyQuizPhase.result);
  }

  Future<void> _openQuestionKiran(DailyQuizQuestion question) {
    return openKiran(
      context,
      kiranIndex: question.kiranIndex,
      partNumber: question.part,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: buildAppBar(
        context,
        title: l10n.daily_quiz,
        titleIcon: Icons.auto_awesome,
        extraActions: [
          if (_existing != null)
            IconButton(
              icon: const Icon(Icons.info_outline),
              tooltip: l10n.daily_quiz_already_scored,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.daily_quiz_already_scored)),
                );
              },
            ),
        ],
      ),
      body: ValueListenableBuilder<AppSettings>(
        valueListenable: appSettingsNotifier,
        builder: (context, _, _) => _buildBody(l10n),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_pack == null || _questions.isEmpty) {
      return Center(child: Text(l10n.daily_quiz_unavailable));
    }
    return switch (_phase) {
      _DailyQuizPhase.intro => _IntroView(
        existing: _existing,
        streak: _streak,
        questionCount: _questions.length,
        onStart: _start,
      ),
      _DailyQuizPhase.playing => _buildPlaying(l10n),
      _DailyQuizPhase.result => _ResultView(
        result: _result!,
        alreadyScored: _existing != null,
        streak: _streak,
        questions: _questions,
        titles: _kiranTitles,
        onOpenKiran: _openQuestionKiran,
        onReview: _start,
      ),
    };
  }

  Widget _buildPlaying(AppLocalizations l10n) {
    final question = _questions[_index];
    final progress = (_index + 1) / _questions.length;
    final colors = Theme.of(context).colorScheme;
    final settings = appSettingsNotifier.value;
    final useGujarati = Localizations.localeOf(context).languageCode == 'gu';
    final questionNo =
        useGujarati ? toGujaratiNumeral(_index + 1) : '${_index + 1}';
    final questionSize = settings.appFontSize.clamp(16.0, 24.0);
    final optionSize = (settings.appFontSize - 1).clamp(15.0, 22.0);

    return Column(
      children: [
        LinearProgressIndicator(
          value: progress,
          minHeight: 4,
          backgroundColor: colors.surfaceContainerHighest,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Text(
                l10n.quiz_question_of(_index + 1, _questions.length),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontSize: questionSize - 2,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              Card(
                elevation: 0,
                color: colors.surfaceContainerHighest.withValues(alpha: 0.55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${l10n.daily_quiz} $questionNo',
                          style: TextStyle(
                            color: colors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        question.prompt,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: questionSize,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              ...List.generate(_optionOrder.length, (displayIndex) {
                final originalIndex = _optionOrder[displayIndex];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: QuizOptionTile(
                    letter: quizOptionLetter(
                      useGujarati: useGujarati,
                      displayIndex: displayIndex,
                    ),
                    label: question.options[originalIndex],
                    selected: _selectedDisplay == displayIndex,
                    locked: _locked,
                    isCorrect: originalIndex == question.correctIndex,
                    fontSize: optionSize,
                    onTap: () => _select(displayIndex),
                  ),
                );
              }),
              if (_locked) ...[
                const SizedBox(height: 8),
                QuizFeedback(
                  correct:
                      _optionOrder[_selectedDisplay!] == question.correctIndex,
                  explanation: question.explanation,
                  fontSize: optionSize,
                  footer: _ReadKiranButton(
                    heading: _kiranHeading(question),
                    onPressed: () => _openQuestionKiran(question),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (_locked)
          SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _advance,
                child: Text(
                  _index == _questions.length - 1
                      ? l10n.quiz_see_result
                      : l10n.quiz_next,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _IntroView extends StatelessWidget {
  const _IntroView({
    required this.existing,
    required this.streak,
    required this.questionCount,
    required this.onStart,
  });

  final DailyQuizResult? existing;
  final int streak;
  final int questionCount;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final dateLabel = DateFormat.yMMMMd(locale).format(DateTime.now());
    final completed = existing != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        children: [
          const Spacer(),
          CircleAvatar(
            radius: 44,
            backgroundColor: colors.primaryContainer,
            child: Icon(
              completed ? Icons.check_circle : Icons.auto_awesome,
              size: 44,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.daily_quiz_intro_title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            dateLabel,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.daily_quiz_intro_subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(height: 1.45),
          ),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                avatar: const Icon(Icons.quiz, size: 18),
                label: Text(l10n.daily_quiz_questions_count(questionCount)),
              ),
              if (streak > 0)
                Chip(
                  avatar: const Icon(Icons.local_fire_department, size: 18),
                  label: Text(l10n.daily_quiz_streak_count(streak)),
                ),
              if (completed)
                Chip(
                  avatar: const Icon(Icons.stars, size: 18),
                  label: Text(
                    l10n.quiz_score(existing!.score, existing!.total),
                  ),
                ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: onStart,
              child: Text(
                completed ? l10n.daily_quiz_review : l10n.daily_quiz_start,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.result,
    required this.alreadyScored,
    required this.streak,
    required this.questions,
    required this.titles,
    required this.onOpenKiran,
    required this.onReview,
  });

  final DailyQuizResult result;
  final bool alreadyScored;
  final int streak;
  final List<DailyQuizQuestion> questions;
  final Map<String, String> titles;
  final Future<void> Function(DailyQuizQuestion question) onOpenKiran;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final showPractice = alreadyScored;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      children: [
        const SizedBox(height: 12),
        Center(
          child: CircleAvatar(
            radius: 44,
            backgroundColor: colors.primaryContainer,
            child: Icon(
              result.isPerfect ? Icons.emoji_events : Icons.auto_awesome,
              size: 44,
              color: colors.primary,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          l10n.quiz_score(result.score, result.total),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: colors.primary,
          ),
        ),
        if (result.isPerfect) ...[
          const SizedBox(height: 8),
          Text(
            l10n.quiz_perfect,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(
              avatar: const Icon(Icons.stars, size: 18),
              label: Text(
                showPractice
                    ? l10n.daily_quiz_already_scored
                    : l10n.quiz_points_count(result.pointsAwarded),
              ),
            ),
            if (streak > 0)
              Chip(
                avatar: const Icon(Icons.local_fire_department, size: 18),
                label: Text(l10n.daily_quiz_streak_count(streak)),
              ),
          ],
        ),
        const SizedBox(height: 28),
        Text(
          l10n.daily_quiz_source_heading,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        ...questions.map((question) {
          final heading = titles[question.id] ?? '';
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: colors.outlineVariant),
              ),
              leading: Icon(Icons.menu_book, color: colors.primary),
              title: Text(
                heading.isEmpty ? l10n.daily_quiz_read_kiran : heading,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => onOpenKiran(question),
            ),
          );
        }),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed:
                () =>
                    Navigator.of(context).pushNamed('/daily-quiz-leaderboard'),
            icon: const Icon(Icons.emoji_events_outlined),
            label: Text(l10n.daily_quiz_leaderboard),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: onReview,
            child: Text(l10n.daily_quiz_review),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(result),
            child: Text(l10n.ok),
          ),
        ),
      ],
    );
  }
}

class _ReadKiranButton extends StatelessWidget {
  const _ReadKiranButton({required this.heading, required this.onPressed});

  final String heading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.menu_book, size: 18),
        label: Text(
          heading.isEmpty ? l10n.daily_quiz_read_kiran : heading,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
