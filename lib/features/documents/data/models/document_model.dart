import '../../domain/entities/document_entity.dart';

class DocumentModel {
  final String id;
  final String name;
  final String type;
  final String? fileUrl;
  final String? size;
  final int? sizeBytes;
  final DateTime? uploadedAt;
  final String category;
  final String status;

  DocumentModel({
    required this.id,
    required this.name,
    required this.type,
    this.fileUrl,
    this.size,
    this.sizeBytes,
    this.uploadedAt,
    required this.category,
    required this.status,
  });

  /// Renders bytes as B / KB / MB per the API doc.
  static String _formatSize(int? bytes) {
    if (bytes == null || bytes <= 0) return '';
    if (bytes < 1000) return '$bytes B';
    if (bytes < 1000000) return '${(bytes / 1000).toStringAsFixed(0)} KB';
    return '${(bytes / 1000000).toStringAsFixed(1)} MB';
  }

  static String _extOf(String name) {
    final i = name.lastIndexOf('.');
    return (i == -1 || i == name.length - 1)
        ? 'file'
        : name.substring(i + 1).toLowerCase();
  }

  factory DocumentModel.fromJson(Map<String, dynamic> j) {
    final name = j['name']?.toString() ?? '';
    final bytes = (j['size_bytes'] as num?)?.toInt();
    return DocumentModel(
      id: j['id']?.toString() ?? j['_id']?.toString() ?? '',
      name: name,
      type: _extOf(name),
      fileUrl: j['file_url']?.toString() ??
          j['fileUrl']?.toString() ??
          j['url']?.toString(),
      sizeBytes: bytes,
      size: _formatSize(bytes),
      uploadedAt: DateTime.tryParse(
          (j['uploaded_at'] ?? j['uploadedAt'] ?? '').toString()),
      category: j['category']?.toString() ?? 'other',
      status: j['status']?.toString() ?? 'submitted',
    );
  }

  DocumentEntity toEntity() => DocumentEntity(
        id: id,
        name: name,
        type: type,
        fileUrl: fileUrl,
        size: size,
        sizeBytes: sizeBytes,
        uploadedAt: uploadedAt,
        category: category,
        status: status,
      );
}
