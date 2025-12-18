import 'package:flutter/material.dart';
import 'package:saxatsavita_flutter/components/appbar.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';
import 'package:saxatsavita_flutter/models/appsettings.dart';
import 'package:saxatsavita_flutter/models/bookuserinfo_model.dart';
import 'package:saxatsavita_flutter/models/kiraninfo_model.dart';
import 'package:saxatsavita_flutter/models/kiranlist_model.dart';
import 'package:saxatsavita_flutter/models/kiranuserinfo_model.dart';
import 'package:saxatsavita_flutter/models/reading_event_model.dart';
import 'package:saxatsavita_flutter/pages/kiranreadpage.dart';
import 'package:saxatsavita_flutter/pages/note_editor_page.dart';
import 'package:saxatsavita_flutter/services/bookservice.dart';
import 'package:saxatsavita_flutter/services/kiranlistservice.dart';
import 'package:saxatsavita_flutter/services/reading_event_service.dart';
import 'package:saxatsavita_flutter/services/utils.dart';
import '../models/bookpart_model.dart';
import '../services/kiranuser_service.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class Kiranlistpage extends StatefulWidget {
  const Kiranlistpage({super.key, required this.bookPart});

  final Bookpartmodel bookPart;

  @override
  State<Kiranlistpage> createState() => _KiranlistpageState();
}

class _KiranlistpageState extends State<Kiranlistpage> {
  late Future<KiranList> _futureKiranList;
  final ScrollController _scrollController = ScrollController();
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  late BookUserInfo bookUserInfo;
  int? _expandedIndex;
  bool _showFavoritesOnly = false;
  int _rebuildCounter = 0; // Counter to force FutureBuilder refresh

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

    bookUserInfo = Bookservice().getBookUserInfo(widget.bookPart.partNumber);

