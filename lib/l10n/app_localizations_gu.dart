// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Gujarati (`gu`).
class AppLocalizationsGu extends AppLocalizations {
  AppLocalizationsGu([String locale = 'gu']) : super(locale);

  @override
  String get sampRakhjo => 'સંપ રાખજો.';

  @override
  String get sakshatSavita => 'સાક્ષાત્ સવિતા';

  @override
  String get menu_one => 'સાક્ષાત્‌ સવિતા';

  @override
  String get aashirvachan => 'આશીર્વચન';

  @override
  String get information => 'માહિતી';

  @override
  String get information_section => 'માહિતી વિભાગ';

  @override
  String get menu_four => 'નોંધ';

  @override
  String get menu_five => 'શોધો';

  @override
  String get menu_six => 'પૂર્વ વાંચન';

  @override
  String get loginWithGoogle => 'Sign in with Google';

  @override
  String get logout => 'Logout';

  @override
  String get profile => 'પ્રોફાઇલ';

  @override
  String get settings => 'સેટિંગ્સ';

  @override
  String get bookmark => 'બુકમાર્ક';

  @override
  String get language => 'એપ્લિકેશનની ભાષા';

  @override
  String get darkMode => 'ડાર્ક મોડ';

  @override
  String get lightMode => 'લાઇટ મોડ';

  @override
  String get part1 => 'ભાગ ૧';

  @override
  String get part2 => 'ભાગ ૨';

  @override
  String get part3 => 'ભાગ ૩';

  @override
  String get part4 => 'ભાગ ૪';

  @override
  String get part5 => 'ભાગ ૫';

  @override
  String get read => 'વાંચો';

  @override
  String get preface => 'પ્રસ્તાવના';

  @override
  String get kiran_start => '|| સ્વામિનારાયણ હરે, સ્વામિનારાયણ હરે ||';

  @override
  String get kiran => 'કિરણ';

  @override
  String get font_size => 'અક્ષરની સાઇઝ';

  @override
  String get line_height => 'લાઇન હાઇટ';

  @override
  String get theme_color => 'થિમનો રંગ';

  @override
  String get theme_variant => 'થિમનો પ્રકાર';

  @override
  String get theme_mode => 'થિમનો મોડ';

  @override
  String get theme_contrast => 'થિમનો વિસંગતિ';

  @override
  String get reading_speed => 'વાંચવાની ગતિ';

  @override
  String get select_language => 'ભાષા પસંદ કરો';

  @override
  String reading_count(int count) {
    return '$count વખત વાંચ્યું';
  }

  @override
  String get kiran_read_finished => 'કિરણ વાંચી લીધું';

  @override
  String get not_yet_read => 'હજી વાંચ્યું નથી';

  @override
  String last_read(DateTime time, DateTime date) {
    final intl.DateFormat timeDateFormat = intl.DateFormat.jm(localeName);
    final String timeString = timeDateFormat.format(time);
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$timeString, $dateString';
  }

  @override
  String time_to_read(String time) {
    return '$time';
  }

  @override
  String get words_per_minute => 'શબ્દો પ્રતિ મિનિટ';

  @override
  String get header_slok => '।। શ્રી સ્વામિનારાયણો વિજયતેતરામ્‌ ।।';
}
