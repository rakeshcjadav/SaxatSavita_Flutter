import 'dart:math';

import 'package:flutter/material.dart';
import 'package:saxatsavita_flutter/components/appbar.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';
import 'package:saxatsavita_flutter/models/kiran_quiz_model.dart';
import 'package:saxatsavita_flutter/services/kiran_quiz_service.dart';

class KiranQuizPage extends StatefulWidget {
  const KiranQuizPage({
    super.key,
    required this.part,
    required this.kiranIndex,
    this.kiranNumber = '',
    this.title = '',
  });

  final int part;
  final int kiranIndex;
  final String kiranNumber;
  final String title;

  @override
  State<KiranQuizPage> createState() => _KiranQuizPageState();
}

const _softGreen = Color(0xFFE8F5E9);
const _softGreenBorder = Color(0xFF81C784);
const _softGreenFg = Color(0xFF1B5E20);
const _softRed = Color(0xFFFFEBEE);
const _softRedBorder = Color(0xFFE57373);
const _softRedFg = Color(0xFFB71C1C);

String _toGujaratiNumeral(int n) {
  return n
      .toString()
      .replaceAll('0', '૦')
      .replaceAll('1', '૧')
      .replaceAll('2', '૨')
      .replaceAll('3', '૩')
      .replaceAll('4', '૪')
      .replaceAll('5', '૫')
      .replaceAll('6', '૬')
      .replaceAll('7', '૭')
      .replaceAll('8', '૮')
      .replaceAll('9', '૯');
}

class _KiranQuizPageState extends State<KiranQuizPage> {
  final KiranQuizService _quizService = KiranQuizService();
  final Random _random = Random();
  KiranQuiz? _quiz;
  KiranQuizResult? _existing;
  bool _loading = true;
  int _index = 0;
  int? _selectedDisplay;
  bool _locked = false;
  final List<int> _answers = [];
  List<int> _optionOrder = [];
  KiranQuizResult? _result;

  @override
  void initState() {
    super.initState();
    _load();
  }

  List<int> _shuffledOrder(KiranQuizQuestion question) {
    final order = List<int>.generate(question.options.length, (i) => i);
    order.shuffle(_random);
    return order;
  }

  Future<void> _load() async {
    final quiz = await _quizService.quizFor(widget.part, widget.kiranIndex);
    final existing = await _quizService.resultFor(
      widget.part,
      widget.kiranIndex,
    );
    if (!mounted) return;
    setState(() {
      _quiz = quiz;
      _existing = existing;
      _loading = false;
      if (quiz != null && quiz.questions.isNotEmpty) {
        _optionOrder = _shuffledOrder(quiz.questions.first);
      }
    });
  }

  void _select(int displayIndex) {
    if (_locked || _quiz == null) return;
    setState(() {
      _selectedDisplay = displayIndex;
      _locked = true;
      if (_answers.length == _index) {
        _answers.add(_optionOrder[displayIndex]);
      }
    });
  }

