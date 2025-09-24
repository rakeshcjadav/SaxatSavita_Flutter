import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

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
    register("slok", (context, extensionContext, innerHtml) {
      Color fontColor = Theme.of(context).colorScheme.primary;
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: fontColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Html(
          data: innerHtml,
          style: {
            "body": Style(
              color: fontColor,
              fontSize: FontSize(18),
              fontWeight: FontWeight.bold,
              lineHeight: LineHeight(1.0),
              textAlign: TextAlign.center,
            ),
          },
        ),
      );
    });

    register("sq", (context, extensionContext, innerHtml) {
      Color fontColor = Theme.of(context).colorScheme.primary;
      return Html(
        data: innerHtml,
        style: {
          "body": Style(
            color: fontColor,
            fontWeight: FontWeight.bold,
            fontSize: FontSize(18),
            display: Display.inline,
          ),
        },
      );
    });

    register("dq", (context, extensionContext, innerHtml) {
      Color fontColor = Theme.of(context).colorScheme.primary;
      return Html(
        data: innerHtml,
        style: {
          "body": Style(
            color: fontColor,
            fontWeight: FontWeight.bold,
            fontSize: FontSize(18),
            display: Display.inline,
          ),
        },
      );
    });

    register("a", (context, extensionContext, innerHtml) {
      Color fontColor = Colors.deepOrange.shade900;
      return Html(
        data: innerHtml,
        style: {
          "body": Style(
            color: fontColor,
            fontWeight: FontWeight.bold,
            fontSize: FontSize(18),
            display: Display.inline,
            lineHeight: LineHeight(1.0),
          ),
        },
      );
    });

    register("footer", (context, extensionContext, innerHtml) {
      Color fontColor = Theme.of(context).colorScheme.primary;
      return Align(
        alignment: Alignment.centerRight,
        child: Html(
          data: innerHtml,
          style: {
            "body": Style(
              color: fontColor,
              fontWeight: FontWeight.bold,
              fontSize: FontSize(18),
              display: Display.inline,
              lineHeight: LineHeight(1.0),
            ),
          },
        ),
      );
    });
  }
}
