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
  String get tag_line => '।। વિચાર કરો તો ખબર પડે ।।';

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

  @override
  String get expandAll => 'Expand All';

  @override
  String get collapseAll => 'Collapse All';

  @override
  String get filterByDate => 'Filter by Date';

  @override
  String get year => 'Year';

  @override
  String get month => 'Month';

  @override
  String get allYears => 'All Years';

  @override
  String get allMonths => 'All Months';

  @override
  String get january => 'January';

  @override
  String get february => 'February';

  @override
  String get march => 'March';

  @override
  String get april => 'April';

  @override
  String get may => 'May';

  @override
  String get june => 'June';

  @override
  String get july => 'July';

  @override
  String get august => 'August';

  @override
  String get september => 'September';

  @override
  String get october => 'October';

  @override
  String get november => 'November';

  @override
  String get december => 'December';

  @override
  String get settings_saved => 'ettings saved successfully';

  @override
  String get changes_discarded => 'Changes discarded';

  @override
  String get unsaved_changes => 'Unsaved Changes';

  @override
  String get unsaved_changes_message =>
      'You have unsaved changes. What would you like to do?';

  @override
  String get discard => 'Discard';

  @override
  String get save => 'Save';

  @override
  String get you_have_unsaved_changes => 'You have unsaved changes';

  @override
  String get discard_changes => 'Discard Changes';

  @override
  String get save_settings => 'Save Settings';

  @override
  String get reading_plans => 'Reading Plans';

  @override
  String get reading_plans_today => 'Today';

  @override
  String get reading_plans_my_plans => 'My Plans';

  @override
  String get reading_plans_progress => 'Progress';

  @override
  String get today_goal_achieved => 'Today\'s Goal Achieved!';

  @override
  String get today_progress => 'Today\'s Progress';

  @override
  String get reading_time => 'Reading Time';

  @override
  String get completed => 'Completed';

  @override
  String get kirans => 'Kirans';

  @override
  String get quick_actions => 'Quick Actions';

  @override
  String get start_reading => 'Start Reading';

  @override
  String get edit_plan => 'Edit Plan';

  @override
  String get test_reminder => 'Test Reminder';

  @override
  String get your_statistics => 'Your Statistics';

  @override
  String get streak => 'Streak';

  @override
  String get days => 'days';

  @override
  String get this_week => 'This Week';

  @override
  String get goals => 'goals';

  @override
  String get total_time => 'Total Time';

  @override
  String get minutes => 'minutes';

  @override
  String get excellent_work_today =>
      'Excellent work today! You\'re building a powerful spiritual habit. 🌟';

  @override
  String on_fire_streak(int streak) {
    return 'You\'re on fire! $streak days streak. Keep the momentum going! 🔥';
  }

  @override
  String get great_start =>
      'Great start! Every minute of spiritual reading counts. 📚';

  @override
  String get ready_to_start =>
      'Ready to start today\'s spiritual journey? Your wisdom awaits! ✨';

  @override
  String get already_active => 'Already Active';

  @override
  String get set_as_active => 'Set as Active';

  @override
  String get reading_plans_edit => 'Edit';

  @override
  String get reading_plans_delete => 'Delete';

  @override
  String get last_30_days_progress => 'Last 30 Days Progress';

  @override
  String get progress_calendar => 'Progress Calendar';

  @override
  String get goal_achieved => 'Goal Achieved';

  @override
  String get partial => 'Partial';

  @override
  String get started => 'Started';

  @override
  String get no_activity => 'No Activity';

  @override
  String get no_reading_plan => 'No Reading Plan';

  @override
  String get create_first_reading_plan =>
      'Create your first reading plan to start building a consistent spiritual reading habit.';

  @override
  String get create_reading_plan => 'Create Reading Plan';

  @override
  String get plan_details_coming_soon => 'Plan details page coming soon!';

  @override
  String plan_now_active(String title) {
    return '$title is now your active plan';
  }

  @override
  String get delete_reading_plan => 'Delete Reading Plan';

  @override
  String confirm_delete_plan(String title) {
    return 'Are you sure you want to delete \"$title\"? This cannot be undone.';
  }

  @override
  String get reading_plans_cancel => 'Cancel';

  @override
  String get reading_plan_deleted => 'Reading plan deleted';

  @override
  String get test_reminder_sent => 'Test reminder sent!';

  @override
  String day_streak(int days) {
    return '$days day streak';
  }

  @override
  String min_per_day(int minutes) {
    return '$minutes min/day';
  }

  @override
  String kirans_target(int count) {
    return '$count Kirans';
  }

  @override
  String get create_plan_title => 'Create Reading Plan';

  @override
  String get edit_plan_title => 'Edit Reading Plan';

  @override
  String get basic_information => 'Basic Information';

  @override
  String get plan_title => 'Plan Title';

  @override
  String get plan_title_hint => 'e.g., Morning Spiritual Reading';

  @override
  String get plan_title_error => 'Please enter a title for your reading plan';

  @override
  String get description_optional => 'Description (Optional)';

  @override
  String get description_hint => 'Brief description of your reading plan';

  @override
  String get daily_goals => 'Daily Goals';

  @override
  String get reading_time_goal => 'Reading Time Goal';

  @override
  String get create_plan_minutes => 'minutes';

  @override
  String get kirans_to_complete => 'Kirans to Complete';

  @override
  String get daily_goals_recommendation =>
      'Recommended: Start with shorter goals and gradually increase';

  @override
  String get create_plan_reminders => 'Reminders';

  @override
  String get enable_daily_reminders => 'Enable Daily Reminders';

  @override
  String get reminder_time => 'Reminder Time';

  @override
  String daily_reminder_at(String time) {
    return 'Daily reminder at $time';
  }

  @override
  String get no_reminders_set => 'No reminders set';

  @override
  String get plan_preview => 'Plan Preview';

  @override
  String get daily_reading => 'Daily Reading';

  @override
  String get preview_kirans => 'Kirans';

  @override
  String get reminders_on => 'ON';

  @override
  String get reminders_off => 'OFF';

  @override
  String minutes_format(int minutes) {
    return '$minutes minutes';
  }

  @override
  String get create_plan_cancel => 'Cancel';

  @override
  String get update_plan => 'Update Plan';

  @override
  String get create_plan => 'Create Plan';

  @override
  String get select_reminder_time => 'Select Reminder Time';

  @override
  String get time_picker_cancel => 'Cancel';

  @override
  String get time_picker_save => 'Save';

  @override
  String get plan_updated_success => 'Reading plan updated successfully!';

  @override
  String get plan_created_success => 'Reading plan created successfully!';

  @override
  String plan_save_error(String error) {
    return 'Error saving plan: $error';
  }

  @override
  String get reminders_enabled_subtitle =>
      'Get notified to maintain your reading habit';

  @override
  String get reminders_disabled_subtitle => 'No reminders will be sent';

  @override
  String get quotes_image_generator => 'Quotes Image Generator';

  @override
  String get inspirational_quotes => 'Inspirational Quotes';

  @override
  String get create_share_quotes => 'Create and share beautiful quote images';

  @override
  String get quote_text => 'Quote Text';

  @override
  String get enter_quote => 'Enter your inspirational quote';

  @override
  String get quote_font_size => 'Font Size';

  @override
  String get background_color => 'Background Color';

  @override
  String get text_color => 'Text Color';

  @override
  String get template => 'Template';

  @override
  String get gradient => 'Gradient';

  @override
  String get solid => 'Solid';

  @override
  String get geometric => 'Geometric';

  @override
  String get simple => 'Simple';

  @override
  String get elegant => 'Elegant';

  @override
  String get modern => 'Modern';

  @override
  String get share_quote => 'Share Quote';

  @override
  String get save_quote => 'Save Quote';

  @override
  String get random_quote => 'Random Quote';

  @override
  String get image_saved => 'Image saved to gallery';

  @override
  String error_saving_image(String error) {
    return 'Error saving image: $error';
  }
}
