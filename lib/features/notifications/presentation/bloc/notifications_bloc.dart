import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notifications_repository.dart';

// ── Events ───────────────────────────────────────────────────
abstract class NotificationsEvent extends Equatable {
  const NotificationsEvent();
  @override
  List<Object?> get props => [];
}

class FetchNotifications extends NotificationsEvent {
  final int page;
  final int limit;
  const FetchNotifications({this.page = 1, this.limit = 20});
  @override
  List<Object?> get props => [page, limit];
}

class MarkAllAsRead extends NotificationsEvent {
  const MarkAllAsRead();
}

class FetchUnreadCount extends NotificationsEvent {
  const FetchUnreadCount();
}

// ── States ───────────────────────────────────────────────────
abstract class NotificationsState extends Equatable {
  const NotificationsState();
  @override
  List<Object?> get props => [];
}

class NotificationsInitial extends NotificationsState {
  const NotificationsInitial();
}

class NotificationsLoading extends NotificationsState {
  const NotificationsLoading();
}

class NotificationsLoaded extends NotificationsState {
  final List<NotificationEntity> notifications;
  final int unreadCount;
  const NotificationsLoaded(this.notifications, this.unreadCount);
  @override
  List<Object?> get props => [notifications, unreadCount];
}

class NotificationsError extends NotificationsState {
  final String message;
  const NotificationsError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── Bloc ─────────────────────────────────────────────────────
class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final NotificationsRepository _repository;

  NotificationsBloc(this._repository) : super(const NotificationsInitial()) {
    on<FetchNotifications>(_onFetchNotifications);
    on<MarkAllAsRead>(_onMarkAllAsRead);
    on<FetchUnreadCount>(_onFetchUnreadCount);
  }

  Future<void> _onFetchNotifications(
    FetchNotifications event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(const NotificationsLoading());
    final (notifications, unreadCount, failure) = await _repository
        .fetchNotifications(page: event.page, limit: event.limit);
    if (failure != null) {
      emit(NotificationsError(failure.message));
      return;
    }
    emit(NotificationsLoaded(notifications, unreadCount));
  }

  Future<void> _onMarkAllAsRead(
    MarkAllAsRead event,
    Emitter<NotificationsState> emit,
  ) async {
    final currentState = state;
    List<NotificationEntity> currentList = [];

    if (currentState is NotificationsLoaded) {
      currentList = currentState.notifications;
    }

    final (success, failure) = await _repository.markAllAsRead();
    if (success) {
      final updatedList = currentList
          .map((n) => n.copyWith(isRead: true))
          .toList();
      emit(NotificationsLoaded(updatedList, 0));
    } else if (failure != null) {
      emit(NotificationsError(failure.message));
    }
  }

  Future<void> _onFetchUnreadCount(
    FetchUnreadCount event,
    Emitter<NotificationsState> emit,
  ) async {
    final currentState = state;
    List<NotificationEntity> currentList = [];

    if (currentState is NotificationsLoaded) {
      currentList = currentState.notifications;
    }

    final (count, failure) = await _repository.fetchUnreadCount();
    if (failure == null) {
      emit(NotificationsLoaded(currentList, count));
    }
  }
}
