import 'package:flutter/material.dart';
import 'package:saxatsavita_flutter/components/appbar.dart';
import 'package:saxatsavita_flutter/components/drawer.dart';
import 'package:saxatsavita_flutter/models/appsettings.dart';
import 'package:saxatsavita_flutter/pages/bookmainpage.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';

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
      appBar: buildAppBar(
        context,
        title: AppLocalizations.of(context)!.sakshatSavita,
        actionItems: [ActionOptions.info, ActionOptions.settings],
      ),
      drawer: const MyDrawer(),
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
          SafeArea(
            child: Container(
              padding: EdgeInsets.only(bottom: 70),
              child: ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BookMainpage(),
                    ),
                  );
                },
                iconAlignment: IconAlignment.start,
                icon: Icon(
                  Icons.menu_book,
                  size: appSettingsNotifier.value.fontSize,
                ),
                style: ButtonStyle(
                  padding: const WidgetStatePropertyAll(
                    EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  textStyle: WidgetStatePropertyAll(
                    Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                label: Text("  ${AppLocalizations.of(context)!.sakshatSavita}"),
              ),
            ),
          ),
          SafeArea(
            child: Container(
              padding: EdgeInsets.only(bottom: 25),
              child: Text(
                AppLocalizations.of(context)!.sampRakhjo,
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  shadows: [
                    Shadow(
                      offset: Offset(1.0, 1.0),
                      blurRadius: 3.0,
                      color: Colors.black.withOpacity(0.8),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      //bottomNavigationBar: const Navigationbar(),
    );
  }
}
