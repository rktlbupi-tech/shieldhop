import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/form_entity.dart';
import '../../domain/repositories/submit_forms_repository.dart';

// ── Events ───────────────────────────────────────────────────────────────────
abstract class SubmitFormsEvent extends Equatable {
  const SubmitFormsEvent();
  @override
  List<Object?> get props => [];
}

class FetchAvailableFormsEvent extends SubmitFormsEvent {
  final String? query;
  const FetchAvailableFormsEvent({this.query});
  @override
  List<Object?> get props => [query];
}

class FetchSubmissionsEvent extends SubmitFormsEvent {
  final String? query;
  const FetchSubmissionsEvent({this.query});
  @override
  List<Object?> get props => [query];
}

class FetchAppTokenUrlEvent extends SubmitFormsEvent {
  const FetchAppTokenUrlEvent();
}

class ResetAppTokenEvent extends SubmitFormsEvent {
  const ResetAppTokenEvent();
}

// ── States ───────────────────────────────────────────────────────────────────
class SubmitFormsState extends Equatable {
  final List<FormEntity> availableForms;
  final List<FormSubmissionEntity> submissions;
  final bool isAvailableFormsLoading;
  final bool isSubmissionsLoading;
  final String? availableFormsError;
  final String? submissionsError;
  
  final String? appTokenUrl;
  final bool isAppTokenLoading;
  final String? appTokenError;

  const SubmitFormsState({
    this.availableForms = const [],
    this.submissions = const [],
    this.isAvailableFormsLoading = false,
    this.isSubmissionsLoading = false,
    this.availableFormsError,
    this.submissionsError,
    this.appTokenUrl,
    this.isAppTokenLoading = false,
    this.appTokenError,
  });

  SubmitFormsState copyWith({
    List<FormEntity>? availableForms,
    List<FormSubmissionEntity>? submissions,
    bool? isAvailableFormsLoading,
    bool? isSubmissionsLoading,
    String? availableFormsError,
    String? submissionsError,
    String? appTokenUrl,
    bool? isAppTokenLoading,
    String? appTokenError,
  }) {
    return SubmitFormsState(
      availableForms: availableForms ?? this.availableForms,
      submissions: submissions ?? this.submissions,
      isAvailableFormsLoading: isAvailableFormsLoading ?? this.isAvailableFormsLoading,
      isSubmissionsLoading: isSubmissionsLoading ?? this.isSubmissionsLoading,
      availableFormsError: availableFormsError,
      submissionsError: submissionsError,
      appTokenUrl: appTokenUrl ?? this.appTokenUrl,
      isAppTokenLoading: isAppTokenLoading ?? this.isAppTokenLoading,
      appTokenError: appTokenError,
    );
  }

  @override
  List<Object?> get props => [
        availableForms,
        submissions,
        isAvailableFormsLoading,
        isSubmissionsLoading,
        availableFormsError,
        submissionsError,
        appTokenUrl,
        isAppTokenLoading,
        appTokenError,
      ];
}

// ── BLoC ─────────────────────────────────────────────────────────────────────
class SubmitFormsBloc extends Bloc<SubmitFormsEvent, SubmitFormsState> {
  final SubmitFormsRepository _repository;

  SubmitFormsBloc(this._repository) : super(const SubmitFormsState()) {
    on<FetchAvailableFormsEvent>(_onFetchAvailableForms);
    on<FetchSubmissionsEvent>(_onFetchSubmissions);
    on<FetchAppTokenUrlEvent>(_onFetchAppTokenUrl);
    on<ResetAppTokenEvent>((e, emit) => emit(state.copyWith(appTokenUrl: null, appTokenError: null, isAppTokenLoading: false)));
  }

  Future<void> _onFetchAvailableForms(
    FetchAvailableFormsEvent event,
    Emitter<SubmitFormsState> emit,
  ) async {
    emit(state.copyWith(isAvailableFormsLoading: true));
    final (forms, failure) = await _repository.getAvailableForms(query: event.query);
    if (failure != null) {
      emit(state.copyWith(
        isAvailableFormsLoading: false,
        availableFormsError: failure.message,
      ));
    } else if (forms != null) {
      emit(state.copyWith(
        isAvailableFormsLoading: false,
        availableForms: forms,
      ));
    }
  }

  Future<void> _onFetchSubmissions(
    FetchSubmissionsEvent event,
    Emitter<SubmitFormsState> emit,
  ) async {
    emit(state.copyWith(isSubmissionsLoading: true));
    final (subs, failure) = await _repository.getSubmissions(query: event.query);
    if (failure != null) {
      emit(state.copyWith(
        isSubmissionsLoading: false,
        submissionsError: failure.message,
      ));
    } else if (subs != null) {
      emit(state.copyWith(
        isSubmissionsLoading: false,
        submissions: subs,
      ));
    }
  }

  Future<void> _onFetchAppTokenUrl(
    FetchAppTokenUrlEvent event,
    Emitter<SubmitFormsState> emit,
  ) async {
    emit(state.copyWith(isAppTokenLoading: true));
    final (url, failure) = await _repository.getAppTokenUrl();
    if (failure != null) {
      emit(state.copyWith(
        isAppTokenLoading: false,
        appTokenError: failure.message,
      ));
    } else if (url != null) {
      emit(state.copyWith(
        isAppTokenLoading: false,
        appTokenUrl: url,
      ));
    }
  }
}
