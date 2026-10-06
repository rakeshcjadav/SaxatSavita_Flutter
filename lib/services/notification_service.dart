import 'dart:io';
import 'package:firebase_app_installations/firebase_app_installations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:saxatsavita_flutter/firebase_options.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';
import 'package:saxatsavita_flutter/models/reading_plan_model.dart';
import 'package:saxatsavita_flutter/services/navigationservice.dart';
import 'package:saxatsavita_flutter/services/daily_quiz_service.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

/// Topic every install joins so one Firebase send can reach all users.
const String fcmTopicAllUsers = 'all_users';

/// Must match `fcm_push_channel_id` in Android resources and
/// [SaxatSavitaApplication].
const String fcmPushChannelId = 'fcm_push';
const String fcmPushChannelName = 'Push notifications';
const String fcmPushChannelDescription =
    'Messages sent to Sakshat Savita users';
const String fcmPushPayload = 'fcm_push';
const String pushTestTitle = 'Sakshat Savita';
const String pushTestBody = 'Test notification';
const int pushTestNotificationId = 81001;

/// Title and body for an incoming FCM message, including data-only payloads.
class PushNotificationText {
  const PushNotificationText({required this.title, required this.body});

  final String title;
  final String body;

  bool get isEmpty => title.isEmpty && body.isEmpty;
}

PushNotificationText pushNotificationText({
  String? title,
  String? body,
  Map<String, dynamic> data = const {},
}) {
  String read(String? value, String key) {
    final direct = value?.trim();
    if (direct != null && direct.isNotEmpty) return direct;
    final fromData = data[key];
    if (fromData is String && fromData.trim().isNotEmpty) {
      return fromData.trim();
    }
    return '';
  }

  return PushNotificationText(
    title: read(title, 'title'),
    body: read(body, 'body'),
  );
}

bool fcmAuthorizationAllowsTopicSubscribe(AuthorizationStatus status) {
  switch (status) {
    case AuthorizationStatus.authorized:
    case AuthorizationStatus.provisional:
      return true;
    case AuthorizationStatus.denied:
    case AuthorizationStatus.notDetermined:
    case AuthorizationStatus.deniedPermanently:
      return false;
  }
}

/// Subscribe when FCM reports access, or when Android already has
/// notifications enabled but FCM still says [AuthorizationStatus.notDetermined]
/// because another plugin requested the permission first.
bool fcmShouldSubscribeToTopic({
  required AuthorizationStatus status,
  required bool notificationsEnabled,
}) {
  if (fcmAuthorizationAllowsTopicSubscribe(status)) return true;
  return status == AuthorizationStatus.notDetermined && notificationsEnabled;
}

bool fcmAuthorizationIsDenied(AuthorizationStatus status) {
  switch (status) {
    case AuthorizationStatus.denied:
    case AuthorizationStatus.deniedPermanently:
      return true;
    case AuthorizationStatus.authorized:
    case AuthorizationStatus.provisional:
    case AuthorizationStatus.notDetermined:
      return false;
  }
}

int pushNotificationId(String? messageId) {
  if (messageId == null || messageId.isEmpty) return 82000;
  return 82000 + (messageId.hashCode.abs() % 10000);
}

