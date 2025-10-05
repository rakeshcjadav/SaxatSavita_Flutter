import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:saxatsavita_flutter/components/customHtmlWidget.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';
import 'package:saxatsavita_flutter/models/kiraninfo_model.dart';
import 'package:saxatsavita_flutter/models/kiranuserinfo_model.dart';

class SliverKiranReadPage extends StatefulWidget {
  const SliverKiranReadPage({
    super.key,
    required this.partNumber,
    required this.kiranInfo,
    required this.kiranUserInfo,
  });
  final String partNumber;
  final KiranInfo kiranInfo;
  final KiranUserInfo kiranUserInfo;

  @override
  State<SliverKiranReadPage> createState() => _SliverKiranReadPageState();
}

class _SliverKiranReadPageState extends State<SliverKiranReadPage> {
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
      body: FutureBuilder<Map<String, dynamic>>(
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
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: false,
                floating: true,
                snap: false,
                backgroundColor: Theme.of(context).colorScheme.primary,
                expandedHeight: 150.0,
                titleTextStyle: Theme.of(context).textTheme.titleSmall!
                    .copyWith(color: Theme.of(context).colorScheme.onPrimary),
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          '${AppLocalizations.of(context)!.kiran} ${widget.kiranInfo.number.replaceAll(".", "")}\n${widget.kiranInfo.title}',
                          textAlign: TextAlign.center,
                          style: Theme.of(
                            context,
                          ).textTheme.titleSmall!.copyWith(
                            color: Theme.of(context).colorScheme.onPrimary,
                            overflow: TextOverflow.visible,
                          ),
                        ),
                      ),
                    ),
                  ),
                  expandedTitleScale: 1.0,
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () {
                      Navigator.pushNamed(context, '/settings');
                    },
                  ),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    SafeArea(
                      top: false,
                      bottom: true,
                      child: CustomHtmlWidget(
                        htmlContent: getKiranContent(contentData),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
