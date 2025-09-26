import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:saxatsavita_flutter/models/appsettings.dart';
import 'package:saxatsavita_flutter/services/customtagregistry.dart';

class CustomHtmlWidget extends StatefulWidget {
  CustomHtmlWidget({super.key, required this.htmlContent}) {
    // Initialize the custom tag registry if needed
    // This can be used to register custom HTML tags for rendering
    // For example, you can register a custom tag for <slok> or <dq>
    // to style them differently in the HTML content.
    // Here, we are just creating an instance of CustomTagRegistry.
    // You can expand this as per your requirements.
    customTagRegistry.registerCustomTags();
  }

  final String htmlContent;

  final CustomTagRegistry customTagRegistry = CustomTagRegistry();

  @override
  State<CustomHtmlWidget> createState() => _CustomHtmlWidgetState();
}

class _CustomHtmlWidgetState extends State<CustomHtmlWidget> {
  @override
  Widget build(BuildContext context) {
    Color fontColor = Theme.of(context).colorScheme.primary;
    String htmlContent = widget.htmlContent.replaceAll('&nbsp; &nbsp;', '⠀ ');
    return ValueListenableBuilder<AppSettings>(
      valueListenable: appSettingsNotifier,
      builder: (context, settings, child) {
        return Html(
          data: htmlContent,
          extensions: [...widget.customTagRegistry.buildExtensions(context)],
          style: {
            "body": Style(
              color: fontColor,
              fontSize: FontSize(
                Theme.of(context).textTheme.bodyLarge!.fontSize!,
              ),
              textAlign: TextAlign.justify,
              padding: HtmlPaddings.all(10),
              lineHeight: LineHeight(appSettingsNotifier.value.lineHeight),
            ),
          },
        );
      },
    );
  }
}