  Future<void> _advance() async {
    final quiz = _quiz;
    if (quiz == null) return;
    if (_index < quiz.questions.length - 1) {
      setState(() {
        _index += 1;
        _selectedDisplay = null;
        _locked = false;
        _optionOrder = _shuffledOrder(quiz.questions[_index]);
      });
      return;
    }

    var correct = 0;
    for (var i = 0; i < quiz.questions.length; i++) {
      if (i < _answers.length &&
          _answers[i] == quiz.questions[i].correctIndex) {
        correct += 1;
      }
    }
    final result = await _quizService.submitAttempt(quiz: quiz, score: correct);
    if (!mounted) return;
    setState(() => _result = result);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: buildAppBar(
        context,
        title: l10n.quiz,
        titleIcon: Icons.quiz,
        extraActions: [
          if (_existing != null)
            IconButton(
              icon: const Icon(Icons.info_outline),
              tooltip: l10n.quiz_already_scored,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.quiz_already_scored)),
                );
              },
            ),
        ],
      ),
      body: _buildBody(l10n),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final quiz = _quiz;
    if (quiz == null || quiz.questions.isEmpty) {
      return Center(child: Text(l10n.quiz_no_questions));
    }
    if (_result != null) {
      return _ResultView(
        result: _result!,
        alreadyScored: _existing != null,
        earnedFirstBadge: _result!.rewardIds.contains(
          KiranQuizService.firstQuizBadge,
        ),
      );
    }

    final question = quiz.questions[_index];
    final progress = (_index + 1) / quiz.questions.length;
    final colors = Theme.of(context).colorScheme;
    final useGujarati = Localizations.localeOf(context).languageCode == 'gu';
    final kiranHeading = [
      widget.kiranNumber.trim(),
      widget.title.trim(),
    ].where((part) => part.isNotEmpty).join(' ');
    final questionNo = useGujarati
        ? _toGujaratiNumeral(_index + 1)
        : '${_index + 1}';

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
              if (kiranHeading.isNotEmpty)
                Text(
                  kiranHeading,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: colors.surfaceContainerHighest.withValues(alpha: 0.55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '$questionNo. ${question.prompt}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ...List.generate(_optionOrder.length, (displayIndex) {
                final originalIndex = _optionOrder[displayIndex];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _OptionTile(
                    letter: String.fromCharCode(65 + displayIndex),
                    label: question.options[originalIndex],
                    selected: _selectedDisplay == displayIndex,
                    locked: _locked,
                    isCorrect: originalIndex == question.correctIndex,
                    onTap: () => _select(displayIndex),
                  ),
                );
              }),
              if (_locked) ...[
                const SizedBox(height: 8),
                _Feedback(
                  correct:
                      _optionOrder[_selectedDisplay!] == question.correctIndex,
                  explanation: question.explanation,
                  sourceHint: question.sourceHint,
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
                  _index == quiz.questions.length - 1
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

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.letter,
    required this.label,
    required this.selected,
    required this.locked,
    required this.isCorrect,
    required this.onTap,
  });

  final String letter;
  final String label;
  final bool selected;
  final bool locked;
  final bool isCorrect;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Color background = colors.surface;
    Color border = colors.outlineVariant;
    Color badgeBg = colors.surfaceContainerHighest;
    Color badgeFg = colors.onSurfaceVariant;
    Color? trailingColor;
    IconData? trailing;

    if (locked && isCorrect) {
      background = _softGreen;
      border = _softGreenBorder;
      badgeBg = _softGreenFg;
      badgeFg = Colors.white;
      trailing = Icons.check_circle;
      trailingColor = _softGreenFg;
    } else if (locked && selected && !isCorrect) {
      background = _softRed;
      border = _softRedBorder;
      badgeBg = _softRedFg;
      badgeFg = Colors.white;
      trailing = Icons.cancel;
      trailingColor = _softRedFg;
    } else if (selected) {
      background = colors.secondaryContainer;
      border = colors.secondary;
    }

    return Material(
      color: background,
      elevation: selected || (locked && isCorrect) ? 1 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: border, width: 1.4),
      ),
      child: InkWell(
        onTap: locked ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: badgeBg,
                child: Text(
                  letter,
                  style: TextStyle(color: badgeFg, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.35,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
              if (trailing != null)
                Icon(trailing, color: trailingColor),
            ],
          ),
        ),
      ),
    );
  }
}

class _Feedback extends StatelessWidget {
  const _Feedback({
    required this.correct,
    required this.explanation,
    required this.sourceHint,
  });

  final bool correct;
  final String explanation;
  final String sourceHint;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final background = correct ? _softGreen : _softRed;
    final border = correct ? _softGreenBorder : _softRedBorder;
    final accent = correct ? _softGreenFg : _softRedFg;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                correct ? Icons.check_circle : Icons.info_outline,
                size: 20,
                color: accent,
              ),
              const SizedBox(width: 8),
              Text(
                correct ? l10n.quiz_correct : l10n.quiz_incorrect,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (explanation.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              explanation,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                height: 1.45,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
          if (sourceHint.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${l10n.quiz_explanation}: $sourceHint',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.result,
    required this.alreadyScored,
    required this.earnedFirstBadge,
  });

  final KiranQuizResult result;
  final bool alreadyScored;
  final bool earnedFirstBadge;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),
          CircleAvatar(
            radius: 44,
            backgroundColor: colors.primaryContainer,
            child: Icon(
              result.isPerfect ? Icons.emoji_events : Icons.quiz,
              size: 44,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.quiz_score(result.score, result.total),
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.primary,
            ),
          ),
          if (result.isPerfect) ...[
            const SizedBox(height: 8),
            Text(
              l10n.quiz_perfect,
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
                  alreadyScored
                      ? l10n.quiz_already_scored
                      : l10n.quiz_points_count(result.pointsAwarded),
                ),
              ),
              if (earnedFirstBadge && !alreadyScored)
                Chip(
                  avatar: const Icon(Icons.military_tech, size: 18),
                  label: Text(l10n.quiz_first_badge),
                ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(result),
              child: Text(l10n.ok),
            ),
          ),
        ],
      ),
    );
  }
}
