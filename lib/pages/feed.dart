import 'package:flutter/material.dart';
import 'package:flutter_application_practice/pages/detail_page.dart';
import 'package:flutter_application_practice/pages/message_page.dart';

/// A single work post made by a beautician.
class FeedPost {
  final String name;
  final String avatarUrl;
  final String distance;
  final String timeAgo;
  final String caption;
  final List<String> images;
  int likeCount;
  int commentCount;
  bool isLiked;

  FeedPost({
    required this.name,
    required this.avatarUrl,
    required this.distance,
    required this.timeAgo,
    required this.caption,
    required this.images,
    required this.likeCount,
    required this.commentCount,
    this.isLiked = false,
  });
}

final List<FeedPost> samplePosts = [
  FeedPost(
    name: 'Erwin Mar',
    avatarUrl: 'assets/man1.jpeg',
    distance: '10 km away',
    timeAgo: '25min',
    caption: 'Upgrade your look, upgrade your vibe.',
    images: ['assets/work1.jpg', 'assets/work2.jpg'],
    likeCount: 1100,
    commentCount: 250,
  ),
  FeedPost(
    name: 'Aliza Watts',
    avatarUrl: 'assets/man2.jpeg',
    distance: '2 km away',
    timeAgo: '1hr',
    caption: 'Fresh nails for the weekend ✨ Book your slot now!',
    images: ['assets/work3.jpg'],
    likeCount: 842,
    commentCount: 96,
  ),
  FeedPost(
    name: 'Lila Katherine Bennett',
    avatarUrl: 'assets/man3.jpeg',
    distance: '4 km away',
    timeAgo: '3hrs',
    caption: 'Soft glam for a soft life 🌸',
    images: ['assets/work4.jpg', 'assets/work1.jpg'],
    likeCount: 530,
    commentCount: 41,
  ),
  FeedPost(
    name: 'Rafael Tomas Dela Cruz',
    avatarUrl: 'assets/man4.jpeg',
    distance: '5 km away',
    timeAgo: '5hrs',
    caption: 'New spa package available this week!',
    images: ['assets/work2.jpg'],
    likeCount: 312,
    commentCount: 18,
  ),
];

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  bool _isActive = true;
  double _radiusKm = 10;

  void _toggleLike(FeedPost post) {
    setState(() {
      post.isLiked = !post.isLiked;
      post.likeCount += post.isLiked ? 1 : -1;
    });
  }

  Future<void> _openDistanceFilter() async {
    double tempValue = _radiusKm;
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Search radius',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${tempValue.round()} km',
                    style:
                        const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                  ),
                  Slider(
                    value: tempValue,
                    min: 1,
                    max: 50,
                    divisions: 49,
                    activeColor: const Color(0xFF22C55E),
                    label: '${tempValue.round()} km',
                    onChanged: (value) {
                      setSheetState(() => tempValue = value);
                    },
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF22C55E),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        setState(() => _radiusKm = tempValue);
                        Navigator.of(context).pop();
                      },
                      child: const Text('Apply',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openPostOptions(FeedPost post) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text("View ${post.name}'s profile"),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ItemDetailPage(
                        title: post.name,
                        subtitle: 'Professional Beautician ALL IN',
                        imageUrl: post.avatarUrl,
                        description:
                            'A professional beautician offering quality services near you. Book now or view more details.',
                        price: 'Starting at ₱1,500',
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: const Text('Report post'),
                onTap: () => Navigator.of(context).pop(),
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancel'),
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openComments(FeedPost post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Comments',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    itemCount: post.commentCount.clamp(0, 20),
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CircleAvatar(
                              radius: 16, backgroundColor: Color(0xFFE5E7EB)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Guest User',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 2),
                                Text('Great work! 🔥 (#${index + 1})',
                                    style: const TextStyle(
                                        color: Color(0xFF6B7280))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar: logo, name, active toggle, chat icon
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  Image.asset('assets/careme_logo.png', height: 30, width: 30),
                  const SizedBox(width: 10),
                  const Text(
                    'CareMe',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Text(
                    _isActive ? 'Active' : 'Away',
                    style: TextStyle(
                      color: _isActive
                          ? const Color(0xFF22C55E)
                          : const Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Transform.scale(
                    scale: 0.85,
                    child: Switch(
                      value: _isActive,
                      activeColor: const Color(0xFF22C55E),
                      onChanged: (value) {
                        setState(() => _isActive = value);
                      },
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const MessagesPage(),
                        ),
                      );
                    },
                    child: const Icon(
                      Icons.chat_bubble_outline,
                      color: Colors.black87,
                      size: 26,
                    ),
                  ),
                ],
              ),
            ),
            // Distance filter row
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: GestureDetector(
                onTap: _openDistanceFilter,
                child: Row(
                  children: [
                    const Icon(Icons.tune, size: 22, color: Colors.black87),
                    const SizedBox(width: 8),
                    Text(
                      '${_radiusKm.round()} km',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            // Feed
            Expanded(
              child: ListView.separated(
                itemCount: samplePosts.length,
                separatorBuilder: (_, __) => Container(
                  height: 10,
                  color: const Color(0xFFF3F4F6),
                ),
                itemBuilder: (context, index) {
                  final post = samplePosts[index];
                  return _PostCard(
                    post: post,
                    onLikeToggle: () => _toggleLike(post),
                    onOptionsTap: () => _openPostOptions(post),
                    onCommentTap: () => _openComments(post),
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

class _PostCard extends StatelessWidget {
  final FeedPost post;
  final VoidCallback onLikeToggle;
  final VoidCallback onOptionsTap;
  final VoidCallback onCommentTap;

  const _PostCard({
    required this.post,
    required this.onLikeToggle,
    required this.onOptionsTap,
    required this.onCommentTap,
  });

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return '$count';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: avatar, name, distance, time, options
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: AssetImage(post.avatarUrl),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              post.name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const Text(' • ',
                              style: TextStyle(color: Color(0xFF9CA3AF))),
                          Text(
                            post.distance,
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFF6B7280)),
                          ),
                        ],
                      ),
                      Text(
                        post.timeAgo,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF9CA3AF)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onOptionsTap,
                  icon: const Icon(Icons.more_horiz, color: Colors.black54),
                ),
              ],
            ),
          ),
          // Caption
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              post.caption,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(height: 10),
          // Image carousel
          _PostImageCarousel(images: post.images),
          const SizedBox(height: 10),
          // Like / comment row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: onLikeToggle,
                  child: Row(
                    children: [
                      Icon(
                        post.isLiked ? Icons.favorite : Icons.favorite_border,
                        size: 22,
                        color: post.isLiked
                            ? const Color(0xFFEF4444)
                            : Colors.black87,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatCount(post.likeCount),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: onCommentTap,
                  child: Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline,
                          size: 20, color: Colors.black87),
                      const SizedBox(width: 6),
                      Text(
                        _formatCount(post.commentCount),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PostImageCarousel extends StatefulWidget {
  final List<String> images;

  const _PostImageCarousel({required this.images});

  @override
  State<_PostImageCarousel> createState() => _PostImageCarouselState();
}

class _PostImageCarouselState extends State<_PostImageCarousel> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        AspectRatio(
          aspectRatio: 4 / 5,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.images.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index) {
              return Image.asset(
                widget.images[index],
                fit: BoxFit.cover,
                width: double.infinity,
              );
            },
          ),
        ),
        if (widget.images.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.images.length, (index) {
                final isActive = index == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 8 : 6,
                  height: isActive ? 8 : 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        isActive ? Colors.white : Colors.white.withOpacity(0.5),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 2,
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}
