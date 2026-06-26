import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../services/api_services.dart';
import '../services/notification_storage.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool loading = true;
  List<Map<String, dynamic>> recommendations = [];
  List<String> readIds = [];

  @override
  void initState() {
    super.initState();
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    try {
      final recData = await ApiService.getRecommendations();
      final readData = await NotificationStorage.getReadIds();

      if (!mounted) return;

      setState(() {
        recommendations = recData;
        readIds = readData;
        loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading notifications: $error")),
      );
    }
  }

  Future<void> markAsRead(String id) async {
    await NotificationStorage.markAsRead(id);
    final updatedRead = await NotificationStorage.getReadIds();
    setState(() {
      readIds = updatedRead;
    });
  }

  Future<void> markAllAsRead() async {
    final unreadIds = recommendations
        .map((rec) => rec["id"].toString())
        .where((id) => !readIds.contains(id))
        .toList();
    
    if (unreadIds.isNotEmpty) {
      await NotificationStorage.markAllAsRead(unreadIds);
      final updatedRead = await NotificationStorage.getReadIds();
      setState(() {
        readIds = updatedRead;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        title: const Text(
          "Notifications",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryGreen,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (recommendations.any((rec) => !readIds.contains(rec["id"].toString())))
            TextButton(
              onPressed: markAllAsRead,
              child: const Text(
                "Read All",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : recommendations.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        "No notifications yet.",
                        style: TextStyle(color: Colors.black54, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: recommendations.length,
                  itemBuilder: (context, index) {
                    final rec = recommendations[index];
                    final recId = rec["id"].toString();
                    final isRead = readIds.contains(recId);
                    final dateStr = rec["date"]?.toString() ?? "";
                    
                    final plot = rec["plots"] != null ? Map<String, dynamic>.from(rec["plots"]) : null;
                    final plotName = plot != null ? plot["nom"]?.toString() ?? "Plot" : "Plot";
                    final vol = double.tryParse(rec["quantite_eau"].toString()) ?? 0;
                    final msg = rec["message"]?.toString() ?? "";

                    final requiresIrrigation = vol > 0;

                    return Card(
                      color: isRead ? Colors.white : const Color(0xFFF0FDF4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isRead ? Colors.transparent : primaryGreen.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      elevation: isRead ? 1 : 3,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: requiresIrrigation
                              ? Colors.blue.shade50
                              : Colors.orange.shade50,
                          child: Icon(
                            requiresIrrigation ? Icons.water_drop : Icons.info_outline,
                            color: requiresIrrigation ? Colors.blue : Colors.orange,
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                plotName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: darkText,
                                ),
                              ),
                            ),
                            Text(
                              dateStr,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              msg,
                              style: TextStyle(
                                color: isRead ? Colors.black87 : darkText,
                                fontSize: 13,
                                fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
                              ),
                            ),
                            if (requiresIrrigation) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  "Irrigation volume: ${vol.toStringAsFixed(1)} m³",
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        trailing: !isRead
                            ? IconButton(
                                icon: const Icon(Icons.check_circle_outline, color: primaryGreen),
                                onPressed: () => markAsRead(recId),
                              )
                            : null,
                      ),
                    );
                  },
                ),
    );
  }
}
