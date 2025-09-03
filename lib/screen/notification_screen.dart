import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../screen/bloc/notificaiton_bloc.dart';
import '../screen/bloc/notification_event.dart';
import '../screen/bloc/notification_state.dart';
import '../screen/bloc/notification_repository.dart';
import '../model/notification_model.dart';
import '../utils/snack_helper.dart';
import '../widgets/notification_card.dart';
import '../widgets/search_bar.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _repo = NotificationRepository();
  late final NotificaitonBloc _bloc;
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _bloc = NotificaitonBloc(_repo);
    // Kick off initial load via the bloc
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    // Ask the bloc to load notifications. A BlocListener in build()
    // will sync the resulting NotificationLoaded/NotificationError
    // into this widget's state.
    _bloc.add(LoadNotificationsEvent());
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
    showAppSnack(
      context,
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
      showAppSnack(context, 'Failed to mark as read', type: SnackType.error);
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

    showAppSnack(
      context,
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
      showAppSnack(
        context,
        'Failed to mark all as read',
        type: SnackType.error,
      );
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

    showAppSnack(
      context,
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
      showAppSnack(
        context,
        'Failed to delete notification',
        type: SnackType.error,
      );
    }
  }

  @override
  void dispose() {
    _bloc.close();
    _repo.dispose();
    super.dispose();
  }

  // simple snack types for consistent appearances
  // (SnackType is provided by snack_helper)
  List<NotificationModel> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _notifications;
    return _notifications.where((n) {
      return n.title.toLowerCase().contains(q) ||
          n.body.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return BlocListener<NotificaitonBloc, NotificationState>(
      bloc: _bloc,
      listener: (context, state) {
        if (state is NotificationLoading) {
          setState(() {
            _isLoading = true;
            _error = null;
          });
        } else if (state is NotificationLoaded) {
          setState(() {
            _isLoading = false;
            _notifications = state.notifications;
            _error = null;
          });
          // If repo fell back to offline/static data, notify the user subtly
          if (state.isUsingOfflineData) {
            showAppSnack(
              context,
              'Offline: showing demo notifications',
              type: SnackType.info,
              duration: const Duration(seconds: 2),
            );
          }
        } else if (state is NotificationError) {
          setState(() {
            _isLoading = false;
            _error = state.message;
          });
        }
      },
      child: Scaffold(
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
            child: AppSearchBar(
              query: _query,
              onChanged: (v) => setState(() => _query = v),
              onRefresh: _refresh,
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
                            return Dismissible(
                              key: ValueKey('notif-${n.id}'),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                child: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.white,
                                ),
                              ),
                              onDismissed: (_) => _deleteNotification(n.id),
                              child: NotificationCard(
                                notification: n,
                                onMarkRead: _markAsRead,
                                onDelete: _deleteNotification,
                              ),
                            );
                          },
                        ),
                ),
        ),
      ),
    );
  }
}
