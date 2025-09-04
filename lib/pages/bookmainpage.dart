import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:saxatsavita_flutter/components/appbar.dart';
import 'package:saxatsavita_flutter/models/bookpart_model.dart';

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

  Future<List<Bookpartmodel>> getBookparts() async {
    final Locale locale = Localizations.localeOf(context);
    final String filename =
        'assets/jsons/bookparts_${locale.languageCode}.json';
    final jsondata = await rootBundle.loadString(filename);
    final list = json.decode(jsondata) as List<dynamic>;

    return list.map((e) => Bookpartmodel.fromJson(e)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade100,
      appBar: buildAppBar(context),
      body: bookPartsWidget(),
    );
  }

  Widget bookPartsWidget() {
    return FutureBuilder(
      future: getBookparts(),
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
    );
  }

  Widget bookPartWidget(List<Bookpartmodel> bookparts, int index) {
    return GestureDetector(
      child: Card(
        color: Theme.of(context).colorScheme.surfaceContainer,
        elevation: 5,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              ListTile(
                leading: Icon(
                  Icons.book,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(bookparts[index].displayname.toString()),
                subtitle: Text(bookparts[index].range),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 2,
                  ),
                  onPressed: () {},
                  child: Text("Read"),
                ),
                titleTextStyle: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
                subtitleTextStyle: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 15,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(
                      Icons.timer,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      "12h:54m:10s",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(),
              Padding(
                padding: const EdgeInsets.only(left: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.bookmark + ": ",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    ElevatedButton.icon(
                      label: Text(AppLocalizations.of(context)!.sakshatSavita),
                      onPressed: () {},
                      icon: const Icon(Icons.bookmark, size: 20),
                      style: ButtonStyle(elevation: WidgetStatePropertyAll(0)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
