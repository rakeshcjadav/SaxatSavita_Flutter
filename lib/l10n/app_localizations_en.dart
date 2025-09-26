// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get sampRakhjo => 'Samp rakhjo';

  @override
  String get sakshatSavita => 'Sakshat Savita';

  @override
  String get menu_one => 'Sakshat Savita';

  @override
  String get aashirvachan => 'Aashirvachan';

  @override
  String get information => 'Information';

  @override
  String get information_section => 'Information Section';

  @override
  String get menu_four => 'Notes';

  @override
  String get menu_five => 'Search';

  @override
  String get menu_six => 'Previous Readings';

  @override
  String get loginWithGoogle => 'Sign in with Google';

  @override
  String get logout => 'Logout';

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get bookmark => 'Bookmark';

  @override
  String get language => 'Application Language';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get lightMode => 'Light Mode';

  @override
  String get part1 => 'Part 1';

  @override
  String get part2 => 'Part 2';

  @override
  String get part3 => 'Part 3';

  @override
  String get part4 => 'Part 4';

  @override
  String get part5 => 'Part 5';

  @override
  String get read => 'Read';

  @override
  String get preface => 'Preface';

  @override
  String get kiran_start => '।। સ્વામિનારાયણ હરે, સ્વામિનારાયણ હરે ।।';

  @override
  String get kiran => 'Kiran';

  @override
  String get font_size => 'Font Size';

  @override
  String get line_height => 'Line Height';

  @override
  String get theme_color => 'Theme Color';

  @override
  String get theme_variant => 'Theme Variant';

  @override
  String get theme_mode => 'Theme Mode';

  @override
  String get theme_contrast => 'Theme Contrast';

  @override
  String get reading_speed => 'Reading Speed';

  @override
  String get select_language => 'Select Language';

  @override
  String reading_count(int count) {
    return 'Read $count times';
  }

  @override
  String get not_yet_read => 'Not yet read';

  @override
  String last_read(DateTime time, DateTime date) {
    final intl.DateFormat timeDateFormat = intl.DateFormat.jm(localeName);
    final String timeString = timeDateFormat.format(time);
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$timeString,$dateString';
  }

  @override
  String time_to_read(String time) {
    return '$time';
  }

  @override
  String get words_per_minute => 'words per min';

  @override
  String get header_slok => '।। શ્રી સ્વામિનારાયણો વિજયતેતરામ્‌ ।।';
}
