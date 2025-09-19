import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

String colorToCss(Color color) =>
    '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';

String generateHtmlContent(String bodyContent, int fontSize, Color textColor) {
  return """
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="UTF-8">
        <style>
          body { margin:0; padding:0; 
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

class Customwebviewwidget extends StatefulWidget {
  const Customwebviewwidget({super.key, required this.content});

  final String content;

  @override
  State<Customwebviewwidget> createState() => _CustomwebviewwidgetState();
}

class _CustomwebviewwidgetState extends State<Customwebviewwidget> {
  late WebViewController _controllerWebView;
  double _webViewHeight = 1;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _isLoading = true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Color textColor = Theme.of(context).primaryColor;
    _controllerWebView =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(Colors.transparent)
          ..loadHtmlString(generateHtmlContent(widget.content, 18, textColor));

    _controllerWebView.setNavigationDelegate(
      NavigationDelegate(
        onPageFinished: (String url) async {
          final height = await _controllerWebView.runJavaScriptReturningResult(
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

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _isLoading ? 0 : 1,
      duration: Duration(milliseconds: 700),
      curve: Curves.easeInOut,
      child: SizedBox(
        height: _webViewHeight,
        child: WebViewWidget(controller: _controllerWebView),
      ),
    );
  }
}
