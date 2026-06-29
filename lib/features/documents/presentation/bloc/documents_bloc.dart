import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/document_entity.dart';
import '../../domain/repositories/documents_repository.dart';

// ── Events ──────────────────────────────────────────────────────────────────
abstract class DocumentsEvent extends Equatable {
  const DocumentsEvent();
  @override
  List<Object?> get props => [];
}

class FetchDocuments extends DocumentsEvent {
  const FetchDocuments();
}

/// Uploads [file] (via the media flow) then creates the document record.
class UploadDocument extends DocumentsEvent {
  final File file;
  final String name;
  final String category; // API value
  const UploadDocument({
    required this.file,
    required this.name,
    required this.category,
  });
  @override
  List<Object?> get props => [file, name, category];
}

class DeleteDocument extends DocumentsEvent {
  final String id;
  const DeleteDocument(this.id);
  @override
  List<Object?> get props => [id];
}

// ── States ──────────────────────────────────────────────────────────────────
abstract class DocumentsState extends Equatable {
  const DocumentsState();
  @override
  List<Object?> get props => [];
}

class DocumentsInitial extends DocumentsState {
  const DocumentsInitial();
}

class DocumentsLoading extends DocumentsState {
  const DocumentsLoading();
}

class DocumentsLoaded extends DocumentsState {
  final List<DocumentEntity> documents;
  final bool isUploading;
  const DocumentsLoaded(this.documents, {this.isUploading = false});
  @override
  List<Object?> get props => [documents, isUploading];
}

/// Emitted once after a successful upload (extends Loaded so the list renders).
class DocumentUploadSuccess extends DocumentsLoaded {
  final DocumentEntity document;
  const DocumentUploadSuccess(this.document, List<DocumentEntity> docs)
      : super(docs);
  @override
  List<Object?> get props => [...super.props, document];
}

class DocumentActionFailure extends DocumentsLoaded {
  final String errorMessage;
  const DocumentActionFailure(this.errorMessage, List<DocumentEntity> docs)
      : super(docs);
  @override
  List<Object?> get props => [...super.props, errorMessage];
}

class DocumentsError extends DocumentsState {
  final String message;
  const DocumentsError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── BLoC ────────────────────────────────────────────────────────────────────
class DocumentsBloc extends Bloc<DocumentsEvent, DocumentsState> {
  final DocumentsRepository _repo;
  List<DocumentEntity> _documents = const [];

  DocumentsBloc(this._repo) : super(const DocumentsInitial()) {
    on<FetchDocuments>(_onFetch);
    on<UploadDocument>(_onUpload);
    on<DeleteDocument>(_onDelete);
  }

  Future<void> _onFetch(
    FetchDocuments e,
    Emitter<DocumentsState> emit,
  ) async {
    emit(const DocumentsLoading());
    final (docs, failure) = await _repo.fetchDocuments();
    if (failure != null && docs.isEmpty) {
      emit(DocumentsError(failure.message));
      return;
    }
    _documents = docs;
    emit(DocumentsLoaded(_documents));
  }

  Future<void> _onUpload(
    UploadDocument e,
    Emitter<DocumentsState> emit,
  ) async {
    emit(DocumentsLoaded(_documents, isUploading: true));

    // 1. Upload the file → URL.
    final (url, upErr) = await _repo.uploadFile(e.file);
    if (upErr != null) {
      emit(DocumentActionFailure(
          'File upload failed: ${upErr.message}', _documents));
      emit(DocumentsLoaded(_documents));
      return;
    }

    // 2. Create the document record.
    final sizeBytes = e.file.existsSync() ? e.file.lengthSync() : null;
    final (doc, err) = await _repo.addDocument(
      name: e.name,
      category: e.category,
      fileUrl: url,
      sizeBytes: sizeBytes,
    );

    if (doc != null) {
      _documents = [doc, ..._documents];
      emit(DocumentUploadSuccess(doc, _documents));
      emit(DocumentsLoaded(_documents));
    } else {
      emit(DocumentActionFailure(
          err?.message ?? 'Unable to save document.', _documents));
      emit(DocumentsLoaded(_documents));
    }
  }

  Future<void> _onDelete(
    DeleteDocument e,
    Emitter<DocumentsState> emit,
  ) async {
    final (ok, err) = await _repo.deleteDocument(e.id);
    if (ok) {
      _documents = _documents.where((d) => d.id != e.id).toList();
      emit(DocumentsLoaded(_documents));
    } else {
      emit(DocumentActionFailure(
          err?.message ?? 'Unable to delete document.', _documents));
      emit(DocumentsLoaded(_documents));
    }
  }
}
