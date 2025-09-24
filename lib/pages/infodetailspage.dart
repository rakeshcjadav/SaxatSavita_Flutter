import 'package:flutter/material.dart';
import 'package:saxatsavita_flutter/components/customHtmlWidget.dart';
import 'package:saxatsavita_flutter/components/customWebViewWidget.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';
import '../models/infocontent_model.dart';
import '../components/appbar.dart';

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
  const Infodetailspage({super.key, required this.infoItem});

  final InfoContentModel infoItem;

  @override
  Widget build(BuildContext context) {
    Color fontColor = Theme.of(context).colorScheme.primary;
    String strContent = infoItem.content.replaceAll('&nbsp; &nbsp;', '󠁪⠀ ');
    //String strContent = generateHtmlContent(infoItem.content, 18, fontColor);
    return Scaffold(
      appBar: buildAppBar(
        context,
        title: AppLocalizations.of(context)!.information,
      ),
      body: Padding(
        padding: const EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          top: 16.0,
          bottom: 16,
        ),
        child: Column(
          children: [
            Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: fontColor.withOpacity(1.0),
                borderRadius: BorderRadius.circular(8.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4.0,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  infoItem.title,
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: GestureDetector(
                  onTap: () {
                    //FocusScope.of(context).unfocus();
                    debugPrint("Unfocus TextField");
                  },
                  child: SafeArea(
                    child: CustomHtmlWidget(htmlContent: strContent),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
