import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:saxatsavita_flutter/components/appbar.dart';
import 'package:saxatsavita_flutter/components/customHtmlWidget.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';
import 'package:saxatsavita_flutter/models/kiraninfo_model.dart';
import 'package:saxatsavita_flutter/models/kiranuserinfo_model.dart';

class KiranReadPage extends StatefulWidget {
  const KiranReadPage({
    super.key,
    required this.partNumber,
    required this.kiranInfo,
    required this.kiranUserInfo,
  });
  final String partNumber;
  final KiranInfo kiranInfo;
  final KiranUserInfo kiranUserInfo;

  @override
  State<KiranReadPage> createState() => _KiranReadPageState();
}

class _KiranReadPageState extends State<KiranReadPage> {
  late Future<Map<String, dynamic>> _futureKiranContent;

  @override
  void initState() {
    super.initState();
    _futureKiranContent = _loadKiranContent();
  }

  Future<Map<String, dynamic>> _loadKiranContent() async {
    final path =
        'assets/book/saxatsavita/${widget.partNumber}/kiran_${widget.kiranInfo.index}.json';
    final jsonString = await rootBundle.loadString(path);
    return json.decode(jsonString);
  }

  String getKiranContent(Map<String, dynamic> contentData) {
    return '<header>${AppLocalizations.of(context)!.kiran_start}</header>'
        '${contentData['main']['content'] ?? ''}'
        '<p><footer>${contentData['main']['footer'] ?? ''}</footer></p>';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(
        context,
        title:
            '${AppLocalizations.of(context)!.kiran} ${widget.kiranInfo.number.replaceAll(".", "")}',
        actionItems: [ActionOptions.settings],
      ),
      body: Padding(
        padding: const EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          top: 0,
          bottom: 16.0,
        ),
        child: Column(
          children: [
            Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainer.withOpacity(1.0),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(20.0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4.0,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  '${widget.kiranInfo.number} ${widget.kiranInfo.title}',
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: FutureBuilder<Map<String, dynamic>>(
                  future: _futureKiranContent,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData) {
                      return const Center(child: Text('No content found.'));
                    }
                    final contentData = snapshot.data!;
                    return Column(
                      children: [
                        CustomHtmlWidget(
                          htmlContent: getKiranContent(contentData),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
