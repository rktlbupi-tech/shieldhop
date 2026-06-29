import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

const numD01 = 0.01;
const numD02 = 0.02;
const numD021 = 0.021;
const numD022 = 0.022;
const numD025 = 0.025;
const numD03 = 0.03;
const numD035 = 0.035;
const numD04 = 0.04;
const numD05 = 0.05;
const numD06 = 0.06;
const numD07 = 0.07;
const numD08 = 0.08;
const numD09 = 0.09;
const numD1 = 0.1;
const numD12 = 0.12;

const colorThemePink = Color(0xFFE91E63);
const colorEmployeeGreen1 = Color(0xFF1877F2);
const numD005 = 0.005;
const numD032 = 0.032;
const size0 = 0.0;
const size100 = 100.0;
const size200 = 200.0;

class DummyProfileData {
  final String? profilePic;
  final String? profileImage;

  final String? avatar;
  final String id;
  final String type;
  DummyProfileData({
    this.profilePic,
    this.profileImage,
    this.avatar,
    this.id = '',
    this.type = 'employee',
  });
}

class DummyProfileController {
  final DummyProfileData profileData = DummyProfileData();
}

class FilterOption {
  final String label;
  final String value;
  const FilterOption({required this.label, required this.value});
}

const List<FilterOption> radiusOptions = [
  FilterOption(label: '2 miles', value: '2 miles'),
  FilterOption(label: '5 miles', value: '5 miles'),
  FilterOption(label: '10 miles', value: '10 miles'),
];

const List<FilterOption> alertOptions = [
  FilterOption(label: 'Alerts', value: ''),
  FilterOption(label: 'Accident', value: 'accident'),
  FilterOption(label: 'Crash', value: 'crash'),
  FilterOption(label: 'Fire Alert', value: 'fire'),
  FilterOption(label: 'Fight', value: 'fight'),
  FilterOption(label: 'Safety Alert', value: 'knife'),
  FilterOption(label: 'Vandalism', value: 'gun'),
  FilterOption(label: 'Medical', value: 'medical'),
  FilterOption(label: 'Protest', value: 'protest'),
  FilterOption(label: 'Police', value: 'police'),
  FilterOption(label: 'Weather', value: 'weather'),
  FilterOption(label: 'Snow', value: 'snow'),
  FilterOption(label: 'Earthquake', value: 'earthquake'),
];

const List<FilterOption> categoryOptions = [
  FilterOption(label: 'Category', value: ''),
  FilterOption(label: 'Latest', value: 'latest'),
  FilterOption(label: 'Crime', value: 'crime'),
  FilterOption(label: 'Event', value: 'event'),
  FilterOption(label: 'Political', value: 'political'),
  FilterOption(label: 'Celebrity', value: 'celebrity'),
  FilterOption(label: 'Sports', value: 'sports'),
];

const numD003 = 0.003;
const numD008 = 0.008;
const numD015 = 0.015;

const numD002 = 0.002;
const numD026 = 0.026;
const numD045 = 0.045;
const numD055 = 0.055;
const numD40 = 0.40;
const numD50 = 0.50;
const numD65 = 0.65;
const size1 = 1.0;
const size1_2 = 1.2;

const String googleMapURL =
    'https://maps.googleapis.com/maps/api/place/autocomplete/json';
const String googlePlaceDetailsURL =
    'https://maps.googleapis.com/maps/api/place/details/json';
const String googleMapAPiKey = 'AIzaSyClF12i0eHy7Nrig6EYu8Z4U5DA2zC09OI';
const String avatarImageUrl = 'https://dev-api.presshop.news:5019/uploads/';
const String hopperIdKey = 'user_id';

class MapUtils {
  static double calculateDistance(List<LatLng> points) {
    double total = 0;
    for (int i = 0; i < points.length - 1; i++) {
      const earthRadiusKm = 6371.0;
      final lat1 = points[i].latitude * (3.14159265358979 / 180);
      final lat2 = points[i + 1].latitude * (3.14159265358979 / 180);
      final dLat = lat2 - lat1;
      final dLng =
          (points[i + 1].longitude - points[i].longitude) *
          (3.14159265358979 / 180);
      final a = (dLat / 2) * (dLat / 2) + (dLng / 2) * (dLng / 2);
      total += 2 * earthRadiusKm * (a < 1 ? a : 1);
    }
    return total;
  }

  static String calculateDuration(double distanceKm) {
    final minutes = (distanceKm * 60 / 50).round();
    if (minutes < 60) return '${minutes}m';
    return '${minutes ~/ 60}h ${minutes % 60}m';
  }
}

const Map<String, String> burstIcons = {
  "accident": "assets/markers/bg-removed/bg-removed-crash.webp",
  "crash": "assets/markers/bg-removed/bg-removed-crash.webp",
  "fire": "assets/markers/bg-removed/bg-removed-fire.webp",
  "medical": "assets/markers/bg-removed/bg-removed-medicine.webp",
  "gun": "assets/markers/bg-removed/bg-removed-vandalism.webp",
  "protest": "assets/markers/bg-removed/bg-removed-protest.webp",
  "knife": "assets/markers/bg-removed/bg-removed-public_safety_alert.webp",
  "fight": "assets/markers/bg-removed/bg-removed-fight.webp",
  "content": "assets/markers/bg-removed/bg-removed-content.webp",
  "police": "assets/markers/bg-removed/bg-removed-police.webp",
  "floods": "assets/markers/bg-removed/bg-removed-flood.webp",
  "storm": "assets/markers/bg-removed/bg-removed-storm.webp",
  "earthquake": "assets/markers/bg-removed/bg-removed-earthquake.webp",
  "road-block": "assets/markers/bg-removed/bg-removed-road-block.webp",
  "snow": "assets/markers/bg-removed/bg-removed-snow.webp",
  "contact_family": "assets/markers/bg-removed/bg-removed-contact-family.webp",
  "need-help": "assets/markers/bg-removed/bg-removed-need-help.webp",
  "send-backup": "assets/markers/bg-removed/bg-removed-send-backup.webp",
  "police_call": "assets/markers/bg-removed/bg-removed-police-call.webp",
  "ambulance_call": "assets/markers/bg-removed/bg-removed-medicine.webp",
  "under_threat": "assets/markers/bg-removed/bg-removed-vandalism.webp",
  "being-followed": "assets/markers/bg-removed/bg-removed-being-followed.webp",
  "get_me_out": "assets/markers/bg-removed/bg-removed-get-me-out.webp",
  "im_safe": "assets/markers/bg-removed/bg-removed-im-safe.webp",
  "send_support": "assets/markers/bg-removed/bg-removed-send-support.webp",
  "no_signal": "assets/markers/bg-removed/bg-removed-no-signal.webp",
  "low_battery": "assets/markers/bg-removed/bg-removed-low-battery.webp",
};
