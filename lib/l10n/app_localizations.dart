import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_gu.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('gu')
  ];

  /// No description provided for @sampRakhjo.
  ///
  /// In en, this message translates to:
  /// **'Samp rakhjo'**
  String get sampRakhjo;

  /// No description provided for @sakshatSavita.
  ///
  /// In en, this message translates to:
  /// **'Sakshat Savita'**
  String get sakshatSavita;

  /// No description provided for @menu_one.
  ///
  /// In en, this message translates to:
  /// **'Sakshat Savita'**
  String get menu_one;

  /// No description provided for @aashirvachan.
  ///
  /// In en, this message translates to:
  /// **'Aashirvachan'**
  String get aashirvachan;

  /// No description provided for @information.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get information;

  /// No description provided for @information_section.
  ///
  /// In en, this message translates to:
  /// **'Information Section'**
  String get information_section;

  /// No description provided for @menu_four.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get menu_four;

  /// No description provided for @menu_five.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get menu_five;

  /// No description provided for @menu_six.
  ///
  /// In en, this message translates to:
  /// **'Previous Readings'**
  String get menu_six;

  /// No description provided for @loginWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get loginWithGoogle;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @bookmark.
  ///
  /// In en, this message translates to:
  /// **'Bookmark'**
  String get bookmark;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @part1.
  ///
  /// In en, this message translates to:
  /// **'Part 1'**
  String get part1;

  /// No description provided for @part2.
  ///
  /// In en, this message translates to:
  /// **'Part 2'**
  String get part2;

  /// No description provided for @part3.
  ///
  /// In en, this message translates to:
  /// **'Part 3'**
  String get part3;

  /// No description provided for @part4.
  ///
  /// In en, this message translates to:
  /// **'Part 4'**
  String get part4;

  /// No description provided for @part5.
  ///
  /// In en, this message translates to:
  /// **'Part 5'**
  String get part5;

  /// No description provided for @read.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get read;

  /// No description provided for @preface.
  ///
  /// In en, this message translates to:
  /// **'Preface'**
  String get preface;

  /// No description provided for @kiran_start.
  ///
  /// In en, this message translates to:
  /// **'।। સ્વામિનારાયણ હરે, સ્વામિનારાયણ હરે ।।'**
  String get kiran_start;

  /// No description provided for @kiran.
  ///
  /// In en, this message translates to:
  /// **'Kiran'**
  String get kiran;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'gu'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'gu': return AppLocalizationsGu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
