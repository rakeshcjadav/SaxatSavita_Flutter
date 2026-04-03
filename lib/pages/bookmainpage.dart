import 'package:flutter/material.dart';
import 'package:saxatsavita_flutter/components/bookmarkwidget.dart';
import 'package:saxatsavita_flutter/components/remote_config_widgets.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';
import 'package:saxatsavita_flutter/components/appbar.dart';
import 'package:saxatsavita_flutter/models/appsettings.dart';
import 'package:saxatsavita_flutter/models/bookpart_model.dart';
import 'package:saxatsavita_flutter/models/bookuserinfo_model.dart';
import 'package:saxatsavita_flutter/models/reading_event_model.dart';
import 'package:saxatsavita_flutter/pages/bookmarks_page.dart';
import 'package:saxatsavita_flutter/pages/kiranreadpage.dart';
import 'package:saxatsavita_flutter/services/bookservice.dart';
import 'package:saxatsavita_flutter/services/kiranlistservice.dart';
import 'package:saxatsavita_flutter/services/kiranuser_service.dart';
import 'package:saxatsavita_flutter/services/reading_event_service.dart';
import 'package:saxatsavita_flutter/services/utils.dart';
import 'kiranlistpage.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class BookMainpage extends StatefulWidget {
  const BookMainpage({super.key});

  @override
  State<BookMainpage> createState() => _BookmainpageState();
}

class _BookmainpageState extends State<BookMainpage> {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  final List<String> bookNumbers = ['૧', '૨', '૩', '૪', '૫'];

