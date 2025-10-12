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
  String get tag_line => '।। વિચાર કરો તો ખબર પડે ।।';

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
  String get theme_contrast => 'થિમનો કોન્ટ્રાસ્ટ';

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
  String get deleteNoteConfirm => 'શું તમે ખરેખર આ નોંધ ડિલીટ કરવા માંગો છો?';

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
    return 'કુલ $total માંથી $filtered નોંધ';
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

  @override
  String get analytics => 'વિશ્લેષણ';

  @override
  String get dailyChart => 'દૈનિક';

  @override
  String get weeklyChart => 'સાપ્તાહિક';

  @override
  String get partsChart => 'ભાગો';

  @override
  String get durationChart => 'સમયગાળો';

  @override
  String get dailyReadingMinutes => 'દૈનિક વાંચન મિનિટ';

  @override
  String get weeklyReadingHours => 'સાપ્તાહિક વાંચન કલાક';

  @override
  String get readingDistributionByParts => 'ભાગો પ્રમાણે વાંચન વિતરણ';

  @override
  String get readingSessionDurationAnalysis => 'વાંચન સત્ર સમયગાળાનું વિશ્લેષણ';

  @override
  String get noAnalyticsAvailable => 'કોઈ વિશ્લેષણ ઉપલબ્ધ નથી';

  @override
  String get startReadingForAnalytics =>
      'તમારા વિશ્લેષણ અને અંતર્દૃષ્ટિ જોવા માટે વાંચવાનું શરૂ કરો.';

  @override
  String get chartMinutesLabel => 'મિનિટ';

  @override
  String get chartHoursLabel => 'કલાક';

  @override
  String get chartSessionsLabel => 'સત્રો';

  @override
  String get dailyChartDescription =>
      'છેલ્લા ૩૦ દિવસમાં દરરોજ વાંચેલી મિનિટો દર્શાવતા આ લાઇન ચાર્ટ સાથે તમારી દૈનિક વાંચન આદતોને ટ્રેક કરો. શિખરો તમારા સૌથી ઉત્પાદક વાંચન દિવસો દર્શાવે છે.';

  @override
  String get weeklyChartDescription =>
      'છેલ્લા ૧૨ અઠવાડિયામાં દર અઠવાડિયે કુલ વાંચેલા કલાકો દર્શાવતા આ બાર ચાર્ટ સાથે તમારા સાપ્તાહિક વાંચન પેટર્નને જુઓ. સતત વાંચન સમયગાળાને ઓળખવામાં મદદ કરે છે.';

  @override
  String get partsChartDescription =>
      'આ પાઇ ચાર્ટ સાથે તમારું વાંચન પુસ્તકના વિવિધ ભાગોમાં કેવી રીતે વિતરિત થયું છે તે જુઓ. ભાગ પ્રમાણે તમારા વાંચન સત્રોનું ટકાવારી વિભાજન દર્શાવે છે.';

  @override
  String get durationChartDescription =>
      'આ બાર ચાર્ટ સાથે તમારા વાંચન સત્રની લંબાઈનું વિશ્લેષણ કરો. તમારા સ્ટેમિના પેટર્નને સમજવામાં મદદ કરવા માટે સત્રોને સમયગાળાની શ્રેણીઓ અનુસાર જૂથબદ્ધ કરે છે.';

  @override
  String get settings_saved => 'સેટિંગ્સ સફળતાપૂર્વક સાચવવામાં આવી';

  @override
  String get changes_discarded => 'બદલાવ રદ કરવામાં આવ્યા';

  @override
  String get unsaved_changes => 'સેવ ન કરેલા બદલાવ';

  @override
  String get unsaved_changes_message =>
      'તમારા પાસે સેવ ન કરેલા બદલાવ છે. તમે શું કરવા માંગો છો?';

  @override
  String get discard => 'રદ કરો';

  @override
  String get save => 'સેવ કરો';

  @override
  String get you_have_unsaved_changes => 'તમારા પાસે સેવ ન કરેલા બદલાવ છે';

  @override
  String get discard_changes => 'બદલાવ રદ કરો';

  @override
  String get save_settings => 'સેટિંગ્સ સેવ કરો';

  @override
  String get reading_plans => 'વાંચન યોજનાઓ';

  @override
  String get reading_plans_today => 'આજે';

  @override
  String get reading_plans_my_plans => 'યોજનાઓ';

  @override
  String get reading_plans_progress => 'પ્રગતિ';

  @override
  String get today_goal_achieved => 'આજનું લક્ષ્ય પૂર્ણ થયું!';

  @override
  String get today_progress => 'આજની પ્રગતિ';

  @override
  String get reading_time => 'વાંચન સમય';

  @override
  String get completed => 'પૂર્ણ થયું';

  @override
  String get kirans => 'કિરણો';

  @override
  String get quick_actions => 'ઝડપી ક્રિયાઓ';

  @override
  String get start_reading => 'વાંચન શરૂ કરો';

  @override
  String get edit_plan => 'યોજના સંપાદિત કરો';

  @override
  String get test_reminder => 'રિમાઇન્ડર ચકાસો';

  @override
  String get your_statistics => 'તમારા આંકડા';

  @override
  String get streak => 'સતત દિવસો';

  @override
  String get days => 'દિવસો';

  @override
  String get this_week => 'આ અઠવાડિયે';

  @override
  String get goals => 'લક્ષ્યો';

  @override
  String get total_time => 'કુલ સમય';

  @override
  String get minutes => 'મિનિટ';

  @override
  String get excellent_work_today =>
      'આજે ઉત્કૃષ્ટ કાર્ય! તમે એક શક્તિશાળી આધ્યાત્મિક આદત બનાવી રહ્યા છો. 🌟';

  @override
  String on_fire_streak(int streak) {
    return 'તમે આગમાં છો! $streak દિવસની શ્રેણી. ગતિ જાળવી રાખો! 🔥';
  }

  @override
  String get great_start =>
      'શાનદાર શરૂઆત! આધ્યાત્મિક વાંચનની દરેક મિનિટ મહત્વની છે. 📚';

  @override
  String get ready_to_start =>
      'આજની આધ્યાત્મિક યાત્રા શરૂ કરવા તૈયાર છો? તમારું જ્ઞાન રાહ જોઈ રહ્યું છે! ✨';

  @override
  String get already_active => 'પહેલેથી સક્રિય';

  @override
  String get set_as_active => 'સક્રિય તરીકે સેટ કરો';

  @override
  String get reading_plans_edit => 'સંપાદિત કરો';

  @override
  String get reading_plans_delete => 'ડિલીટ કરો';

  @override
  String get last_30_days_progress => 'છેલ્લા ૩૦ દિવસની પ્રગતિ';

  @override
  String get progress_calendar => 'પ્રગતિ કૅલેન્ડર';

  @override
  String get goal_achieved => 'લક્ષ્ય પૂર્ણ';

  @override
  String get partial => 'આંશિક';

  @override
  String get started => 'શરૂ થયું';

  @override
  String get no_activity => 'કોઈ પ્રવૃત્તિ નથી';

  @override
  String get no_reading_plan => 'કોઈ વાંચન યોજના નથી';

  @override
  String get create_first_reading_plan =>
      'સતત આધ્યાત્મિક વાંચનની આદત બનાવવા માટે તમારી પ્રથમ વાંચન યોજના બનાવો.';

  @override
  String get create_reading_plan => 'વાંચન યોજના બનાવો';

  @override
  String get plan_details_coming_soon =>
      'યોજનાની વિગતો પૃષ્ઠ ટૂંક સમયમાં આવી રહ્યું છે!';

  @override
  String plan_now_active(String title) {
    return 'હવે તમારી યોજના \"$title\" સક્રિય છે';
  }

  @override
  String get delete_reading_plan => 'વાંચન યોજના ડિલીટ કરો';

  @override
  String confirm_delete_plan(String title) {
    return 'શું તમે ખરેખર \"$title\" ને ડિલીટ કરવા માંગો છો? આ પૂર્વવત્ કરી શકાતું નથી.';
  }

  @override
  String get reading_plans_cancel => 'રદ કરો';

  @override
  String get reading_plan_deleted => 'વાંચન યોજના ડિલીટ કરવામાં આવી';

  @override
  String get test_reminder_sent => 'ટેસ્ટ રિમાઇન્ડર મોકલવામાં આવ્યું!';

  @override
  String day_streak(int days) {
    return '$days દિવસની શ્રેણી';
  }

  @override
  String min_per_day(int minutes) {
    return '$minutes મિનિટ/દિવસ';
  }

  @override
  String kirans_target(int count) {
    return '$count કિરણો';
  }

  @override
  String get create_plan_title => 'વાંચન યોજના બનાવો';

  @override
  String get edit_plan_title => 'વાંચન યોજના સંપાદિત કરો';

  @override
  String get basic_information => 'મૂળભૂત માહિતી';

  @override
  String get plan_title => 'યોજનાનું શીર્ષક';

  @override
  String get plan_title_hint => 'જેમ કે, સવારનું આધ્યાત્મિક વાંચન';

  @override
  String get plan_title_error =>
      'કૃપા કરીને તમારી યોજના માટે એક શીર્ષક દાખલ કરો';

  @override
  String get description_optional => 'વર્ણન (વૈકલ્પિક)';

  @override
  String get description_hint => 'તમારી વાંચન યોજનાનું ટૂંકું વર્ણન';

  @override
  String get daily_goals => 'દૈનિક લક્ષ્યો';

  @override
  String get reading_time_goal => 'વાંચન સમયનું લક્ષ્ય';

  @override
  String get create_plan_minutes => 'મિનિટ';

  @override
  String get kirans_to_complete => 'પૂર્ણ કરવાના કિરણો';

  @override
  String get daily_goals_recommendation =>
      'ભલામણ: ટૂંકા લક્ષ્યોથી શરૂ કરો અને ધીમે ધીમે વધારો';

  @override
  String get create_plan_reminders => 'રિમાઇન્ડર';

  @override
  String get enable_daily_reminders => 'દૈનિક રિમાઇન્ડર ચાલુ/બંધ કરો';

  @override
  String get reminder_time => 'રિમાઇન્ડર સમય';

  @override
  String daily_reminder_at(String time) {
    return 'દરરોજ $time વાગ્યે રિમાઇન્ડર';
  }

  @override
  String get no_reminders_set => 'કોઈ રિમાઇન્ડર સેટ નથી';

  @override
  String get plan_preview => 'યોજનાનું પૂર્વાવલોકન';

  @override
  String get daily_reading => 'દૈનિક વાંચન';

  @override
  String get preview_kirans => 'કિરણો';

  @override
  String get reminders_on => 'ચાલુ';

  @override
  String get reminders_off => 'બંધ';

  @override
  String minutes_format(int minutes) {
    return '$minutes મિનિટ';
  }

  @override
  String get create_plan_cancel => 'રદ કરો';

  @override
  String get update_plan => 'યોજના અપડેટ કરો';

  @override
  String get create_plan => 'યોજના બનાવો';

  @override
  String get select_reminder_time => 'રિમાઇન્ડર સમય પસંદ કરો';

  @override
  String get time_picker_cancel => 'રદ કરો';

  @override
  String get time_picker_save => 'સેવ કરો';

  @override
  String get plan_updated_success =>
      'વાંચન યોજના સફળતાપૂર્વક અપડેટ કરવામાં આવી!';

  @override
  String get plan_created_success => 'વાંચન યોજના સફળતાપૂર્વક બનાવવામાં આવી!';

  @override
  String plan_save_error(String error) {
    return 'યોજના સેવ કરવામાં ભૂલ: $error';
  }

  @override
  String get reminders_enabled_subtitle =>
      'તમારી વાંચનની આદત જાળવવા માટે નોટિફિકેશન મેળવો';

  @override
  String get reminders_disabled_subtitle => 'કોઈ રિમાઇન્ડર મોકલવામાં આવશે નહીં';

  @override
  String get quotes_image_generator => 'સુવિચાર બનાવો';

  @override
  String get inspirational_quotes => 'પ્રેરણાદાયક સુવિચાર';

  @override
  String get create_share_quotes => 'સુંદર સુવિચાર છબીઓ બનાવો અને શેર કરો';

  @override
  String get quote_text => 'સુવિચાર લખાણ';

  @override
  String get enter_quote => 'તમારું પ્રેરણાદાયક સુવિચાર દાખલ કરો';

  @override
  String get quote_font_size => 'ફોન્ટ સાઇઝ';

  @override
  String get background_color => 'પૃષ્ઠભૂમિ રંગ';

  @override
  String get text_color => 'લખાણ રંગ';

  @override
  String get template => 'ટેમ્પલેટ';

  @override
  String get gradient => 'ગ્રેડિઅન્ટ';

  @override
  String get solid => 'સોલિડ';

  @override
  String get geometric => 'ભૌમિતિક';

  @override
  String get simple => 'સરળ';

  @override
  String get elegant => 'ભવ્ય';

  @override
  String get modern => 'આધુનિક';

  @override
  String get share_quote => 'સુવિચાર શેર કરો';

  @override
  String get save_quote => 'સુવિચાર સેવ કરો';

  @override
  String get random_quote => 'રેન્ડમ સુવિચાર';

  @override
  String get image_saved => 'ગેલરીમાં સુવિચાર સેવ થયો.';

  @override
  String error_saving_image(String error) {
    return 'સુવિચાર સેવ કરવામાં ભૂલ: $error';
  }

  @override
  String get create_quote_image => 'સુવિચાર બનાવો';

  @override
  String get quote_content => 'સુવિચાર સામગ્રી';

  @override
  String get author => 'લેખક';

  @override
  String get quote_author_hint => 'સુવિચારનો લેખક અથવા સ્ત્રોત';

  @override
  String get enter_author => 'લેખક અથવા સ્ત્રોત દાખલ કરો';

  @override
  String get customization => 'કસ્ટમાઇઝેશન';

  @override
  String get template_style => 'ટેમ્પલેટ શૈલી';

  @override
  String get background => 'પૃષ્ઠભૂમિ';
}
