import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings);
  }

  Future<void> requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // 安排喝水提醒
  Future<void> scheduleWaterReminders({
    required String wakeUp, // "08:00"
    required String sleepTime, // "23:00"
    required int intervalMinutes, // 60 = 每小时提醒
  }) async {
    // 取消所有现有提醒
    await cancelAll();

    final wakeParts = wakeUp.split(':');
    final sleepParts = sleepTime.split(':');
    
    final wakeHour = int.parse(wakeParts[0]);
    final wakeMin = int.parse(wakeParts[1]);
    final sleepHour = int.parse(sleepParts[0]);
    final sleepMin = int.parse(sleepParts[1]);

    final now = DateTime.now();
    var current = DateTime(now.year, now.month, now.day, wakeHour, wakeMin);
    final end = DateTime(now.year, now.month, now.day, sleepHour, sleepMin);

    int id = 100;
    while (current.isBefore(end)) {
      if (current.isAfter(now)) {
        await _scheduleNotification(
          id: id++,
          time: current,
          title: '💧 该喝水啦！',
          body: '保持水分，身体更健康～',
        );
      }
      current = current.add(Duration(minutes: intervalMinutes));
    }

    // 为明天也安排提醒
    current = DateTime(now.year, now.month, now.day + 1, wakeHour, wakeMin);
    final tomorrowEnd = DateTime(now.year, now.month, now.day + 1, sleepHour, sleepMin);
    while (current.isBefore(tomorrowEnd)) {
      await _scheduleNotification(
        id: id++,
        time: current,
        title: '💧 该喝水啦！',
        body: '保持水分，身体更健康～',
      );
      current = current.add(Duration(minutes: intervalMinutes));
    }
  }

  Future<void> _scheduleNotification({
    required int id,
    required DateTime time,
    required String title,
    required String body,
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(time, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'water_reminder',
          '喝水提醒',
          channelDescription: '定期提醒您喝水',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // 发送即时通知
  Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      9999,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'water_tracker',
          'Water Tracker',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
