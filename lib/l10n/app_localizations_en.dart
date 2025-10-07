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
  String get reading_history => 'Reading History';

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
  String get kiran_read_finished => 'Read the kiran';

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

  @override
  String get search_kiranas => 'Search kiranas by title or content...';

  @override
  String get search_all_kiranas => 'Search through all Kirans';

  @override
  String get enter_keywords => 'Enter keywords to find relevant content';

  @override
  String get no_results_found => 'No results found';

  @override
  String get try_different_keywords =>
      'Try different keywords or check spelling';

  @override
  String results_found(int count) {
    return '$count results found';
  }

  @override
  String get search_min_chars => 'Enter at least 2 characters to search';

  @override
  String get content_match => 'Content';

  @override
  String get title_match => 'Title';

  @override
  String get filters => 'Filters';

  @override
  String get clear_all_filters => 'Clear All';

  @override
  String get match_type => 'Match Type';

  @override
  String get book_parts => 'Book Parts';

  @override
  String get no_filtered_results => 'No results match current filters';

  @override
  String get adjust_filters => 'Try adjusting your filter settings';

  @override
  String results_filtered(int filtered, int total) {
    return '$filtered of $total results shown';
  }

  @override
  String get expand_filters => 'Expand Filters';

  @override
  String get collapse_filters => 'Collapse Filters';

  @override
  String get search_hint => 'Search in this kiran... (Enter: search)';

  @override
  String get no_match_found => 'No matches found';

  @override
  String get search_in_kiran => 'Search in Kiran';

  @override
  String get close_search => 'Close Search';

  @override
  String get edit_notes => 'Edit Notes';

  @override
  String get save_notes => 'Save Notes';

  @override
  String get notes => 'Notes';

  @override
  String get add_notes => 'Add Notes';

  @override
  String get notes_hint => 'Add your personal notes here...';

  @override
  String get notesSaved => 'Notes saved successfully';

  @override
  String get cancel => 'Cancel';

  @override
  String get deleteNoteConfirm => 'Are you sure you want to delete this note?';

  @override
  String get delete => 'Delete';

  @override
  String get noteDeletedSuccess => 'Note deleted successfully';

  @override
  String errorDeletingNote(String error) {
    return 'Error deleting note: $error';
  }

  @override
  String daysAgo(int days) {
    return '$days days ago';
  }

  @override
  String hoursAgo(int hours) {
    return '$hours hours ago';
  }

  @override
  String minutesAgo(int minutes) {
    return '$minutes minutes ago';
  }

  @override
  String get justNow => 'Just now';

  @override
  String get sortBy => 'Sort by';

  @override
  String get lastModified => 'Last Modified';

  @override
  String get searchNotesHint => 'Search notes and titles...';

  @override
  String notesCount(int filtered, int total) {
    return '$filtered of $total notes';
  }

  @override
  String sortedBy(String sortName, String direction) {
    return 'Sorted by $sortName $direction';
  }

  @override
  String get noNotesFound => 'No Notes Found';

  @override
  String get startTakingNotes => 'Start taking notes while reading Kiranas';

  @override
  String get noMatchingNotes => 'No matching notes';

  @override
  String get characters => 'characters';

  @override
  String get tapToEdit => 'Tap to edit';

  @override
  String get adjustSearchFilters => 'Try adjusting your search or filters';

  @override
  String get editNote => 'Edit Note';

  @override
  String get viewKiran => 'View Kiran';

  @override
  String get deleteNote => 'Delete Note';

  @override
  String get bookPart => 'Book Part';

  @override
  String get noteLength => 'Note Length';

  @override
  String get bookParts => 'Book Parts:';

  @override
  String get favorite => 'Favorite';

  @override
  String get favoriteKiranSuccess => 'Kiran favorited successfully';

  @override
  String get readingHistoryTitle => 'Reading History';

  @override
  String get totalReadingTime => 'Total Reading Time';

  @override
  String get readingSessions => 'Reading Sessions';

  @override
  String get noReadingHistory => 'No Reading History';

  @override
  String get startReadingMessage =>
      'Start reading Kiranas to track your progress';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get thisWeek => 'This Week';

  @override
  String get thisMonth => 'This Month';

  @override
  String get older => 'Older';

  @override
  String get duration => 'Duration';

  @override
  String get readingSession => 'Reading Session';

  @override
  String get filterByCategory => 'Filter by Category';

  @override
  String get allCategories => 'All Categories';

  @override
  String get clearFilters => 'Clear Filters';
}
