import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'chat_screen.dart';
import 'chat_users_screen.dart';

/// Inbox: conversations ordered by latest message (newest on top).
/// Tap one to open the chat; the button starts a new chat with anyone.
class ChatInboxScreen extends StatefulWidget {
  const ChatInboxScreen({super.key});

  @override
  State<ChatInboxScreen> createState() => _ChatInboxScreenState();
}

class _ChatInboxScreenState extends State<ChatInboxScreen> {
  final _db = Supabase.instance.client;
  RealtimeChannel? _channel;
  List<Map<String, dynamic>>? _rows;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    // Refresh the list whenever a message is sent, received or deleted.
    // Row-level security means only your own messages trigger this.
    _channel = _db
        .channel('inbox-${_db.auth.currentUser!.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'messages',
          callback: (_) => _load(),
        )
        .subscribe();
  }

  @override
  void dispose() {
    if (_channel != null) _db.removeChannel(_channel!);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final rows = await _db.rpc('get_chat_inbox');
      if (!mounted) return;
      setState(() {
        _rows = List<Map<String, dynamic>>.from(rows);
        _error = null;
      });
    } catch (e) {
      debugPrint('load inbox failed: $e');
      if (!mounted) return;
      setState(() => _error = '$e');
    }
  }

  String _when(DateTime t) {
    final now = DateTime.now();
    bool same(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;

    if (same(t, now)) {
      final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
      final m = t.minute.toString().padLeft(2, '0');
      return '$h:$m ${t.hour >= 12 ? 'PM' : 'AM'}';
    }
    if (same(t, now.subtract(const Duration(days: 1)))) return 'Yesterday';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[t.month - 1]} ${t.day}';
  }

  Future<void> _open(String id, String name) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(otherUserId: id, otherUserName: name),
      ),
    );
    _load(); // refresh after coming back
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChatUsersScreen()),
          );
          _load();
        },
        icon: const Icon(Icons.edit_outlined),
        label: const Text('New message'),
      ),
      body: _body(),
    );
  }

  Widget _body() {
    if (_error != null && _rows == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Could not load messages.\n$_error',
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (_rows == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_rows!.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Icon(Icons.chat_bubble_outline, size: 48, color: Color(0xFF9CA3AF)),
            SizedBox(height: 12),
            Center(
              child: Text(
                'No messages yet.\nTap "New message" to start a chat.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
            ),
          ],
        ),
      );
    }

    final myId = _db.auth.currentUser!.id;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 88),
        itemCount: _rows!.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final r = _rows![i];
          final name = '${r['first_name']} ${r['last_name']}';
          final mine = r['last_sender_id'] == myId;
          final unread = (r['unread_count'] as int?) ?? 0;
          final hasUnread = unread > 0;
          final preview = '${mine ? 'You: ' : ''}${r['last_message']}';
          final at = DateTime.parse(r['last_message_at'] as String).toLocal();

          return ListTile(
            tileColor: hasUnread ? const Color(0xFFEFF6FF) : null,
            leading: CircleAvatar(child: Text(name[0].toUpperCase())),
            title: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w500),
            ),
            subtitle: Text(
              preview,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: hasUnread ? FontWeight.w700 : FontWeight.normal,
                color: hasUnread ? Colors.black : null,
              ),
            ),
            trailing: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _when(at),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: hasUnread ? FontWeight.w700 : FontWeight.normal,
                    color: hasUnread
                        ? const Color(0xFF1D4ED8)
                        : const Color(0xFF6B7280),
                  ),
                ),
                if (hasUnread)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D4ED8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      unread > 99 ? '99+' : '$unread',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            onTap: () => _open(r['other_user_id'] as String, name),
          );
        },
      ),
    );
  }
}
