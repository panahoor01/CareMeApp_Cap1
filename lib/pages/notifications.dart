import 'package:flutter/material.dart';
import 'package:flutter_application_practice/auth/auth_service.dart';
import 'package:flutter_application_practice/pages/bookings/booking_detail_sheet.dart';
import 'package:flutter_application_practice/pages/bookings/booking_models.dart';
import 'package:flutter_application_practice/pages/bookings/bookings_repository.dart';
import 'package:flutter_application_practice/realtime/app_badges.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppNotification {
  final String id;
  final String actorName;
  final String? actorImage;
  final String type;
  final String message;
  final String? bookingId;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.actorName,
    this.actorImage,
    required this.type,
    required this.message,
    this.bookingId,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromRow(Map<String, dynamic> r) => AppNotification(
        id: r['notification_id'] as String,
        actorName: r['actor_name'] as String,
        actorImage: r['actor_image'] as String?,
        type: r['notification_type'] as String,
        message: r['message'] as String,
        bookingId: r['booking_id'] as String?,
        isRead: r['is_read'] as bool,
        createdAt: DateTime.parse(r['created_at'] as String).toLocal(),
      );

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        actorName: actorName,
        actorImage: actorImage,
        type: type,
        message: message,
        bookingId: bookingId,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );
}

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<AppNotification> _items = [];
  BookingsStore? _bookingStore;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    AppBadges.instance.changes.addListener(_load); // live updates
    _load();
  }

  @override
  void dispose() {
    AppBadges.instance.changes.removeListener(_load);
    _bookingStore?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final res = await Supabase.instance.client.rpc('get_my_notifications');
      final list = (res as List)
          .map((e) =>
              AppNotification.fromRow(Map<String, dynamic>.from(e as Map)))
          .toList();
      if (!mounted) return;
      setState(() {
        _items = list;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      debugPrint('load notifications failed: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (_items.isEmpty) _error = AuthService.friendlyError(e);
      });
    }
  }

  Future<void> _openNotification(AppNotification notification) async {
    var selected = notification;
    if (!notification.isRead) {
      try {
        await Supabase.instance.client.rpc('mark_notification_read', params: {
          'p_notification_id': notification.id,
        });
        selected = notification.copyWith(isRead: true);
        if (!mounted) return;
        setState(() {
          _items = _items
              .map((item) => item.id == notification.id ? selected : item)
              .toList();
        });
        await AppBadges.instance.refresh();
      } catch (e) {
        debugPrint('mark notification read failed: $e');
      }
    }
    if (!mounted) return;
    if (await _openBookingNotification(selected)) return;
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => NotificationDetailsPage(notification: selected),
      ),
    );
  }

  Future<bool> _openBookingNotification(AppNotification notification) async {
    if (!notification.type.startsWith('booking_')) return false;

    try {
      var bookingId = notification.bookingId;
      if (bookingId == null) {
        final row = await Supabase.instance.client
            .from('notifications')
            .select('booking_id')
            .eq('notification_id', notification.id)
            .maybeSingle();
        bookingId = row?['booking_id'] as String?;
      }
      if (bookingId == null) return false;

      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return false;
      final user = await Supabase.instance.client
          .from('users')
          .select('role')
          .eq('id', userId)
          .maybeSingle();
      if (user == null || !mounted) return false;

      final store = _bookingStore ??= BookingsStore();
      await store.load();
      if (!mounted) return true;
      BookingItem? booking;
      for (final item in store.items) {
        if (item.id == bookingId) {
          booking = item;
          break;
        }
      }
      if (booking == null) return false;

      final isBeautician = user['role'] == 'beautician';
      if (notification.type == 'booking_on_the_way' ||
          notification.type == 'booking_ongoing') {
        await openBooking(
          context,
          booking: booking,
          isBeautician: isBeautician,
          store: store,
        );
      } else {
        await showBookingDetail(
          context,
          booking: booking,
          isBeautician: isBeautician,
          store: store,
        );
      }
      return true;
    } catch (e) {
      debugPrint('open booking notification failed: $e');
      return false;
    }
  }

  Widget _avatar(AppNotification n) {
    final initial = n.actorName.isEmpty ? '?' : n.actorName[0].toUpperCase();
    final image = n.actorImage;
    return CircleAvatar(
      radius: 22,
      backgroundColor: const Color(0xFFE0F2FE),
      backgroundImage:
          (image != null && image.isNotEmpty) ? NetworkImage(image) : null,
      child: (image != null && image.isNotEmpty) ? null : Text(initial),
    );
  }

  Widget _body() {
    const physics = AlwaysScrollableScrollPhysics();

    if (_loading) {
      return ListView(physics: physics, children: const [
        SizedBox(height: 120),
        Center(child: CircularProgressIndicator()),
      ]);
    }
    if (_error != null && _items.isEmpty) {
      return ListView(physics: physics, children: [
        const SizedBox(height: 100),
        Center(child: Text(_error!)),
        TextButton(onPressed: _load, child: const Text('Retry')),
      ]);
    }
    if (_items.isEmpty) {
      return ListView(physics: physics, children: const [
        SizedBox(height: 100),
        Icon(Icons.notifications_none, size: 48, color: Color(0xFF9CA3AF)),
        SizedBox(height: 10),
        Center(
          child: Text('No notifications yet.',
              style: TextStyle(color: Color(0xFF6B7280))),
        ),
      ]);
    }

    return ListView.separated(
      physics: physics,
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final n = _items[index];
        final isNew = !n.isRead;
        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: () => _openNotification(n),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              decoration: BoxDecoration(
                color: isNew ? const Color(0xFFFFF1EF) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color:
                      isNew ? const Color(0xFFF28B82) : const Color(0xFFE5E7EB),
                  width: isNew ? 1.5 : 1,
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _avatar(n),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                n.actorName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                            Text(timeAgo(n.createdAt),
                                style:
                                    const TextStyle(color: Color(0xFF9CA3AF))),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(n.message,
                            style: const TextStyle(color: Color(0xFF4B5563))),
                      ],
                    ),
                  ),
                  if (isNew)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFDCD7),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text('New',
                          style: TextStyle(
                              color: Color(0xFFC43D32),
                              fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 18),
              Row(
                children: [
                  Image.asset('assets/careme_logo.png', height: 34, width: 34),
                  const SizedBox(width: 12),
                  const Text(
                    'CareMe',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Notifications',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Latest updates for your account and bookings.',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: RefreshIndicator(onRefresh: _load, child: _body()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NotificationDetailsPage extends StatelessWidget {
  final AppNotification notification;

  const NotificationDetailsPage({
    super.key,
    required this.notification,
  });

  String get _title => switch (notification.type) {
        'booking_accepted' => 'Booking accepted',
        'booking_declined' => 'Booking declined',
        'booking_cancelled' => 'Booking cancelled',
        'booking_on_the_way' => 'Beautician on the way',
        'booking_ongoing' => 'Booking in progress',
        _ => 'Account update',
      };

  @override
  Widget build(BuildContext context) {
    final receivedAt =
        '${dateLong(notification.createdAt)} at ${timeLabel(notification.createdAt.hour * 60 + notification.createdAt.minute)}';
    final image = notification.actorImage;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text('Notification details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFFE0F2FE),
            backgroundImage:
                image == null || image.isEmpty ? null : NetworkImage(image),
            child: image == null || image.isEmpty
                ? Text(notification.actorName.isEmpty
                    ? '?'
                    : notification.actorName[0].toUpperCase())
                : null,
          ),
          const SizedBox(height: 20),
          Text(_title,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(receivedAt, style: const TextStyle(color: Color(0xFF6B7280))),
          const Divider(height: 32),
          const Text('From',
              style: TextStyle(
                  color: Color(0xFF6B7280), fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(notification.actorName,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          const Text('Message',
              style: TextStyle(
                  color: Color(0xFF6B7280), fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(notification.message,
              style: const TextStyle(fontSize: 16, height: 1.5)),
        ],
      ),
    );
  }
}
