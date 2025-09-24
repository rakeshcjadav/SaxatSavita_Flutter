import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';
import 'package:saxatsavita_flutter/pages/infolistpage.dart';
import 'package:saxatsavita_flutter/services/bookservice.dart';
import 'pages/splashpage.dart';
import 'firebase_options.dart';
import 'package:saxatsavita_flutter/services/appdataservice.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Load JSON data
  await AppDataService().loadData('assets/jsons/data.json');
  await AppDataService().loadInfoContent('assets/jsons/infodata.json');
  runApp(const SakshatSavitaApp());
}

class SakshatSavitaApp extends StatelessWidget {
  const SakshatSavitaApp({super.key});

  final String titleText = 'Sakshat Savita';
  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(seedColor: Colors.orange.shade500);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('gu', 'IN'),
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      title: titleText,
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        fontFamily: 'NotoSansGujarati',
        iconTheme: IconThemeData(color: colorScheme.primary),
        textTheme: TextTheme(
          bodyLarge: TextStyle(fontSize: 18, color: colorScheme.primary),
          bodyMedium: TextStyle(fontSize: 16, color: colorScheme.primary),
          bodySmall: TextStyle(fontSize: 14, color: colorScheme.primary),

          titleLarge: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
          titleMedium: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
          titleSmall: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),

          labelLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
          labelMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
          labelSmall: TextStyle(
            fontSize: 14,
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
      ),
      home: const SplashPage(),
      routes: {'/info': (context) => const Infolistpage()},
    );
  }
}
