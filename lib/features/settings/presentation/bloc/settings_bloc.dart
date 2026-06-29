import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/settings_repository.dart';

// Events
abstract class SettingsEvent extends Equatable {
  const SettingsEvent();
  @override List<Object?> get props => [];
}

class DeleteAccount extends SettingsEvent {
  final Map<String, String> reason;
  const DeleteAccount(this.reason);
  @override List<Object?> get props => [reason];
}

class ContactUs extends SettingsEvent {
  final Map<String, String> data;
  const ContactUs(this.data);
  @override List<Object?> get props => [data];
}

class FetchAdminDetails extends SettingsEvent { const FetchAdminDetails(); }

class FetchLegalTerms extends SettingsEvent {
  final String type;
  const FetchLegalTerms(this.type);
  @override List<Object?> get props => [type];
}

class ChangePassword extends SettingsEvent {
  final Map<String, String> data;
  const ChangePassword(this.data);
  @override List<Object?> get props => [data];
}

// States
abstract class SettingsState extends Equatable {
  const SettingsState();
  @override List<Object?> get props => [];
}
class SettingsInitial extends SettingsState { const SettingsInitial(); }
class SettingsLoading extends SettingsState { const SettingsLoading(); }
class SettingsSuccess extends SettingsState {
  final String message;
  const SettingsSuccess(this.message);
  @override List<Object?> get props => [message];
}
class AdminDetailsLoaded extends SettingsState {
  final String details;
  const AdminDetailsLoaded(this.details);
  @override List<Object?> get props => [details];
}
class LegalTermsLoaded extends SettingsState {
  final String content;
  const LegalTermsLoaded(this.content);
  @override List<Object?> get props => [content];
}
class SettingsError extends SettingsState {
  final String message;
  const SettingsError(this.message);
  @override List<Object?> get props => [message];
}

// BLoC
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsRepository _repo;

  SettingsBloc(this._repo) : super(const SettingsInitial()) {
    on<DeleteAccount>(_onDeleteAccount);
    on<ContactUs>(_onContactUs);
    on<FetchAdminDetails>(_onFetchAdminDetails);
    on<FetchLegalTerms>(_onFetchLegalTerms);
    on<ChangePassword>(_onChangePassword);
  }

  Future<void> _onDeleteAccount(DeleteAccount e, Emitter<SettingsState> emit) async {
    emit(const SettingsLoading());
    final (success, failure) = await _repo.deleteAccount(e.reason);
    if (failure != null || !success) { emit(SettingsError(failure?.message ?? "Failed to delete account")); return; }
    emit(const SettingsSuccess("Account deleted successfully"));
  }

  Future<void> _onContactUs(ContactUs e, Emitter<SettingsState> emit) async {
    emit(const SettingsLoading());
    final (success, failure) = await _repo.contactUs(e.data);
    if (failure != null || !success) { emit(SettingsError(failure?.message ?? "Failed to send message")); return; }
    emit(const SettingsSuccess("Message sent successfully"));
  }

  Future<void> _onFetchAdminDetails(FetchAdminDetails e, Emitter<SettingsState> emit) async {
    emit(const SettingsLoading());
    final (details, failure) = await _repo.fetchAdminDetails();
    if (failure != null || details == null) { emit(SettingsError(failure?.message ?? "Failed to fetch admin details")); return; }
    emit(AdminDetailsLoaded(details));
  }

  Future<void> _onFetchLegalTerms(FetchLegalTerms e, Emitter<SettingsState> emit) async {
    emit(const SettingsLoading());
    final (content, failure) = await _repo.fetchLegalTerms(e.type);
    if (failure != null || content == null) { emit(SettingsError(failure?.message ?? "Failed to fetch legal terms")); return; }
    emit(LegalTermsLoaded(content));
  }

  Future<void> _onChangePassword(ChangePassword e, Emitter<SettingsState> emit) async {
    emit(const SettingsLoading());
    final (success, failure) = await _repo.changePassword(e.data);
    if (failure != null || !success) { emit(SettingsError(failure?.message ?? "Failed to change password")); return; }
    emit(const SettingsSuccess("Password changed successfully"));
  }
}
