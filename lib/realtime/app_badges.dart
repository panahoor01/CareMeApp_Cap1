import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show AppLifecycleListener;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Live badge numbers and "something changed" signal, fed by Supabase Realtime.
class AppBadges {
  AppBadges._();
  static final AppBadges instance = AppBadges._();

  final ValueNotifier<int> unseenBookings = ValueNotifier(0);
  final ValueNotifier<int> unreadNotifications = ValueNotifier(0);

  /// Bumps when a new notification arrives (or the app resumes).
  /// Pages listen to this and reload their data.
  final ValueNotifier<int> changes = ValueNotifier(0);

  SupabaseClient get _db => Supabase.instance.client;
  RealtimeChannel? _channel;
  String? _userId;
  AppLifecycleListener? _lifecycle;

  void start() {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return;
    if (_userId == uid && _channel != null) {
      refresh();
      return;
    }
    stop();
    _userId = uid;

    _channel = _db
        .channel('app-badges-$uid')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'recipient_id',
            value: uid,
          ),
          callback: (payload) {
            if (payload.eventType == PostgresChangeEvent.insert) {
              changes.value++;
            }
            refresh();
          },
        )
        .subscribe();

    _lifecycle = AppLifecycleListener(onResume: () {
      changes.value++;
      refresh();
    });

    refresh();
  }

  void stop() {
    final ch = _channel;
    _channel = null;
    _userId = null;
    if (ch != null) _db.removeChannel(ch);
    _lifecycle?.dispose();
    _lifecycle = null;
    unseenBookings.value = 0;
    unreadNotifications.value = 0;
  }

  Future<void> refresh() async {
    if (_db.auth.currentUser == null) return;
    try {
      final res = await _db.rpc('get_badge_counts');
      final m = Map<String, dynamic>.from(res as Map);
      unseenBookings.value = (m['bookings'] as num?)?.toInt() ?? 0;
      unreadNotifications.value = (m['notifications'] as num?)?.toInt() ?? 0;
    } catch (e) {
      debugPrint('badge refresh failed: $e');
    }
  }

  Future<void> markNotificationsRead() async {
    try {
      await _db.rpc('mark_notifications_read');
      unreadNotifications.value = 0;
    } catch (e) {
      debugPrint('mark notifications read failed: $e');
    }
  }
}
