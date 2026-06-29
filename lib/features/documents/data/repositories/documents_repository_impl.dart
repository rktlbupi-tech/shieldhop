import 'dart:io';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/document_entity.dart';
import '../../domain/repositories/documents_repository.dart';
import '../datasources/documents_remote_datasource.dart';

class DocumentsRepositoryImpl implements DocumentsRepository {
  final DocumentsRemoteDatasource _ds;
  DocumentsRepositoryImpl(this._ds);

  @override
  Future<(List<DocumentEntity>, Failure?)> fetchDocuments() async {
    try {
      final models = await _ds.fetchDocuments();
      return (models.map((m) => m.toEntity()).toList(), null);
    } on NotFoundFailure {
      return (const <DocumentEntity>[], null);
    } on Failure catch (f) {
      return (<DocumentEntity>[], f);
    } catch (e) {
      return (<DocumentEntity>[], UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(String?, Failure?)> uploadFile(File file) async {
    try {
      return (await _ds.uploadFile(file), null);
    } on Failure catch (f) {
      return (null, f);
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(DocumentEntity?, Failure?)> addDocument({
    required String name,
    required String category,
    String? fileUrl,
    int? sizeBytes,
  }) async {
    try {
      final model = await _ds.addDocument(
        name: name,
        category: category,
        fileUrl: fileUrl,
        sizeBytes: sizeBytes,
      );
      return (model.toEntity(), null);
    } on Failure catch (f) {
      return (null, f);
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(bool, Failure?)> deleteDocument(String id) async {
    try {
      await _ds.deleteDocument(id);
      return (true, null);
    } on Failure catch (f) {
      return (false, f);
    } catch (e) {
      return (false, UnknownFailure(e.toString()));
    }
  }
}
