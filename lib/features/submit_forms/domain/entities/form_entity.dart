class FormEntity {
  final String id;
  final String name;
  final String description;
  final List<String> tags;
  final String formCode;
  final String thumbnailUrl;

  FormEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.tags,
    required this.formCode,
    required this.thumbnailUrl,
  });
}

class FormSubmissionEntity {
  final String id;
  final String formId;
  final String submissionCode;
  final String status;
  final DateTime createdAt;

  FormSubmissionEntity({
    required this.id,
    required this.formId,
    required this.submissionCode,
    required this.status,
    required this.createdAt,
  });
}
