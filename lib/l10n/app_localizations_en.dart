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
  String get aashirvachan => 'Aashirvachan';

  @override
  String get information => 'Information';

  @override
  String get information_section => 'Information Section';

  @override
  String get search => 'Search';

  @override
  String get reading_history => 'Reading History';

  @override
  String get reading => 'Reading';

  @override
  String get loginWithGoogle => 'Sign in with Google';

  @override
  String get loginWithApple => 'Sign in with Apple';

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
  String kiran_read_finished_message(Object count) {
    return 'You have read this kiran $count times.';
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
  String get header_slok =>
      '।। શ્રી સ્વામિનારાયણો વિજયતેતરામ્‌ ।।\n\nશ્રી સહજાનંદ સંસ્કારધામ\nમહામંત્રપીઠ - ફરેણી';

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
  String get showFavoritesOnly => 'Show Favorites Only';

  @override
  String get showAllKirans => 'Show All Kirans';

  @override
  String get noFavoriteKirans => 'No Favorite Kirans';

  @override
  String get noFavoriteKiransMessage =>
      'Tap the heart icon on any Kiran to add it to favorites';

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
  String get analytics => 'Analytics';

  @override
  String get dailyChart => 'Daily';

  @override
  String get weeklyChart => 'Weekly';

  @override
  String get partsChart => 'Parts';

  @override
  String get durationChart => 'Duration';

  @override
  String get dailyReadingMinutes => 'Daily Reading Minutes';

  @override
  String get weeklyReadingHours => 'Weekly Reading Hours';

  @override
  String get readingDistributionByParts => 'Reading Distribution by Parts';

  @override
  String get readingSessionDurationAnalysis =>
      'Reading Session Duration Analysis';

  @override
  String get noAnalyticsAvailable => 'No Analytics Available';

  @override
  String get startReadingForAnalytics =>
      'Start reading to see your analytics and insights.';

  @override
  String get chartMinutesLabel => 'minutes';

  @override
  String get chartHoursLabel => 'hours';

  @override
  String get chartSessionsLabel => 'sessions';

  @override
  String get dailyChartDescription =>
      'Track your daily reading habits with this line chart showing minutes read per day over the last 30 days. Peaks indicate your most productive reading days.';

  @override
  String get weeklyChartDescription =>
      'View your weekly reading patterns with this bar chart displaying total hours read per week over the last 12 weeks. Helps identify consistent reading periods.';

  @override
  String get partsChartDescription =>
      'See how your reading is distributed across different parts of the book with this pie chart. Shows the percentage breakdown of your reading sessions by part.';

  @override
  String get durationChartDescription =>
      'Analyze your reading session lengths with this bar chart. Groups your sessions by duration ranges to help you understand your reading stamina patterns.';

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
  String get quotes_image_generator => 'Quotes Generator';

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

  @override
  String get create_quote_image => 'Create Quote';

  @override
  String get quote_content => 'Quote Content';

  @override
  String get author => 'Author';

  @override
  String get quote_author_hint => 'Quote author or source';

  @override
  String get enter_author => 'Enter author or source';

  @override
  String get customization => 'Customization';

  @override
  String get template_style => 'Template Style';

  @override
  String get background => 'Background';

  @override
  String get reading_preferences => 'Reading Preferences';

  @override
  String get theme_appearance => 'Theme & Appearance';

  @override
  String get language_localization => 'Language & Localization';

  @override
  String get light_mode_option => 'Light';

  @override
  String get dark_mode_option => 'Dark';

  @override
  String get error_saving_settings => 'Error saving settings';

  @override
  String get language_gujarati => 'ગુજરાતી';

  @override
  String get language_english => 'English';

  @override
  String get account_and_privacy => 'Account & Privacy';

  @override
  String get delete_account => 'Delete Account';

  @override
  String get delete_account_description =>
      'Permanently delete your account and all associated data from this app.';

  @override
  String get delete_account_button => 'Delete Account';

  @override
  String get confirm => 'Confirm';

  @override
  String get confirm_delete_account_message =>
      'This will permanently delete your account and all associated data. This action cannot be undone.';

  @override
  String get delete_account_requires_relogin =>
      'Account deletion requires you to re-authenticate. Please try again.';

  @override
  String get delete_account_failed =>
      'Failed to delete account. Please contact support.';

  @override
  String get quote_preview => 'Preview';

  @override
  String get swipe_templates => 'Swipe to see all templates →';

  @override
  String get spiritual_seeker => 'Spiritual Seeker';

  @override
  String get devotee_of_sakshat_savita => 'Devotee of Sakshat Savita';

  @override
  String get tab_colors => 'Colors';

  @override
  String get tab_font_size => 'Font';

  @override
  String get tab_image_size => 'Image';

  @override
  String get tab_user_info => 'User';

  @override
  String get sign_in_to_show_profile => 'Sign in to show your profile info';

  @override
  String get show_avatar => 'Show Avatar';

  @override
  String get show_name => 'Show Name';

  @override
  String get predefined_quotes => 'Predefined Spiritual Quotes';

  @override
  String get quote_font => 'Quote';

  @override
  String get author_font => 'Author';

  @override
  String get height_label => 'Height';

  @override
  String get width_label => 'Width';

  @override
  String get part_label => 'Part';

  @override
  String get kiran_label => 'Kiran';

  @override
  String get sharing_spiritual_wisdom => 'Sharing Spiritual Wisdom';

  @override
  String get shared_spiritual_thought => 'shared a spiritual thought';

  @override
  String get error_sharing_image => 'Error sharing image';

  @override
  String get share_text =>
      'Inspirational quote generated with Sakshat Savita app';

  @override
  String get album_name => 'Sakshat Savita Quotes';

  @override
  String get predefined_quote_1 =>
      '🙏 Connecting with the soul is life\'s greatest achievement.';

  @override
  String get predefined_quote_2 =>
      '📖 Daily spiritual reading brings light to your life.';

  @override
  String get predefined_quote_3 =>
      '✨ Peace comes not from outside, but from within.';

  @override
  String get predefined_quote_4 =>
      '🌅 Every new day is an opportunity for spiritual growth.';

  @override
  String get predefined_quote_5 =>
      '💫 Truth, love and compassion - these three are the foundation of life.';

  @override
  String get jogi_swami =>
      'પ.પૂ.પ્ર.બ્ર.સ્વ. સદ્. જોગીસ્વામી\nશ્રી ધર્મપ્રસાદદાસજી સ્વામી';

  @override
  String get shastri_swami =>
      'વચનામૃત મર્મજ્ઞ પ.પૂ. સદ્. શાસ્ત્રી\nશ્રી બાલકૃષ્ણદાસજી સ્વામી';

  @override
  String get below_target => 'Below Target';

  @override
  String get target_achieved => 'Target Achieved';

  @override
  String reminder_6am(int minutes) {
    return '🌅 Start your day with spiritual wisdom! Time for your $minutes-minute reading.';
  }

  @override
  String reminder_7am(int kirans) {
    return '☀️ Good morning! Begin today with $kirans Kiran(s) from Saxat Savita.';
  }

  @override
  String get reminder_8am =>
      '🌤️ Morning reading time! Your daily spiritual journey awaits.';

  @override
  String get reminder_9am =>
      '🌞 It\'s 9 AM - perfect time for your daily reading practice.';

  @override
  String reminder_12pm(int minutes) {
    return '🌤️ Midday spiritual break! Take $minutes minutes for inner peace.';
  }

  @override
  String get reminder_3pm =>
      '🌤️ Afternoon reading session! Continue your spiritual growth.';

  @override
  String get reminder_6pm =>
      '🌇 Evening reading time! Reflect on today with spiritual wisdom.';

  @override
  String reminder_7pm(int kirans) {
    return '🌆 Wind down with your evening reading. $kirans Kiran(s) to go!';
  }

  @override
  String get reminder_8pm =>
      '🌙 Evening spiritual time! Complete your daily reading goal.';

  @override
  String get reminder_9pm =>
      '✨ Before bed, nourish your soul with divine wisdom.';

  @override
  String reminder_default(int minutes) {
    return '📖 Reading reminder! Don\'t forget your daily $minutes-minute spiritual practice.';
  }

  @override
  String get read_now => 'Read Now';

  @override
  String get remind_later => 'Remind Later';

  @override
  String get skip => 'Skip';

  @override
  String get previous => 'Previous';

  @override
  String get next => 'Next';

  @override
  String get get_started => 'Get Started';

  @override
  String get welcome_tour => 'Welcome!';

  @override
  String get welcome_spiritual_reading =>
      'P.P. Sad. Jogiswami explained the secrets of Vachanamrut and transformed souls into Brahmarup. Shastri Balkrishndasji Swami compiled these divine discourses under the name \'Sakshat Savita\'.';

  @override
  String get welcome_aashirvachan_desc =>
      'Receive divine blessings and spiritual guidance through the sacred words of P.P.Pr.Br.Sw. Sad. Jogiswami and Vachanamrut expert P.P. Sad. Shastri Shri Balkrishndasji Swami.';

  @override
  String get welcome_search_desc =>
      'Quickly search for specific Kirans, verses, or topics with powerful search functionality.';

  @override
  String get welcome_notes_desc =>
      'Capture your spiritual insights and create personal notes to enhance your learning and meditation practice.';

  @override
  String get welcome_reading_plans_desc =>
      'Set personal reading goals and track your progress with daily plans for regular spiritual reading.';

  @override
  String get welcome_reading_history_desc =>
      'Keep track of your spiritual journey with detailed reading history and personal milestones.';

  @override
  String get welcome_quotes_generator_desc =>
      'Create beautiful, shareable quote images from inspirational spiritual texts to spread knowledge and positivity.';

  @override
  String get welcome_information_desc =>
      'Get detailed information about P.P.Pr.Br.Sw. Sad. Jogiswami\'s biography, the origin of Sakshat Savita, and Shri Sahjanand Sanskardham Mahamantrapith - Fareni.';

  @override
  String get welcome_feature_spiritual_texts => 'Understand \"Vachanamrut\"';

  @override
  String get welcome_feature_five_parts => 'All five parts';

  @override
  String get welcome_feature_gujarati_english =>
      'Available in Gujarati and English';

  @override
  String get welcome_feature_divine_blessings =>
      'Receive daily divine blessings';

  @override
  String get welcome_feature_spiritual_guidance =>
      'Get spiritual guidance for life';

  @override
  String get welcome_feature_advanced_search => 'Advanced search capabilities';

  @override
  String get welcome_feature_instant_results => 'Get instant, relevant results';

  @override
  String get welcome_feature_personal_notes =>
      'Write and organize personal notes';

  @override
  String get welcome_feature_sync_across_devices =>
      'Sync across all your devices (mobile, tablet)';

  @override
  String get welcome_feature_custom_reading_goals => 'Set daily reading goals';

  @override
  String get welcome_feature_progress_tracking => 'Track your reading progress';

  @override
  String get welcome_feature_beautiful_quotes =>
      'Create beautiful quote images';

  @override
  String get welcome_feature_share_inspiration => 'Inspire others';

  @override
  String get login_required => 'Login Required';

  @override
  String get login_to_sync_progress =>
      'Please login to sync your reading progress and access all features.';

  @override
  String get recent_searches => 'Recent Searches';

  @override
  String get clear => 'Clear';

  @override
  String get login => 'Login';

  @override
  String get deleteReadingHistory => 'Delete Reading History';

  @override
  String get confirmDeleteReadingHistory =>
      'Are you sure you want to delete this reading history entry? This action cannot be undone.';

  @override
  String get readingHistoryDeleted => 'Reading history deleted successfully';

  @override
  String get errorDeletingHistory => 'Error deleting reading history';

  @override
  String get error => 'Error';

  @override
  String get updateAvailable => 'Update Available';

  @override
  String get updateAvailableMessage =>
      'A new version of the app is available. Update now to enjoy the latest features and improvements.';

  @override
  String get criticalUpdateMessage =>
      'This is a critical update that is required to continue using the app.';

  @override
  String get later => 'Later';

  @override
  String get updateNow => 'Update Now';

  @override
  String get checkForUpdates => 'Check for Updates';

  @override
  String get iOSUpdateMessage =>
      'Visit the App Store to check for the latest version of the app.';

  @override
  String get openAppStore => 'Open App Store';

  @override
  String get upToDate => 'Up to Date';

  @override
  String get noUpdateAvailable =>
      'You\'re using the latest version of the app.';

  @override
  String get ok => 'OK';

  @override
  String get updateCheckFailed => 'Update check failed';

  @override
  String get updateReady => 'Update Ready';

  @override
  String get updateReadyMessage =>
      'The update has been downloaded and is ready to install. Restart the app to complete the update.';

  @override
  String get restartNow => 'Restart Now';

  @override
  String get app_settings => 'App Settings';

  @override
  String get checkForUpdatesDescription =>
      'Check if a newer version of the app is available for download.';

  @override
  String get app_version => 'App Version';

  @override
  String get loading => 'Loading...';

  @override
  String get keepScreenOn => 'Keep Screen On';

  @override
  String get keepScreenOnDescription =>
      'Prevent screen from turning off while reading';

  @override
  String get plan_name => 'Plan Name';

  @override
  String get start_date => 'Start Date';

  @override
  String get end_date => 'End Date';

  @override
  String get total_kirans => 'Total Kirans';

  @override
  String get goals_achieved => 'Goals Achieved';

  @override
  String get completion_rate => 'Completion Rate';

  @override
  String get streak_days => 'Streak Days';

  @override
  String get close => 'Close';

  @override
  String get personal_information => 'Personal Information';

  @override
  String get first_name => 'First Name';

  @override
  String get last_name => 'Last Name';

  @override
  String get city_or_village => 'City/Village';

  @override
  String get first_name_required => 'First name is required';

  @override
  String get last_name_required => 'Last name is required';

  @override
  String get city_or_village_required => 'City or village is required';

  @override
  String get save_profile => 'Save Profile';

  @override
  String get profile_updated_successfully => 'Profile updated successfully';

  @override
  String get profile_update_failed =>
      'Failed to update profile. Please try again.';

  @override
  String get incomplete_profile => 'Incomplete Profile';

  @override
  String get please_complete_profile =>
      'Please complete all required fields to continue.';

  @override
  String get continue_editing => 'Continue Editing';

  @override
  String get exit_anyway => 'Exit Anyway';
}
