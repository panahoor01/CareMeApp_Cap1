import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// Model + sample data (same pattern as `FeedItem`/`sampleFeed` in feed.dart)
/// ─────────────────────────────────────────────────────────────────────────
class ConversationItem {
  final String name;
  final String lastMessage;
  final String time;
  final String imageUrl;
  final int unreadCount;
  final bool isOnline;

  const ConversationItem({
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.imageUrl,
    this.unreadCount = 0,
    this.isOnline = false,
  });
}

const sampleConversations = [
  ConversationItem(
    name: 'Aliza Watts',
    lastMessage: 'Sure! I have a 2 PM slot open tomorrow.',
    time: '9:41 AM',
    imageUrl: 'assets/man1.jpeg',
    unreadCount: 2,
    isOnline: true,
  ),
  ConversationItem(
    name: 'Adrian Mateo Cruz',
    lastMessage: 'Thank you for booking! See you soon.',
    time: 'Yesterday',
    imageUrl: 'assets/man2.jpeg',
  ),
  ConversationItem(
    name: 'Lila Katherine Bennett',
    lastMessage: 'Can you send a photo of the style you want?',
    time: 'Yesterday',
    imageUrl: 'assets/man3.jpeg',
    unreadCount: 1,
  ),
  ConversationItem(
    name: 'Rafael Tomas Dela Cruz',
    lastMessage: 'Got it, rescheduled to Friday 5 PM.',
    time: 'Mon',
    imageUrl: 'assets/man4.jpeg',
  ),
];

/// ─────────────────────────────────────────────────────────────────────────
/// Messages list (inbox)
/// ─────────────────────────────────────────────────────────────────────────
class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = sampleConversations
        .where((c) => c.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                  ),
                  const SizedBox(width: 4),
                  Image.asset('assets/careme_logo.png', height: 34, width: 34),
                  const SizedBox(width: 12),
                  const Text(
                    'CareMe',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child:
                        const Icon(Icons.edit_outlined, color: Colors.black87),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Messages',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _query = value),
                      decoration: const InputDecoration(
                        icon: Icon(Icons.search, color: Color(0xFF9CA3AF)),
                        hintText: 'Search messages',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Text(
                        'No conversations found.',
                        style: TextStyle(color: Color(0xFF6B7280)),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final convo = filtered[index];
                        return _ConversationTile(
                          conversation: convo,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    ChatThreadPage(conversation: convo),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ConversationItem conversation;
  final VoidCallback onTap;

  const _ConversationTile({required this.conversation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasUnread = conversation.unreadCount > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: AssetImage(conversation.imageUrl),
                ),
                if (conversation.isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    conversation.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: hasUnread
                          ? const Color(0xFF111827)
                          : const Color(0xFF6B7280),
                      fontWeight:
                          hasUnread ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  conversation.time,
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                ),
                const SizedBox(height: 8),
                if (hasUnread)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2B73E9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${conversation.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────
/// Chat thread (opened when a conversation is tapped)
/// ─────────────────────────────────────────────────────────────────────────
class ChatMessage {
  final String text;
  final bool isMe;

  const ChatMessage({required this.text, required this.isMe});
}

class ChatThreadPage extends StatefulWidget {
  final ConversationItem conversation;

  const ChatThreadPage({super.key, required this.conversation});

  @override
  State<ChatThreadPage> createState() => _ChatThreadPageState();
}

class _ChatThreadPageState extends State<ChatThreadPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late List<ChatMessage> _messages;

  @override
  void initState() {
    super.initState();
    _messages = [
      ChatMessage(
          text: 'Hi! Is your ${_serviceHint()} slot open this week?',
          isMe: true),
      ChatMessage(text: widget.conversation.lastMessage, isMe: false),
    ];
  }

  String _serviceHint() => 'service';

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isMe: true));
      _messageController.clear();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                  ),
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: AssetImage(widget.conversation.imageUrl),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.conversation.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.conversation.isOnline
                              ? 'Active now'
                              : 'Offline',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.calendar_today_outlined,
                        color: Colors.black87, size: 18),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return Align(
                    alignment: message.isMe
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.72,
                      ),
                      decoration: BoxDecoration(
                        color: message.isMe
                            ? const Color(0xFF2B73E9)
                            : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(18),
                          topRight: const Radius.circular(18),
                          bottomLeft: Radius.circular(message.isMe ? 18 : 4),
                          bottomRight: Radius.circular(message.isMe ? 4 : 18),
                        ),
                      ),
                      child: Text(
                        message.text,
                        style: TextStyle(
                          color: message.isMe ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: TextField(
                        controller: _messageController,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: const InputDecoration(
                          hintText: 'Type a message',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(
                        color: Color(0xFF7BB8F0),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
