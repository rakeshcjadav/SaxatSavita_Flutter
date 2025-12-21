import 'package:flutter/material.dart';
import 'package:saxatsavita_flutter/components/appbar.dart';
import 'package:saxatsavita_flutter/components/drawer.dart';
import 'package:saxatsavita_flutter/models/appsettings.dart';
import 'package:saxatsavita_flutter/pages/bookmainpage.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';
import 'package:saxatsavita_flutter/services/analytics_service.dart';
import 'package:saxatsavita_flutter/services/in_app_update_service.dart';
import 'package:saxatsavita_flutter/services/home_widget_service.dart';
import 'package:saxatsavita_flutter/services/utils.dart';

class HomePage extends StatefulWidget {
  final bool showScaffold;

  const HomePage({super.key, this.showScaffold = true});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Track screen view
    AnalyticsService().logScreenView(screenName: 'home_page');

    // Update home widgets
    HomeWidgetService().scheduleWidgetUpdates();

    // Check for app updates automatically
    WidgetsBinding.instance.addPostFrameCallback((_) {
      InAppUpdateService().checkForUpdateOnAppStart(context);
      _checkProfileAndNavigate();
    });
  }

  Future<void> _checkProfileAndNavigate() async {
    // Check if user has profile data to determine navigation
    bool shouldGoToProfile = await Utils.shouldNavigateToProfile();

    // Navigate based on profile completeness
    if (shouldGoToProfile && mounted) {
      debugPrint('_handleAuthenticationEvent : Routing to Profile Page');
      await Navigator.pushNamed(context, '/profile');
    } else {
      debugPrint('_handleAuthenticationEvent : Staying on Home Page');
    }
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
    final body = OrientationBuilder(
      builder:
          (context, orientation) =>
              orientation == Orientation.portrait
                  ? _buildPortraitHomePage(context)
                  : _buildLandScapeHomePage(context),
    );

    if (!widget.showScaffold) {
      return body;
    }

    return Scaffold(
      appBar: buildAppBar(
        context,
        title: AppLocalizations.of(context)!.sakshatSavita,
        actionItems: [ActionOptions.info, ActionOptions.settings],
      ),
      drawer: MyDrawer(
        items: [
          DrawerItem.aashirvachan,
          DrawerItem.notes,
          DrawerItem.search,
          DrawerItem.readingPlans,
          DrawerItem.readingHistory,
          DrawerItem.quotesImageGenerator,
          DrawerItem.profile,
          DrawerItem.welcomeTour,
          DrawerItem.marketingShowcase,
          DrawerItem.migration,
          DrawerItem.adminpanel,
          DrawerItem.logout,
        ],
      ),
      body: body,
      //bottomNavigationBar: const Navigationbar(),
    );
  }

  Widget _buildLandScapeHomePage(BuildContext context) {
    return Row(
      children: [
        Column(
          children: [
            Expanded(
              child: ClipRRect(
                child: Image(
                  image: AssetImage('assets/res/z_jogi_swami_small.png'),
                  fit: BoxFit.fill,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Text(
                AppLocalizations.of(context)!.jogi_swami,
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Center(
                  child: Text(
                    AppLocalizations.of(context)!.header_slok,
                    style: Theme.of(context).textTheme.titleSmall!.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const Spacer(),
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
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Stack _buildPortraitHomePage(BuildContext context) {
    return Stack(
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
                    AppLocalizations.of(context)!.jogi_swami,
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
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
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
    );
  }
}
