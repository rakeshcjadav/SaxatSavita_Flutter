import 'package:flutter/material.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';
import 'package:saxatsavita_flutter/models/appsettings.dart';
import 'package:saxatsavita_flutter/models/bookuserinfo_model.dart';
import 'package:saxatsavita_flutter/pages/kiranreadpage.dart';
import 'package:saxatsavita_flutter/services/bookservice.dart';
import 'package:saxatsavita_flutter/services/kiranlistservice.dart';
import 'package:saxatsavita_flutter/services/kiranuser_service.dart';

class Bookmarkwidget extends StatefulWidget {
  final int partNumber;
  final Bookmark bookmark;
  final Function(int partNumber, int kiranIndex)? onTap;

  const Bookmarkwidget({
    super.key,
    required this.partNumber,
    required this.bookmark,
    required this.onTap,
  });

  @override
  State<Bookmarkwidget> createState() => _BookmarkwidgetState();
}

class _BookmarkwidgetState extends State<Bookmarkwidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          label: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Text(
              getNameofBookMark(widget.partNumber, widget.bookmark.kiranIndex),
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          onPressed: () {
            widget.onTap!(widget.partNumber, widget.bookmark.kiranIndex);
          },
          icon: const Icon(Icons.bookmark, color: Colors.amber),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const SizedBox(width: 18),
            Icon(
              Icons.history,
              size: appSettingsNotifier.value.fontSize * 0.6,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(width: 4),
            Text(
              getUpdatedAt(widget.bookmark),
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                fontSize: appSettingsNotifier.value.fontSize * 0.6,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String getNameofBookMark(int partNumber, int kiranIndex) {
    var kiranInfo = KiranListService().getKiranInfo(partNumber, kiranIndex);
    return "${kiranInfo.number} ${kiranInfo.title}";
  }

  String getUpdatedAt(Bookmark bookmark) {
    return AppLocalizations.of(
      context,
    )!.last_read(bookmark.createdAt, bookmark.createdAt);
  }

  void _navigateToBookMark(
    BuildContext context,
    int partNumber,
    int kiranIndex,
  ) async {
    var bookUserInfo = Bookservice().getBookUserInfo(partNumber);
    var kiranInfo = KiranListService().getKiranInfo(partNumber, kiranIndex);
    var kiranUserInfo = KiranUserService().getKiranUserInfo(kiranIndex);
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => KiranReadPage(
              partNumber: bookUserInfo.id,
              kiranInfo: kiranInfo,
              kiranUserInfo: kiranUserInfo,
            ),
      ),
    );
    if (result == true) {
      setState(() {
        // Refresh the state to reflect any changes made in KiranReadPage
      });
    }
  }
}
