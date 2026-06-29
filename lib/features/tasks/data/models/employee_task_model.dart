import 'package:flutter/material.dart';

class ScheduleTask {
  final String id;
  final String startTime;
  final String endTime;
  final String title;
  final String location;
  final String tag;
  final DateTime date;
  final Color color;
  final String? link;
  final String? mediaHouseLogo;

  ScheduleTask({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.title,
    required this.location,
    required this.tag,
    required this.date,
    this.color = const Color(0xFF1B8E3D),
    this.link,
    this.mediaHouseLogo,
  });
}

class GetTasksResponseModel {
  final bool success;
  final List<EmployeeTaskModel> data;
  final int totalCount;
  final int page;
  final int limit;
  final int totalPages;

  GetTasksResponseModel({
    required this.success,
    required this.data,
    required this.totalCount,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory GetTasksResponseModel.fromJson(Map<String, dynamic> json) {
    return GetTasksResponseModel(
      success: json['success'] ?? false,
      data: (json['data'] as List<dynamic>? ?? [])
          .map((e) => EmployeeTaskModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCount: json['totalCount'] ?? 0,
      page: json['page'] ?? 0,
      limit: json['limit'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
    );
  }
}

class EmployeeTaskModel {
  final String id;
  final String taskCode;
  final String organizationId;
  final String sourceMode;
  final String status;
  final String priority;
  final String title;
  final String reference;
  final String description;
  final String industry;
  final List<dynamic> tags;

  final TaskDestination? taskDestination;
  final String? dueAt;
  final String? scheduledFor;
  final String? startWindowAt;
  final String? endWindowAt;

  final bool requiresEvidence;
  final bool emergency;
  final String moderationState;
  final Map<String, dynamic> metadata;
  final String createdAt;
  final String updatedAt;
  final CreatorSummary? creatorSummary;

  EmployeeTaskModel({
    required this.id,
    required this.taskCode,
    required this.organizationId,
    required this.sourceMode,
    required this.status,
    required this.priority,
    required this.title,
    required this.reference,
    required this.description,
    required this.industry,
    required this.tags,
    this.taskDestination,
    this.dueAt,
    this.scheduledFor,
    this.startWindowAt,
    this.endWindowAt,
    required this.requiresEvidence,
    required this.emergency,
    required this.moderationState,
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
    this.creatorSummary,
  });

  factory EmployeeTaskModel.fromJson(Map<String, dynamic> json) {
    return EmployeeTaskModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      taskCode: json['taskCode']?.toString() ?? '',
      organizationId: json['organizationId']?.toString() ?? '',
      sourceMode: json['sourceMode']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      priority: json['priority']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      reference: json['reference']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      industry: json['industry']?.toString() ?? '',
      tags: json['tags'] as List<dynamic>? ?? [],
      taskDestination: json['taskDestination'] != null
          ? TaskDestination.fromJson(
              json['taskDestination'] as Map<String, dynamic>,
            )
          : null,
      dueAt:
          (json['dueAt'] != null &&
              json['dueAt'].toString() != 'null' &&
              json['dueAt'].toString().isNotEmpty)
          ? json['dueAt'].toString()
          : (json['endWindowAt'] != null &&
                json['endWindowAt'].toString() != 'null' &&
                json['endWindowAt'].toString().isNotEmpty)
          ? json['endWindowAt'].toString()
          : null,
      scheduledFor: json['scheduledFor']?.toString(),
      startWindowAt: json['startWindowAt']?.toString(),
      endWindowAt: json['endWindowAt']?.toString(),
      requiresEvidence: json['requiresEvidence'] as bool? ?? false,
      emergency: json['emergency'] as bool? ?? false,
      moderationState: json['moderationState']?.toString() ?? '',
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
      creatorSummary: json['creatorSummary'] != null
          ? CreatorSummary.fromJson(
              json['creatorSummary'] as Map<String, dynamic>,
              creatorProfileImage: json['metadata']?['creatorProfileImage']
                  ?.toString(),
            )
          : null,
    );
  }
}

class TaskDestination {
  final GeoPoint point;
  final String label;
  final String description;
  final Address address;

  TaskDestination({
    required this.point,
    required this.label,
    required this.description,
    required this.address,
  });

  factory TaskDestination.fromJson(Map<String, dynamic> json) {
    return TaskDestination(
      point: GeoPoint.fromJson(json['point'] as Map<String, dynamic>? ?? {}),
      label: json['label']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      address: Address.fromJson(json['address'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class GeoPoint {
  final String type;
  final List<double> coordinates;

  GeoPoint({required this.type, required this.coordinates});

  factory GeoPoint.fromJson(Map<String, dynamic> json) {
    return GeoPoint(
      type: json['type']?.toString() ?? '',
      coordinates: List<double>.from(
        (json['coordinates'] as List? ?? []).map((e) => (e as num).toDouble()),
      ),
    );
  }
}

class Address {
  final String line1;
  final String city;
  final String country;
  final String postalCode;

  Address({
    required this.line1,
    required this.city,
    required this.country,
    required this.postalCode,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      line1: json['line1']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      postalCode: json['postalCode']?.toString() ?? '',
    );
  }
}

class CreatorSummary {
  final String id;
  final String model;
  final String fullName;
  final String email;
  final String countryCode;
  final String phone;
  final String profileImage;

  CreatorSummary({
    required this.id,
    required this.model,
    required this.fullName,
    required this.email,
    required this.countryCode,
    required this.phone,
    required this.profileImage,
  });

  factory CreatorSummary.fromJson(
    Map<String, dynamic> json, {
    String? creatorProfileImage,
  }) {
    return CreatorSummary(
      id: json['id']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      countryCode: json['countryCode']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      profileImage:
          (creatorProfileImage != null && creatorProfileImage.isNotEmpty)
          ? creatorProfileImage
          : (json['profileImage']?.toString() ?? ''),
    );
  }
}
