import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      type: json['type'] as String? ?? 'general',
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance =>
      _instance ??= NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  RealtimeChannel? _channel;
  RealtimeChannel? _broadcastChannel;

  SupabaseClient get _client => Supabase.instance.client;

  // ─── Initialize ──────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_initialized) return;
    if (kIsWeb) {
      _initialized = true;
      return;
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification tapped: ${response.payload}');
      },
    );

    // Create the Android notification channel with high importance for heads-up display
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      const channel = AndroidNotificationChannel(
        'maintix_channel',
        'Maintix Notifications',
        description: 'Maintix app notifications',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );
      await androidPlugin.createNotificationChannel(channel);
    }

    _initialized = true;
  }

  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    try {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        return granted ?? false;
      }
      final iosPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (iosPlugin != null) {
        final granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    } catch (e) {
      debugPrint('requestPermission error: $e');
    }
    return false;
  }

  // ─── Show local notification ──────────────────────────────────────────────

  Future<void> showNotification({
    required String title,
    required String body,
    int id = 0,
  }) async {
    if (kIsWeb || !_initialized) return;
    try {
      const androidDetails = AndroidNotificationDetails(
        'maintix_channel',
        'Maintix Notifications',
        channelDescription: 'Maintix app notifications',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
        ticker: 'ticker',
        fullScreenIntent: false,
        visibility: NotificationVisibility.public,
         styleInformation: BigTextStyleInformation(body),
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.active,
      );
      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
      );
    } catch (e) {
      debugPrint('showNotification error: $e');
    }
  }

  // ─── Save to Supabase ─────────────────────────────────────────────────────

  Future<void> saveNotification({
    required String userId,
    required String title,
    required String body,
    String type = 'general',
  }) async {
    try {
      await _client.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'body': body,
        'type': type,
      });
    } catch (e) {
      debugPrint('saveNotification error: $e');
    }
  }

  // ─── Trigger notification (show + save) ──────────────────────────────────

  Future<void> triggerNotification({
    required String userId,
    required String title,
    required String body,
    String type = 'general',
    int localId = 0,
  }) async {
    await Future.wait([
      showNotification(title: title, body: body, id: localId),
      saveNotification(userId: userId, title: title, body: body, type: type),
    ]);
  }

  // ─── Fetch notifications ──────────────────────────────────────────────────

  Future<List<NotificationModel>> fetchNotifications(String userId) async {
    try {
      final data = await _client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);
      return (data as List)
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('fetchNotifications error: $e');
      return [];
    }
  }

  Future<void> markAllRead(String userId) async {
    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId);
    } catch (e) {
      debugPrint('markAllRead error: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _client.from('notifications').delete().eq('id', notificationId);
    } catch (e) {
      debugPrint('deleteNotification error: $e');
    }
  }

  // ─── Real-time subscription ───────────────────────────────────────────────

  void subscribeToUserNotifications(
    String userId,
    void Function(NotificationModel) onNew,
  ) {
    _channel?.unsubscribe();
    _channel = _client
        .channel('notifications_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            try {
              final model = NotificationModel.fromJson(payload.newRecord);
              onNew(model);
              // Show system status bar notification immediately
              showNotification(
                title: model.title,
                body: model.body,
                id: DateTime.now().millisecondsSinceEpoch % 100000,
              );
            } catch (e) {
              debugPrint('realtime notification parse error: $e');
            }
          },
        )
        .subscribe();
  }

  /// Subscribe to admin_broadcasts table — triggers a system push notification
  /// for every new broadcast row inserted (visible to all users).
  void subscribeToAdminBroadcasts(
    void Function(String title, String body) onBroadcast,
  ) {
    _broadcastChannel?.unsubscribe();
    _broadcastChannel = _client
        .channel('admin_broadcasts_global')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'admin_broadcasts',
          callback: (payload) {
            try {
              final title = payload.newRecord['title'] as String? ?? 'Maintix';
              final body = payload.newRecord['body'] as String? ?? '';
              onBroadcast(title, body);
              showNotification(
                title: title,
                body: body,
                id: DateTime.now().millisecondsSinceEpoch % 100000,
              );
            } catch (e) {
              debugPrint('realtime broadcast parse error: $e');
            }
          },
        )
        .subscribe();
  }

  void unsubscribe() {
    _channel?.unsubscribe();
    _channel = null;
    _broadcastChannel?.unsubscribe();
    _broadcastChannel = null;
  }

  // ─── Admin: broadcast to all users ───────────────────────────────────────

  Future<bool> broadcastToAllUsers({
    required String title,
    required String body,
    required String sentBy,
  }) async {
    try {
      // Save broadcast record
      await _client.from('admin_broadcasts').insert({
        'title': title,
        'body': body,
        'sent_by': sentBy,
      });

      // Fetch all user IDs from profiles
      final profiles = await _client.from('profiles').select('id');
      final userIds = (profiles as List).map((p) => p['id'] as String).toList();

      // Insert notification for each user
      if (userIds.isNotEmpty) {
        final notifications = userIds
            .map(
              (uid) => {
                'user_id': uid,
                'title': title,
                'body': body,
                'type': 'broadcast',
              },
            )
            .toList();
        await _client.from('notifications').insert(notifications);
      }
      return true;
    } catch (e) {
      debugPrint('broadcastToAllUsers error: $e');
      return false;
    }
  }
}
