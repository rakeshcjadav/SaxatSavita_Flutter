import 'package:flutter/material.dart';
import 'package:saxatsavita_flutter/services/appdataservice.dart';
import '../components/appbar.dart';
import '../models/infocontent_model.dart';
import 'infodetailspage.dart';

class Infolistpage extends StatefulWidget {
  const Infolistpage({super.key});

  final List<String> infoKeys = const [
    'about_us',
    'jogi_swami_biography',
    'about_book',
    'granth_darshan',
    // Add more titles as needed
  ];

  @override
  State<Infolistpage> createState() => _InfolistpageState();
}

class _InfolistpageState extends State<Infolistpage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context, title: "Info List"),
      body: ListView.builder(
        itemCount: widget.infoKeys.length,
        itemBuilder: (context, index) {
          final infoKey = widget.infoKeys[index];
          final infoItem = AppDataService().getInfoValue(infoKey);
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Center(child: Text(infoItem!.title)),
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
