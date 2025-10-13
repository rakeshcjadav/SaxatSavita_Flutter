import 'package:flutter/material.dart';
import 'package:saxatsavita_flutter/components/appbar.dart';
import 'package:saxatsavita_flutter/components/bookmarkwidget.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';
import 'package:saxatsavita_flutter/models/bookuserinfo_model.dart';
import 'package:saxatsavita_flutter/pages/kiranreadpage.dart';
import 'package:saxatsavita_flutter/services/bookservice.dart';
import 'package:saxatsavita_flutter/services/kiranlistservice.dart';
import 'package:saxatsavita_flutter/services/kiranuser_service.dart';

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
