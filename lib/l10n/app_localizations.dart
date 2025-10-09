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

  /// No description provided for @reading_history.
  ///
  /// In en, this message translates to:
  /// **'Reading History'**
  String get reading_history;

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
  /// **'।। શ્રી સ્વામિનારાયણો વિજયતેતરામ્‌ ।।'**
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
