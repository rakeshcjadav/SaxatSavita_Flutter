import 'package:flutter/material.dart';
import 'package:saxatsavita_flutter/helpers/open_kiran_map.dart';
import 'package:saxatsavita_flutter/models/kiraninfo_model.dart';
import 'package:saxatsavita_flutter/services/remote_config_service.dart';

/// One-line sitting path with even padding around each village name.
class KiranPlaceLine extends StatelessWidget {
  const KiranPlaceLine({
    super.key,
    required this.kiranInfo,
    this.color,
    this.enableMapTap = true,
  });

  final KiranInfo kiranInfo;
  final Color? color;
  final bool enableMapTap;

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
    final textColor = color ?? colorScheme.onSurfaceVariant;
    final style = Theme.of(
      context,
    ).textTheme.labelSmall?.copyWith(color: textColor);

    Widget line = Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 2),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Icon(Icons.location_on_outlined, size: 14, color: textColor),
            const SizedBox(width: 6),
            for (int i = 0; i < places.length; i++) ...[
              if (i > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.arrow_forward,
                    size: 12,
                    color: textColor.withValues(alpha: 0.7),
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

    if (enableMapTap && RemoteConfigService().enableKiranMap) {
      line = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => openKiranMap(context, kiranIndex: kiranInfo.index),
        child: line,
      );
    }
    return line;
  }
}