/// Required top-level FCM background handler. Notification payloads are shown
/// by the OS; data-only messages are posted on the push channel.
///
/// The binding must be ready before any other Flutter call. In release, the
/// background isolate crashes if [debugPrint] runs first.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint(
    'FCM background: id=${message.messageId} '
    'title=${message.notification?.title} data=${message.data}',
  );
  if (message.notification != null) return;
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    debugPrint('FCM background Firebase init error: $e');
  }
  await NotificationService().showDataOnlyPush(message);
}

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
  static const String _dailyQuizChannelId = 'daily_quiz';
  static const int dailyQuizNotificationId = 7001;
  static const String dailyQuizPayload = 'daily_quiz';

  bool _isInitialized = false;
  bool _localPluginReady = false;
  bool _pushListenersReady = false;
  bool _tokenRefreshListening = false;
  bool _pushMessagingReady = false;
  bool _pushRetryScheduled = false;
  int _pushInitAttempts = 0;
  String? _fcmToken;
  String? _installationId;
  String? _pendingNamedRoute;
  DateTime? _lastNamedRouteNav;
  bool _capturedLaunchPayload = false;
  bool _readyForNamedRoutes = false;
  Future<void>? _initFuture;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (kIsWeb) return;
    await (_initFuture ??= _doInitialize());
    if (!_pushMessagingReady) {
      await _initializeFirebaseMessaging();
    }
  }

  Future<void> _doInitialize() async {
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
        settings: initializationSettings,
        onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
      );
      _localPluginReady = true;
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

      await _captureLaunchPayload();
      await _initializeFirebaseMessaging();
      _isInitialized = true;
      debugPrint('✅ Notification service initialized successfully');
    } catch (e, stackTrace) {
      _initFuture = null;
      debugPrint('❌ Failed to initialize notifications: $e');
      debugPrint('❌ Stack trace: $stackTrace');
    }
  }

  Future<void> _captureLaunchPayload() async {
    if (_capturedLaunchPayload) return;
    _capturedLaunchPayload = true;
    try {
      final details =
          await _flutterLocalNotificationsPlugin
              .getNotificationAppLaunchDetails();
      if (details?.didNotificationLaunchApp == true) {
        _queuePayload(details?.notificationResponse?.payload);
      }
    } catch (e) {
      debugPrint('❌ Failed to read notification launch details: $e');
    }
  }

  void _queuePayload(String? payload) {
    if (payload == dailyQuizPayload ||
        (payload != null && payload.startsWith('daily_quiz'))) {
      _pendingNamedRoute = '/daily-quiz';
    }
  }

  /// Open `/daily-quiz` if a reminder tap launched the app (after splash).
  Future<void> consumePendingLaunchRoute() async {
    if (kIsWeb) return;
    _readyForNamedRoutes = true;
    final route = _pendingNamedRoute;
    if (route == null) return;
    _handleNamedRouteTap(route);
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

      await androidPlugin.createNotificationChannel(
        AndroidNotificationChannel(
          _dailyQuizChannelId,
          'Daily Quiz',
          description: 'Daily quiz reminder',
          importance: Importance.high,
          enableVibration: true,
          playSound: true,
          showBadge: true,
          enableLights: true,
          ledColor: Colors.deepOrange,
        ),
      );

      await androidPlugin.createNotificationChannel(
        AndroidNotificationChannel(
          fcmPushChannelId,
          fcmPushChannelName,
          description: fcmPushChannelDescription,
          importance: Importance.high,
          enableVibration: true,
          playSound: true,
          showBadge: true,
          enableLights: true,
          ledColor: const Color(0xFFB8572A),
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
      id: notificationId,
      title: '📚 ${appLocalizations.reading_time}',
      body: _getReminderMessage(plan, reminderTime),
      scheduledDate: scheduledDate,
      notificationDetails: NotificationDetails(
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
        id: plan.id.hashCode + 1000, // Unique ID for goal notifications
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
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
        id: streakDays + 2000, // Unique ID for streak notifications
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
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

  /// Schedule the daily quiz local reminder at the user's chosen time.
  Future<void> scheduleDailyQuizReminder({
    required int hour,
    required int minute,
  }) async {
    if (kIsWeb) return;
    if (!_isInitialized) await initialize();
    await cancelDailyQuizReminder();

    final now = DateTime.now();
    var scheduledLocal = DateTime(now.year, now.month, now.day, hour, minute);
    var scheduledDate = tz.TZDateTime.from(scheduledLocal, tz.local);
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      scheduledLocal = scheduledLocal.add(const Duration(days: 1));
      scheduledDate = tz.TZDateTime.from(scheduledLocal, tz.local);
    }

    String title = 'Today\'s teaching is ready';
    String body = 'Five teachings from Sakshat Savita — take today\'s quiz.';
    final context = NavigationService.navigatorKey.currentContext;
    if (context != null && context.mounted) {
      final l10n = AppLocalizations.of(context);
      if (l10n != null) {
        title = l10n.daily_quiz_notification_title;
        body = l10n.daily_quiz_notification_body;
      }
    }

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id: dailyQuizNotificationId,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _dailyQuizChannelId,
          'Daily Quiz',
          channelDescription: 'Daily quiz reminder',
          importance: Importance.high,
          priority: Priority.high,
          icon: 'notifications_24dp_fill',
          playSound: true,
          enableVibration: true,
          enableLights: true,
          ledColor: Colors.deepOrange,
          ledOnMs: 500,
          ledOffMs: 500,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: dailyQuizPayload,
    );
  }

  Future<void> cancelDailyQuizReminder() async {
    await _flutterLocalNotificationsPlugin.cancel(id: dailyQuizNotificationId);
  }

  Future<void> ensureDailyQuizReminderScheduled() async {
    if (kIsWeb) return;
    await initialize();
    final quiz = DailyQuizService();
    final enabled = await quiz.reminderEnabled();
    if (!enabled || !quiz.isEnabled) {
      await cancelDailyQuizReminder();
      return;
    }
    final time = await quiz.reminderTime();
    await scheduleDailyQuizReminder(hour: time.hour, minute: time.minute);
  }

  Future<void> cancelReadingPlanReminders() async {
    try {
      // Cancel all scheduled notifications
      await _flutterLocalNotificationsPlugin.cancelAll();
      debugPrint('🚫 Cancelled all reading plan reminders');
      await ensureDailyQuizReminderScheduled();
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
        await _flutterLocalNotificationsPlugin.cancel(id: notificationId);
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
      id: 9999, // Fixed ID for suggestions
      title: "💡 Reading Suggestion",
      body: randomSuggestion,
      notificationDetails: NotificationDetails(
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
        final payload = response.payload ?? '';
        if (payload == fcmPushPayload) {
          debugPrint('FCM notification tapped: id=${response.id}');
          return;
        }
        if (payload == dailyQuizPayload || payload.startsWith('daily_quiz')) {
          _handleNamedRouteTap('/daily-quiz');
          return;
        }
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

  static void _handleNamedRouteTap(String routeName) {
    try {
      final service = NotificationService();
      service._pendingNamedRoute = routeName;
      if (!service._readyForNamedRoutes) {
        return;
      }

      final now = DateTime.now();
      if (service._lastNamedRouteNav != null &&
          now.difference(service._lastNamedRouteNav!) <
              const Duration(seconds: 2)) {
        return;
      }

      final navigator = NavigationService.navigator;
      if (navigator != null) {
        service._pendingNamedRoute = null;
        service._lastNamedRouteNav = now;
        navigator.pushNamed(routeName);
        return;
      }
      final context = NavigationService.navigatorKey.currentContext;
      if (context != null) {
        service._pendingNamedRoute = null;
        service._lastNamedRouteNav = now;
        Navigator.of(context).pushNamed(routeName);
        return;
      }
      if (NavigationService.navigatorKey.currentState != null) {
        service._pendingNamedRoute = null;
        service._lastNamedRouteNav = now;
        NavigationService.navigatorKey.currentState!.pushNamed(routeName);
        return;
      }
    } catch (e) {
      debugPrint('❌ Error navigating to $routeName: $e');
      NotificationService()._pendingNamedRoute = routeName;
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
    final remindTime = DateTime.now().add(const Duration(minutes: 15));
    final scheduledDate = tz.TZDateTime.from(remindTime, tz.local);

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id: 8888, // Fixed ID for remind later
      title: "📚 Reading Reminder",
      body: "You asked to be reminded - time for your spiritual reading!",
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
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

  /// Request FCM permission, subscribe to [fcmTopicAllUsers], and show
  /// foreground messages with the local notifications plugin.
  Future<void> _initializeFirebaseMessaging() async {
    if (kIsWeb) return;
    try {
      if (!_pushListenersReady) {
        FirebaseMessaging.onMessage.listen(_onForegroundMessage);
        FirebaseMessaging.onMessageOpenedApp.listen(_logPushOpened);
        _pushListenersReady = true;
      }

      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        _logPushOpened(initialMessage);
      }

      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('FCM permission: ${settings.authorizationStatus}');

      if (Platform.isIOS) {
        await FirebaseMessaging.instance
            .setForegroundNotificationPresentationOptions(
              alert: false,
              badge: true,
              sound: false,
            );
      }

      final notificationsEnabled = await areNotificationsEnabled();
      if (fcmShouldSubscribeToTopic(
        status: settings.authorizationStatus,
        notificationsEnabled: notificationsEnabled,
      )) {
        try {
          await _subscribeToAllUsers();
        } catch (e) {
          debugPrint('❌ FCM topic subscribe error: $e');
        }
      } else {
        debugPrint(
          'FCM topic subscribe skipped: ${settings.authorizationStatus}',
        );
      }
      await _refreshPushIdentifiers();

      if (!_tokenRefreshListening) {
        _tokenRefreshListening = true;
        FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
          try {
            _fcmToken = token;
            _logFcmToken(token);
            final current =
                await FirebaseMessaging.instance.getNotificationSettings();
            final enabled = await areNotificationsEnabled();
            if (fcmShouldSubscribeToTopic(
              status: current.authorizationStatus,
              notificationsEnabled: enabled,
            )) {
              await _subscribeToAllUsers();
            }
          } catch (e) {
            debugPrint('❌ FCM token refresh error: $e');
          }
        });
      }
      _pushMessagingReady = true;
    } catch (e, stackTrace) {
      debugPrint('❌ FCM initialization error: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      _schedulePushInitRetry();
    }
  }

  /// Release startup can request notification permission before the activity
  /// exists. Retry on a later frame instead of leaving the install unsubscribed.
  void _schedulePushInitRetry() {
    if (_pushRetryScheduled || _pushMessagingReady || _pushInitAttempts >= 3) {
      return;
    }
    _pushInitAttempts++;
    _pushRetryScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pushRetryScheduled = false;
      if (_pushMessagingReady) return;
      _initializeFirebaseMessaging();
    });
  }

  /// FCM registration token and Firebase installation ID for the console
  /// "Send test message" field. Unavailable on web and before FCM init.
  Future<PushDeviceIdentity> loadPushDeviceIdentity() async {
    if (kIsWeb) {
      return const PushDeviceIdentity(
        available: false,
        notificationsDenied: false,
      );
    }
    await initialize();
    if (!_pushMessagingReady) {
      return const PushDeviceIdentity(
        available: false,
        notificationsDenied: false,
      );
    }

    var notificationsDenied = false;
    try {
      final settings =
          await FirebaseMessaging.instance.getNotificationSettings();
      notificationsDenied = fcmAuthorizationIsDenied(
        settings.authorizationStatus,
      );
    } catch (e) {
      debugPrint('❌ FCM settings error: $e');
    }
    await _refreshPushIdentifiers();
    return PushDeviceIdentity(
      available: true,
      notificationsDenied: notificationsDenied,
      fcmToken: _nonEmpty(_fcmToken),
      installationId: _nonEmpty(_installationId),
    );
  }

  Future<void> _refreshPushIdentifiers() async {
    try {
      _fcmToken = await FirebaseMessaging.instance.getToken();
      _logFcmToken(_fcmToken);
    } catch (e) {
      debugPrint('❌ FCM getToken error: $e');
    }
    try {
      final id = (await FirebaseInstallations.instance.getId()).trim();
      if (id.isNotEmpty) _installationId = id;
    } catch (e) {
      debugPrint('❌ Firebase installation id error: $e');
    }
  }

  String? _nonEmpty(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  Future<void> _subscribeToAllUsers() async {
    await FirebaseMessaging.instance.subscribeToTopic(fcmTopicAllUsers);
    debugPrint('FCM subscribed to topic $fcmTopicAllUsers');
  }

  void _logFcmToken(String? token) {
    if (!kDebugMode) return;
    debugPrint('FCM token: $token');
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    debugPrint(
      'FCM foreground: id=${message.messageId} '
      'title=${message.notification?.title} data=${message.data}',
    );
    try {
      await _showIncomingPush(message);
    } catch (e, stackTrace) {
      debugPrint('❌ FCM foreground display error: $e');
      debugPrint('❌ Stack trace: $stackTrace');
    }
  }

  void _logPushOpened(RemoteMessage message) {
    debugPrint(
      'FCM opened app: id=${message.messageId} '
      'title=${message.notification?.title} data=${message.data}',
    );
  }

  /// Posts a data-only FCM message. Called from the background isolate.
  Future<void> showDataOnlyPush(RemoteMessage message) async {
    if (kIsWeb) return;
    try {
      await _ensurePluginForBackgroundIsolate();
      await _showIncomingPush(message);
    } catch (e, stackTrace) {
      debugPrint('❌ FCM data message display error: $e');
      debugPrint('❌ Stack trace: $stackTrace');
    }
  }

  Future<void> _ensurePluginForBackgroundIsolate() async {
    if (_localPluginReady) return;
    tz.initializeTimeZones();
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('ic_launcher_foreground'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    );
    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }
    _localPluginReady = true;
  }

  Future<void> _showIncomingPush(RemoteMessage message) async {
    final text = pushNotificationText(
      title: message.notification?.title,
      body: message.notification?.body,
      data: message.data,
    );
    if (text.isEmpty) {
      debugPrint('FCM message had no displayable text: ${message.messageId}');
      return;
    }
    await _showPushNotification(
      id: pushNotificationId(message.messageId),
      title: text.title,
      body: text.body,
    );
  }

  NotificationDetails _pushNotificationDetails({
    required String title,
    required String body,
  }) {
    // Bundled launcher portrait. The Firebase console "Notification image"
    // field only accepts a public URL, so pushes the app displays use this.
    const image = DrawableResourceAndroidBitmap('ic_launcher_foreground');
    return NotificationDetails(
      android: AndroidNotificationDetails(
        fcmPushChannelId,
        fcmPushChannelName,
        channelDescription: fcmPushChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: 'notifications_24dp_fill',
        largeIcon: image,
        styleInformation: BigPictureStyleInformation(
          image,
          contentTitle: title,
          summaryText: body,
          hideExpandedLargeIcon: true,
        ),
        playSound: true,
        enableVibration: true,
        enableLights: true,
        ledColor: const Color(0xFFB8572A),
        ledOnMs: 1000,
        ledOffMs: 500,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  Future<void> _showPushNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await _flutterLocalNotificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _pushNotificationDetails(title: title, body: body),
      payload: fcmPushPayload,
    );
  }

  /// Shows the same channel and copy as an incoming test push, and returns
  /// the device FCM token when notification permission allows it.
  Future<PushTestResult> presentPushTestNotification() async {
    if (kIsWeb) {
      return const PushTestResult(
        token: null,
        subscribed: false,
        notificationShown: false,
      );
    }
    await initialize();
    var notificationShown = false;
    try {
      await _showPushNotification(
        id: pushTestNotificationId,
        title: pushTestTitle,
        body: pushTestBody,
      );
      notificationShown = true;
    } catch (e) {
      debugPrint('❌ Push test notification error: $e');
    }

    String? token = _fcmToken;
    var subscribed = false;
    try {
      final settings =
          await FirebaseMessaging.instance.getNotificationSettings();
      if (fcmAuthorizationAllowsTopicSubscribe(settings.authorizationStatus)) {
        await _subscribeToAllUsers();
        subscribed = true;
        token = await FirebaseMessaging.instance.getToken();
        _fcmToken = token;
        _logFcmToken(token);
      } else {
        debugPrint(
          'FCM test token unavailable: ${settings.authorizationStatus}',
        );
      }
    } catch (e) {
      debugPrint('❌ FCM test token error: $e');
    }

    return PushTestResult(
      token: token,
      subscribed: subscribed,
      notificationShown: notificationShown,
    );
  }
}

class PushTestResult {
  const PushTestResult({
    required this.token,
    required this.subscribed,
    required this.notificationShown,
  });

  final String? token;
  final bool subscribed;
  final bool notificationShown;
}

class PushDeviceIdentity {
  const PushDeviceIdentity({
    required this.available,
    required this.notificationsDenied,
    this.fcmToken,
    this.installationId,
  });

  final bool available;
  final bool notificationsDenied;
  final String? fcmToken;
  final String? installationId;
}
