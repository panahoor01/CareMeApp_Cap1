import 'package:flutter/material.dart';
import 'package:flutter_application_practice/profile/profile_widgets.dart';

/// Compact beautician bar pinned at the top of the service overview.
class BeauticianTopBar extends StatelessWidget {
  final String name;
  final String initial;
  final String? imageUrl;
  final String followers; // display text
  final String rating; // display text

  const BeauticianTopBar({
    super.key,
    required this.name,
    required this.initial,
    this.imageUrl,
    this.followers = '0',
    this.rating = '0',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ProfileAvatar(initial: initial, imageUrl: imageUrl, size: 40),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Wrap(
                spacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(followers,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 3),
                      const Text('Followers', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star,
                          size: 14, color: Color(0xFF22C55E)),
                      const SizedBox(width: 3),
                      Text(rating,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
