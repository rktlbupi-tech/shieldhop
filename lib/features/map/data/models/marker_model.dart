import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:presshop_enterprise/features/map/core/map_constants.dart';

class Incident {
  final String id;
  final String markerType; // "icon", "content", "hopper"
  final String? type; // e.g. accident, fire (only for icon)
  final LatLng position;
  final String? address;
  final String? time;
  final String? image; // For content/hopper markers
  final String? title;
  final String? description;
  final String? name;
  final String? rating;
  final String? specialization;
  final String? distance;
  final String? statusColor;
  final String? category; // e.g. "Accident", "Crime", "Event"
  final String? alertType; // e.g. "Alert", "Info", "Warning"
  final String? author;
  final String? authorImage;
  final String? date;
  final int? soldCount;
  final double? earnings;
  final int? viewCount;
  final bool? isPublished;
  final bool? isMostViewed;
  final int? likesCount;
  final int? commentsCount;
  final int? sharesCount;
  final bool? isHtml;
  final String? userName;
  final String? avatarImage;

  final bool? isLiked;
  final bool? isLiked2;
  final int? totalViews;

  // Weather fields
  final double? temperature;
  final double? wind;
  final double? visibility;
  final String? heading;

  // Media fields
  final String? media;
  final String? mediaType;

  Incident({
    required this.id,
    required this.markerType,
    required this.position,
    this.type,
    this.address,
    this.time,
    this.image,
    this.title,
    this.description,
    this.name,
    this.rating,
    this.specialization,
    this.distance,
    this.statusColor,
    this.category,
    this.alertType,
    this.author,
    this.authorImage,
    this.date,
    this.soldCount,
    this.earnings,
    this.viewCount,
    this.isPublished,
    this.isMostViewed,
    this.likesCount,
    this.commentsCount,
    this.sharesCount,
    this.isLiked,
    this.isLiked2,
    this.totalViews,
    this.temperature,
    this.wind,
    this.visibility,
    this.heading,
    this.media,
    this.mediaType,
    this.isHtml,
    this.userName,
    this.avatarImage,
  });

  factory Incident.fromMap(Map<String, dynamic> map) {
    double lat = 0.0;
    double lng = 0.0;

    final pos = map['position'];
    if (pos is Map<String, dynamic>) {
      if (pos['coordinates'] is List &&
          (pos['coordinates'] as List).length >= 2) {
        final c0 = (pos['coordinates'][0] as num).toDouble();
        final c1 = (pos['coordinates'][1] as num).toDouble();

        // Smart Detection: Latitude is always between -90 and 90.
        // If coordinate 0 is outside -90 to 90, it MUST be longitude.
        if (c0.abs() > 90) {
          lng = c0;
          lat = c1;
        } else if (c1.abs() > 90) {
          lat = c0;
          lng = c1;
        } else {
          // Fallback: API 'position' field usually sends [lat, lng]
          lat = c0;
          lng = c1;
        }
      } else {
        lat = (pos['lat'] ?? pos['latitude'] ?? 0.0).toDouble();
        lng = (pos['lng'] ?? pos['longitude'] ?? 0.0).toDouble();
      }
    }

    String? userName = map['userName'] ?? map['author'];
    String? resolvedAvatar = map['avatarImage'] ?? map['author_url'];

    if (map['created_by'] is Map) {
      final cb = map['created_by'] as Map;
      userName ??= cb['user_name'];
      if (resolvedAvatar == null && cb['avatar_id'] is Map) {
        resolvedAvatar = cb['avatar_id']['avatar'];
      }
    }

    if (resolvedAvatar != null &&
        resolvedAvatar.isNotEmpty &&
        !resolvedAvatar.startsWith('http')) {
      resolvedAvatar = "$avatarImageUrl$resolvedAvatar";
    }

    return Incident(
      id: map['id'],
      markerType: map['markerType'],
      type: map['type'],
      position: LatLng(lat, lng),
      address: map['location'],
      time: map['time'],
      image: map['image'],
      title: map['title'],
      description: map['description'],
      name: map['name'],
      rating: map['rating'],
      specialization: map['specialization'],
      distance: map['distance'],
      statusColor: map['statusColor'],
      category: map['category'],
      alertType: map['alertType'],
      author: map['author'],
      authorImage: map['author_url'],
      date: map['date'],
      soldCount: map['soldCount'],
      earnings: map['earnings']?.toDouble(),
      viewCount: map['viewCount'],
      isPublished: map['isPublished'],
      isMostViewed: map['isMostViewed'],
      likesCount: map['likesCount'],
      commentsCount: map['commentsCount'],
      sharesCount: map['sharesCount'],
      isLiked: map['isLiked'],
      isLiked2: map['isLiked2'],
      totalViews: map['totalViews'],
      media: map['media'],
      mediaType: map['mediaType'],
      isHtml: map['isHtml'],
      userName: userName,
      avatarImage: resolvedAvatar,
    );
  }

