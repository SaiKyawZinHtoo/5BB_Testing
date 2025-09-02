import 'dart:async';
import 'package:bloc/bloc.dart';
import 'notification_event.dart';
import 'notification_state.dart';
import 'notification_repository.dart';

class NotificaitonBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository repository;

  NotificaitonBloc(this.repository) : super(NotificationInitial()) {
    on<LoadNotificationsEvent>(_onLoad);
    on<RefreshNotificationsEvent>(_onRefresh);
    on<MarkAsReadEvent>(_onMarkAsRead);
    on<MarkAllReadEvent>(_onMarkAllRead);
    on<DeleteNotificationEvent>(_onDelete);
  }

  Future<void> _onLoad(
    LoadNotificationsEvent event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoading());
    try {
      final items = await repository.fetchNotifications();
      emit(NotificationLoaded(items));
    } catch (e) {
      try {
        final items = await repository.getStaticNotifications();
        emit(NotificationLoaded(items, isUsingOfflineData: true));
      } catch (e) {
        emit(NotificationError('Failed to load notifications: $e'));
      }
    }
  }

  Future<void> _onRefresh(
    RefreshNotificationsEvent event,
    Emitter<NotificationState> emit,
  ) async {
    await _onLoad(LoadNotificationsEvent(), emit);
  }

  Future<void> _onMarkAsRead(
    MarkAsReadEvent event,
    Emitter<NotificationState> emit,
  ) async {
    if (state is NotificationLoaded) {
      final current = state as NotificationLoaded;
      final updated = current.notifications.map((n) {
        if (n.id == event.notificationId) return n.copyWith(isRead: true);
        return n;
      }).toList();
      emit(
        NotificationLoaded(
          updated,
          isUsingOfflineData: current.isUsingOfflineData,
        ),
      );
    }
  }

  Future<void> _onMarkAllRead(
    MarkAllReadEvent event,
    Emitter<NotificationState> emit,
  ) async {
    if (state is NotificationLoaded) {
      final current = state as NotificationLoaded;
      final updated = current.notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
      emit(
        NotificationLoaded(
          updated,
          isUsingOfflineData: current.isUsingOfflineData,
        ),
      );
    }
  }

  Future<void> _onDelete(
    DeleteNotificationEvent event,
    Emitter<NotificationState> emit,
  ) async {
    if (state is NotificationLoaded) {
      final current = state as NotificationLoaded;
      final success = await repository.deleteNotification(event.notificationId);
      if (success) {
        final updated = current.notifications
            .where((n) => n.id != event.notificationId)
            .toList();
        emit(
          NotificationLoaded(
            updated,
            isUsingOfflineData: current.isUsingOfflineData,
          ),
        );
      } else {
        // keep state unchanged, could emit error if desired
      }
    }
  }
}
