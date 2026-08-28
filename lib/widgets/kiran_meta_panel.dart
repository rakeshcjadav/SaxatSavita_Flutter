import 'package:flutter/material.dart';
import 'package:saxatsavita_flutter/components/custom_html_widget.dart';
import 'package:saxatsavita_flutter/helpers/html_to_textspan.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';
import 'package:saxatsavita_flutter/models/appsettings.dart';
import 'package:saxatsavita_flutter/services/remote_config_service.dart';

List<String> parseKiranLocations(Map<String, dynamic> contentData) {
  final String place = (contentData['main']?['place'] as String? ?? '').trim();
  final String venue = (contentData['meta']?['venue'] as String? ?? '').trim();
  final List<String> locations =
      (contentData['meta']?['locations'] as List<dynamic>? ?? [])
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
  if (locations.isEmpty) {
    if (venue.isNotEmpty && place.isNotEmpty) {
      locations.add('$venue, $place');
    } else if (place.isNotEmpty) {
      locations.add(place);
    }
  }
  return locations;
}

/// Date/place context card plus Teaching and Summary for kiran meta.
class KiranMetaPanel extends StatelessWidget {
  const KiranMetaPanel({
    super.key,
    required this.locations,
    required this.date,
    required this.moral,
    required this.history,
    required this.summary,
    this.showAiCaption = false,
    this.onAddNote,
    this.onCreateQuoteImage,
  });

  factory KiranMetaPanel.fromContent(
    Map<String, dynamic> contentData, {
    Key? key,
    bool showAiCaption = false,
    Future<void> Function(String selectedText)? onAddNote,
    Future<void> Function(String selectedText)? onCreateQuoteImage,
  }) {
    return KiranMetaPanel(
      key: key,
      locations: parseKiranLocations(contentData),
      date: (contentData['meta']?['date'] as String? ?? '').trim(),
      moral: (contentData['meta']?['moral'] as String? ?? '').trim(),
      history: (contentData['meta']?['history'] as String? ?? '').trim(),
      summary:
          (contentData['meta']?['summary'] as List<dynamic>? ?? [])
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList(),
      showAiCaption: showAiCaption,
      onAddNote: onAddNote,
      onCreateQuoteImage: onCreateQuoteImage,
    );
  }

  final List<String> locations;
  final String date;
  final String moral;
  final String history;
  final List<String> summary;
  final bool showAiCaption;
  final Future<void> Function(String selectedText)? onAddNote;
  final Future<void> Function(String selectedText)? onCreateQuoteImage;

  bool get _isEmpty =>
      locations.isEmpty &&
      date.isEmpty &&
      moral.isEmpty &&
      history.isEmpty &&
      summary.isEmpty;

  static String toGujaratiNumeral(int n) {
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

  @override
  Widget build(BuildContext context) {
    if (_isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ValueListenableBuilder<AppSettings>(
      valueListenable: appSettingsNotifier,
      builder: (context, settings, _) {
        final contentStyle = textTheme.bodyMedium!.copyWith(
          color: colorScheme.primary,
          fontSize: settings.fontSize,
        );

        Widget metaHtml(String html) {
          if (RemoteConfigService().useCustomHtmlWidget) {
            return CustomHtmlWidget(
              htmlContent: html,
              wrapInSelectionArea: false,
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: HtmlToTextSpan.convertToWidgets(
              html,
              contentStyle,
              context,
              textAlign: TextAlign.justify,
              lineHeight: settings.lineHeight,
              onAddNote: onAddNote,
              onCreateQuoteImage: onCreateQuoteImage,
            ),
          );
        }

        Widget numberedItem(int index, String html) {
          final number = toGujaratiNumeral(index);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: metaHtml('<b>$number.</b> $html'),
          );
        }

        Widget sectionLabel(String label) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              label,
              style: textTheme.labelLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }

        final hasContext = locations.isNotEmpty || date.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showAiCaption) ...[
              Text(
                l10n.kiran_info_ai_generated,
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.outline,
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (hasContext) ...[
              _ContextCard(
                locations: locations,
                date: date,
                colorScheme: colorScheme,
                textTheme: textTheme,
                fontSize: settings.fontSize,
              ),
              if (moral.isNotEmpty || history.isNotEmpty || summary.isNotEmpty)
                const SizedBox(height: 20),
            ],
            if (moral.isNotEmpty) ...[
              sectionLabel(l10n.kiran_moral),
              _QuoteCard(colorScheme: colorScheme, child: metaHtml(moral)),
              if (history.isNotEmpty || summary.isNotEmpty)
                const SizedBox(height: 20),
            ],
            if (history.isNotEmpty) ...[
              sectionLabel(l10n.kiran_history),
              metaHtml(history),
              if (summary.isNotEmpty) const SizedBox(height: 20),
            ],
            if (summary.isNotEmpty) ...[
              sectionLabel(l10n.kiran_summary),
              ...summary.indexed.map(
                ((int, String) entry) => numberedItem(entry.$1 + 1, entry.$2),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ContextCard extends StatelessWidget {
  const _ContextCard({
    required this.locations,
    required this.date,
    required this.colorScheme,
    required this.textTheme,
    required this.fontSize,
  });

  final List<String> locations;
  final String date;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final textStyle = textTheme.bodyMedium?.copyWith(
      color: colorScheme.onSurface,
      fontSize: fontSize,
      height: 1.35,
    );
    final iconColor = colorScheme.primary;
    final connectorColor = colorScheme.outlineVariant;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < locations.length; i++)
            _ContextRow(
              icon: Icons.location_on_outlined,
              iconColor: iconColor,
              showConnectorBelow: i < locations.length - 1,
              connectorColor: connectorColor,
              firstLineHeight: fontSize * 1.35,
              child: Text(locations[i], style: textStyle),
            ),
          if (date.isNotEmpty) ...[
            if (locations.isNotEmpty) const SizedBox(height: 8),
            _ContextRow(
              icon: Icons.calendar_today_outlined,
              iconColor: iconColor,
              showConnectorBelow: false,
              connectorColor: connectorColor,
              firstLineHeight: fontSize * 1.35,
              child: Text(date, style: textStyle),
            ),
          ],
        ],
      ),
    );
  }
}

class _ContextRow extends StatelessWidget {
  const _ContextRow({
    required this.icon,
    required this.iconColor,
    required this.showConnectorBelow,
    required this.connectorColor,
    required this.firstLineHeight,
    required this.child,
  });

  final IconData icon;
  final Color iconColor;
  final bool showConnectorBelow;
  final Color connectorColor;
  final double firstLineHeight;
  final Widget child;

  static const double _iconSize = 18;

  @override
  Widget build(BuildContext context) {
    final iconTop = ((firstLineHeight - _iconSize) / 2).clamp(0.0, 8.0);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 22,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(top: iconTop),
                child: Icon(icon, size: _iconSize, color: iconColor),
              ),
              if (showConnectorBelow)
                Container(
                  width: 2,
                  height: 14,
                  margin: const EdgeInsets.only(top: 2, bottom: 2),
                  decoration: BoxDecoration(
                    color: connectorColor,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: child),
      ],
    );
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({required this.colorScheme, required this.child});

  final ColorScheme colorScheme;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ColoredBox(
        color: colorScheme.primaryContainer.withValues(alpha: 0.45),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: colorScheme.primary),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