    // ✅ Schedule scroll AFTER the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToLastOpenedKiran();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _navigateToKiranReadPage(
    KiranInfo kiran,
    KiranUserInfo kiranUserInfo, {
    bool fromSearch = false,
  }) async {
    // Check if there's an existing reading event for this kiran
    final existingEvent = await ReadingEventService.getReadingEventForKiran(
      kiran.index,
    );

    ReadingMode? selectedMode;
    ReadingEvent? eventToResume;

    if (fromSearch) {
      // Coming from search, always use browse mode
      selectedMode = ReadingMode.browse;
    } else if (existingEvent != null) {
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

    Utils.updateLastOpenedKiran(bookUserInfo, kiran.index);
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => KiranReadPage(
              partNumber: widget.bookPart.id,
              kiranInfo: kiran,
              kiranUserInfo: kiranUserInfo,
              readingMode: selectedMode!,
              existingEvent: eventToResume,
            ),
      ),
    );
    if (result == true) {
      setState(() {
        debugPrint(
          '🔄 Returning from KiranReadPage, refreshing KiranListPage state',
        );
        // Refresh the state to reflect any changes made in KiranReadPage
        _rebuildCounter++; // Force FutureBuilder refresh to update event badges
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

  void _scrollToLastOpenedKiran() {
    // Check if lastOpenedKiranIndex exists and is valid
    if (bookUserInfo.lastOpenedKiranIndex == null) {
      return;
    }

    final targetIndex =
        bookUserInfo.lastOpenedKiranIndex! - widget.bookPart.startKiranIndex;

    // Ensure the index is valid
    if (targetIndex < 0) {
      return;
    }

    // Wait a bit more to ensure ListView is built and ScrollController is attached
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _scrollToIndex(targetIndex);
      }
    });
  }

  void _scrollToIndex(int index) {
    // Check if ScrollController is attached and widget is still mounted
    if (!mounted) {
      return;
    }

    _itemScrollController.scrollTo(
      index: index,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
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
        ],
        extraActions: [
          IconButton(
            icon: Stack(
              children: [
                Icon(
                  _showFavoritesOnly ? Icons.favorite : Icons.favorite_border,
                  color: _showFavoritesOnly ? Colors.pink : null,
                ),
                if (_showFavoritesOnly) ...[
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Icon(Icons.filter_alt, size: 15),
                  ),
                ],
              ],
            ),
            tooltip:
                _showFavoritesOnly
                    ? AppLocalizations.of(context)!.showAllKirans
                    : AppLocalizations.of(context)!.showFavoritesOnly,
            onPressed: () {
              setState(() {
                _showFavoritesOnly = !_showFavoritesOnly;
                _expandedIndex = null; // Reset expanded state when filtering
              });
            },
          ),
        ],
      ),
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, Object? result) {
          if (!didPop) {
            Navigator.of(context).pop(true);
          }
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: 4.0, right: 4.0),
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

                // Filter kirans based on favorites toggle
                final allKirans = snapshot.data!.list;
                final kirans =
                    _showFavoritesOnly
                        ? allKirans.where((kiran) {
                          final kiranUserInfo = KiranUserService()
                              .getKiranUserInfo(kiran.index);
                          return kiranUserInfo.isFavourite == 1;
                        }).toList()
                        : allKirans;

                // Show message when no favorites found
                if (_showFavoritesOnly && kirans.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.favorite_border,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context)!.noFavoriteKirans,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context)!.noFavoriteKiransMessage,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[500]),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _showFavoritesOnly = false;
                            });
                          },
                          icon: const Icon(Icons.list),
                          label: Text(
                            AppLocalizations.of(context)!.showAllKirans,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ScrollablePositionedList.builder(
                  itemScrollController: _itemScrollController,
                  itemPositionsListener: _itemPositionsListener,
                  itemCount: kirans.length,
                  itemBuilder: (context, index) {
                    final kiran = kirans[index];
                    final kiranUserInfo = KiranUserService().getKiranUserInfo(
                      kiran.index,
                    );
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        side:
                            bookUserInfo.lastOpenedKiranIndex == kiran.index
                                ? BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 1.0,
                                )
                                : BorderSide.none,
                      ),
                      key: Key(kiran.index.toString()),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            InkWell(
                              onTap: () {
                                _navigateToKiranReadPage(kiran, kiranUserInfo);
                                setState(() {
                                  bookUserInfo.updateLastOpenedKiran(
                                    kiran.index,
                                  );
                                  _expandedIndex = index;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _buildKiranListItemWidget(
                                        kiran,
                                        kiranUserInfo,
                                        _expandedIndex == index,
                                      ),
                                    ),
                                    if (bookUserInfo.lastOpenedKiranIndex !=
                                        kiran.index) ...[
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
                                  ],
                                ),
                              ),
                            ),
                            if (_expandedIndex == index ||
                                bookUserInfo.lastOpenedKiranIndex ==
                                    kiran.index)
                              ..._buildKiranListItemExpandedWidget(
                                kiran,
                                kiranUserInfo,
                              ),
                          ],
                        ),
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
            _buildFavoriteButton(kiran, kiranUserInfo),
            _buildNoteButton(kiran, kiranUserInfo),
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
            const SizedBox(width: 2),
            Expanded(
              child: ColoredBox(
                color: Colors.transparent,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Text(
                    kiran.title,
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            // Reading event badge
            FutureBuilder<ReadingEvent?>(
              key: ValueKey('event_${kiran.index}_$_rebuildCounter'),
              future: ReadingEventService.getReadingEventForKiran(kiran.index),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  return Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.pending,
                          size: 14,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${kiranUserInfo.progress}%',
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
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
            Icon(
              Icons.timer,
              size: Theme.of(context).textTheme.bodySmall!.fontSize,
              color: Colors.grey.withValues(alpha: 0.3),
            ),
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
        Row(
          children: [
            Icon(
              kiranUserInfo.readCount == 0
                  ? Icons.visibility_off
                  : Icons.remove_red_eye,
              size: Theme.of(context).textTheme.bodySmall!.fontSize,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(width: 4),
            Text(
              getReadCount(kiranUserInfo),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        if (kiranUserInfo.updatedAt != null) ...[
          const SizedBox(height: 8),
          // Any other KiranUserInfo fields
          Row(
            children: [
              Icon(
                Icons.history,
                size: Theme.of(context).textTheme.bodySmall!.fontSize,
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
          ),
        ],
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

  Container _buildFavoriteButton(KiranInfo kiran, KiranUserInfo kiranUserInfo) {
    return Container(
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
    );
  }

  Container _buildNoteButton(KiranInfo kiran, KiranUserInfo kiranUserInfo) {
    return Container(
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
    );
  }
}
