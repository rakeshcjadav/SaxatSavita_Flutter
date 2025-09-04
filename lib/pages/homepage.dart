import 'package:flutter/material.dart';
import 'package:saxatsavita_flutter/components/appbar.dart';
import 'package:saxatsavita_flutter/components/drawer.dart';
import 'package:saxatsavita_flutter/pages/bookmainpage.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Initialize any required resources here
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context),
      drawer: const MyDrawer(),
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          ClipRRect(
            child: Image(
              image: AssetImage('assets/res/z_jogi_swami_tallest.jpg'),
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
          Container(
            padding: EdgeInsets.only(bottom: 90),
            child: ElevatedButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BookMainpage()),
                );
              },
              iconAlignment: IconAlignment.start,
              icon: const Icon(Icons.menu_book, size: 30),
              style: ButtonStyle(
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                textStyle: const WidgetStatePropertyAll(
                  TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              label: Text("  " + AppLocalizations.of(context)!.menu_one),
            ),
          ),
          Container(
            padding: EdgeInsets.only(bottom: 45),
            child: Text(
              AppLocalizations.of(context)!.sampRakhjo,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.normal,
                color: Colors.orange.shade100,
                shadows: [
                  Shadow(
                    offset: Offset(1.0, 1.0),
                    blurRadius: 5.0,
                    color: Color.fromARGB(115, 0, 0, 0),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      //bottomNavigationBar: const Navigationbar(),
    );
  }
}