  @override
  void initState() {
    super.initState();

    // ✅ Schedule scroll AFTER the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Wait a bit more to ensure ListView is built and ScrollController is attached
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _itemScrollController.scrollTo(
            index: Bookservice().currentPartNumber - 1,
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeInOut,
          );
        }
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    //Navigator.pop(context, true); // Notify parent of changes
  }

  Future<List<Bookpartmodel>>? get bookparts {
    return Bookservice().getBookParts(context);
  }

  @override
  Widget build(BuildContext context) {
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;
    return Scaffold(
      appBar:
          isPortrait
              ? buildAppBar(
                context,
                title: AppLocalizations.of(context)!.sakshatSavita,
                actionItems: [
                  ActionOptions.notes,
                  ActionOptions.search,
                  ActionOptions.settings,
                ],
                extraActions: [
                  IconButton(
                    icon: const Icon(Icons.calendar_month_outlined),
                    tooltip: AppLocalizations.of(context)!.kiran_calendar,
                    onPressed:
                        () => Navigator.pushNamed(context, '/kiran-calendar'),
                  ),
                ],
              )
              : buildAppBar(
                context,
                title: AppLocalizations.of(context)!.sakshatSavita,
                actionItems: [
                  ActionOptions.aashirvachan,
                  ActionOptions.preface,
                  ActionOptions.notes,
                  ActionOptions.search,
                  ActionOptions.settings,
                ],
                extraActions: [
                  IconButton(
                    icon: const Icon(Icons.calendar_month_outlined),
                    tooltip: AppLocalizations.of(context)!.kiran_calendar,
                    onPressed:
                        () => Navigator.pushNamed(context, '/kiran-calendar'),
                  ),
                ],
              ),
      body: OrientationBuilder(
        builder:
            (context, orientation) =>
                orientation == Orientation.portrait
                    ? _buildPotraitPage(context)
                    : _buildLandscapePage(context),
      ),
    );
  }

  SafeArea _buildLandscapePage(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const AnnouncementBanner(),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.tag_line,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Expanded(child: _buildBookPartsWidget()),
        ],
      ),
    );
  }

  SafeArea _buildPotraitPage(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          Container(
            height: 300,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 1.0),
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Column(
            children: [
              const AnnouncementBanner(),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        await Navigator.pushNamed(context, '/aashirvachan');
                      },
                      style: ButtonStyle(
                        elevation: WidgetStatePropertyAll(5),
                        backgroundColor: WidgetStatePropertyAll(
                          Theme.of(context).colorScheme.surfaceContainer,
                        ),
                        shape: WidgetStatePropertyAll(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                      ),
                      //icon: const Icon(Icons.topic),
                      child: Text(
                        AppLocalizations.of(context)!.aashirvachan,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        await Navigator.pushNamed(context, '/preface');
                      },
                      style: ButtonStyle(
                        elevation: WidgetStatePropertyAll(5),
                        backgroundColor: WidgetStatePropertyAll(
                          Theme.of(context).colorScheme.surfaceContainer,
                        ),
                        shape: WidgetStatePropertyAll(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                      ),
                      //icon: const Icon(Icons.article),
                      child: Text(
                        AppLocalizations.of(context)!.preface,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20.0),
                child: Image(
                  image: const AssetImage('assets/res/z_swami_aashirvad.webp'),
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              Text(
                AppLocalizations.of(context)!.tag_line,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall!.copyWith(fontSize: 18),
              ),
              Expanded(child: _buildBookPartsWidget()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookPartsWidget() {
    return ValueListenableBuilder<AppSettings>(
      valueListenable: appSettingsNotifier,
      builder: (context, appSettings, child) {
        return Padding(
          padding: const EdgeInsets.only(left: 4.0, right: 4.0),
          child: FutureBuilder(
            future: bookparts,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Text(snapshot.error.toString());
              } else if (snapshot.data == null || snapshot.data!.isEmpty) {
                return const Center(child: Text("No data found"));
              } else if (snapshot.data != null) {
                var bookparts = snapshot.data as List<Bookpartmodel>;
                return ScrollablePositionedList.builder(
                  itemScrollController: _itemScrollController,
                  itemPositionsListener: _itemPositionsListener,
                  itemCount: bookparts.length,
                  itemBuilder: (context, index) {
                    return bookPartWidget(bookparts, index);
                  },
                );
              } else {
                return const Center(child: Text("No data found"));
              }
            },
          ),
        );
      },
    );
  }

  Widget bookPartWidget(List<Bookpartmodel> bookparts, int index) {
    final partNumber = bookparts[index].partNumber;
    final accentColor = Utils.getPartAccentColor(partNumber, context);
    final isCurrentPart = Bookservice().currentPartNumber == partNumber;

    return GestureDetector(
      onTap: () => navigateToKiranList(bookparts, index),
      child: Card(
        color: Theme.of(context).colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side:
              isCurrentPart
                  ? BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  )
                  : BorderSide.none,
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              ListTile(
                tileColor: Theme.of(context).colorScheme.surfaceContainer,
                //onTap: () => navigateToKiranList(bookparts, index),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(
                      color: accentColor.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      bookNumbers[partNumber - 1],
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ),
                ),
                title: Text(bookparts[index].displayname.toString()),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bookparts[index].range),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.timer,
                          size: appSettingsNotifier.value.fontSize * 0.8,
                        ),
                        const SizedBox(width: 5),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Text(
                            Utils.getEstimatedReadingTime(
                              KiranListService()
                                      .getKiranList(bookparts[index].id)
                                      ?.totalWordCount ??
                                  0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0),
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainer.withValues(alpha: 1.0),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.shadow.withValues(alpha: 0.2),
                        spreadRadius: 0.5,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(Icons.bookmarks, color: Colors.amber),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => BookmarksPage(
                                partNumber: bookparts[index].partNumber,
                              ),
                        ),
                      );
                    },
                  ),
                ),
                titleTextStyle: Theme.of(context).textTheme.titleMedium,
                subtitleTextStyle: Theme.of(context).textTheme.bodySmall,
              ),
              if (hasBookmarks(bookparts[index].partNumber)) ...[
                const SizedBox(height: 8),
                Divider(),
                const SizedBox(height: 8),
                Bookmarkwidget(
                  partNumber: bookparts[index].partNumber,
                  bookmark: getLatestBookmark(bookparts[index].partNumber)!,
                  onTap: (partNumber, kiranIndex) {
                    _navigateToBookMark(partNumber, kiranIndex);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void navigateToKiranList(List<Bookpartmodel> bookparts, int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Kiranlistpage(bookPart: bookparts[index]),
      ),
    );
    if (result == true) {
      setState(() {
        Bookservice().currentPartNumber = bookparts[index].partNumber;
        // Refresh the state to reflect any changes made in KiranReadPage
      });
    }
  }

  String getNameofBookMark(int partNumber, int kiranIndex) {
    var bookUserInfo = Bookservice().getBookUserInfo(partNumber);
    final latestBookmark = bookUserInfo.latestBookmark;
    if (latestBookmark == null) {
      return "";
    } else {
      var kiranInfo = KiranListService().getKiranInfo(
        partNumber,
        latestBookmark.kiranIndex,
      );
      return "${kiranInfo.number} ${kiranInfo.title}";
    }
  }

  String getUpdatedAt(int partNumber) {
    var bookUserInfo = Bookservice().getBookUserInfo(partNumber);
    if (bookUserInfo.updatedAt == null) {
      return "";
    } else {
      return AppLocalizations.of(
        context,
      )!.last_read(bookUserInfo.updatedAt!, bookUserInfo.updatedAt!);
    }
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
        selectedMode = ReadingMode.reading;
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

  void navigateToBookMark(List<Bookpartmodel> bookparts, int partNumber) async {
    var bookUserInfo = Bookservice().getBookUserInfo(partNumber);
    final latestBookmark = bookUserInfo.latestBookmark;
    if (latestBookmark == null) {
      return;
    }
    var kiranInfo = KiranListService().getKiranInfo(
      partNumber,
      latestBookmark.kiranIndex,
    );
    var kiranUserInfo = KiranUserService().getKiranUserInfo(
      latestBookmark.kiranIndex,
    );

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
        selectedMode = ReadingMode.reading;
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
                  onTap: () => Navigator.pop(context, ReadingMode.reading),
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

  Bookmark? getLatestBookmark(int partNumber) {
    var bookUserInfo = Bookservice().getBookUserInfo(partNumber);
    return bookUserInfo.latestBookmark;
  }

  // Get all bookmarks of current bookuserinfo
  List<Bookmark> getBookmarks(int partNumber) {
    var bookUserInfo = Bookservice().getBookUserInfo(partNumber);
    return bookUserInfo.bookmarks;
  }

  bool hasBookmarks(int partNumber) {
    var bookUserInfo = Bookservice().getBookUserInfo(partNumber);
    return bookUserInfo.bookmarks.isNotEmpty;
  }
}
