import '../../domain/entities/form_entity.dart';

class FormModel extends FormEntity {
  FormModel({
    required super.id,
    required super.name,
    required super.description,
    required super.tags,
    required super.formCode,
    required super.thumbnailUrl,
  });

  factory FormModel.fromJson(Map<String, dynamic> j) {
    return FormModel(
      id: j['_id']?.toString() ?? j['id']?.toString() ?? '',
      name: j['name']?.toString() ?? '',
      description: j['description']?.toString() ?? '',
      tags: (j['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      formCode: (j['form_code'] ?? j['formCode'] ?? '').toString(),
      thumbnailUrl: j['thumbnailUrl']?.toString() ?? '',
    );
  }

  FormEntity toEntity() {
    return FormEntity(
      id: id,
      name: name,
      description: description,
      tags: tags,
      formCode: formCode,
      thumbnailUrl: thumbnailUrl,
    );
  }
}

class FormSubmissionModel extends FormSubmissionEntity {
  FormSubmissionModel({
    required super.id,
    required super.formId,
    required super.submissionCode,
    required super.status,
    required super.createdAt,
  });

  factory FormSubmissionModel.fromJson(Map<String, dynamic> j) {
    return FormSubmissionModel(
      id: j['_id']?.toString() ?? j['id']?.toString() ?? '',
      formId: j['formId']?.toString() ?? '',
      submissionCode: (j['submissionCode'] ?? j['code'] ?? '').toString(),
      status: j['status']?.toString() ?? '',
      createdAt: j['createdAt'] != null
          ? DateTime.tryParse(j['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  FormSubmissionEntity toEntity() {
    return FormSubmissionEntity(
      id: id,
      formId: formId,
      submissionCode: submissionCode,
      status: status,
      createdAt: createdAt,
    );
  }
}
