import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:saxatsavita_flutter/auth/pages/google_sign_in_page.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';
import 'package:saxatsavita_flutter/models/appsettings.dart';
import 'package:saxatsavita_flutter/pages/bookmainpage.dart';
import 'package:saxatsavita_flutter/pages/homepage.dart';
import 'package:saxatsavita_flutter/pages/infodetailspage.dart';
import 'package:saxatsavita_flutter/pages/infolistpage.dart';
import 'package:saxatsavita_flutter/pages/kiransearchpage.dart';
import 'package:saxatsavita_flutter/pages/welcome_screen.dart';
import 'package:saxatsavita_flutter/pages/notelistpage.dart';
import 'package:saxatsavita_flutter/pages/reading_history_page.dart';
import 'package:saxatsavita_flutter/pages/reading_plan_page.dart';
import 'package:saxatsavita_flutter/pages/quotes_image_generator_page.dart';
import 'package:saxatsavita_flutter/pages/profile_page.dart';
import 'package:saxatsavita_flutter/services/bookservice.dart';
import 'package:saxatsavita_flutter/services/navigationservice.dart';
import 'package:saxatsavita_flutter/services/analytics_service.dart';
import 'package:saxatsavita_flutter/services/in_app_review_service.dart';
import 'package:saxatsavita_flutter/services/home_widget_service.dart';
import 'pages/splashpage.dart';
import 'firebase_options.dart';
import 'package:saxatsavita_flutter/services/appdataservice.dart';
import 'pages/settingspage.dart';
import 'pages/aashirvachanlistpage.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter/foundation.dart';

// Conditional imports for debug-only pages
import 'pages/marketing_showcase_page_conditional.dart';
import 'pages/comprehensive_migration_page_conditional.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // Keep splash until initialization completes
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  if (!kIsWeb) {
    // Initialize Firebase with comprehensive error handling
    try {
      // Check if Firebase is already initialized
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } else {
        // Firebase already initialized, use the existing app
        Firebase.app();
      }
    } catch (e) {
      // Handle any Firebase initialization errors
      print('Firebase initialization error: $e');
      // If it's a duplicate app error, try to get the existing app
      if (e.toString().contains('duplicate-app')) {
        try {
          Firebase.app();
        } catch (getAppError) {
          print('Could not get existing Firebase app: $getAppError');
        }
      }
    }

    // Initialize Firebase Analytics
    FirebaseAnalytics analytics = FirebaseAnalytics.instance;

    // Initialize Analytics Service
    AnalyticsService().initialize(analytics);
    print('Firebase Analytics initialized successfully');

    // Initialize In-App Review Service
    await InAppReviewService().initialize();
    print('In-App Review Service initialized successfully');

    // Initialize Home Widget Service
    await HomeWidgetService().initialize();
    print('Home Widget Service initialized successfully');
  }

  // Load JSON data
  await AppDataService().loadData('assets/jsons/data.json');
  await AppDataService().loadInfoContent('assets/jsons/infodata.json');
  Bookservice().loadBook('saxatsavita');

  // Pass analytics only if not on web
  runApp(
    SakshatSavitaApp(analytics: kIsWeb ? null : FirebaseAnalytics.instance),
  );
}

class SakshatSavitaApp extends StatelessWidget {
  const SakshatSavitaApp({super.key, this.analytics});

