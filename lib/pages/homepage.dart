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

class HomePageState extends State<HomePage> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {}

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
              image: AssetImage('assets/res/z_jogi_swami_tallest_2.jpg'),
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 1.0),
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.0),
                ],
              ),
            ),
            height: 200,
            width: double.infinity,
          ),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.only(bottom: 100),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 1.0),
                        Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                  //color: Theme.of(
                  //  context,
                  //).colorScheme.primary.withValues(alpha: 1.0),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Center(
                      child: Text(
                        AppLocalizations.of(context)!.header_slok,
                        style: Theme.of(context).textTheme.titleSmall!.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "પ.પૂ.પ્ર.બ્ર.સ્વ.સદ્. જોગીસ્વામી\nશ્રી ધર્મપ્રસાદદાસજી સ્વામી",
                      style: Theme.of(context).textTheme.titleSmall!.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: EdgeInsets.only(bottom: 10),
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
                          elevation: WidgetStatePropertyAll(10),
                        ),
                        label: Text(
                          "  ${AppLocalizations.of(context)!.sakshatSavita}",
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.only(bottom: 10),
                      child: Text(
                        AppLocalizations.of(context)!.sampRakhjo,
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium!.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      //bottomNavigationBar: const Navigationbar(),
    );
  }
}
