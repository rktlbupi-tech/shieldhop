class CameraData {
  String path;
  String mimeType;
  String videoImagePath;
  String latitude;
  String longitude;
  String dateTime;
  String location;
  String country;
  String city;
  String state;
  bool fromGallary;

  CameraData({
    required this.path,
    required this.mimeType,
    required this.videoImagePath,
    required this.latitude,
    required this.longitude,
    required this.dateTime,
    required this.location,
    required this.country,
    required this.city,
    required this.state,
    this.fromGallary = false,
  });
}

class MediaData {
  String mimeType;
  String latitude;
  String longitude;
  String location;
  String dateTime;
  String mediaPath;
  String thumbnail;
  bool isLocalMedia;

  MediaData({
    required this.mimeType,
    required this.latitude,
    required this.longitude,
    required this.location,
    required this.dateTime,
    required this.mediaPath,
    required this.thumbnail,
    this.isLocalMedia = false,
  });
}

class PublishData {
  String imagePath;
  String address;
  String date;
  String city;
  String state;
  String country;
  String latitude;
  String longitude;
  String mimeType;
  String videoImagePath;
  List<MediaData> mediaList;

  PublishData({
    required this.imagePath,
    required this.address,
    required this.date,
    required this.city,
    required this.state,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.mimeType,
    required this.videoImagePath,
    required this.mediaList,
  });
}

class CameraTaskModel {
  final String id;
  final String title;
  final String? destinationLabel;
  final String? creatorProfileImage;

  const CameraTaskModel({
    required this.id,
    required this.title,
    this.destinationLabel,
    this.creatorProfileImage,
  });

  factory CameraTaskModel.fromJson(Map<String, dynamic> j) {
    final dest = j['taskDestination'];
    final creator = j['creatorSummary'] ?? j['assignedBy'];
    return CameraTaskModel(
      id: j['_id']?.toString() ?? j['id']?.toString() ?? '',
      title: j['title']?.toString() ?? '',
      destinationLabel: dest is Map ? dest['label']?.toString() : null,
      creatorProfileImage: creator is Map ? creator['profileImage']?.toString() : null,
    );
  }
}

class CameraTaskMediaData {
  final String mediaPath;
  final String mimeType;
  final String thumbnail;
  final String latitude;
  final String longitude;
  final String location;
  final String dateTime;
  final bool isLocalMedia;

  CameraTaskMediaData({
    required this.mediaPath,
    required this.mimeType,
    required this.thumbnail,
    required this.latitude,
    required this.longitude,
    required this.location,
    required this.dateTime,
    required this.isLocalMedia,
  });
}
