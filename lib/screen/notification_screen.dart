import 'package:flutter/material.dart';
import '../screen/bloc/notification_repository.dart';
import '../model/notification_model.dart';

enum SnackType { success, error, info }

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _repo = NotificationRepository();
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final items = await _repo.fetchNotifications();
      setState(() {
        _notifications = items;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load notifications';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refresh() async => _loadNotifications();

  Future<void> _markAsRead(int id) async {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx == -1) return;
    final original = _notifications[idx];
    if (original.isRead) return; // already read

    // optimistic update
    setState(() {
      _notifications[idx] = original.copyWith(isRead: true);
    });

    // show modern snack with UNDO
    _showSnack(
      'Marked as read',
      type: SnackType.success,
      actionLabel: 'UNDO',
      onAction: () {
        if (!mounted) return;
        setState(() {
          final pos = _notifications.indexWhere((n) => n.id == id);
          if (pos != -1) {
            _notifications[pos] = original;
          }
        });
      },
    );

    // try to persist change; rollback if persistence fails
    final success = await _repo.updateNotification(id, {'isRead': true});
    if (!success) {
      if (!mounted) return;
      setState(() {
        final pos = _notifications.indexWhere((n) => n.id == id);
        if (pos != -1) _notifications[pos] = original;
      });
      _showSnack('Failed to mark as read', type: SnackType.error);
    }
  }

  Future<void> _markAllRead() async {
    if (_notifications.isEmpty) return;
    final previous = List<NotificationModel>.from(_notifications);

    // optimistic update
    setState(() {
      _notifications = _notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
    });

    _showSnack(
      'All notifications marked as read',
      type: SnackType.success,
      actionLabel: 'UNDO',
      onAction: () {
        if (!mounted) return;
        setState(() {
          _notifications = previous;
        });
      },
    );

    // attempt to persist; try best-effort, if many fail show error and restore
    bool anyFailed = false;
    for (final n in previous) {
      final ok = await _repo.updateNotification(n.id, {'isRead': true});
      if (!ok) anyFailed = true;
    }
    if (anyFailed) {
      if (!mounted) return;
      setState(() {
        // restore previous state if needed
        _notifications = previous;
      });
      _showSnack('Failed to mark all as read', type: SnackType.error);
    }
  }

  Future<void> _deleteNotification(int id) async {
    final removed = _notifications.firstWhere(
      (n) => n.id == id,
      orElse: () => NotificationModel(
        userId: 0,
        id: -1,
        title: '',
        body: '',
        date: '',
        isRead: true,
      ),
    );
    if (removed.id == -1) return;

    // remove locally and show an undo-able, modern snack
    setState(() {
      _notifications.removeWhere((n) => n.id == id);
    });

    _showSnack(
      'Deleted',
      type: SnackType.success,
      actionLabel: 'UNDO',
      onAction: () {
        if (!mounted) return;
        setState(() {
          _notifications.insert(0, removed);
        });
      },
    );

    // perform backend delete; if it fails, notify user
    final success = await _repo.deleteNotification(id);
    if (!success) {
      if (!mounted) return;
      setState(() {
        // ensure item present locally
        if (!_notifications.any((n) => n.id == removed.id)) {
          _notifications.insert(0, removed);
        }
      });
      _showSnack('Failed to delete notification', type: SnackType.error);
    }
  }

  // small, modern snackbar helper used across the screen
  // shows floating snack with icon, optional action, and consistent styling
  void _showSnack(
    String message, {
    SnackType type = SnackType.info,
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration,
  }) {
    if (!mounted) return;
    final color = {
      SnackType.success: Colors.green[600],
      SnackType.error: Colors.redAccent[700],
      SnackType.info: Colors.grey[850],
    }[type]!;
    final icon = {
      SnackType.success: Icons.check_circle_outline,
      SnackType.error: Icons.error_outline,
      SnackType.info: Icons.info_outline,
    }[type]!;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        elevation: 6,
        duration: duration ?? const Duration(seconds: 3),
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            Icon(icon, color: Colors.white70),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        action: actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onAction ?? () {},
              )
            : null,
      ),
    );
  }

  // simple snack types for consistent appearances
  // placed here to keep the helper private to the screen
  // (could be moved to a shared util if reused across app)
  List<NotificationModel> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _notifications;
    return _notifications.where((n) {
      return n.title.toLowerCase().contains(q) ||
          n.body.toLowerCase().contains(q);
    }).toList();
  }

  Widget _buildCard(NotificationModel n) {
    final avatarColor =
        Colors.primaries[n.userId % Colors.primaries.length].shade400;
    return Dismissible(
      key: ValueKey('notif-${n.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => _deleteNotification(n.id),
      child: AnimatedContainer(
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
            onTap: () => _markAsRead(n.id),
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
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
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          n.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey[800],
                            height: 1.3,
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
                              onPressed: () => _markAsRead(n.id),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 92,
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: const Text('Notifications'),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: _markAllRead,
            icon: const Icon(Icons.mark_email_read_outlined),
            tooltip: 'Mark all read',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration.collapsed(
                              hintText: 'Search notifications',
                            ),
                            onChanged: (v) => setState(() => _query = v),
                          ),
                        ),
                        if (_query.isNotEmpty)
                          GestureDetector(
                            onTap: () => setState(() => _query = ''),
                            child: const Icon(Icons.close, color: Colors.grey),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _refresh,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.secondary.withAlpha(31),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.refresh),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 74,
                        color: Colors.red[400],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        onPressed: _loadNotifications,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            : RefreshIndicator(
                onRefresh: _refresh,
                edgeOffset: 8,
                child: filtered.isEmpty
                    ? ListView(
                        padding: const EdgeInsets.symmetric(
                          vertical: 40,
                          horizontal: 24,
                        ),
                        children: [
                          AnimatedOpacity(
                            opacity: 1,
                            duration: const Duration(milliseconds: 350),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.notifications_off_outlined,
                                  size: 72,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  unreadCount == 0
                                      ? 'No notifications'
                                      : 'No results',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  unreadCount == 0
                                      ? 'You have caught up — there are no notifications right now.'
                                      : 'Try changing your search',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 18),
                                if (unreadCount > 0)
                                  ElevatedButton.icon(
                                    onPressed: _markAllRead,
                                    icon: const Icon(
                                      Icons.mark_email_read_outlined,
                                    ),
                                    label: const Text('Mark all read'),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 12, bottom: 20),
                        itemCount: filtered.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            // header with counts
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Row(
                                children: [
                                  Chip(
                                    label: Text('$unreadCount unread'),
                                    backgroundColor: Colors.deepPurple
                                        .withAlpha(20),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${_notifications.length} total',
                                    style: TextStyle(color: Colors.grey[700]),
                                  ),
                                ],
                              ),
                            );
                          }
                          final n = filtered[index - 1];
                          return _buildCard(n);
                        },
                      ),
              ),
      ),
    );
  }
}
