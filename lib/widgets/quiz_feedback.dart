import 'package:flutter/material.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';
import 'package:saxatsavita_flutter/widgets/quiz_colors.dart';

class QuizFeedback extends StatelessWidget {
  const QuizFeedback({
    super.key,
    required this.correct,
    required this.explanation,
    required this.fontSize,
    this.sourceHint = '',
    this.footer,
  });

  final bool correct;
  final String explanation;
  final String sourceHint;
  final double fontSize;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final background = correct ? quizSoftGreen : quizSoftRed;
    final border = correct ? quizSoftGreenBorder : quizSoftRedBorder;
    final accent = correct ? quizSoftGreenFg : quizSoftRedFg;
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
                fontSize: fontSize,
                height: 1.45,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
          if (sourceHint.isNotEmpty && !explanation.contains(sourceHint)) ...[
            const SizedBox(height: 10),
            Text(
              sourceHint,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: accent,
                fontWeight: FontWeight.w600,
                fontSize: fontSize - 1,
              ),
            ),
          ],
          if (footer != null) ...[const SizedBox(height: 12), footer!],
        ],
      ),
    );
  }
}
