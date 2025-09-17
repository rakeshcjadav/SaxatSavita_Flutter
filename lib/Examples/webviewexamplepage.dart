import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart'; // for base64 encoding

void main() => runApp(MaterialApp(home: WebViewDynamicHeightPage()));

class WebViewDynamicHeightPage extends StatefulWidget {
  const WebViewDynamicHeightPage({super.key});
  @override
  State<WebViewDynamicHeightPage> createState() =>
      _WebViewDynamicHeightPageState();
}

class _WebViewDynamicHeightPageState extends State<WebViewDynamicHeightPage> {
  late WebViewController _controller;
  double _webViewHeight = 1; // Start with minimal height

  @override
  void initState() {
    super.initState();

    String aashirvachanContent = 'generate Hello <p>Html CSS</p> Content';
    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          //..setBackgroundColor(Colors.transparent)
          ..loadHtmlString(_loadLocalHtml(aashirvachanContent));

    _controller.setNavigationDelegate(
      NavigationDelegate(
        onPageFinished: (String url) async {
          await Future.delayed(Duration(milliseconds: 300));
          final height = await _controller.runJavaScriptReturningResult(
            "document.documentElement.scrollHeight.toString();",
          );
          setState(() {
            _webViewHeight =
                double.tryParse(height.toString().replaceAll('"', '')) ?? 1;
            debugPrint('WebView content height: $height, $_webViewHeight');
          });
        },
      ),
    );
  }

  String _loadLocalHtml(String content) {
    return """
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="UTF-8">
        <title>Sample</title>
        <style> body { margin:0; padding:0; font-family: sans-serif; } </style>
        <script>
          function getContentHeight() {
            return document.documentElement.scrollHeight;
          }
        </script>
      </head>
      <body>
        This is text before webview
      </body>
      </html>
    """;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Dynamic WebView Height')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: _webViewHeight,
              child: WebViewWidget(controller: _controller),
            ),
            Text('Below WebView Content'),
          ],
        ),
      ),
    );
  }
}
