import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:saxatsavita_flutter/models/meanings_model.dart';
import 'package:saxatsavita_flutter/services/bookservice.dart';
import 'package:saxatsavita_flutter/services/utils.dart';

/// Registry for mapping custom tag → widget builder
typedef CustomTagBuilder =
    Widget Function(
      BuildContext context,
      ExtensionContext extensionContext,
      String innerHtml,
    );

class CustomTagRegistry {
  final Map<String, CustomTagBuilder> _registry = {};

  void register(String tag, CustomTagBuilder builder) {
    _registry[tag] = builder;
  }

  List<TagExtension> buildExtensions(BuildContext context) {
    return _registry.entries.map((entry) {
      return TagExtension(
        tagsToExtend: {entry.key},
        builder: (extensionContext) {
          final builder = entry.value;
          return builder(context, extensionContext, extensionContext.innerHtml);
        },
      );
    }).toList();
  }

  void registerCustomTags() {
    register("slok-", (context, extensionContext, innerHtml) {
      Color fontColor = Theme.of(context).colorScheme.primary;
      TextStyle slokStyle = Theme.of(context).textTheme.titleSmall!;
      return Html(
        data: innerHtml,
        style: {
          "body": Style(
            color: fontColor,
            fontSize:
                slokStyle.fontSize != null
                    ? FontSize(slokStyle.fontSize!)
                    : FontSize(18),
            fontWeight: slokStyle.fontWeight,
            textAlign: TextAlign.center,
            display: Display.inline,
            lineHeight: LineHeight(1.0),
          ),
        },
        //extensions: [...CustomTagRegistry().buildExtensions(context)],
      );
    });

    register("slok", (context, extensionContext, innerHtml) {
      // grab and replace anchor tag from innerHtml if exists
      // <a> tags should be replaced with their text content
      // e.g. <a href="dict:word">word</a> becomes just "word"
      // This is to avoid nested clickable links inside slok blocks
      // Render this anchor link separately after slok rendering
      // using the "a" tag handler below.
      // Use RegExp to find and anchor tag
      final anchorMatches = innerHtml.getRegExpMatches(
        RegExp(r'<a[^>]*>(.*?)<\/a>'),
      );
      innerHtml = innerHtml.replaceAllMapped(
        RegExp(r'<a[^>]*>(.*?)<\/a>'),
        (match) => match.group(1) ?? '',
      );

      Color fontColor = Theme.of(context).colorScheme.primary;
      TextStyle slokStyle = Theme.of(context).textTheme.titleSmall!;
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        decoration: BoxDecoration(
          color: fontColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(0),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: ColoredBox(
                    color: fontColor,
                    child: SizedBox(
                      width: 4,
                      height: slokStyle.fontSize! * 2.0,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(innerHtml, style: slokStyle)),
              ],
            ),
            if (anchorMatches.isNotEmpty) ...[
              const SizedBox(height: 8),
              ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children:
                    anchorMatches.map((match) {
                      MeaningItem? meaning = Bookservice().getMeaning(match);
                      if (meaning != null && meaning.index != -1) {
                        return Text(
                          '📚 ${meaning.word}: ${meaning.meaning}',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            color: Utils.oppositeColor(
                              Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        );
                      } else {
                        return Text(
                          '$match: No meaning found',
                          style: Theme.of(context).textTheme.bodyMedium,
                        );
                      }
                    }).toList(),
              ),
            ],
          ],
        ),
      );
    });

    register("a", (context, extensionContext, innerHtml) {
      Color fontColor = Utils.oppositeColor(
        Theme.of(context).colorScheme.primary,
      );
      TextStyle anchorStyle = Theme.of(context).textTheme.titleSmall!;
      return GestureDetector(
        onTap: () {
          String? href = extensionContext.attributes['href'];
          if (href != null && href.isNotEmpty) {
            MeaningItem? meaning = Bookservice().getMeaning(href);
            if (meaning != null && meaning.index != -1) {
              debugPrint("Meaning found: ${meaning.meaning}");
              showMeaningDialog(context, meaning);
            } else {
              debugPrint("Meaning not found for: $href");
            }
          }
        },
        child: Html(
          data: innerHtml,
          style: {
            "body": Style(
              color: fontColor,
              fontWeight: anchorStyle.fontWeight,
              fontSize:
                  anchorStyle.fontSize != null
                      ? FontSize(anchorStyle.fontSize!)
                      : FontSize(18),
              display: Display.inline,
              textAlign: TextAlign.justify,
              lineHeight: LineHeight(1.0),
            ),
          },
        ),
      );
    });

    register("header", (context, extensionContext, innerHtml) {
      Color fontColor = Theme.of(context).colorScheme.primary;
      TextStyle headerStyle = Theme.of(context).textTheme.bodySmall!;
      return Align(
        alignment: Alignment.center,
        child: Html(
          data: innerHtml,
          style: {
            "body": Style(
              color: fontColor,
              fontWeight: headerStyle.fontWeight,
              fontSize:
                  headerStyle.fontSize != null
                      ? FontSize(headerStyle.fontSize!)
                      : FontSize(18),
              display: Display.inline,
              textAlign: TextAlign.center,
            ),
          },
        ),
      );
    });

    register("footer", (context, extensionContext, innerHtml) {
      Color fontColor = Theme.of(context).colorScheme.primary;
      TextStyle footerStyle = Theme.of(context).textTheme.titleSmall!;
      return Align(
        alignment: Alignment.centerRight,
        child: Html(
          data: innerHtml,
          style: {
            "body": Style(
              color: fontColor,
              fontWeight: footerStyle.fontWeight,
              fontSize:
                  footerStyle.fontSize != null
                      ? FontSize(footerStyle.fontSize!)
                      : FontSize(18),
              display: Display.inline,
            ),
          },
        ),
      );
    });

    register("img", (context, extensionContext, innerHtml) {
      Color primaryColor = Theme.of(context).colorScheme.primary;
      String? src = extensionContext.attributes['src'];
      if (src == null || src.isEmpty) {
        return const SizedBox.shrink();
      }
      if (src.startsWith('http://') || src.startsWith('https://')) {
        return Image.network(src);
      } else {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Image.asset(src, color: primaryColor),
        );
      }
    });
  }

  Future<dynamic> showMeaningDialog(BuildContext context, MeaningItem meaning) {
    return showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Text(
                        meaning.word,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(
                      meaning.meaning,
                      style: Theme.of(context).textTheme.bodyLarge,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

extension on String {
  List<String> getRegExpMatches(RegExp regExp) {
    final matches = regExp.allMatches(this);
    return matches.map((m) => m.group(1) ?? '').toList();
  }
}
