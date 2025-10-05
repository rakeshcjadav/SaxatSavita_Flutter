import 'package:flutter/material.dart';
import 'package:saxatsavita_flutter/components/appbar.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';
import 'package:saxatsavita_flutter/models/appsettings.dart';
import 'package:saxatsavita_flutter/models/kiraninfo_model.dart';
import 'package:saxatsavita_flutter/models/kiranlist_model.dart';
import 'package:saxatsavita_flutter/models/kiranuserinfo_model.dart';
import 'package:saxatsavita_flutter/pages/kiranreadpage.dart';
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
        actionItems: [ActionOptions.info, ActionOptions.settings],
      ),
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, Object? result) {
          if (!didPop) {
            Navigator.of(context).pop(_hasDataChanged);
          }
        },
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
                  child: ExpansionTile(
                    showTrailingIcon: true,
                    key: Key(kiran.index.toString()),
                    initiallyExpanded: _expandedIndex == index,
                    onExpansionChanged: (expanded) {
                      setState(() {
                        _expandedIndex = expanded ? index : null;
                      });
                    },
                    title: _buildKiranListItemWidget(
                      kiran,
                      kiranUserInfo,
                      _expandedIndex == index,
                    ),
                    children: _buildKiranListItemExpandedWidget(
                      kiran,
                      kiranUserInfo,
                    ),
                  ),
                );
              },
            );
          },
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
          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  kiranUserInfo.toggleFavourite();
                });
              },
              iconSize: appSettingsNotifier.value.fontSize * 2.0,
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
            const SizedBox(width: 8),
          ],
        ),
        trailing: ElevatedButton(
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
              child: Text(
                kiran.title,
                style: Theme.of(context).textTheme.titleMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // 2. All data from KiranUserInfo
        Row(
          children: [
            Icon(
              kiranUserInfo.isFavourite == 1
                  ? Icons.favorite
                  : Icons.favorite_border,
              color:
                  kiranUserInfo.isFavourite == 1
                      ? Colors.pink.withValues(alpha: 0.3)
                      : Colors.grey.withValues(alpha: 0.0),
            ),
            const Spacer(),
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
            Icon(Icons.timer, color: Colors.grey.withOpacity(0.3)),
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
          value: kiranUserInfo.progress.toDouble(),
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
