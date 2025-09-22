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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      home: const SplashPage(),
      routes: {'/info': (context) => const Infolistpage()},
    );
  }
}
