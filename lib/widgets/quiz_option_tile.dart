import 'package:flutter/material.dart';
import 'package:saxatsavita_flutter/widgets/quiz_colors.dart';

class QuizOptionTile extends StatelessWidget {
  const QuizOptionTile({
    super.key,
    required this.letter,
    required this.label,
    required this.selected,
    required this.locked,
    required this.isCorrect,
    required this.fontSize,
    required this.onTap,
  });

  final String letter;
  final String label;
  final bool selected;
  final bool locked;
  final bool isCorrect;
  final double fontSize;
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
      background = quizSoftGreen;
      border = quizSoftGreenBorder;
      badgeBg = quizSoftGreenFg;
      badgeFg = Colors.white;
      trailing = Icons.check_circle;
      trailingColor = quizSoftGreenFg;
    } else if (locked && selected && !isCorrect) {
      background = quizSoftRed;
      border = quizSoftRedBorder;
      badgeBg = quizSoftRedFg;
      badgeFg = Colors.white;
      trailing = Icons.cancel;
      trailingColor = quizSoftRedFg;
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
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: badgeBg,
                child: Text(
                  letter,
                  style: TextStyle(
                    color: badgeFg,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: fontSize,
                    height: 1.45,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                Icon(trailing, color: trailingColor),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
