import 'package:flutter/material.dart';

import '../screens/notifications_screen.dart';
import '../services/api_services.dart';
import '../services/notification_storage.dart';

class NotificationBell extends StatefulWidget {
  final Color color;

  const NotificationBell({
    super.key,
    this.color = Colors.white,
  });

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  bool hasUnread = false;

  @override
  void initState() {
    super.initState();
    checkUnread();
  }

  Future<void> checkUnread() async {
    try {
      final recs = await ApiService.getRecommendations();
      final readIds = await NotificationStorage.getReadIds();

      final unreadExist = recs.any((rec) {
        final recId = rec["id"].toString();
        return !readIds.contains(recId);
      });

      if (mounted) {
        setState(() {
          hasUnread = unreadExist;
        });
      }
    } catch (_) {
      // Fail silently
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Stack(
        children: [
          Icon(Icons.notifications_none, color: widget.color),
          if (hasUnread)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(6),
                ),
                constraints: const BoxConstraints(
                  minWidth: 10,
                  minHeight: 10,
                ),
              ),
            ),
        ],
      ),
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const NotificationsScreen(),
          ),
        );
        // Re-check unread state after returning
        checkUnread();
      },
    );
  }
}
