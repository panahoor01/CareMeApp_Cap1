import 'package:supabase_flutter/supabase_flutter.dart';

class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.createdAt,
  });

  factory Message.fromMap(Map<String, dynamic> map) => Message(
        id: map['id'] as String,
        conversationId: map['conversation_id'] as String,
        senderId: map['sender_id'] as String,
        receiverId: map['receiver_id'] as String,
        content: map['content'] as String,
        createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      );
}

class MessageService {
  MessageService._();
  static final instance = MessageService._();

  final SupabaseClient _db = Supabase.instance.client;

  String get currentUserId {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Sign in before using chat.');
    }
    return userId;
  }

  Future<String> _conversationIdWith(String otherUserId) async {
    final result = await _db.rpc(
      'get_or_create_chat_conversation',
      params: {'p_other_user_id': otherUserId},
    );
    return result as String;
  }

  /// Loads existing messages and receives inserts/deletes in real time.
  Stream<List<Message>> watchMessages(String otherUserId) {
    return Stream.fromFuture(_conversationIdWith(otherUserId)).asyncExpand(
      (conversationId) => _db
          .from('messages')
          .stream(primaryKey: ['id'])
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true)
          .map((rows) {
            final messages = rows.map(Message.fromMap).toList()
              ..sort((a, b) {
                final byTime = a.createdAt.compareTo(b.createdAt);
                return byTime != 0 ? byTime : a.id.compareTo(b.id);
              });
            return messages;
          }),
    );
  }

  Future<void> sendMessage({
    required String otherUserId,
    required String content,
  }) async {
    final text = content.trim();
    if (text.isEmpty) return;

    final conversationId = await _conversationIdWith(otherUserId);
    await _db.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': currentUserId,
      'receiver_id': otherUserId,
      'content': text,
    });
  }

  Future<void> deleteMessage(String messageId) async {
    await _db.from('messages').delete().eq('id', messageId);
  }

  Future<void> markRead(String otherUserId) async {
    await _db.rpc('mark_chat_read', params: {'p_other_user_id': otherUserId});
  }
}