  final FirebaseAnalytics? analytics;
  final String titleText = 'Sakshat Savita';
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppSettings>(
      valueListenable: appSettingsNotifier,
      builder: (context, settings, child) {
        ColorScheme colorScheme = ColorScheme.fromSeed(
          seedColor: settings.themeColor,
          contrastLevel: settings.themeContrastLevel,
          brightness: settings.brightness,
          dynamicSchemeVariant: settings.themeVariant,
        );
        return MaterialApp(
          navigatorKey: NavigationService.navigatorKey, // Assign the key here
          navigatorObservers:
              analytics != null
                  ? [FirebaseAnalyticsObserver(analytics: analytics!)]
                  : [],
          debugShowCheckedModeBanner: false,
          locale: Locale(settings.language, 'IN'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            FlutterQuillLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          title: titleText,
          theme: ThemeData(
            colorScheme: colorScheme,
            useMaterial3: true,
            fontFamily: 'NotoSansGujarati',
            iconTheme: IconThemeData(
              color: colorScheme.primary,
              size: settings.fontSize,
            ),
            textTheme: TextTheme(
              bodyLarge: TextStyle(
                fontSize: settings.fontSize,
                color: colorScheme.primary,
              ),
              bodyMedium: TextStyle(
                fontSize: settings.fontSize - 2,
                color: colorScheme.primary,
              ),
              bodySmall: TextStyle(
                fontSize: settings.fontSize - 4,
                color: colorScheme.primary,
              ),

              titleLarge: TextStyle(
                fontSize: settings.fontSize + 4,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
              titleMedium: TextStyle(
                fontSize: settings.fontSize + 2,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
              titleSmall: TextStyle(
                fontSize: settings.fontSize,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),

              labelLarge: TextStyle(
                fontSize: settings.fontSize,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
              labelMedium: TextStyle(
                fontSize: settings.fontSize - 2,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
              labelSmall: TextStyle(
                fontSize: settings.fontSize - 4,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              centerTitle: true,
            ),
            drawerTheme: DrawerThemeData(
              backgroundColor: colorScheme.surfaceContainer,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
            ),
            dividerColor: Colors.transparent,
            dividerTheme: DividerThemeData(
              color: colorScheme.primary.withValues(alpha: 0.1),
              space: 0,
              thickness: 2,
            ),
            listTileTheme: ListTileThemeData(
              textColor: colorScheme.primary,
              iconColor: colorScheme.primary,
              tileColor: colorScheme.surfaceContainer,
              selectedColor: Colors.white,
              selectedTileColor: Colors.blue.shade300,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            cardTheme: CardThemeData(
              color: colorScheme.surfaceContainer,
              shadowColor: Colors.black54,
              elevation: 5,
              margin: const EdgeInsets.all(8.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
            scrollbarTheme: ScrollbarThemeData(
              thumbColor: WidgetStateProperty.all(
                colorScheme.primary.withValues(alpha: 0.5),
              ),
              trackColor: WidgetStateProperty.all(
                colorScheme.primary.withValues(alpha: 0.1),
              ),
              trackBorderColor: WidgetStateProperty.all(Colors.transparent),
              radius: const Radius.circular(6),
              thickness: WidgetStateProperty.all(3.0),
            ),
            popupMenuTheme: PopupMenuThemeData(
              color: colorScheme.primaryContainer,
              textStyle: TextStyle(
                fontSize: settings.fontSize - 2,
                color: colorScheme.primary,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              elevation: 10,
            ),
            textSelectionTheme: TextSelectionThemeData(
              cursorColor: colorScheme.primary,
              selectionColor: Colors.amber.withValues(alpha: 0.5),
              selectionHandleColor: Colors.amber,
            ),
            tabBarTheme: TabBarThemeData(
              labelColor: colorScheme.onPrimary,
              unselectedLabelColor: colorScheme.onPrimary.withValues(
                alpha: 0.5,
              ),
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(
                  color: colorScheme.onPrimary,
                  width: 4.0,
                ),
              ),
            ),
          ),
          home: const SplashPage(),
          routes: {
            '/info': (context) => const Infolistpage(),
            '/preface':
                (context) => Infodetailspage(
                  infoItem: AppDataService().getInfoValue("preface")!,
                ),
            '/search': (context) => const Kiransearchpage(),
            '/settings': (context) => const SettingsPage(),
            '/aashirvachan': (context) => const Aashirvachanpage(),
            '/home': (context) => const HomePage(),
            '/bookmainpage': (context) => const BookMainpage(),
            '/notes': (context) => const NoteListPage(),
            '/readinghistory': (context) => const ReadingHistoryPage(),
            '/reading_plans': (context) => const ReadingPlanPage(),
            '/quotes_generator':
                (context) => const QuotesImageGeneratorPage(quote: null),
            '/profile':
                (context) => const ProfilePage(continueAfterProfile: false),
            '/welcome': (context) => const WelcomeScreen(),
            '/login': (context) => const GoogleSignInPage(),
            // Debug-only routes (excluded from release builds)
            ...kDebugMode
                ? {
                  '/migration': (context) => const ComprehensiveMigrationPage(),
                  '/marketing_showcase':
                      (context) => const MarketingShowcasePage(),
                }
                : {},
          },
        );
      },
    );
  }
}
