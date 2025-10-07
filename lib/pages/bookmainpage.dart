import 'package:flutter/material.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';
import 'package:saxatsavita_flutter/components/appbar.dart';
import 'package:saxatsavita_flutter/models/appsettings.dart';
import 'package:saxatsavita_flutter/models/bookpart_model.dart';
import 'package:saxatsavita_flutter/pages/aashirvachanlistpage.dart';
import 'package:saxatsavita_flutter/pages/infodetailspage.dart';
import 'package:saxatsavita_flutter/pages/kiranreadpage.dart';
import 'package:saxatsavita_flutter/services/appdataservice.dart';
import 'package:saxatsavita_flutter/services/bookservice.dart';
import 'package:saxatsavita_flutter/services/kiranlistservice.dart';
import 'package:saxatsavita_flutter/services/kiranuser_service.dart';
import 'package:saxatsavita_flutter/services/utils.dart';
import 'kiranlistpage.dart';

class BookMainpage extends StatefulWidget {
  const BookMainpage({super.key});

  @override
  State<BookMainpage> createState() => _BookmainpageState();
}

class _BookmainpageState extends State<BookMainpage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    //Navigator.pop(context, true); // Notify parent of changes
  }

  Future<List<Bookpartmodel>> get bookparts {
    return Bookservice().loadBook(context, 'saxatsavita');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(
        context,
        title: AppLocalizations.of(context)!.sakshatSavita,
        actionItems: [
          ActionOptions.notes,
          ActionOptions.search,
          ActionOptions.settings,
        ],
      ),
      body: Column(
        children: [
          ColoredBox(
            color: Theme.of(context).colorScheme.primary,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Aashirvachanpage(),
                        ),
                      );
                    },
                    style: ButtonStyle(
                      elevation: WidgetStatePropertyAll(5),
                      backgroundColor: WidgetStatePropertyAll(
                        Theme.of(context).colorScheme.surfaceContainer,
                      ),
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.aashirvachan,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final infoItem = AppDataService().getInfoValue("preface");
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => Infodetailspage(infoItem: infoItem!),
                        ),
                      );
                    },
                    style: ButtonStyle(
                      elevation: WidgetStatePropertyAll(5),
                      backgroundColor: WidgetStatePropertyAll(
                        Theme.of(context).colorScheme.surfaceContainer,
                      ),
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.preface,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20.0),
            child: Image(
              image: const AssetImage('assets/res/z_swami_aashirvad.webp'),
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          Expanded(child: bookPartsWidget()),
        ],
      ),
    );
  }

  /*
  Padding _carouselSlider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          CarouselSlider(
            items: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: const ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(20.0)),
                  child: Image(
                    image: AssetImage(
                      'assets/res/z_ashirvachan_jogiswami_image.webp',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: const ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(20.0)),
                  child: Image(
                    image: AssetImage(
                      'assets/res/z_ashirvachan_swami_shree_image.webp',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
            options: CarouselOptions(
              height: 150,
              aspectRatio: 16 / 9,
              viewportFraction: 0.8,
              initialPage: 0,
              enableInfiniteScroll: false,
              reverse: false,
              autoPlay: false,
              autoPlayInterval: const Duration(seconds: 3),
              autoPlayAnimationDuration: const Duration(milliseconds: 800),
              autoPlayCurve: Curves.fastOutSlowIn,
              enlargeCenterPage: true,
              scrollDirection: Axis.horizontal,
              onPageChanged: (index, reason) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(2, (index) {
                return Container(
                  width: _currentIndex == index ? 24 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color:
                        _currentIndex == index
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.3),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
  */

  Widget bookPartsWidget() {
    return ValueListenableBuilder<AppSettings>(
      valueListenable: appSettingsNotifier,
      builder: (context, appSettings, child) {
        return Padding(
          padding: const EdgeInsets.only(left: 4.0, right: 4.0),
          child: Scrollbar(
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
                  return ListView.builder(
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
          ),
        );
      },
    );
  }

  Widget bookPartWidget(List<Bookpartmodel> bookparts, int index) {
    return GestureDetector(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              ListTile(
                leading: Icon(
                  Icons.book,
                  size: appSettingsNotifier.value.fontSize * 2.0,
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
                        Text(
                          Utils.getEstimatedReadingTime(
                            KiranListService()
                                    .getKiranList(bookparts[index].id)
                                    ?.totalWordCount ??
                                0,
                          ),
                        ),
                        const SizedBox(width: 15),
                      ],
                    ),
                  ],
                ),

                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  onPressed: () {
                    navigateToKiranList(bookparts, index);
                  },
                  child: Text(
                    AppLocalizations.of(context)!.read,
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
                titleTextStyle: Theme.of(context).textTheme.titleMedium,
                subtitleTextStyle: Theme.of(context).textTheme.bodySmall,
              ),
              if (isValidBookmark(bookparts[index].partNumber)) ...[
                const SizedBox(height: 8),
                Divider(),
                const SizedBox(height: 8),
                Column(
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
                          getNameofBookMark(
                            bookparts[index].partNumber,
                            Bookservice()
                                .getBookUserInfo(bookparts[index].partNumber)
                                .bookmarkKiranIndex,
                          ),
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      onPressed: () {
                        navigateToBookMark(bookparts, index + 1);
                      },
                      icon: const Icon(Icons.bookmark, color: Colors.amber),
                    ),
                    if (Bookservice()
                            .getBookUserInfo(bookparts[index].partNumber)
                            .updatedAt !=
                        null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.history,
                            size: appSettingsNotifier.value.fontSize * 0.6,
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.3),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            getUpdatedAt(bookparts[index].partNumber),
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall!.copyWith(
                              fontSize:
                                  appSettingsNotifier.value.fontSize * 0.6,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool isValidBookmark(int partNumber) {
    var bookUserInfo = Bookservice().getBookUserInfo(partNumber);
    if (bookUserInfo.bookmarkKiranIndex == 0) {
      return false;
    } else {
      return bookUserInfo.bookmarkKiranIndex !=
          Bookservice().bookparts![partNumber - 1].startKiranIndex;
    }
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
        // Refresh the state to reflect any changes made in KiranReadPage
      });
    }
  }

  String getNameofBookMark(int partNumber, int kiranIndex) {
    var bookUserInfo = Bookservice().getBookUserInfo(partNumber);
    if (bookUserInfo.bookmarkKiranIndex == 0) {
      return "";
    } else {
      var kiranInfo = KiranListService().getKiranInfo(
        partNumber,
        bookUserInfo.bookmarkKiranIndex,
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

  void navigateToBookMark(List<Bookpartmodel> bookparts, int partNumber) async {
    var bookUserInfo = Bookservice().getBookUserInfo(partNumber);
    var kiranInfo = KiranListService().getKiranInfo(
      partNumber,
      bookUserInfo.bookmarkKiranIndex,
    );
    var kiranUserInfo = KiranUserService().getKiranUserInfo(
      bookUserInfo.bookmarkKiranIndex,
    );
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
