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
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('gu'),
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

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @reading_history.
  ///
  /// In en, this message translates to:
  /// **'Reading History'**
  String get reading_history;

  /// No description provided for @reading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get reading;

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
  /// **'Application Language'**
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

  /// No description provided for @tag_line.
  ///
  /// In en, this message translates to:
  /// **'।। વિચાર કરો તો ખબર પડે ।।'**
  String get tag_line;

  /// No description provided for @kiran.
  ///
  /// In en, this message translates to:
  /// **'Kiran'**
  String get kiran;

  /// No description provided for @font_size.
  ///
  /// In en, this message translates to:
  /// **'Font Size'**
  String get font_size;

  /// No description provided for @line_height.
  ///
  /// In en, this message translates to:
  /// **'Line Height'**
  String get line_height;

  /// No description provided for @theme_color.
  ///
  /// In en, this message translates to:
  /// **'Theme Color'**
  String get theme_color;

  /// No description provided for @theme_variant.
  ///
  /// In en, this message translates to:
  /// **'Theme Variant'**
  String get theme_variant;

  /// No description provided for @theme_mode.
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get theme_mode;

  /// No description provided for @theme_contrast.
  ///
  /// In en, this message translates to:
  /// **'Theme Contrast'**
  String get theme_contrast;

  /// No description provided for @reading_speed.
  ///
  /// In en, this message translates to:
  /// **'Reading Speed'**
  String get reading_speed;

  /// No description provided for @select_language.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get select_language;

  /// Indicates how many times the user has read a particular item.
  ///
  /// In en, this message translates to:
  /// **'Read {count} times'**
  String reading_count(int count);

  /// No description provided for @kiran_read_finished.
  ///
  /// In en, this message translates to:
  /// **'Read the kiran'**
  String get kiran_read_finished;

  /// No description provided for @not_yet_read.
  ///
  /// In en, this message translates to:
  /// **'Not yet read'**
  String get not_yet_read;

  /// Indicates the last date the user read a particular item.
  ///
  /// In en, this message translates to:
  /// **'{time},{date}'**
  String last_read(DateTime time, DateTime date);

  /// Indicates the format for displaying time.
  ///
  /// In en, this message translates to:
  /// **'{time}'**
  String time_format(DateTime time);

  /// Indicates the estimated time to read a particular item.
  ///
  /// In en, this message translates to:
  /// **'{time}'**
  String time_to_read(String time);

  /// No description provided for @words_per_minute.
  ///
  /// In en, this message translates to:
  /// **'words per min'**
  String get words_per_minute;

  /// No description provided for @header_slok.
  ///
  /// In en, this message translates to:
  /// **'।। શ્રી સ્વામિનારાયણો વિજયતેતરામ્‌ ।।\n\nશ્રી સહજાનંદ સંસ્કારધામ\nમહામંત્રપીઠ - ફરેણી'**
  String get header_slok;

  /// No description provided for @search_kiranas.
  ///
  /// In en, this message translates to:
  /// **'Search kiranas by title or content...'**
  String get search_kiranas;

  /// No description provided for @search_all_kiranas.
  ///
  /// In en, this message translates to:
  /// **'Search through all Kirans'**
  String get search_all_kiranas;

  /// No description provided for @enter_keywords.
  ///
  /// In en, this message translates to:
  /// **'Enter keywords to find relevant content'**
  String get enter_keywords;

  /// No description provided for @no_results_found.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get no_results_found;

  /// No description provided for @try_different_keywords.
  ///
  /// In en, this message translates to:
  /// **'Try different keywords or check spelling'**
  String get try_different_keywords;

  /// Number of search results
  ///
  /// In en, this message translates to:
  /// **'{count} results found'**
  String results_found(int count);

  /// No description provided for @search_min_chars.
  ///
  /// In en, this message translates to:
  /// **'Enter at least 2 characters to search'**
  String get search_min_chars;

  /// No description provided for @content_match.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get content_match;

  /// No description provided for @title_match.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title_match;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @clear_all_filters.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clear_all_filters;

  /// No description provided for @match_type.
  ///
  /// In en, this message translates to:
  /// **'Match Type'**
  String get match_type;

  /// No description provided for @book_parts.
  ///
  /// In en, this message translates to:
  /// **'Book Parts'**
  String get book_parts;

  /// No description provided for @no_filtered_results.
  ///
  /// In en, this message translates to:
  /// **'No results match current filters'**
  String get no_filtered_results;

  /// No description provided for @adjust_filters.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your filter settings'**
  String get adjust_filters;

  /// Shows filtered vs total results
  ///
  /// In en, this message translates to:
  /// **'{filtered} of {total} results shown'**
  String results_filtered(int filtered, int total);

  /// No description provided for @expand_filters.
  ///
  /// In en, this message translates to:
  /// **'Expand Filters'**
  String get expand_filters;

  /// No description provided for @collapse_filters.
  ///
  /// In en, this message translates to:
  /// **'Collapse Filters'**
  String get collapse_filters;

  /// No description provided for @search_hint.
  ///
  /// In en, this message translates to:
  /// **'Search in this kiran... (Enter: search)'**
  String get search_hint;

  /// No description provided for @no_match_found.
  ///
  /// In en, this message translates to:
  /// **'No matches found'**
  String get no_match_found;

  /// No description provided for @search_in_kiran.
  ///
  /// In en, this message translates to:
  /// **'Search in Kiran'**
  String get search_in_kiran;

  /// No description provided for @close_search.
  ///
  /// In en, this message translates to:
  /// **'Close Search'**
  String get close_search;

  /// No description provided for @edit_notes.
  ///
  /// In en, this message translates to:
  /// **'Edit Notes'**
  String get edit_notes;

  /// No description provided for @save_notes.
  ///
  /// In en, this message translates to:
  /// **'Save Notes'**
  String get save_notes;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @add_notes.
  ///
  /// In en, this message translates to:
  /// **'Add Notes'**
  String get add_notes;

  /// No description provided for @notes_hint.
  ///
  /// In en, this message translates to:
  /// **'Add your personal notes here...'**
  String get notes_hint;

  /// No description provided for @notesSaved.
  ///
  /// In en, this message translates to:
  /// **'Notes saved successfully'**
  String get notesSaved;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @deleteNoteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this note?'**
  String get deleteNoteConfirm;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @noteDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Note deleted successfully'**
  String get noteDeletedSuccess;

  /// No description provided for @errorDeletingNote.
  ///
  /// In en, this message translates to:
  /// **'Error deleting note: {error}'**
  String errorDeletingNote(String error);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days} days ago'**
  String daysAgo(int days);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours} hours ago'**
  String hoursAgo(int hours);

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes ago'**
  String minutesAgo(int minutes);

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// No description provided for @lastModified.
  ///
  /// In en, this message translates to:
  /// **'Last Modified'**
  String get lastModified;

  /// No description provided for @searchNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Search notes and titles...'**
  String get searchNotesHint;

  /// No description provided for @notesCount.
  ///
  /// In en, this message translates to:
  /// **'{filtered} of {total} notes'**
  String notesCount(int filtered, int total);

  /// No description provided for @sortedBy.
  ///
  /// In en, this message translates to:
  /// **'Sorted by {sortName} {direction}'**
  String sortedBy(String sortName, String direction);

  /// No description provided for @noNotesFound.
  ///
  /// In en, this message translates to:
  /// **'No Notes Found'**
  String get noNotesFound;

  /// No description provided for @startTakingNotes.
  ///
  /// In en, this message translates to:
  /// **'Start taking notes while reading Kiranas'**
  String get startTakingNotes;

  /// No description provided for @noMatchingNotes.
  ///
  /// In en, this message translates to:
  /// **'No matching notes'**
  String get noMatchingNotes;

  /// No description provided for @characters.
  ///
  /// In en, this message translates to:
  /// **'characters'**
  String get characters;

  /// No description provided for @tapToEdit.
  ///
  /// In en, this message translates to:
  /// **'Tap to edit'**
  String get tapToEdit;

  /// No description provided for @adjustSearchFilters.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search or filters'**
  String get adjustSearchFilters;

  /// No description provided for @editNote.
  ///
  /// In en, this message translates to:
  /// **'Edit Note'**
  String get editNote;

  /// No description provided for @viewKiran.
  ///
  /// In en, this message translates to:
  /// **'View Kiran'**
  String get viewKiran;

  /// No description provided for @deleteNote.
  ///
  /// In en, this message translates to:
  /// **'Delete Note'**
  String get deleteNote;

  /// No description provided for @bookPart.
  ///
  /// In en, this message translates to:
  /// **'Book Part'**
  String get bookPart;

  /// No description provided for @noteLength.
  ///
  /// In en, this message translates to:
  /// **'Note Length'**
  String get noteLength;

  /// No description provided for @bookParts.
  ///
  /// In en, this message translates to:
  /// **'Book Parts:'**
  String get bookParts;

  /// No description provided for @favorite.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get favorite;

  /// No description provided for @favoriteKiranSuccess.
  ///
  /// In en, this message translates to:
  /// **'Kiran favorited successfully'**
  String get favoriteKiranSuccess;

  /// No description provided for @readingHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Reading History'**
  String get readingHistoryTitle;

  /// No description provided for @totalReadingTime.
  ///
  /// In en, this message translates to:
  /// **'Total Reading Time'**
  String get totalReadingTime;

  /// No description provided for @readingSessions.
  ///
  /// In en, this message translates to:
  /// **'Reading Sessions'**
  String get readingSessions;

  /// No description provided for @noReadingHistory.
  ///
  /// In en, this message translates to:
  /// **'No Reading History'**
  String get noReadingHistory;

  /// No description provided for @startReadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Start reading Kiranas to track your progress'**
  String get startReadingMessage;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @older.
  ///
  /// In en, this message translates to:
  /// **'Older'**
  String get older;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @readingSession.
  ///
  /// In en, this message translates to:
  /// **'Reading Session'**
  String get readingSession;

  /// No description provided for @filterByCategory.
  ///
  /// In en, this message translates to:
  /// **'Filter by Category'**
  String get filterByCategory;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get allCategories;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get clearFilters;

  /// No description provided for @expandAll.
  ///
  /// In en, this message translates to:
  /// **'Expand All'**
  String get expandAll;

  /// No description provided for @collapseAll.
  ///
  /// In en, this message translates to:
  /// **'Collapse All'**
  String get collapseAll;

  /// No description provided for @filterByDate.
  ///
  /// In en, this message translates to:
  /// **'Filter by Date'**
  String get filterByDate;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get year;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month;

  /// No description provided for @allYears.
  ///
  /// In en, this message translates to:
  /// **'All Years'**
  String get allYears;

  /// No description provided for @allMonths.
  ///
  /// In en, this message translates to:
  /// **'All Months'**
  String get allMonths;

  /// No description provided for @january.
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get january;

  /// No description provided for @february.
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get february;

  /// No description provided for @march.
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get march;

  /// No description provided for @april.
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get april;

  /// No description provided for @may.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get may;

  /// No description provided for @june.
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get june;

  /// No description provided for @july.
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get july;

  /// No description provided for @august.
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get august;

  /// No description provided for @september.
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get september;

  /// No description provided for @october.
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get october;

  /// No description provided for @november.
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get november;

  /// No description provided for @december.
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get december;

  /// No description provided for @analytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analytics;

  /// No description provided for @dailyChart.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get dailyChart;

  /// No description provided for @weeklyChart.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weeklyChart;

  /// No description provided for @partsChart.
  ///
  /// In en, this message translates to:
  /// **'Parts'**
  String get partsChart;

  /// No description provided for @durationChart.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get durationChart;

  /// No description provided for @dailyReadingMinutes.
  ///
  /// In en, this message translates to:
  /// **'Daily Reading Minutes'**
  String get dailyReadingMinutes;

  /// No description provided for @weeklyReadingHours.
  ///
  /// In en, this message translates to:
  /// **'Weekly Reading Hours'**
  String get weeklyReadingHours;

  /// No description provided for @readingDistributionByParts.
  ///
  /// In en, this message translates to:
  /// **'Reading Distribution by Parts'**
  String get readingDistributionByParts;

  /// No description provided for @readingSessionDurationAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Reading Session Duration Analysis'**
  String get readingSessionDurationAnalysis;

  /// No description provided for @noAnalyticsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No Analytics Available'**
  String get noAnalyticsAvailable;

  /// No description provided for @startReadingForAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Start reading to see your analytics and insights.'**
  String get startReadingForAnalytics;

  /// No description provided for @chartMinutesLabel.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get chartMinutesLabel;

  /// No description provided for @chartHoursLabel.
  ///
  /// In en, this message translates to:
  /// **'hours'**
  String get chartHoursLabel;

  /// No description provided for @chartSessionsLabel.
  ///
  /// In en, this message translates to:
  /// **'sessions'**
  String get chartSessionsLabel;

  /// No description provided for @dailyChartDescription.
  ///
  /// In en, this message translates to:
  /// **'Track your daily reading habits with this line chart showing minutes read per day over the last 30 days. Peaks indicate your most productive reading days.'**
  String get dailyChartDescription;

  /// No description provided for @weeklyChartDescription.
  ///
  /// In en, this message translates to:
  /// **'View your weekly reading patterns with this bar chart displaying total hours read per week over the last 12 weeks. Helps identify consistent reading periods.'**
  String get weeklyChartDescription;

  /// No description provided for @partsChartDescription.
  ///
  /// In en, this message translates to:
  /// **'See how your reading is distributed across different parts of the book with this pie chart. Shows the percentage breakdown of your reading sessions by part.'**
  String get partsChartDescription;

  /// No description provided for @durationChartDescription.
  ///
  /// In en, this message translates to:
  /// **'Analyze your reading session lengths with this bar chart. Groups your sessions by duration ranges to help you understand your reading stamina patterns.'**
  String get durationChartDescription;

  /// No description provided for @settings_saved.
  ///
  /// In en, this message translates to:
  /// **'ettings saved successfully'**
  String get settings_saved;

  /// No description provided for @changes_discarded.
  ///
  /// In en, this message translates to:
  /// **'Changes discarded'**
  String get changes_discarded;

  /// No description provided for @unsaved_changes.
  ///
  /// In en, this message translates to:
  /// **'Unsaved Changes'**
  String get unsaved_changes;

  /// No description provided for @unsaved_changes_message.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. What would you like to do?'**
  String get unsaved_changes_message;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @you_have_unsaved_changes.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes'**
  String get you_have_unsaved_changes;

  /// No description provided for @discard_changes.
  ///
  /// In en, this message translates to:
  /// **'Discard Changes'**
  String get discard_changes;

  /// No description provided for @save_settings.
  ///
  /// In en, this message translates to:
  /// **'Save Settings'**
  String get save_settings;

  /// No description provided for @reading_plans.
  ///
  /// In en, this message translates to:
  /// **'Reading Plans'**
  String get reading_plans;

  /// No description provided for @reading_plans_today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get reading_plans_today;

  /// No description provided for @reading_plans_my_plans.
  ///
  /// In en, this message translates to:
  /// **'My Plans'**
  String get reading_plans_my_plans;

  /// No description provided for @reading_plans_progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get reading_plans_progress;

  /// No description provided for @today_goal_achieved.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Goal Achieved!'**
  String get today_goal_achieved;

  /// No description provided for @today_progress.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Progress'**
  String get today_progress;

  /// No description provided for @reading_time.
  ///
  /// In en, this message translates to:
  /// **'Reading Time'**
  String get reading_time;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @kirans.
  ///
  /// In en, this message translates to:
  /// **'Kirans'**
  String get kirans;

  /// No description provided for @quick_actions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quick_actions;

  /// No description provided for @start_reading.
  ///
  /// In en, this message translates to:
  /// **'Start Reading'**
  String get start_reading;

  /// No description provided for @edit_plan.
  ///
  /// In en, this message translates to:
  /// **'Edit Plan'**
  String get edit_plan;

  /// No description provided for @test_reminder.
  ///
  /// In en, this message translates to:
  /// **'Test Reminder'**
  String get test_reminder;

  /// No description provided for @your_statistics.
  ///
  /// In en, this message translates to:
  /// **'Your Statistics'**
  String get your_statistics;

  /// No description provided for @streak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get streak;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// No description provided for @this_week.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get this_week;

  /// No description provided for @goals.
  ///
  /// In en, this message translates to:
  /// **'goals'**
  String get goals;

  /// No description provided for @total_time.
  ///
  /// In en, this message translates to:
  /// **'Total Time'**
  String get total_time;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get minutes;

  /// No description provided for @excellent_work_today.
  ///
  /// In en, this message translates to:
  /// **'Excellent work today! You\'re building a powerful spiritual habit. 🌟'**
  String get excellent_work_today;

  /// Message when user has a long streak
  ///
  /// In en, this message translates to:
  /// **'You\'re on fire! {streak} days streak. Keep the momentum going! 🔥'**
  String on_fire_streak(int streak);

  /// No description provided for @great_start.
  ///
  /// In en, this message translates to:
  /// **'Great start! Every minute of spiritual reading counts. 📚'**
  String get great_start;

  /// No description provided for @ready_to_start.
  ///
  /// In en, this message translates to:
  /// **'Ready to start today\'s spiritual journey? Your wisdom awaits! ✨'**
  String get ready_to_start;

  /// No description provided for @already_active.
  ///
  /// In en, this message translates to:
  /// **'Already Active'**
  String get already_active;

  /// No description provided for @set_as_active.
  ///
  /// In en, this message translates to:
  /// **'Set as Active'**
  String get set_as_active;

  /// No description provided for @reading_plans_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get reading_plans_edit;

  /// No description provided for @reading_plans_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get reading_plans_delete;

  /// No description provided for @last_30_days_progress.
  ///
  /// In en, this message translates to:
  /// **'Last 30 Days Progress'**
  String get last_30_days_progress;

  /// No description provided for @progress_calendar.
  ///
  /// In en, this message translates to:
  /// **'Progress Calendar'**
  String get progress_calendar;

  /// No description provided for @goal_achieved.
  ///
  /// In en, this message translates to:
  /// **'Goal Achieved'**
  String get goal_achieved;

  /// No description provided for @partial.
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get partial;

  /// No description provided for @started.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get started;

  /// No description provided for @no_activity.
  ///
  /// In en, this message translates to:
  /// **'No Activity'**
  String get no_activity;

  /// No description provided for @no_reading_plan.
  ///
  /// In en, this message translates to:
  /// **'No Reading Plan'**
  String get no_reading_plan;

  /// No description provided for @create_first_reading_plan.
  ///
  /// In en, this message translates to:
  /// **'Create your first reading plan to start building a consistent spiritual reading habit.'**
  String get create_first_reading_plan;

  /// No description provided for @create_reading_plan.
  ///
  /// In en, this message translates to:
  /// **'Create Reading Plan'**
  String get create_reading_plan;

  /// No description provided for @plan_details_coming_soon.
  ///
  /// In en, this message translates to:
  /// **'Plan details page coming soon!'**
  String get plan_details_coming_soon;

  /// Message when a plan is set as active
  ///
  /// In en, this message translates to:
  /// **'{title} is now your active plan'**
  String plan_now_active(String title);

  /// No description provided for @delete_reading_plan.
  ///
  /// In en, this message translates to:
  /// **'Delete Reading Plan'**
  String get delete_reading_plan;

  /// Confirmation message for deleting a plan
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{title}\"? This cannot be undone.'**
  String confirm_delete_plan(String title);

  /// No description provided for @reading_plans_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get reading_plans_cancel;

  /// No description provided for @reading_plan_deleted.
  ///
  /// In en, this message translates to:
  /// **'Reading plan deleted'**
  String get reading_plan_deleted;

  /// No description provided for @test_reminder_sent.
  ///
  /// In en, this message translates to:
  /// **'Test reminder sent!'**
  String get test_reminder_sent;

  /// Display streak in days
  ///
  /// In en, this message translates to:
  /// **'{days} day streak'**
  String day_streak(int days);

  /// Minutes per day target
  ///
  /// In en, this message translates to:
  /// **'{minutes} min/day'**
  String min_per_day(int minutes);

  /// Number of Kirans target
  ///
  /// In en, this message translates to:
  /// **'{count} Kirans'**
  String kirans_target(int count);

  /// No description provided for @create_plan_title.
  ///
  /// In en, this message translates to:
  /// **'Create Reading Plan'**
  String get create_plan_title;

  /// No description provided for @edit_plan_title.
  ///
  /// In en, this message translates to:
  /// **'Edit Reading Plan'**
  String get edit_plan_title;

  /// No description provided for @basic_information.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get basic_information;

  /// No description provided for @plan_title.
  ///
  /// In en, this message translates to:
  /// **'Plan Title'**
  String get plan_title;

  /// No description provided for @plan_title_hint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Morning Spiritual Reading'**
  String get plan_title_hint;

  /// No description provided for @plan_title_error.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title for your reading plan'**
  String get plan_title_error;

  /// No description provided for @description_optional.
  ///
  /// In en, this message translates to:
  /// **'Description (Optional)'**
  String get description_optional;

  /// No description provided for @description_hint.
  ///
  /// In en, this message translates to:
  /// **'Brief description of your reading plan'**
  String get description_hint;

  /// No description provided for @daily_goals.
  ///
  /// In en, this message translates to:
  /// **'Daily Goals'**
  String get daily_goals;

  /// No description provided for @reading_time_goal.
  ///
  /// In en, this message translates to:
  /// **'Reading Time Goal'**
  String get reading_time_goal;

  /// No description provided for @create_plan_minutes.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get create_plan_minutes;

  /// No description provided for @kirans_to_complete.
  ///
  /// In en, this message translates to:
  /// **'Kirans to Complete'**
  String get kirans_to_complete;

  /// No description provided for @daily_goals_recommendation.
  ///
  /// In en, this message translates to:
  /// **'Recommended: Start with shorter goals and gradually increase'**
  String get daily_goals_recommendation;

  /// No description provided for @create_plan_reminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get create_plan_reminders;

  /// No description provided for @enable_daily_reminders.
  ///
  /// In en, this message translates to:
  /// **'Enable Daily Reminders'**
  String get enable_daily_reminders;

  /// No description provided for @reminder_time.
  ///
  /// In en, this message translates to:
  /// **'Reminder Time'**
  String get reminder_time;

  /// Shows when daily reminder is set
  ///
  /// In en, this message translates to:
  /// **'Daily reminder at {time}'**
  String daily_reminder_at(String time);

  /// No description provided for @no_reminders_set.
  ///
  /// In en, this message translates to:
  /// **'No reminders set'**
  String get no_reminders_set;

  /// No description provided for @plan_preview.
  ///
  /// In en, this message translates to:
  /// **'Plan Preview'**
  String get plan_preview;

  /// No description provided for @daily_reading.
  ///
  /// In en, this message translates to:
  /// **'Daily Reading'**
  String get daily_reading;

  /// No description provided for @preview_kirans.
  ///
  /// In en, this message translates to:
  /// **'Kirans'**
  String get preview_kirans;

  /// No description provided for @reminders_on.
  ///
  /// In en, this message translates to:
  /// **'ON'**
  String get reminders_on;

  /// No description provided for @reminders_off.
  ///
  /// In en, this message translates to:
  /// **'OFF'**
  String get reminders_off;

  /// Format for displaying minutes
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes'**
  String minutes_format(int minutes);

  /// No description provided for @create_plan_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get create_plan_cancel;

  /// No description provided for @update_plan.
  ///
  /// In en, this message translates to:
  /// **'Update Plan'**
  String get update_plan;

  /// No description provided for @create_plan.
  ///
  /// In en, this message translates to:
  /// **'Create Plan'**
  String get create_plan;

  /// No description provided for @select_reminder_time.
  ///
  /// In en, this message translates to:
  /// **'Select Reminder Time'**
  String get select_reminder_time;

  /// No description provided for @time_picker_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get time_picker_cancel;

  /// No description provided for @time_picker_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get time_picker_save;

  /// No description provided for @plan_updated_success.
  ///
  /// In en, this message translates to:
  /// **'Reading plan updated successfully!'**
  String get plan_updated_success;

  /// No description provided for @plan_created_success.
  ///
  /// In en, this message translates to:
  /// **'Reading plan created successfully!'**
  String get plan_created_success;

  /// Error message when saving plan fails
  ///
  /// In en, this message translates to:
  /// **'Error saving plan: {error}'**
  String plan_save_error(String error);

  /// No description provided for @reminders_enabled_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Get notified to maintain your reading habit'**
  String get reminders_enabled_subtitle;

  /// No description provided for @reminders_disabled_subtitle.
  ///
  /// In en, this message translates to:
  /// **'No reminders will be sent'**
  String get reminders_disabled_subtitle;

  /// No description provided for @quotes_image_generator.
  ///
  /// In en, this message translates to:
  /// **'Quotes Generator'**
  String get quotes_image_generator;

  /// No description provided for @inspirational_quotes.
  ///
  /// In en, this message translates to:
  /// **'Inspirational Quotes'**
  String get inspirational_quotes;

  /// No description provided for @create_share_quotes.
  ///
  /// In en, this message translates to:
  /// **'Create and share beautiful quote images'**
  String get create_share_quotes;

  /// No description provided for @quote_text.
  ///
  /// In en, this message translates to:
  /// **'Quote Text'**
  String get quote_text;

  /// No description provided for @enter_quote.
  ///
  /// In en, this message translates to:
  /// **'Enter your inspirational quote'**
  String get enter_quote;

  /// No description provided for @quote_font_size.
  ///
  /// In en, this message translates to:
  /// **'Font Size'**
  String get quote_font_size;

  /// No description provided for @background_color.
  ///
  /// In en, this message translates to:
  /// **'Background Color'**
  String get background_color;

  /// No description provided for @text_color.
  ///
  /// In en, this message translates to:
  /// **'Text Color'**
  String get text_color;

  /// No description provided for @template.
  ///
  /// In en, this message translates to:
  /// **'Template'**
  String get template;

  /// No description provided for @gradient.
  ///
  /// In en, this message translates to:
  /// **'Gradient'**
  String get gradient;

  /// No description provided for @solid.
  ///
  /// In en, this message translates to:
  /// **'Solid'**
  String get solid;

  /// No description provided for @geometric.
  ///
  /// In en, this message translates to:
  /// **'Geometric'**
  String get geometric;

  /// No description provided for @simple.
  ///
  /// In en, this message translates to:
  /// **'Simple'**
  String get simple;

  /// No description provided for @elegant.
  ///
  /// In en, this message translates to:
  /// **'Elegant'**
  String get elegant;

  /// No description provided for @modern.
  ///
  /// In en, this message translates to:
  /// **'Modern'**
  String get modern;

  /// No description provided for @share_quote.
  ///
  /// In en, this message translates to:
  /// **'Share Quote'**
  String get share_quote;

  /// No description provided for @save_quote.
  ///
  /// In en, this message translates to:
  /// **'Save Quote'**
  String get save_quote;

  /// No description provided for @random_quote.
  ///
  /// In en, this message translates to:
  /// **'Random Quote'**
  String get random_quote;

  /// No description provided for @image_saved.
  ///
  /// In en, this message translates to:
  /// **'Image saved to gallery'**
  String get image_saved;

  /// Error message when saving image fails
  ///
  /// In en, this message translates to:
  /// **'Error saving image: {error}'**
  String error_saving_image(String error);

  /// No description provided for @create_quote_image.
  ///
  /// In en, this message translates to:
  /// **'Create Quote'**
  String get create_quote_image;

  /// No description provided for @quote_content.
  ///
  /// In en, this message translates to:
  /// **'Quote Content'**
  String get quote_content;

  /// No description provided for @author.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get author;

  /// No description provided for @quote_author_hint.
  ///
  /// In en, this message translates to:
  /// **'Quote author or source'**
  String get quote_author_hint;

  /// No description provided for @enter_author.
  ///
  /// In en, this message translates to:
  /// **'Enter author or source'**
  String get enter_author;

  /// No description provided for @customization.
  ///
  /// In en, this message translates to:
  /// **'Customization'**
  String get customization;

  /// No description provided for @template_style.
  ///
  /// In en, this message translates to:
  /// **'Template Style'**
  String get template_style;

  /// No description provided for @background.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get background;

  /// No description provided for @reading_preferences.
  ///
  /// In en, this message translates to:
  /// **'Reading Preferences'**
  String get reading_preferences;

  /// No description provided for @theme_appearance.
  ///
  /// In en, this message translates to:
  /// **'Theme & Appearance'**
  String get theme_appearance;

  /// No description provided for @language_localization.
  ///
  /// In en, this message translates to:
  /// **'Language & Localization'**
  String get language_localization;

  /// No description provided for @light_mode_option.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light_mode_option;

  /// No description provided for @dark_mode_option.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark_mode_option;

  /// No description provided for @error_saving_settings.
  ///
  /// In en, this message translates to:
  /// **'Error saving settings'**
  String get error_saving_settings;

  /// No description provided for @language_gujarati.
  ///
  /// In en, this message translates to:
  /// **'ગુજરાતી'**
  String get language_gujarati;

  /// No description provided for @language_english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get language_english;

  /// No description provided for @quote_preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get quote_preview;

  /// No description provided for @swipe_templates.
  ///
  /// In en, this message translates to:
  /// **'Swipe to see all templates →'**
  String get swipe_templates;

  /// No description provided for @spiritual_seeker.
  ///
  /// In en, this message translates to:
  /// **'Spiritual Seeker'**
  String get spiritual_seeker;

  /// No description provided for @devotee_of_sakshat_savita.
  ///
  /// In en, this message translates to:
  /// **'Devotee of Sakshat Savita'**
  String get devotee_of_sakshat_savita;

  /// No description provided for @tab_colors.
  ///
  /// In en, this message translates to:
  /// **'Colors'**
  String get tab_colors;

  /// No description provided for @tab_font_size.
  ///
  /// In en, this message translates to:
  /// **'Font'**
  String get tab_font_size;

  /// No description provided for @tab_image_size.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get tab_image_size;

  /// No description provided for @tab_user_info.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get tab_user_info;

  /// No description provided for @sign_in_to_show_profile.
  ///
  /// In en, this message translates to:
  /// **'Sign in to show your profile info'**
  String get sign_in_to_show_profile;

  /// No description provided for @show_avatar.
  ///
  /// In en, this message translates to:
  /// **'Show Avatar'**
  String get show_avatar;

  /// No description provided for @show_name.
  ///
  /// In en, this message translates to:
  /// **'Show Name'**
  String get show_name;

  /// No description provided for @predefined_quotes.
  ///
  /// In en, this message translates to:
  /// **'Predefined Spiritual Quotes'**
  String get predefined_quotes;

  /// No description provided for @quote_font.
  ///
  /// In en, this message translates to:
  /// **'Quote'**
  String get quote_font;

  /// No description provided for @author_font.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get author_font;

  /// No description provided for @height_label.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get height_label;

  /// No description provided for @width_label.
  ///
  /// In en, this message translates to:
  /// **'Width'**
  String get width_label;

  /// No description provided for @part_label.
  ///
  /// In en, this message translates to:
  /// **'Part'**
  String get part_label;

  /// No description provided for @kiran_label.
  ///
  /// In en, this message translates to:
  /// **'Kiran'**
  String get kiran_label;

  /// No description provided for @sharing_spiritual_wisdom.
  ///
  /// In en, this message translates to:
  /// **'Sharing Spiritual Wisdom'**
  String get sharing_spiritual_wisdom;

  /// No description provided for @shared_spiritual_thought.
  ///
  /// In en, this message translates to:
  /// **'shared a spiritual thought'**
  String get shared_spiritual_thought;

  /// No description provided for @error_sharing_image.
  ///
  /// In en, this message translates to:
  /// **'Error sharing image'**
  String get error_sharing_image;

  /// No description provided for @share_text.
  ///
  /// In en, this message translates to:
  /// **'Inspirational quote generated with Sakshat Savita app'**
  String get share_text;

  /// No description provided for @album_name.
  ///
  /// In en, this message translates to:
  /// **'Sakshat Savita Quotes'**
  String get album_name;

  /// No description provided for @predefined_quote_1.
  ///
  /// In en, this message translates to:
  /// **'🙏 Connecting with the soul is life\'s greatest achievement.'**
  String get predefined_quote_1;

  /// No description provided for @predefined_quote_2.
  ///
  /// In en, this message translates to:
  /// **'📖 Daily spiritual reading brings light to your life.'**
  String get predefined_quote_2;

  /// No description provided for @predefined_quote_3.
  ///
  /// In en, this message translates to:
  /// **'✨ Peace comes not from outside, but from within.'**
  String get predefined_quote_3;

  /// No description provided for @predefined_quote_4.
  ///
  /// In en, this message translates to:
  /// **'🌅 Every new day is an opportunity for spiritual growth.'**
  String get predefined_quote_4;

  /// No description provided for @predefined_quote_5.
  ///
  /// In en, this message translates to:
  /// **'💫 Truth, love and compassion - these three are the foundation of life.'**
  String get predefined_quote_5;

  /// No description provided for @jogi_swami.
  ///
  /// In en, this message translates to:
  /// **'પ.પૂ.પ્ર.બ્ર.સ્વ. સદ્. જોગીસ્વામી\nશ્રી ધર્મપ્રસાદદાસજી સ્વામી'**
  String get jogi_swami;

  /// No description provided for @shastri_swami.
  ///
  /// In en, this message translates to:
  /// **'વચનામૃત મર્મજ્ઞ પ.પૂ. સદ્. શાસ્ત્રી\nશ્રી બાલકૃષ્ણદાસજી સ્વામી'**
  String get shastri_swami;

  /// No description provided for @below_target.
  ///
  /// In en, this message translates to:
  /// **'Below Target'**
  String get below_target;

  /// No description provided for @target_achieved.
  ///
  /// In en, this message translates to:
  /// **'Target Achieved'**
  String get target_achieved;

  /// No description provided for @reminder_6am.
  ///
  /// In en, this message translates to:
  /// **'🌅 Start your day with spiritual wisdom! Time for your {minutes}-minute reading.'**
  String reminder_6am(int minutes);

  /// No description provided for @reminder_7am.
  ///
  /// In en, this message translates to:
  /// **'☀️ Good morning! Begin today with {kirans} Kiran(s) from Saxat Savita.'**
  String reminder_7am(int kirans);

  /// No description provided for @reminder_8am.
  ///
  /// In en, this message translates to:
  /// **'🌤️ Morning reading time! Your daily spiritual journey awaits.'**
  String get reminder_8am;

  /// No description provided for @reminder_9am.
  ///
  /// In en, this message translates to:
  /// **'🌞 It\'s 9 AM - perfect time for your daily reading practice.'**
  String get reminder_9am;

  /// No description provided for @reminder_12pm.
  ///
  /// In en, this message translates to:
  /// **'🌤️ Midday spiritual break! Take {minutes} minutes for inner peace.'**
  String reminder_12pm(int minutes);

  /// No description provided for @reminder_3pm.
  ///
  /// In en, this message translates to:
  /// **'🌤️ Afternoon reading session! Continue your spiritual growth.'**
  String get reminder_3pm;

  /// No description provided for @reminder_6pm.
  ///
  /// In en, this message translates to:
  /// **'🌇 Evening reading time! Reflect on today with spiritual wisdom.'**
  String get reminder_6pm;

  /// No description provided for @reminder_7pm.
  ///
  /// In en, this message translates to:
  /// **'🌆 Wind down with your evening reading. {kirans} Kiran(s) to go!'**
  String reminder_7pm(int kirans);

  /// No description provided for @reminder_8pm.
  ///
  /// In en, this message translates to:
  /// **'🌙 Evening spiritual time! Complete your daily reading goal.'**
  String get reminder_8pm;

  /// No description provided for @reminder_9pm.
  ///
  /// In en, this message translates to:
  /// **'✨ Before bed, nourish your soul with divine wisdom.'**
  String get reminder_9pm;

  /// No description provided for @reminder_default.
  ///
  /// In en, this message translates to:
  /// **'📖 Reading reminder! Don\'t forget your daily {minutes}-minute spiritual practice.'**
  String reminder_default(int minutes);

  /// No description provided for @read_now.
  ///
  /// In en, this message translates to:
  /// **'Read Now'**
  String get read_now;

  /// No description provided for @remind_later.
  ///
  /// In en, this message translates to:
  /// **'Remind Later'**
  String get remind_later;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @get_started.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get get_started;

  /// No description provided for @welcome_tour.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Sakshat Savita'**
  String get welcome_tour;

  /// No description provided for @welcome_spiritual_reading.
  ///
  /// In en, this message translates to:
  /// **'Dive into the divine wisdom of Sakshat Savita, a comprehensive collection of spiritual teachings that will guide your soul\'s journey.'**
  String get welcome_spiritual_reading;

  /// No description provided for @welcome_aashirvachan_desc.
  ///
  /// In en, this message translates to:
  /// **'Receive divine blessings and spiritual guidance through the sacred words of revered saints and spiritual masters.'**
  String get welcome_aashirvachan_desc;

  /// No description provided for @welcome_search_desc.
  ///
  /// In en, this message translates to:
  /// **'Quickly find specific teachings, verses, or topics with our powerful search feature that works across all content.'**
  String get welcome_search_desc;

  /// No description provided for @welcome_notes_desc.
  ///
  /// In en, this message translates to:
  /// **'Capture your spiritual insights and create personal notes to enhance your learning and meditation practice.'**
  String get welcome_notes_desc;

  /// No description provided for @welcome_reading_plans_desc.
  ///
  /// In en, this message translates to:
  /// **'Set personalized reading goals and track your progress through structured spiritual learning plans.'**
  String get welcome_reading_plans_desc;

  /// No description provided for @welcome_reading_history_desc.
  ///
  /// In en, this message translates to:
  /// **'Keep track of your spiritual journey with detailed reading history and personal milestones.'**
  String get welcome_reading_history_desc;

  /// No description provided for @welcome_quotes_generator_desc.
  ///
  /// In en, this message translates to:
  /// **'Create beautiful, shareable quote images from inspiring spiritual texts to spread wisdom and positivity.'**
  String get welcome_quotes_generator_desc;

  /// No description provided for @welcome_information_desc.
  ///
  /// In en, this message translates to:
  /// **'Access detailed information about spiritual practices, traditions, and the profound teachings within.'**
  String get welcome_information_desc;

  /// No description provided for @welcome_feature_spiritual_texts.
  ///
  /// In en, this message translates to:
  /// **'Access authentic spiritual texts'**
  String get welcome_feature_spiritual_texts;

  /// No description provided for @welcome_feature_five_parts.
  ///
  /// In en, this message translates to:
  /// **'Navigate through five comprehensive parts'**
  String get welcome_feature_five_parts;

  /// No description provided for @welcome_feature_gujarati_english.
  ///
  /// In en, this message translates to:
  /// **'Available in Gujarati and English'**
  String get welcome_feature_gujarati_english;

  /// No description provided for @welcome_feature_divine_blessings.
  ///
  /// In en, this message translates to:
  /// **'Receive divine blessings daily'**
  String get welcome_feature_divine_blessings;

  /// No description provided for @welcome_feature_spiritual_guidance.
  ///
  /// In en, this message translates to:
  /// **'Get spiritual guidance for life'**
  String get welcome_feature_spiritual_guidance;

  /// No description provided for @welcome_feature_advanced_search.
  ///
  /// In en, this message translates to:
  /// **'Advanced search capabilities'**
  String get welcome_feature_advanced_search;

  /// No description provided for @welcome_feature_instant_results.
  ///
  /// In en, this message translates to:
  /// **'Get instant, relevant results'**
  String get welcome_feature_instant_results;

  /// No description provided for @welcome_feature_personal_notes.
  ///
  /// In en, this message translates to:
  /// **'Write and organize personal notes'**
  String get welcome_feature_personal_notes;

  /// No description provided for @welcome_feature_sync_across_devices.
  ///
  /// In en, this message translates to:
  /// **'Sync across all your devices'**
  String get welcome_feature_sync_across_devices;

  /// No description provided for @welcome_feature_custom_reading_goals.
  ///
  /// In en, this message translates to:
  /// **'Set custom reading goals'**
  String get welcome_feature_custom_reading_goals;

  /// No description provided for @welcome_feature_progress_tracking.
  ///
  /// In en, this message translates to:
  /// **'Track your reading progress'**
  String get welcome_feature_progress_tracking;

  /// No description provided for @welcome_feature_beautiful_quotes.
  ///
  /// In en, this message translates to:
  /// **'Create beautiful quote images'**
  String get welcome_feature_beautiful_quotes;

  /// No description provided for @welcome_feature_share_inspiration.
  ///
  /// In en, this message translates to:
  /// **'Share inspiration with others'**
  String get welcome_feature_share_inspiration;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'gu'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'gu':
      return AppLocalizationsGu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
