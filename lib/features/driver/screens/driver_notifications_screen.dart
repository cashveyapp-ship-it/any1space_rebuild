import 'package:flutter/material.dart';
import '../../../core/services/driver_notification_service.dart';
import '../../../core/widgets/apple_back_button.dart';

class DriverNotificationsScreen extends StatelessWidget {
  final bool showBackButton;

  const DriverNotificationsScreen({
    super.key,
    this.showBackButton = true,
  });

  String _message(Map<String, dynamic> data) {
    final message = (data['message'] ?? data['body'] ?? '').toString().trim();

    if (message.isNotEmpty) return message;

    final spaceName = (data['spaceName'] ?? 'your parking space').toString();

    return 'Reminder from host: Your Any1Space booking for $spaceName is active. Please check in when you arrive.';
  }

  @override
  Widget build(BuildContext context) {
    final service = DriverNotificationService();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: showBackButton ? const AppleBackButton() : null,
        title: const Text('Notifications'),
      ),
      body: StreamBuilder(
        stream: service.myNotifications(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Notifications failed: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No notifications yet.',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(18),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final read = data['read'] == true;
              final text = _message(data);

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: read
                        ? const Color(0xFFEFEFEF)
                        : const Color(0xFFEAF1FF),
                    child: Icon(
                      read
                          ? Icons.notifications_none_rounded
                          : Icons.notifications_active_rounded,
                      color: const Color(0xFF0B1F3A),
                    ),
                  ),
                  title: Text(
                    data['title'] ?? 'Notification',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0B1F3A),
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      text,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'read') {
                        await service.markRead(doc.id);
                      }

                      if (value == 'delete') {
                        await service.deleteNotification(doc.id);
                      }
                    },
                    itemBuilder: (_) => [
                      if (!read)
                        const PopupMenuItem(
                          value: 'read',
                          child: Text('Mark as Read'),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                  onTap: () async {
                    await service.markRead(doc.id);

                    if (!context.mounted) return;

                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text(data['title'] ?? 'Notification'),
                        content: Text(text),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                          TextButton(
                            onPressed: () async {
                              await service.deleteNotification(doc.id);
                              if (context.mounted) Navigator.pop(context);
                            },
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
