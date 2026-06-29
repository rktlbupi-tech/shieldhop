import 'package:google_maps_flutter/google_maps_flutter.dart';

class HeatmapWorker {
  final String id;
  final String name;
  final String role;
  final String profileImage;
  final double lat;
  final double lng;
  final double? distanceMiles;
  final String distanceLabel;
  final String formattedAddress;
  final DateTime? lastSeenAt;
  final bool isStale;
  final bool isSelf;
  final String phone;

  bool get isOnline => !isStale;

  HeatmapWorker({
    required this.id,
    required this.name,
    required this.role,
    required this.profileImage,
    required this.lat,
    required this.lng,
    required this.distanceMiles,
    required this.distanceLabel,
    required this.formattedAddress,
    required this.lastSeenAt,
    required this.isStale,
    this.isSelf = false,
    this.phone = '',
  });

  factory HeatmapWorker.fromJson(Map<String, dynamic> json) {
    final worker = json['worker'] ?? {};
    final position = json['position'] ?? {};
    final address = json['address'] ?? {};

    return HeatmapWorker(
      id: worker['id']?.toString() ?? '',
      name: worker['name']?.toString() ?? '',
      role: worker['role']?.toString() ?? '',
      profileImage: worker['profileImage']?.toString() ?? '',
      lat: (position['lat'] ?? 0).toDouble(),
      lng: (position['lng'] ?? 0).toDouble(),
      distanceMiles: json['distanceMiles'] == null
          ? null
          : (json['distanceMiles']).toDouble(),
      distanceLabel: json['distanceLabel']?.toString() ?? '',
      formattedAddress: address['formattedAddress']?.toString() ?? '',
      lastSeenAt: json['lastSeenAt'] != null
          ? DateTime.tryParse(json['lastSeenAt'])
          : null,
      isStale: json['isStale'] == true,
      isSelf: json['isSelf'] == true,
      phone: worker['phone']?.toString() ??
          worker['phoneNumber']?.toString() ??
          worker['mobileNumber']?.toString() ??
          '',
    );
  }
}

class HeatmapAlert {
  final String id;
  final String type;
  final String typeLabel;
  final String severity;
  final String status;
  final double lat;
  final double lng;
  final String description;
  final String formattedAddress;
  final double? distanceMiles;
  final String distanceLabel;
  final String imageUrl;
  final String creatorName;
  final String creatorImage;

  HeatmapAlert({
    required this.id,
    required this.type,
    required this.typeLabel,
    required this.severity,
    required this.status,
    required this.lat,
    required this.lng,
    required this.description,
    required this.formattedAddress,
    required this.distanceMiles,
    required this.distanceLabel,
    this.imageUrl = '',
    this.creatorName = '',
    this.creatorImage = '',
  });

  factory HeatmapAlert.fromJson(Map<String, dynamic> json) {
    final position = json['position'] ?? {};
    final address = json['address'] ?? {};
    final metadata = json['metadata'] ?? {};
    final creator = json['creatorSummary'] ?? {};

    return HeatmapAlert(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      typeLabel: json['typeLabel']?.toString() ?? '',
      severity: json['severity']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      lat: (position['lat'] ?? 0).toDouble(),
      lng: (position['lng'] ?? 0).toDouble(),
      description: json['description']?.toString() ?? '',
      formattedAddress: address['formattedAddress']?.toString() ?? '',
      distanceMiles: json['distanceMiles'] == null
          ? null
          : (json['distanceMiles']).toDouble(),
      distanceLabel: json['distanceLabel']?.toString() ?? '',
      imageUrl: metadata['imageUrl']?.toString() ?? '',
      creatorName: creator['name']?.toString() ?? '',
      creatorImage: (metadata['creatorProfileImage'] != null &&
              metadata['creatorProfileImage'].toString().isNotEmpty)
          ? metadata['creatorProfileImage'].toString()
          : creator['profileImage']?.toString() ?? '',
    );
  }
}

class EmployeeAlertMarker {
  final String id;
  final String type;
  final String typeLabel;
  final LatLng position;
  final String imageUrl;
  final DateTime timestamp;
  final String description;
  final String formattedAddress;
  final String creatorName;
  final String creatorImage;

  EmployeeAlertMarker({
    required this.id,
    required this.type,
    required this.typeLabel,
    required this.position,
    required this.imageUrl,
    required this.timestamp,
    this.description = '',
    this.formattedAddress = '',
    this.creatorName = '',
    this.creatorImage = '',
  });
}

class EmployeeMapState {
  final bool isAlertPanelOpen;
  final bool isLoading;
  final bool isGetDirectionOpen;
  final List<EmployeeAlertMarker> alertMarkers;
  final List<HeatmapWorker> workers;
  final EmployeeAlertMarker? newlyCreatedAlert;

  EmployeeMapState({
    this.isAlertPanelOpen = false,
    this.isLoading = false,
    this.isGetDirectionOpen = false,
    this.alertMarkers = const [],
    this.workers = const [],
    this.newlyCreatedAlert,
  });

  EmployeeMapState copyWith({
    bool? isAlertPanelOpen,
    bool? isLoading,
    bool? isGetDirectionOpen,
    List<EmployeeAlertMarker>? alertMarkers,
    List<HeatmapWorker>? workers,
    EmployeeAlertMarker? newlyCreatedAlert,
  }) {
    return EmployeeMapState(
      isAlertPanelOpen: isAlertPanelOpen ?? this.isAlertPanelOpen,
      isLoading: isLoading ?? this.isLoading,
      isGetDirectionOpen: isGetDirectionOpen ?? this.isGetDirectionOpen,
      alertMarkers: alertMarkers ?? this.alertMarkers,
      workers: workers ?? this.workers,
      newlyCreatedAlert: newlyCreatedAlert ?? this.newlyCreatedAlert,
    );
  }
}

class SosSession {
  final String sessionId;
  final String status;
  final String? activeAlertId;
  final DateTime? startedAt;
  final DateTime? resolvedAt;

  bool get isActive => status == 'active';

  SosSession({
    required this.sessionId,
    required this.status,
    this.activeAlertId,
    this.startedAt,
    this.resolvedAt,
  });

  factory SosSession.fromJson(Map<String, dynamic> json) {
    final d = json['data'] ?? json;
    return SosSession(
      sessionId: d['sessionId']?.toString() ?? d['_id']?.toString() ?? '',
      status: d['status']?.toString() ?? 'active',
      activeAlertId: d['activeAlertId']?.toString(),
      startedAt:
          d['startedAt'] != null ? DateTime.tryParse(d['startedAt']) : null,
      resolvedAt:
          d['resolvedAt'] != null ? DateTime.tryParse(d['resolvedAt']) : null,
    );
  }
}
