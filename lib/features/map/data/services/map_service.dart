import 'dart:convert';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:presshop_enterprise/features/map/core/map_constants.dart';

class MapService {
  final String googleApiKey;
  MapService({required this.googleApiKey});

  Future<RouteInfo> getRouteInfo(LatLng start, LatLng end) async {
    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${start.latitude},${start.longitude}&destination=${end.latitude},${end.longitude}&mode=driving&key=$googleApiKey';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) throw 'HTTP Error: ${response.statusCode}';

    final data = json.decode(response.body);
    if (data['status'] != 'OK')
      throw 'Google Directions Error: ${data['status']}';

    final route = data['routes'][0];
    final leg = route['legs'][0];

    // Get distance in meters and convert to km
    final distanceMeters = leg['distance']['value'] as int;
    final distanceKm = distanceMeters / 1000.0;

    // Get duration in seconds and convert to minutes
    final durationSeconds = leg['duration']['value'] as int;
    final durationMinutes = (durationSeconds / 60).round();

    final encodedPolyline = route['overview_polyline']['points'];
    final resultPoints = PolylinePoints().decodePolyline(encodedPolyline);
    final points = resultPoints
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();

    return RouteInfo(
      points: points,
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
    );
  }

  Future<List<LatLng>> getRoutePoints(LatLng start, LatLng end) async {
    final routeInfo = await getRouteInfo(start, end);
    return routeInfo.points;
  }

  Future<LatLng?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint("MapService: Location services are disabled.");
      return null;
    }

    // Permission is requested once upstream (MapCubit / TeamMapScreen). Here we
    // only read the current status so we never trigger a second system prompt.
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      debugPrint("MapService: Location permissions are denied.");
      return null;
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint(
        "MapService: Location permissions are permanently denied, we cannot request permissions.",
      );
      return null;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 3),
      );
      return LatLng(pos.latitude, pos.longitude);
    } catch (e) {
      debugPrint("MapService: Error/Timeout getting fresh position: $e");
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        debugPrint(
          "MapService: Using last known location as fallback: ${lastKnown.latitude}, ${lastKnown.longitude}",
        );
        return LatLng(lastKnown.latitude, lastKnown.longitude);
      }
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getPlaceSuggestions(String input) async {
    final url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$googleApiKey';
    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);

    if (data['status'] == 'OK') {
      return (data['predictions'] as List)
          .map(
            (p) => {'description': p['description'], 'place_id': p['place_id']},
          )
          .toList();
    }
    return [];
  }

  Future<LatLng?> getPlaceDetails(String placeId) async {
    final url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$googleApiKey';
    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);

    if (data['status'] == 'OK') {
      final location = data['result']['geometry']['location'];
      return LatLng(location['lat'], location['lng']);
    }
    return null;
  }

  String getDistanceText(List<LatLng> points) {
    final distance = MapUtils.calculateDistance(points);
    final duration = MapUtils.calculateDuration(distance);
    return '${distance.toStringAsFixed(2)} km • $duration';
  }
}

class RouteInfo {
  final List<LatLng> points;
  final double distanceKm;
  final int durationMinutes;

  RouteInfo({
    required this.points,
    required this.distanceKm,
    required this.durationMinutes,
  });

  String get formattedDistance => '${distanceKm.toStringAsFixed(1)} km';
  String get formattedDuration => '$durationMinutes min';
  String get formattedInfo => '$formattedDistance • $formattedDuration';
}
