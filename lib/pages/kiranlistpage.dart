import 'package:flutter/material.dart';
import 'package:saxatsavita_flutter/components/appbar.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';
import 'package:saxatsavita_flutter/models/appsettings.dart';
import 'package:saxatsavita_flutter/models/kiraninfo_model.dart';
import 'package:saxatsavita_flutter/models/kiranlist_model.dart';
import 'package:saxatsavita_flutter/models/kiranuserinfo_model.dart';
import 'package:saxatsavita_flutter/pages/kiranreadpage.dart';
import 'package:saxatsavita_flutter/pages/note_editor_page.dart';
import 'package:saxatsavita_flutter/services/kiranlistservice.dart';
import 'package:saxatsavita_flutter/services/utils.dart';
import '../models/bookpart_model.dart';
import '../services/kiranuser_service.dart';

class Kiranlistpage extends StatefulWidget {
  final Bookpartmodel bookPart;
  const Kiranlistpage({super.key, required this.bookPart});

  @override
  State<Kiranlistpage> createState() => _KiranlistpageState();
}

class _KiranlistpageState extends State<Kiranlistpage> {
  late Future<KiranList> _futureKiranList;

  bool _hasDataChanged = false;

  @override
  void initState() {
    super.initState();
    KiranUserService().buildKiranUserInfoList();
    _futureKiranList =
        KiranListService().getKiranList(widget.bookPart.id) != null
            ? Future.value(KiranListService().getKiranList(widget.bookPart.id))
            : KiranListService()
                .loadPart("saxatsavita", widget.bookPart.id)
                .then((_) {
                  return KiranListService().getKiranList(widget.bookPart.id)!;
                });
  }