  factory Incident.fromJson(Map<String, dynamic> json) {
    double lat = 0.0;
    double lng = 0.0;

    double parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    bool parseBool(dynamic value) {
      if (value is bool) return value;
      if (value is num) return value == 1;
      if (value is String) {
        final s = value.toLowerCase();
        return s == 'true' || s == '1';
      }
      return false;
    }

    if (json['position'] is Map) {
      final posMap = json['position'] as Map;
      if (posMap['coordinates'] is List &&
          (posMap['coordinates'] as List).length >= 2) {
        final c0 = parseDouble(posMap['coordinates'][0]);
        final c1 = parseDouble(posMap['coordinates'][1]);

        if (c0.abs() > 90) {
          lng = c0;
          lat = c1;
        } else if (c1.abs() > 90) {
          lat = c0;
          lng = c1;
        } else {
          // 'position' usually [lat, lng]
          lat = c0;
          lng = c1;
        }
      } else {
        lat = parseDouble(posMap['lat'] ?? posMap['latitude']);
        lng = parseDouble(posMap['lng'] ?? posMap['longitude']);
      }
    } else if (json['location'] is Map) {
      final locMap = json['location'] as Map;
      if (locMap['coordinates'] is List &&
          (locMap['coordinates'] as List).length >= 2) {
        final c0 = parseDouble(locMap['coordinates'][0]);
        final c1 = parseDouble(locMap['coordinates'][1]);

        if (c0.abs() > 90) {
          lng = c0;
          lat = c1;
        } else if (c1.abs() > 90) {
          lat = c0;
          lng = c1;
        } else {
          // 'location' (GeoJSON standard) is [lng, lat]
          lng = c0;
          lat = c1;
        }
      }
    } else {
      lat = parseDouble(json['lat'] ?? json['latitude']);
      lng = parseDouble(json['lng'] ?? json['longitude']);
    }

    String? userName = json['userName'] ?? json['author'];
    String? resolvedAvatar =
        json['avatarImage'] ?? json['author_url'] ?? json['authorImage'];

    if (json['created_by'] is Map) {
      final cb = json['created_by'] as Map;
      userName ??= cb['user_name'];
      if (resolvedAvatar == null && cb['avatar_id'] is Map) {
        resolvedAvatar = cb['avatar_id']['avatar'];
      }
    }

    if (resolvedAvatar != null &&
        resolvedAvatar.isNotEmpty &&
        !resolvedAvatar.startsWith('http')) {
      resolvedAvatar = "$avatarImageUrl$resolvedAvatar";
    }

    return Incident(
      id: (json['_id'] ?? json['id'] ?? DateTime.now().millisecondsSinceEpoch)
          .toString(),
      markerType: json['markerType'] ?? 'icon',
      type: json['type'] ?? 'accident',
      position: LatLng(lat, lng),
      address: json['address'] is String
          ? json['address']
          : (json['location'] is String ? json['location'] : null),
      time: (json['date'] ??
              json['createdAt'] ??
              json['time'] ??
              json['created_at'])
          ?.toString(),
      image: json['image'] is String ? json['image'] : null,
      title: json['title'] is String ? json['title'] : null,
      description: (json['description'] ?? json['message']) is String
          ? (json['description'] ?? json['message'])
          : null,
      name: json['name'] is String ? json['name'] : null,
      rating: json['rating']?.toString(),
      specialization:
          json['specialization'] is String ? json['specialization'] : null,
      distance: json['distance']?.toString(),
      statusColor: json['statusColor'] is String ? json['statusColor'] : null,
      category: json['category'] is String ? json['category'] : null,
      alertType: json['alertType'] is String ? json['alertType'] : null,
      author: json['author'] is String ? json['author'] : null,
      date: json['date'] is String ? json['date'] : null,
      soldCount: json['soldCount'],
      earnings: (json['earnings'] ?? 0.0).toDouble(),
      viewCount: json['viewCount'] ?? json['total_views'] ?? json['views'],
      isPublished: json['isPublished'],
      isMostViewed: json['isMostViewed'],
      likesCount: json['likesCount'] ?? json['likes'] ?? json['total_likes'],
      commentsCount: json['commentsCount'] ?? json['comments'],
      sharesCount: json['sharesCount'] ?? json['shares'] ?? json['shareCount'],
      isLiked: parseBool(json['isLiked'] ?? json['is_liked']),
      totalViews: json['total_views'] ?? json['views'],
      temperature: (json['temperature'] is num)
          ? json['temperature'].toDouble()
          : double.tryParse(json['temperature'].toString()),
      wind: (json['wind'] is num)
          ? json['wind'].toDouble()
          : double.tryParse(json['wind'].toString()),
      visibility: (json['visibility'] is num)
          ? json['visibility'].toDouble()
          : double.tryParse(json['visibility'].toString()),
      heading: json['heading'] is String ? json['heading'] : null,
      media: json['media'] is String ? json['media'] : null,
      authorImage: (json['author_url']),
      mediaType: json['mediaType'] is String
          ? json['mediaType']
          : (json['mediatype'] is String ? json['mediatype'] : null),
      isHtml: parseBool(json['isHtml']),
      userName: userName,
      avatarImage: resolvedAvatar,
    );
  }

