import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_application_practice/auth/auth_service.dart';
import 'package:flutter_application_practice/location/active_toggle.dart';
import 'package:flutter_application_practice/location/availability_tracker.dart';
import 'package:flutter_application_practice/realtime/app_badges.dart';
import 'package:flutter_application_practice/screens/login_screen/login_screen.dart';

class ProfileHeaderBar extends StatelessWidget {
  final bool showActive;
  const ProfileHeaderBar({super.key, this.showActive = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Row(
        children: [
          Image.asset('assets/careme_logo.png', width: 36, height: 36),
          const SizedBox(width: 10),
          const Text('CareMe',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const Spacer(),
          if (showActive) const ActiveToggle(),
        ],
      ),
    );
  }
}

class ProfileAvatar extends StatelessWidget {
  final String initial;
  final String? imageUrl;
  final Uint8List? bytes; // freshly picked photo (not uploaded yet)
  final double size;

  const ProfileAvatar({
    super.key,
    required this.initial,
    this.imageUrl,
    this.bytes,
    this.size = 76,
  });

  Widget _fallback() => Container(
        color: const Color(0xFF7BB8F0),
        alignment: Alignment.center,
        child: Text(
          initial,
          style: TextStyle(
            fontSize: size * 0.45,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final Widget content;
    if (bytes != null) {
      content = Image.memory(bytes!, fit: BoxFit.cover);
    } else if (imageUrl != null && imageUrl!.isNotEmpty) {
      content = Image.network(imageUrl!,
          fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fallback());
    } else {
      content = _fallback();
    }
    return ClipOval(child: SizedBox(width: size, height: size, child: content));
  }
}

class ProfileStat extends StatelessWidget {
  final String value;
  final String label;
  final Widget? leading;

  const ProfileStat(
      {super.key, required this.value, required this.label, this.leading});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 2)],
            Text(value,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class ProfileActionRow extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onMenu;
  const ProfileActionRow(
      {super.key, required this.onEdit, required this.onMenu});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 44,
            child: ElevatedButton(
              onPressed: onEdit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7BB8F0),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Edit Profile', style: TextStyle(fontSize: 16)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          onPressed: onMenu,
          icon: const Icon(Icons.menu, size: 32, color: Colors.black),
        ),
      ],
    );
  }
}

/// Text tabs that behave like a nav bar (underline on the selected one).
class ProfileTabSwitcher extends StatelessWidget {
  final List<String> tabs;
  final int selected;
  final ValueChanged<int> onChanged;

  const ProfileTabSwitcher({
    super.key,
    required this.tabs,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Divider(height: 1, thickness: 1, color: Colors.black),
        ),
        Row(
          children: [
            for (var i = 0; i < tabs.length; i++)
              Expanded(
                child: InkWell(
                  onTap: () => onChanged(i),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 10, bottom: 6),
                        child: Text(
                          tabs[i],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: i == selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      Container(
                        height: 3,
                        color:
                            i == selected ? Colors.black : Colors.transparent,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class ProfileCard extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback? onMore;

  const ProfileCard(
      {super.key, required this.title, required this.child, this.onMore});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6B7280)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
              ),
              if (onMore != null)
                IconButton(
                  onPressed: onMore,
                  padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.more_horiz, color: Colors.black),
              ),
            ],
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

class ComingSoon extends StatelessWidget {
  final String text;
  const ComingSoon(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Text(text, style: const TextStyle(color: Color(0xFF6B7280))),
      ),
    );
  }
}

Future<void> confirmLogout(BuildContext context) async {
  final shouldLogout = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Logout'),
      content: const Text('Do you want to logout?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Logout'),
        ),
      ],
    ),
  );

  if (shouldLogout == true) {
    AppBadges.instance.stop(); // stop the live updates for this account
    await AvailabilityTracker.instance.shutdown(); // go offline before leaving
    await AuthService().signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}

/// Hamburger menu. Only Log out for now; more options can be added later.
void showProfileMenu(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.logout, color: Color(0xFFEF4444)),
            title: const Text('Log out'),
            onTap: () {
              Navigator.pop(sheetContext);
              confirmLogout(context);
            },
          ),
        ],
      ),
    ),
  );
}
