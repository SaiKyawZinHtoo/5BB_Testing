import 'package:flutter/material.dart';
import '../model/notification_model.dart';

typedef OnMarkRead = void Function(int id);
typedef OnDelete = void Function(int id);

class NotificationCard extends StatefulWidget {
  final NotificationModel notification;
  final OnMarkRead onMarkRead;
  final OnDelete? onDelete;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onMarkRead,
    this.onDelete,
  });

  @override
  State<NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<NotificationCard> {
  bool _expanded = false;

  void _toggleExpand() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    final n = widget.notification;
    final avatarColor =
        Colors.primaries[n.userId % Colors.primaries.length].shade400;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: n.isRead ? Colors.white : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _toggleExpand,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Unread accent
                Container(
                  width: 4,
                  height: 64,
                  margin: const EdgeInsets.only(right: 10, top: 6),
                  decoration: BoxDecoration(
                    color: n.isRead
                        ? Colors.transparent
                        : Colors.deepPurpleAccent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                CircleAvatar(
                  radius: 22,
                  backgroundColor: avatarColor,
                  child: Text(
                    (n.title.isNotEmpty ? n.title[0] : '?').toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              n.title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: n.isRead
                                    ? FontWeight.w600
                                    : FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            n.date,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 4),
                          // popup menu
                          PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'mark') widget.onMarkRead(n.id);
                              if (v == 'delete' && widget.onDelete != null)
                                widget.onDelete!(n.id);
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'mark',
                                child: Text('Mark read'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 260),
                        child: ConstrainedBox(
                          constraints: _expanded
                              ? const BoxConstraints()
                              : const BoxConstraints(maxHeight: 42),
                          child: Text(
                            n.body,
                            overflow: TextOverflow.fade,
                            softWrap: true,
                            style: TextStyle(
                              color: Colors.grey[800],
                              height: 1.35,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          if (!n.isRead)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.deepPurpleAccent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'NEW',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => widget.onMarkRead(n.id),
                            icon: Icon(
                              Icons.mark_email_read_outlined,
                              color: Colors.grey[600],
                            ),
                            tooltip: 'Mark read',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
