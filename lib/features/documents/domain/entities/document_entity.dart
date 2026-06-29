import 'package:equatable/equatable.dart';

class DocumentEntity extends Equatable {
  final String id;
  final String name;
  final String type; // file extension, e.g. 'pdf', 'jpg'
  final String? fileUrl;
  final String? size; // formatted, e.g. "1.2 MB"
  final int? sizeBytes;
  final DateTime? uploadedAt;

  /// API value: contracts | id_proofs | certificates | other.
  final String category;

  /// submitted | pending.
  final String status;

  const DocumentEntity({
    required this.id,
    required this.name,
    required this.type,
    this.fileUrl,
    this.size,
    this.sizeBytes,
    this.uploadedAt,
    required this.category,
    this.status = 'submitted',
  });

  /// Human label for the category value.
  String get categoryLabel {
    switch (category) {
      case 'contracts':
        return 'Contracts';
      case 'id_proofs':
        return 'ID Proofs';
      case 'certificates':
        return 'Certificates';
      case 'other':
        return 'Other';
      default:
        return category.isEmpty ? 'Other' : category;
    }
  }

  @override
  List<Object?> get props => [id, name, type, category, status, fileUrl];
}
