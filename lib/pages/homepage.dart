import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../styles.dart';
import '../components/navigationbar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(AppLocalizations.of(context)!.sakshatSavita),
        surfaceTintColor: Colors.transparent,
        elevation: 20,
        actions: [
          IconButton(
            icon: const Icon(Icons.info, size: 24),
            tooltip: AppLocalizations.of(context)!.menu_three,
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.search, size: 24),
            tooltip: AppLocalizations.of(context)!.menu_five,
            onPressed: () {},
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image(
                    image: AssetImage('assets/res/z_icon_saxat_savita.webp'),
                    width: 64,
                    height: 64,
                  ),
                  SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.sakshatSavita,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context)!.sakshatSavita,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.normal,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: Text(AppLocalizations.of(context)!.menu_one),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: Text(AppLocalizations.of(context)!.menu_two),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.edit_document),
              title: Text(AppLocalizations.of(context)!.menu_four),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: Text(AppLocalizations.of(context)!.menu_six),
              onTap: () {},
            ),
          ],
        ),
      ),
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
            padding: EdgeInsets.only(bottom: 65),
            child: ElevatedButton.icon(
              onPressed: () {},
              iconAlignment: IconAlignment.start,
              icon: const Icon(Icons.menu_book, size: 24),
              style: MyButtonStyles.elevatedButtonStyle,
              label: Text(AppLocalizations.of(context)!.menu_one),
            ),
          ),
          Container(
            padding: EdgeInsets.only(bottom: 25),
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
