import 'package:flutter/material.dart';
import 'package:saxatsavita_flutter/components/appbar.dart';
import 'package:saxatsavita_flutter/components/bookmarkwidget.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';
import 'package:saxatsavita_flutter/models/bookuserinfo_model.dart';
import 'package:saxatsavita_flutter/models/reading_event_model.dart';
import 'package:saxatsavita_flutter/pages/kiranreadpage.dart';
import 'package:saxatsavita_flutter/services/bookservice.dart';
import 'package:saxatsavita_flutter/services/kiranlistservice.dart';
import 'package:saxatsavita_flutter/services/kiranuser_service.dart';
import 'package:saxatsavita_flutter/services/reading_event_service.dart';
import 'package:saxatsavita_flutter/services/utils.dart';

class BookmarksPage extends StatefulWidget {
  const BookmarksPage({super.key, required this.partNumber});

  final int partNumber;

  @override
  State<BookmarksPage> createState() => _BookmarksPageState();
}

class _BookmarksPageState extends State<BookmarksPage> {
  late BookUserInfo bookUserInfo;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    bookUserInfo = Bookservice().getBookUserInfo(widget.partNumber);
  }

  void _navigateToBookMark(int partNumber, int kiranIndex) async {
    var bookUserInfo = Bookservice().getBookUserInfo(partNumber);
    var kiranInfo = KiranListService().getKiranInfo(partNumber, kiranIndex);
    var kiranUserInfo = KiranUserService().getKiranUserInfo(kiranIndex);

    // Check if there's an existing reading event for this kiran
    final existingEvent = await ReadingEventService.getReadingEventForKiran(
      kiranInfo.index,
    );

    ReadingMode? selectedMode;
    ReadingEvent? eventToResume;

    if (existingEvent != null) {
      // Show resume dialog
      final resumeChoice = await _showResumeDialog(existingEvent);
      if (resumeChoice == null) return; // User cancelled

      if (resumeChoice == 'resume') {
        selectedMode = ReadingMode.reading;
        eventToResume = existingEvent;
      } else if (resumeChoice == 'new') {
        // Delete old event and start new reading session
        await ReadingEventService.deleteReadingEvent(existingEvent.id);
        selectedMode = ReadingMode.reading;
      } else {
        // browse
        selectedMode = ReadingMode.browse;
      }
    } else {
      // No existing event, show mode selection dialog
      selectedMode = await _showReadingModeDialog();
      if (selectedMode == null) return; // User cancelled
    }

    Utils.updateLastOpenedKiran(bookUserInfo, kiranInfo.index);
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => KiranReadPage(
              partNumber: bookUserInfo.id,
              kiranInfo: kiranInfo,
              kiranUserInfo: kiranUserInfo,
              readingMode: selectedMode!,
              existingEvent: eventToResume,
            ),
      ),
    );
    if (result == true) {
      setState(() {
        // Refresh the state to reflect any changes made in KiranReadPage
      });
    }
  }

  /// Show dialog to select reading mode
  Future<ReadingMode?> _showReadingModeDialog() async {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<ReadingMode>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(l10n.reading_mode_dialog_title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.book, color: Colors.blue, size: 32),
                  title: Text(
                    l10n.reading_mode,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(l10n.reading_mode_subtitle),
                  onTap: () => Navigator.pop(context, ReadingMode.reading),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(
                    Icons.search,
                    color: Colors.grey,
                    size: 32,
                  ),
                  title: Text(
                    l10n.browse_mode,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(l10n.browse_mode_subtitle),
                  onTap: () => Navigator.pop(context, ReadingMode.browse),
                ),
              ],
            ),
          ),
    );
  }

  /// Show dialog to resume existing reading session
  Future<String?> _showResumeDialog(ReadingEvent event) async {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(l10n.continue_reading),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.ongoing_session,
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.pending, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      l10n.percent_complete(event.currentProgress),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.timer, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      l10n.time_read(event.formattedDuration),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      event.timeAgo,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, 'browse'),
                child: Text(l10n.just_browse),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, 'new'),
                child: Text(l10n.start_new),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, 'resume'),
                icon: const Icon(Icons.play_arrow),
                label: Text(l10n.resume),
              ),
            ],
          ),
    );
  }

  void _removeBookmark(Bookmark bookmark) {
    setState(() {
      bookUserInfo.removeBookmark(bookmark.kiranIndex);
    });

    // Update the service
    Bookservice().bookUserInfoList = [
      ...?Bookservice().bookUserInfoList?.where(
        (info) => info.partNumber != bookUserInfo.partNumber,
      ),
      bookUserInfo,
    ];

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Bookmark removed'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              bookUserInfo.addBookmark(bookmark.kiranIndex);
            });

            // Update the service again
            Bookservice().bookUserInfoList = [
              ...?Bookservice().bookUserInfoList?.where(
                (info) => info.partNumber != bookUserInfo.partNumber,
              ),
              bookUserInfo,
            ];
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allBookmarks = bookUserInfo.bookmarks;
    final partTitle = Bookservice().getPartTitle(context, widget.partNumber);
    return Scaffold(
      appBar: buildAppBar(
        context,
        title:
            '$partTitle : ${AppLocalizations.of(context)!.bookmark} (${allBookmarks.length})',
      ),
      body:
          allBookmarks.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bookmark_border, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'No bookmarks found',
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add bookmarks while reading to see them here',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                itemCount: allBookmarks.length,
                itemBuilder: (context, index) {
                  final bookmark = allBookmarks[index];

                  return Card(
                    child: ListTile(
                      title: Bookmarkwidget(
                        partNumber: widget.partNumber,
                        bookmark: bookmark,
                        onTap: (partNumber, kiranIndex) {
                          _navigateToBookMark(partNumber, kiranIndex);
                        },
                      ),
                      trailing: PopupMenuButton(
                        itemBuilder:
                            (context) => [
                              PopupMenuItem(
                                value: 'read',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.read_more,
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onPrimaryContainer,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Read',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium!.copyWith(
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'remove',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete,
                                      color: Colors.red.shade300,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Remove',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium!
                                          .copyWith(color: Colors.red.shade300),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                        onSelected: (value) {
                          if (value == 'read') {
                            _navigateToBookMark(
                              widget.partNumber,
                              bookmark.kiranIndex,
                            );
                          } else if (value == 'remove') {
                            _removeBookmark(bookmark);
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
