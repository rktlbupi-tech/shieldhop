import 'dart:io';
import '../../../../core/errors/failures.dart';
import '../entities/document_entity.dart';

abstract class DocumentsRepository {
  Future<(List<DocumentEntity>, Failure?)> fetchDocuments();

  /// Uploads a file via the media flow, returning its hosted URL.
  Future<(String?, Failure?)> uploadFile(File file);

  /// Creates a document record (after the file is uploaded).
  Future<(DocumentEntity?, Failure?)> addDocument({
    required String name,
    required String category,
    String? fileUrl,
    int? sizeBytes,
  });

  /// Soft-deletes one of the member's documents.
  Future<(bool, Failure?)> deleteDocument(String id);
}
