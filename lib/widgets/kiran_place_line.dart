import 'package:flutter/material.dart';
import 'package:saxatsavita_flutter/models/kiraninfo_model.dart';

/// One-line sitting path with even padding around each village name.
class KiranPlaceLine extends StatelessWidget {
  const KiranPlaceLine({super.key, required this.kiranInfo});

  final KiranInfo kiranInfo;

  @override
  Widget build(BuildContext context) {
    final places =
        kiranInfo.places.isNotEmpty
            ? kiranInfo.places
            : (kiranInfo.place.isNotEmpty
                ? [kiranInfo.place]
                : const <String>[]);
    if (places.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final style = Theme.of(
      context,
    ).textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant);

    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 2),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (int i = 0; i < places.length; i++) ...[
              if (i > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.arrow_forward,
                    size: 12,
                    color: colorScheme.outline,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(places[i], style: style),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
