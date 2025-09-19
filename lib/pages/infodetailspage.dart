import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:saxatsavita_flutter/components/customWebViewWidget.dart';
import 'package:saxatsavita_flutter/services/customtagregistry.dart';
import '../models/infocontent_model.dart';
import '../components/appbar.dart';
import '../components/customWebViewWidget.dart';

String generateHtmlContent(String bodyContent, int fontSize, Color textColor) {
  return """
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="UTF-8">
        <style>
          body { margin:8; padding:0; 
          font-size: ${fontSize}px; 
          text-align: justify; 
          color: ${colorToCss(textColor)};
          font-family: 'Noto Sans Gujarati', 'Shruti', 'Gujarati MT', sans-serif;}
        </style>
        <script>
          function getContentHeight() {
            return document.documentElement.scrollHeight;
          }
        </script>
      </head>
      <body>
        $bodyContent
      </body>
    </html>
  """;
}

class Infodetailspage extends StatelessWidget {
  Infodetailspage({super.key, required this.infoItem}) {
    // Initialize the custom tag registry if needed
    // This can be used to register custom HTML tags for rendering
    // For example, you can register a custom tag for <slok> or <dq>
    // to style them differently in the HTML content.
    // Here, we are just creating an instance of CustomTagRegistry.
    // You can expand this as per your requirements.
    customTagRegistry.registerCustomTags();
  }

  final InfoContentModel infoItem;

  final CustomTagRegistry customTagRegistry = CustomTagRegistry();

  @override
  Widget build(BuildContext context) {
    Color fontColor = Theme.of(context).colorScheme.primary;
    String strContent = infoItem.content.replaceAll('&nbsp; &nbsp;', '󠁪⠀ ');
    //String strContent = generateHtmlContent(infoItem.content, 18, fontColor);
    return Scaffold(
      appBar: buildAppBar(context, title: infoItem.title),
      body: Padding(
        padding: const EdgeInsets.only(left: 16.0, right: 16.0),
        //child: Customwebviewwidget(content: infoItem.content),
        child: SingleChildScrollView(
          child: GestureDetector(
            onTap: () {
              //FocusScope.of(context).unfocus();
              debugPrint("Unfocus TextField");
            },
            child: Html(
              onAnchorTap:
                  (url, attributes, element) => {
                    debugPrint("Opening $url..."),
                    //launchUrlString(url!)
                  },
              data: strContent,
              extensions: [...customTagRegistry.buildExtensions(context)],
              style: {
                "body": Style(
                  color: fontColor,
                  fontSize: FontSize(18),
                  textAlign: TextAlign.justify,
                ),
              },
            ),
          ),
        ),
      ),
    );
  }
}