  Incident copyWith({
    String? id,
    String? markerType,
    String? type,
    LatLng? position,
    String? address,
    String? time,
    String? image,
    String? title,
    String? description,
    String? name,
    String? rating,
    String? specialization,
    String? distance,
    String? statusColor,
    String? category,
    String? alertType,
    String? author,
    String? date,
    int? soldCount,
    double? earnings,
    int? viewCount,
    bool? isPublished,
    bool? isMostViewed,
    int? likesCount,
    int? commentsCount,
    int? sharesCount,
    bool? isLiked,
    int? totalViews,
    double? temperature,
    double? wind,
    double? visibility,
    String? heading,
    String? media,
    String? mediaType,
    String? userName,
    String? avatarImage,
  }) {
    return Incident(
      id: id ?? this.id,
      markerType: markerType ?? this.markerType,
      type: type ?? this.type,
      position: position ?? this.position,
      address: address ?? this.address,
      time: time ?? this.time,
      image: image ?? this.image,
      title: title ?? this.title,
      description: description ?? this.description,
      name: name ?? this.name,
      rating: rating ?? this.rating,
      specialization: specialization ?? this.specialization,
      distance: distance ?? this.distance,
      statusColor: statusColor ?? this.statusColor,
      category: category ?? this.category,
      alertType: alertType ?? this.alertType,
      author: author ?? this.author,
      authorImage: authorImage ?? this.authorImage,
      date: date ?? this.date,
      soldCount: soldCount ?? this.soldCount,
      earnings: earnings ?? this.earnings,
      viewCount: viewCount ?? this.viewCount,
      isPublished: isPublished ?? this.isPublished,
      isMostViewed: isMostViewed ?? this.isMostViewed,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      isLiked: isLiked ?? this.isLiked,
      totalViews: totalViews ?? this.totalViews,
      temperature: temperature ?? this.temperature,
      wind: wind ?? this.wind,
      visibility: visibility ?? this.visibility,
      heading: heading ?? this.heading,
      media: media ?? this.media,
      mediaType: mediaType ?? this.mediaType,
      isHtml: isHtml ?? this.isHtml,
      userName: userName ?? this.userName,
      avatarImage: avatarImage ?? this.avatarImage,
    );
  }
}

class RoadGeometry {
  final String type;
  final List<List<double>> coordinates;

  RoadGeometry({required this.type, required this.coordinates});

  factory RoadGeometry.fromJson(Map<String, dynamic> json) {
    List<List<double>> coords = [];
    if (json['coordinates'] != null) {
      if (json['type'] == 'LineString') {
        // [[80.3, 26.4], ...]
        for (var point in json['coordinates']) {
          if (point is List) {
            coords.add(point.map((e) => (e as num).toDouble()).toList());
          }
        }
      } else if (json['type'] == 'Polygon') {
        // [[[80.3, 26.4], ...]] - GeoJSON polygons are list of rings
        // We handle simple polygon (first ring)
        if (json['coordinates'] is List && json['coordinates'].isNotEmpty) {
          var ring = json['coordinates'][0];
          if (ring is List) {
            for (var point in ring) {
              if (point is List) {
                coords.add(point.map((e) => (e as num).toDouble()).toList());
              }
            }
          }
        }
      }
    }
    return RoadGeometry(
      type: json['type'] ?? 'Unknown',
      coordinates: coords,
    );
  }

  List<LatLng> toLatLngList() {
    return coordinates.map((c) => LatLng(c[1], c[0])).toList();
  }
}

class RoadIncident {
  final String type;
  final int severity;
  final String reason;
  final RoadGeometry geometry;

  RoadIncident({
    required this.type,
    required this.severity,
    required this.reason,
    required this.geometry,
  });

  factory RoadIncident.fromJson(Map<String, dynamic> json) {
    return RoadIncident(
      type: json['type'] ?? '',
      severity: json['severity'] ?? 0,
      reason: json['reason'] ?? '',
      geometry: RoadGeometry.fromJson(json['geometry'] ?? {}),
    );
  }
}

class BlockedRoadResponse {
  final List<RoadIncident> blockedRoads;
  final RoadIncident? dangerZone;
  final List<RoadIncident> incidents;

  BlockedRoadResponse({
    required this.blockedRoads,
    this.dangerZone,
    required this.incidents,
  });

  factory BlockedRoadResponse.fromJson(Map<String, dynamic> json) {
    var data = json['data'];
    if (data == null)
      return BlockedRoadResponse(blockedRoads: [], incidents: []);

    return BlockedRoadResponse(
      blockedRoads: (data['blockedRoads'] as List?)
              ?.map((e) => RoadIncident.fromJson(e))
              .toList() ??
          [],
      dangerZone: data['dangerZone'] != null
          ? RoadIncident.fromJson(data['dangerZone'])
          : null,
      incidents: (data['incidents'] as List?)
              ?.map((e) => RoadIncident.fromJson(e))
              .toList() ??
          [],
    );
  }
}
