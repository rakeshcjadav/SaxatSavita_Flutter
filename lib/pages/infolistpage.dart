import 'package:flutter/material.dart';
import 'package:saxatsavita_flutter/services/appdataservice.dart';
import '../components/appbar.dart';
import 'infodetailspage.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';

class Infolistpage extends StatefulWidget {
  const Infolistpage({super.key});

  final List<String> infoKeys = const [
    'jogi_swami_biography',
    'about_book',
    'granth_darshan',
    'about_us',
    // Add more titles as needed
  ];

  @override
  State<Infolistpage> createState() => _InfolistpageState();
}

class _InfolistpageState extends State<Infolistpage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(
        context,
        title: AppLocalizations.of(context)!.information_section,
      ),
      body: ListView.builder(
        itemCount: widget.infoKeys.length,
        itemBuilder: (context, index) {
          final infoKey = widget.infoKeys[index];
          final infoItem = AppDataService().getInfoValue(infoKey);
          return Card(
            child: ListTile(
              title: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    infoItem!.title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Infodetailspage(infoItem: infoItem),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
