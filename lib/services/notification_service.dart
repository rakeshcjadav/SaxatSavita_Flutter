import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';
import 'package:saxatsavita_flutter/models/reading_plan_model.dart';
import 'package:saxatsavita_flutter/services/navigationservice.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

/// NotificationService handles all notification functionality including sound playback
///
/// For Android notification sounds to work properly, ensure:
/// 1. AndroidManifest.xml has required permissions (POST_NOTIFICATIONS, VIBRATE, etc.)
/// 2. Notification channels are created with playSound: true
/// 3. Individual notifications have playSound: true in AndroidNotificationDetails
/// 4. Device is not in silent/DND mode
/// 5. App has notification permissions granted
/// 6. Notification volume is not muted in system settings

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String _readingReminderChannelId = 'reading_reminder';
  static const String _goalAchievedChannelId = 'goal_achieved';
  static const String _motivationChannelId = 'motivation';

  bool _isInitialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize timezone data
      tz.initializeTimeZones();
      debugPrint('📍 Timezone initialized');

      // Android initialization
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('ic_launcher_foreground');

      // iOS initialization
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      const InitializationSettings initializationSettings =
          InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS,
          );

      final initialized = await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
      );
      debugPrint('📍 Flutter notifications initialized: $initialized');

      // Create notification channels for Android
      if (Platform.isAndroid) {
        await _createNotificationChannels();
        debugPrint('📍 Android notification channels created');
      }

      // Request permissions
      final hasPermissions = await _requestPermissions();
      debugPrint('📍 Permissions granted: $hasPermissions');

      // Check current notification status
      final enabled = await areNotificationsEnabled();
      debugPrint('📍 Notifications enabled: $enabled');

      _isInitialized = true;
      debugPrint('✅ Notification service initialized successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to initialize notifications: $e');
      debugPrint('❌ Stack trace: $stackTrace');
    }
  }

  /// Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    final androidPlugin =
        _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidPlugin != null) {
      // Reading reminder channel
      await androidPlugin.createNotificationChannel(
        AndroidNotificationChannel(
          _readingReminderChannelId,
          'Reading Reminders',
          description: 'Daily reading plan reminders',
          importance: Importance.high,
          enableVibration: true,
          playSound: true,
          showBadge: true,
          enableLights: true,
          ledColor: Colors.blue,
        ),
      );

      // Goal achieved channel
      await androidPlugin.createNotificationChannel(
        AndroidNotificationChannel(
          _goalAchievedChannelId,
          'Goal Achievements',
          description: 'Notifications for achieved reading goals',
          importance: Importance.high,
          enableVibration: true,
          playSound: true,
          showBadge: true,
          enableLights: true,
          ledColor: Colors.green,
        ),
      );

      // Motivation channel
      await androidPlugin.createNotificationChannel(
        AndroidNotificationChannel(
          _motivationChannelId,
          'Motivation',
          description: 'Motivational reading messages',
          importance: Importance.defaultImportance,
          enableVibration: true,
          playSound: true,
          showBadge: false,
          enableLights: true,
          ledColor: Colors.orange,
        ),
      );
    }
  }

  /// Request notification permissions
  Future<bool> _requestPermissions() async {
    if (Platform.isIOS) {
      final result = await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      debugPrint('📱 iOS notification permissions: $result');
      return result ?? false;
    } else if (Platform.isAndroid) {
      final androidImplementation =
          _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      // Request notification permission (Android 13+)
      final notificationResult =
          await androidImplementation?.requestNotificationsPermission();
      debugPrint('📱 Android notification permission: $notificationResult');

      // Request exact alarms permission
      final alarmResult =
          await androidImplementation?.requestExactAlarmsPermission();
      debugPrint('📱 Android exact alarms permission: $alarmResult');

      return notificationResult ?? false;
    }
    return true;
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      final androidImplementation =
          _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
      return await androidImplementation?.areNotificationsEnabled() ?? false;
    }
    return true;
  }

  /// Schedule reading plan reminder notifications
  Future<void> scheduleReadingPlanReminders(ReadingPlan plan) async {
    if (!_isInitialized) await initialize();

    // Cancel existing reminders first
    await cancelReadingPlanReminders();

    if (!plan.isActive || plan.reminderTimes.isEmpty) return;

    try {
      for (final reminderTime in plan.reminderTimes) {
        await _scheduleDailyReminderAtTime(plan, reminderTime);
      }

      debugPrint('✅ Scheduled reminders for plan: ${plan.title}');
    } catch (e) {
      debugPrint('❌ Error scheduling reminders: $e');
    }
  }

  /// Schedule a daily reminder at specific time
  Future<void> _scheduleDailyReminderAtTime(
    ReadingPlan plan,
    ReminderTime reminderTime,
  ) async {
    final now = DateTime.now();
    var scheduledDateLocal = DateTime(
      now.year,
      now.month,
      now.day,
      reminderTime.hour,
      reminderTime.minute,
    );

    final tz.Location localLocation = tz.local;

    tz.TZDateTime scheduledDate = tz.TZDateTime.from(
      scheduledDateLocal,
      localLocation,
    );

    debugPrint('Now (Local): $now');
    debugPrint('scheduledDateLocal (local): $scheduledDateLocal');
    debugPrint('Now (TZ): ${tz.TZDateTime.from(now, localLocation)}');
    debugPrint('scheduledDateLocal (TZ): $scheduledDate');

    debugPrint(
      '🕐 Scheduling reminder for plan "${plan.title}" at: $scheduledDate',
    );

    // If the time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final notificationId =
        plan.id.hashCode + (reminderTime.hour * 100 + reminderTime.minute);

    AppLocalizations appLocalizations =
        AppLocalizations.of(NavigationService.navigatorKey.currentContext!)!;

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId,
      '📚 ${appLocalizations.reading_time}',
      _getReminderMessage(plan, reminderTime),
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _readingReminderChannelId,
          'Reading Reminders',
          channelDescription: 'Daily reading plan reminders',
          importance: Importance.high,
          priority: Priority.high,
          icon: 'notifications_24dp_fill',
          playSound: true,
          enableVibration: true,
          enableLights: true,
          ledColor: Colors.blue,
          ledOnMs: 1000,
          ledOffMs: 500,
          showWhen: true,
          when: DateTime.now().millisecondsSinceEpoch,
          usesChronometer: false,
          fullScreenIntent: true,
          actions: [
            AndroidNotificationAction(
              'read_now',
              '📖 ${appLocalizations.read_now}',
              //icon: DrawableResourceAndroidBitmap('menu_book_24dp'),
              showsUserInterface: true,
            ),
            AndroidNotificationAction(
              'remind_later',
              '⏰ ${appLocalizations.remind_later}',
              //icon: DrawableResourceAndroidBitmap('notifications_24dp_fill'),
              showsUserInterface: true,
            ),
          ],
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          categoryIdentifier: 'reading_reminder',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload:
          'reading_reminder:${plan.id}:${reminderTime.hour}:${reminderTime.minute}', // Add payload
    );
  }

  /// Get appropriate reminder message based on time and plan
  String _getReminderMessage(ReadingPlan plan, ReminderTime reminderTime) {
    AppLocalizations localizations =
        AppLocalizations.of(NavigationService.navigatorKey.currentContext!)!;
    final hour = reminderTime.hour;
    final minutes = plan.targetSeconds ~/ 60;
    final kirans = plan.targetKirans;

    switch (hour) {
      case 6:
        return localizations.reminder_6am(minutes);
      case 7:
        return localizations.reminder_7am(kirans);
      case 8:
        return localizations.reminder_8am;
      case 9:
        return localizations.reminder_9am;
      case 12:
        return localizations.reminder_12pm(minutes);
      case 15:
        return localizations.reminder_3pm;
      case 18:
        return localizations.reminder_6pm;
      case 19:
        return localizations.reminder_7pm(kirans);
      case 20:
        return localizations.reminder_8pm;
      case 21:
        return localizations.reminder_9pm;
      default:
        return localizations.reminder_default(minutes);
    }
  }

  /// Show goal achieved notification
  Future<void> showGoalAchievedNotification(ReadingPlan plan) async {
    if (!_isInitialized) await initialize();

    try {
      final streak = plan.streakDays;
      final title =
          streak > 1
              ? "🎉 Goal Achieved! $streak Day Streak!"
              : "🎉 Daily Goal Achieved!";

      final body =
          streak > 1
              ? "Amazing! You've maintained your reading habit for $streak days straight. Keep the momentum going!"
              : "Congratulations! You've completed today's reading goal. Your dedication to spiritual growth is inspiring.";

      await _flutterLocalNotificationsPlugin.show(
        plan.id.hashCode + 1000, // Unique ID for goal notifications
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _goalAchievedChannelId,
            'Goal Achievements',
            channelDescription: 'Notifications for achieved reading goals',
            importance: Importance.high,
            priority: Priority.high,
            icon: 'crown_24dp_fill',
            styleInformation: BigTextStyleInformation(
              body,
              contentTitle: title,
            ),
            playSound: true,
            enableVibration: true,
            enableLights: true,
            ledColor: Colors.green,
            ledOnMs: 1000,
            ledOffMs: 500,
            showWhen: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            categoryIdentifier: 'goal_achieved',
          ),
        ),
      );

      debugPrint('🎉 Showed goal achieved notification');
    } catch (e) {
      debugPrint('❌ Error showing goal notification: $e');
    }
  }

  /// Show motivational notification for streak milestones
  Future<void> showStreakMilestoneNotification(int streakDays) async {
    if (!_isInitialized) await initialize();

    if (streakDays < 3) return; // Only show for meaningful streaks

    try {
      String title;
      String body;

      switch (streakDays) {
        case 7:
          title = "🔥 One Week Streak!";
          body =
              "You've read consistently for 7 days! You're building a powerful habit.";
          break;
        case 14:
          title = "⭐ Two Week Champion!";
          body =
              "14 days of consistent reading! Your spiritual discipline is remarkable.";
          break;
        case 30:
          title = "🏆 Monthly Milestone!";
          body =
              "30 days of daily reading! You've truly embraced the spiritual journey.";
          break;
        case 50:
          title = "💎 Diamond Reader!";
          body =
              "50 days straight! Your commitment to spiritual growth is diamond-solid.";
          break;
        case 100:
          title = "👑 Century Reader!";
          body =
              "100 days! You're a true spiritual warrior. This is life-changing dedication!";
          break;
        default:
          if (streakDays % 10 == 0) {
            title = "🎯 $streakDays Day Streak!";
            body =
                "Incredible! $streakDays consecutive days of spiritual reading. You're unstoppable!";
          } else {
            return; // Don't show notification
          }
      }

      await _flutterLocalNotificationsPlugin.show(
        streakDays + 2000, // Unique ID for streak notifications
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _motivationChannelId,
            'Motivation',
            channelDescription: 'Motivational reading messages',
            importance: Importance.high,
            priority: Priority.high,
            icon: 'electric_bolt_24dp_fill',
            playSound: true,
            enableVibration: true,
            enableLights: true,
            ledColor: Colors.orange,
            ledOnMs: 500,
            ledOffMs: 500,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: false,
            presentSound: false,
          ),
        ),
      );

      debugPrint('🔥 Showed streak milestone notification: $streakDays days');
    } catch (e) {
      debugPrint('❌ Error showing streak notification: $e');
    }
  }

  /// Cancel all reading plan reminders
  Future<void> cancelReadingPlanReminders() async {
    try {
      // Cancel all scheduled notifications
      await _flutterLocalNotificationsPlugin.cancelAll();
      debugPrint('🚫 Cancelled all reading plan reminders');
    } catch (e) {
      debugPrint('❌ Error cancelling reminders: $e');
    }
  }

  /// Cancel reminders for a specific reading plan
  Future<void> cancelReadingPlanRemindersForPlan(ReadingPlan plan) async {
    if (!_isInitialized) await initialize();

    try {
      for (final reminderTime in plan.reminderTimes) {
        final notificationId =
            plan.id.hashCode + (reminderTime.hour * 100 + reminderTime.minute);
        await _flutterLocalNotificationsPlugin.cancel(notificationId);
      }
      debugPrint('🚫 Cancelled reminders for plan: ${plan.title}');
    } catch (e) {
      debugPrint('❌ Error cancelling reminders for plan ${plan.title}: $e');
    }
  }

  /// Show immediate reading suggestion notification
  Future<void> showReadingSuggestion() async {
    if (!_isInitialized) await initialize();

    final suggestions = [
      "📖 Take a 5-minute spiritual break with Saxat Savita",
      "✨ A short reading session can brighten your day",
      "🌟 Feed your soul with divine wisdom",
      "📚 Even 2 minutes of reading can transform your mindset",
      "💫 Your spiritual growth awaits - open Saxat Savita",
    ];

    final randomSuggestion =
        suggestions[DateTime.now().millisecond % suggestions.length];

    await _flutterLocalNotificationsPlugin.show(
      9999, // Fixed ID for suggestions
      "💡 Reading Suggestion",
      randomSuggestion,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _motivationChannelId,
          'Motivation',
          channelDescription: 'Motivational reading messages',
          importance: Importance.high,
          priority: Priority.high,
          icon: 'notifications_24dp_fill',
          playSound: true,
          enableVibration: true,
          enableLights: true,
          ledColor: Colors.orange,
          ledOnMs: 500,
          ledOffMs: 500,
          actions: [
            const AndroidNotificationAction(
              'read_now',
              '📖 Read Now',
              //icon: DrawableResourceAndroidBitmap('menu_book_24dp'),
              showsUserInterface: true,
            ),
            const AndroidNotificationAction(
              'remind_later',
              '⏰ Remind Later',
              //icon: DrawableResourceAndroidBitmap('notifications_24dp_fill'),
              showsUserInterface: true,
            ),
          ],
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  /// Handle notification tap
  @pragma('vm:entry-point')
  static void onDidReceiveNotificationResponse(NotificationResponse response) {
    debugPrint('📱 === NOTIFICATION RESPONSE RECEIVED ===');
    debugPrint('   - ID: ${response.id}');
    debugPrint('   - Action ID: ${response.actionId}');
    debugPrint('   - Notification Type: ${response.notificationResponseType}');
    debugPrint('   - Payload: ${response.payload}');

    try {
      // Add small delay to ensure app context is ready
      Future.delayed(const Duration(milliseconds: 100), () {
        switch (response.actionId) {
          case 'read_now':
            debugPrint('📚 Processing READ NOW action...');
            _handleReadNowAction();
            break;
          case 'remind_later':
            debugPrint('⏰ Processing REMIND LATER action...');
            NotificationService()._scheduleRemindLater();
            break;
          default:
            debugPrint('📱 Processing DEFAULT TAP action...');
            _handleDefaultTap();
            break;
        }
      });
    } catch (e) {
      debugPrint('❌ Error handling notification response: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
    }
  }

  /// Handle the "Read Now" action
  static void _handleReadNowAction() {
    try {
      // Method 1: Try using NavigationService
      final navigator = NavigationService.navigator;
      if (navigator != null) {
        debugPrint('📚 Using NavigationService.navigator');
        navigator.pushNamed('/bookmainpage');
        debugPrint('✅ Navigation command sent via NavigationService');
        return;
      }

      // Method 2: Try using current context
      final context = NavigationService.navigatorKey.currentContext;
      if (context != null) {
        debugPrint('📚 Using context navigator');
        Navigator.of(context).pushNamed('/bookmainpage');
        debugPrint('✅ Navigation command sent via context');
        return;
      }

      // Method 3: Try using global navigator key directly
      if (NavigationService.navigatorKey.currentState != null) {
        debugPrint('📚 Using global navigator key');
        NavigationService.navigatorKey.currentState!.pushNamed('/bookmainpage');
        debugPrint('✅ Navigation command sent via global key');
        return;
      }

      debugPrint('❌ All navigation methods failed - no context available');
    } catch (e) {
      debugPrint('❌ Error navigating to reading page: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
    }
  }

  /// Handle default notification tap
  static void _handleDefaultTap() {
    try {
      debugPrint('📱 Attempting to navigate to reading history...');

      // Method 1: Try using NavigationService
      final navigator = NavigationService.navigator;
      if (navigator != null) {
        debugPrint('📱 Using NavigationService.navigator');
        navigator.pushNamed('/homepage');
        debugPrint('✅ Navigation command sent via NavigationService');
        return;
      }

      // Method 2: Try using current context
      final context = NavigationService.navigatorKey.currentContext;
      if (context != null) {
        debugPrint('📱 Using context navigator');
        Navigator.of(context).pushNamed('/homepage');
        debugPrint('✅ Navigation command sent via context');
        return;
      }

      // Method 3: Try using global navigator key directly
      if (NavigationService.navigatorKey.currentState != null) {
        debugPrint('📱 Using global navigator key');
        NavigationService.navigatorKey.currentState!.pushNamed('/homepage');
        debugPrint('✅ Navigation command sent via global key');
        return;
      }

      debugPrint('❌ All navigation methods failed - no context available');
    } catch (e) {
      debugPrint('❌ Error handling default tap: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
    }
  }

  /// Handle iOS notification received while app is in foreground
  static void onDidReceiveLocalNotification(
    int id,
    String? title,
    String? body,
    String? payload,
  ) {
    debugPrint('📱 iOS notification received: $title');
  }

  /// Schedule a "remind later" notification
  Future<void> _scheduleRemindLater() async {
    final remindTime = DateTime.now().add(const Duration(minutes: 1));
    final scheduledDate = tz.TZDateTime.from(remindTime, tz.local);

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      8888, // Fixed ID for remind later
      "📚 Reading Reminder",
      "You asked to be reminded - time for your spiritual reading!",
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _readingReminderChannelId,
          'Reading Reminders',
          importance: Importance.high,
          priority: Priority.high,
          icon: 'notifications_24dp_fill',
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    debugPrint(
      '⏰ Scheduled remind later notification for ${remindTime.toString()}',
    );
  }
}