  int? _expandedIndex;

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _navigateToKiranReadPage(
    KiranInfo kiran,
    KiranUserInfo kiranUserInfo,
  ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => KiranReadPage(
              partNumber: widget.bookPart.id,
              kiranInfo: kiran,
              kiranUserInfo: kiranUserInfo,
            ),
      ),
    );
    if (result == true) {
      setState(() {
        _hasDataChanged = true;
        // Refresh the state to reflect any changes made in KiranReadPage
      });
    }
    /*
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => SliverKiranReadPage(
              partNumber: widget.bookPart.id,
              kiranInfo: kiran,
              kiranUserInfo: kiranUserInfo,
            ),
      ),
    );
    */
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(
        context,
        title: widget.bookPart.displayname,
        actionItems: [
          ActionOptions.info,
          ActionOptions.notes,
          ActionOptions.search,
          ActionOptions.settings,
        ],
      ),
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, Object? result) {
          if (!didPop) {
            Navigator.of(context).pop(_hasDataChanged);
          }
        },
        child: Padding(
          padding: const EdgeInsets.only(left: 4.0, right: 4.0),
          child: Scrollbar(
            child: FutureBuilder<KiranList>(
              future: _futureKiranList,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.list.isEmpty) {
                  return const Center(child: Text('No kirans found.'));
                }
                final kirans = snapshot.data!.list;
                return ListView.builder(
                  itemCount: kirans.length,
                  itemBuilder: (context, index) {
                    final kiran = kirans[index];
                    final kiranUserInfo = KiranUserService().getKiranUserInfo(
                      kiran.index,
                    );
                    return Card(
                      key: Key(kiran.index.toString()),
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () {
                              _navigateToKiranReadPage(kiran, kiranUserInfo);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _buildKiranListItemWidget(
                                      kiran,
                                      kiranUserInfo,
                                      _expandedIndex == index,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      _expandedIndex == index
                                          ? Icons.expand_less
                                          : Icons.expand_more,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _expandedIndex =
                                            _expandedIndex == index
                                                ? null
                                                : index;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_expandedIndex == index)
                            ..._buildKiranListItemExpandedWidget(
                              kiran,
                              kiranUserInfo,
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildKiranListItemExpandedWidget(
    KiranInfo kiran,
    KiranUserInfo kiranUserInfo,
  ) {
    return [
      ListTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(5.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        kiranUserInfo.toggleFavourite();
                      });
                    },
                    iconSize: appSettingsNotifier.value.fontSize,
                    icon: Icon(
                      kiranUserInfo.isFavourite == 1
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color:
                          kiranUserInfo.isFavourite == 1
                              ? Colors.pink
                              : Theme.of(context).iconTheme.color,
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context)!.favorite,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(5.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => NoteEditorPage(
                                kiranUserInfo: kiranUserInfo,
                                kiranTitle:
                                    '${AppLocalizations.of(context)!.kiran} ${kiran.number.replaceAll(".", "")}',
                              ),
                        ),
                      );
                    },
                    iconSize: appSettingsNotifier.value.fontSize,
                    icon: Icon(Icons.note),
                  ),
                  Text(
                    AppLocalizations.of(context)!.notes,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
          onPressed: () {
            _navigateToKiranReadPage(kiran, kiranUserInfo);
          },
          child: Text(AppLocalizations.of(context)!.read),
        ),
      ),
    ];
  }

  Widget _buildKiranListItemWidget(
    KiranInfo kiran,
    KiranUserInfo kiranUserInfo,
    bool isExpanded,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Kiran Number and Name
        Row(
          children: [
            Text(kiran.number, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(width: 12),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  kiran.title,
                  style: Theme.of(context).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // 2. All data from KiranUserInfo
        Row(
          children: [
            if (Utils.isBookmarked(kiranUserInfo)) ...[
              Icon(
                Utils.isBookmarked(kiranUserInfo)
                    ? Icons.bookmark
                    : Icons.bookmark_border,
                color:
                    Utils.isBookmarked(kiranUserInfo)
                        ? Colors.amber
                        : Colors.grey.withValues(alpha: 0.0),
              ),
              const Spacer(),
            ],
            if (kiranUserInfo.isFavourite == 1) ...[
              Icon(
                kiranUserInfo.isFavourite == 1
                    ? Icons.favorite
                    : Icons.favorite_border,
                color:
                    kiranUserInfo.isFavourite == 1
                        ? Colors.pink.withValues(alpha: 0.3)
                        : Colors.grey.withValues(alpha: 0.0),
              ),
            ],
            const Spacer(),
            Icon(Icons.timer, color: Colors.grey.withValues(alpha: 0.3)),
            const SizedBox(width: 4),
            Text(
              AppLocalizations.of(
                context,
              )!.time_to_read(Utils.getEstimatedReadingTime(kiran.wordCount)),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Progress bar (if relevant)
        LinearProgressIndicator(
          value: kiranUserInfo.progress.toDouble() / 100.0,
          //value: 100 / kiran.wordCount,
          minHeight: 3,
          borderRadius: BorderRadius.circular(3),
          backgroundColor: Theme.of(
            context,
          ).primaryColor.withValues(alpha: 0.1),
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        // Any other KiranUserInfo fields
        Row(
          children: [
            if (kiranUserInfo.updatedAt != null) ...[
              Icon(
                Icons.history,
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.3),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  getLastUpdatedDate(kiranUserInfo),
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            Text(
              getReadCount(kiranUserInfo),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }

  String getLastUpdatedDate(KiranUserInfo kiranUserInfo) {
    if (kiranUserInfo.updatedAt == null) {
      return "";
    }
    return AppLocalizations.of(
      context,
    )!.last_read(kiranUserInfo.updatedAt!, kiranUserInfo.updatedAt!);
  }

  String getReadCount(KiranUserInfo kiranUserInfo) {
    if (kiranUserInfo.readCount == 0) {
      return AppLocalizations.of(context)!.not_yet_read;
    }
    return AppLocalizations.of(context)!.reading_count(kiranUserInfo.readCount);
  }
}
