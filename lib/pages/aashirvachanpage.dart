import 'package:flutter/material.dart';
import '../models/aashirvachan_model.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:saxatsavita_flutter/services/appdataservice.dart';
import '../components/customWebViewWidget.dart';
import 'package:flutter_html/flutter_html.dart';
import '../services/customtagregistry.dart';

String generateHtmlContent(String bodyContent) {
  return """
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="UTF-8">
        <style>
          body { margin:0; padding:0; font-size: 18px; text-align: justify; font-family: 'Noto Sans Gujarati', 'Shruti', 'Gujarati MT', sans-serif;}
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

class AashirvachanDetailPage extends StatefulWidget {
  AashirvachanDetailPage({super.key, required this.aashirvachan}) {
    customTagRegistry.registerCustomTags();
  }

  final AashirvachanModel aashirvachan;
  final CustomTagRegistry customTagRegistry = CustomTagRegistry();

  @override
  State<AashirvachanDetailPage> createState() => _AashirvachanDetailPageState();
}

class _AashirvachanDetailPageState extends State<AashirvachanDetailPage> {
  late WebViewController _controllerWebView;
  double _webViewHeight = 1;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _isLoading = true;
    if (widget.aashirvachan.content.text != null) {
      var aashirvachanContent = AppDataService().getValue(
        widget.aashirvachan.content.text!,
      ); // Ensure the singleton is initialized
      _controllerWebView =
          WebViewController()
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..setBackgroundColor(Colors.transparent)
            ..loadHtmlString(generateHtmlContent(aashirvachanContent!));

      _controllerWebView.setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) async {
            await Future.delayed(Duration(milliseconds: 300));
            final height = await _controllerWebView
                .runJavaScriptReturningResult(
                  "document.documentElement.scrollHeight.toString();",
                );
            setState(() {
              _isLoading = false;
              _webViewHeight =
                  double.tryParse(height.toString().replaceAll('"', '')) ?? 1;
              debugPrint('WebView content height: $height, $_webViewHeight');
            });
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = Theme.of(context).colorScheme.inversePrimary;
    return Scaffold(
      backgroundColor: Colors.orange.shade100,
      appBar: AppBar(
        backgroundColor: bgColor,
        surfaceTintColor: Colors.transparent,
        elevation: 20,
        title: Text(widget.aashirvachan.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Hero(
              tag: '${widget.aashirvachan.tag}-image',
              child: Material(
                elevation: 5,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    widget.aashirvachan.image,
                    height: 195,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                widget.aashirvachan.title,
                style: TextStyle(
                  fontSize: 24,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (widget.aashirvachan.content.image != null) ...[
              const SizedBox(height: 16),
              Expanded(
                child: Image.asset(
                  widget.aashirvachan.content.image!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            if (widget.aashirvachan.content.text != null) ...[
              const SizedBox(height: 16),
              Html(
                data:
                    AppDataService().getValue(
                      widget.aashirvachan.content.text!,
                    )!,
                style: {
                  "body": Style(
                    fontSize: FontSize(18),
                    textAlign: TextAlign.justify,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                },
                extensions: [
                  ...widget.customTagRegistry.buildExtensions(context),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
