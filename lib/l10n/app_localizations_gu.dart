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
  String get reading_history => 'પૂર્વ વાંચન';

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
  String time_format(DateTime time) {
    final intl.DateFormat timeDateFormat = intl.DateFormat.jm(localeName);
    final String timeString = timeDateFormat.format(time);

    return '$timeString';
  }

  @override
  String time_to_read(String time) {
    return '$time';
  }

  @override
  String get words_per_minute => 'શબ્દો પ્રતિ મિનિટ';

  @override
  String get header_slok => '।। શ્રી સ્વામિનારાયણો વિજયતેતરામ્‌ ।।';

  @override
  String get search_kiranas => 'શીર્ષક અથવા સામગ્રી દ્વારા કિરણો શોધો...';

  @override
  String get search_all_kiranas => 'તમામ કિરણો શોધો';

  @override
  String get enter_keywords => 'સંબંધિત સામગ્રી શોધવા માટે કીવર્ડ્સ દાખલ કરો';

  @override
  String get no_results_found => 'કોઈ પરિણામ મળ્યા નથી';

  @override
  String get try_different_keywords =>
      'અલગ કીવર્ડ્સ અજમાવો અથવા સ્પેલિંગ ચકાસો';

  @override
  String results_found(int count) {
    return '$count પરિણામો મળ્યા';
  }

  @override
  String get search_min_chars => 'શોધવા માટે ઓછામાં ઓછા 2 અક્ષરો દાખલ કરો';

  @override
  String get content_match => 'સામગ્રી';

  @override
  String get title_match => 'શીર્ષક';

  @override
  String get filters => 'ફિલ્ટર્સ';

  @override
  String get clear_all_filters => 'બધા સાફ કરો';

  @override
  String get match_type => 'મેચ પ્રકાર';

  @override
  String get book_parts => 'પુસ્તક ભાગો';

  @override
  String get no_filtered_results =>
      'વર્તમાન ફિલ્ટર્સ સાથે કોઈ પરિણામ મેળ ખાતા નથી';

  @override
  String get adjust_filters => 'તમારી ફિલ્ટર સેટિંગ્સ એડજસ્ટ કરવાનો પ્રયાસ કરો';

  @override
  String results_filtered(int filtered, int total) {
    return '$total માંથી $filtered પરિણામો દર્શાવવામાં આવ્યા છે';
  }

  @override
  String get expand_filters => 'ફિલ્ટર્સ વિસ્તૃત કરો';

  @override
  String get collapse_filters => 'ફિલ્ટર્સ સંકુચિત કરો';

  @override
  String get search_hint => 'આ કિરણમાં શોધો... (Enter: શોધો)';

  @override
  String get no_match_found => 'કોઈ મેચ મળ્યો નથી';

  @override
  String get search_in_kiran => 'કિરણમાં શોધો';

  @override
  String get close_search => 'શોધ બંધ કરો';

  @override
  String get edit_notes => 'નોંધ સંપાદિત કરો';

  @override
  String get save_notes => 'નોંધ સેવ કરો';

  @override
  String get notes => 'નોંધ';

  @override
  String get add_notes => 'નોંધ ઉમેરો';

  @override
  String get notes_hint => 'અહીં તમારી વ્યક્તિગત નોંધ ઉમેરો...';

  @override
  String get notesSaved => 'નોંધ સફળતાપૂર્વક સેવ થઈ...';

  @override
  String get cancel => 'રદ કરો';

  @override
  String get deleteNoteConfirm => 'શું તમે ખરેખર આ નોટ ડિલીટ કરવા માંગો છો?';

  @override
  String get delete => 'ડિલિટ';

  @override
  String get noteDeletedSuccess => 'નોંધ સફળતાપૂર્વક ડિલીટ થઈ...';

  @override
  String errorDeletingNote(String error) {
    return 'નોંધ ડિલીટ કરવામાં ભૂલ: $error';
  }

  @override
  String daysAgo(int days) {
    return '$days દિવસ પહેલાં';
  }

  @override
  String hoursAgo(int hours) {
    return '$hours કલાક પહેલાં';
  }

  @override
  String minutesAgo(int minutes) {
    return '$minutes મિનિટ પહેલાં';
  }

  @override
  String get justNow => 'હમણાં';

  @override
  String get sortBy => 'આ પ્રમાણે ક્રમાંકિત કરો';

  @override
  String get lastModified => 'છેલ્લે બદલાયેલ';

  @override
  String get searchNotesHint => 'નોંધ અને શીર્ષકો શોધો...';

  @override
  String notesCount(int filtered, int total) {
    return 'કુલ $total માંથી $filtered નોટ્સ';
  }

  @override
  String sortedBy(String sortName, String direction) {
    return '$direction $sortName દ્વારા ક્રમાંકિત';
  }

  @override
  String get noNotesFound => 'કોઈ નોંધ મળી નથી';

  @override
  String get startTakingNotes => 'કિરણો વાંચતી વખતે નોંધ લેવાનું શરૂ કરો';

  @override
  String get noMatchingNotes => 'મેળ થતી નોંધ નથી';

  @override
  String get characters => 'અક્ષરો';

  @override
  String get tapToEdit => 'સંપાદિત કરવા માટે ટેપ કરો';

  @override
  String get adjustSearchFilters =>
      'તમારી શોધ અથવા ફિલ્ટર એડજસ્ટ કરવાનો પ્રયાસ કરો';

  @override
  String get editNote => 'નોંધ સંપાદિત કરો';

  @override
  String get viewKiran => 'કિરણ જુઓ';

  @override
  String get deleteNote => 'નોંધ મિટાવો';

  @override
  String get bookPart => 'પુસ્તક ભાગ';

  @override
  String get noteLength => 'નોંધની લંબાઈ';

  @override
  String get bookParts => 'પુસ્તક ભાગો:';

  @override
  String get favorite => 'ફેવરિટ';

  @override
  String get favoriteKiranSuccess => 'કિરણ સફળતાપૂર્વક ફેવરિટ કરવામાં આવ્યું.';

  @override
  String get readingHistoryTitle => 'વાંચન ઇતિહાસ';

  @override
  String get totalReadingTime => 'કુલ વાંચન સમય';

  @override
  String get readingSessions => 'વાંચન સત્રો';

  @override
  String get noReadingHistory => 'કોઈ વાંચન ઇતિહાસ નથી';

  @override
  String get startReadingMessage =>
      'તમારી પ્રગતિ ટ્રેક કરવા માટે કિરણો વાંચવાનું શરૂ કરો';

  @override
  String get today => 'આજ';

  @override
  String get yesterday => 'ગઈકાલે';

  @override
  String get thisWeek => 'આ અઠવાડિયે';

  @override
  String get thisMonth => 'આ મહિને';

  @override
  String get older => 'જૂના';

  @override
  String get duration => 'સમયગાળો';

  @override
  String get readingSession => 'વાંચન સત્ર';

  @override
  String get filterByCategory => 'શ્રેણી દ્વારા ફિલ્ટર કરો';

  @override
  String get allCategories => 'બધી શ્રેણીઓ';

  @override
  String get clearFilters => 'ફિલ્ટર સાફ કરો';

  @override
  String get expandAll => 'બધું વિસ્તાર કરો';

  @override
  String get collapseAll => 'બધું સંકુચિત કરો';

  @override
  String get filterByDate => 'તારીખ દ્વારા ફિલ્ટર કરો';

  @override
  String get year => 'વર્ષ';

  @override
  String get month => 'મહિનો';

  @override
  String get allYears => 'બધા વર્ષો';

  @override
  String get allMonths => 'બધા મહિનાઓ';

  @override
  String get january => 'જાન્યુઆરી';

  @override
  String get february => 'ફેબ્રુઆરી';

  @override
  String get march => 'માર્ચ';

  @override
  String get april => 'એપ્રિલ';

  @override
  String get may => 'મે';

  @override
  String get june => 'જૂન';

  @override
  String get july => 'જુલાઈ';

  @override
  String get august => 'ઓગસ્ટ';

  @override
  String get september => 'સપ્ટેમ્બર';

  @override
  String get october => 'ઓક્ટોબર';

  @override
  String get november => 'નવેમ્બર';

  @override
  String get december => 'ડિસેમ્બર';
}
