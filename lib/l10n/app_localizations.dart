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
