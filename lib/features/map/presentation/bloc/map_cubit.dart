import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:presshop_enterprise/features/map/data/models/map_state.dart';
import 'package:presshop_enterprise/features/map/data/services/map_service.dart';

class MapCubit extends Cubit<MapState> {
  final MapService _mapService;

  MapCubit({MapService? mapService})
      : _mapService = mapService ??
            MapService(googleApiKey: 'AIzaSyClF12i0eHy7Nrig6EYu8Z4U5DA2zC09OI'),
        super(MapState(selectedDistance: '5 miles'));

  Future<void> initLocationAndData({
    bool forceRefresh = false,
    bool isFeedOnly = false,
    bool isBackgroundRefresh = true,
  }) async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        const fallback = LatLng(51.5135893, -0.1285953);
        if (!isClosed) emit(state.copyWith(myLocation: fallback));
        return;
      }

      final pos = await _mapService.getCurrentLocation();
      if (pos != null && !isClosed) {
        final address = await getAddressFromCoordinates(pos);
        emit(state.copyWith(myLocation: pos, myLocationAddress: address));
      }
    } catch (e) {
      debugPrint('MapCubit.initLocationAndData error: $e');
    }
  }

  Future<String> getAddressFromCoordinates(LatLng position) async {
    try {
      final placemarks = await geo.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        return '${p.street}, ${p.locality}, ${p.country}';
      }
    } catch (_) {}
    return 'Unknown location';
  }

  Future<void> addRoute(LatLng? origin, LatLng destination) async {
    final start = origin ?? state.myLocation;
    if (start == null) return;
    try {
      final routeInfo = await _mapService.getRouteInfo(start, destination);
      final polyline = Polyline(
        polylineId: const PolylineId('route'),
        points: routeInfo.points,
        color: Colors.blue,
        width: 5,
      );
      if (!isClosed) {
        emit(state.copyWith(
          routeInfo: routeInfo,
          polylines: {polyline},
          destination: destination,
        ));
      }
    } catch (e) {
      debugPrint('MapCubit.addRoute error: $e');
    }
  }

  void startNavigation() {
    if (!isClosed) emit(state.copyWith(isNavigating: true));
  }

  void clearRoute() {
    if (!isClosed) {
      emit(state.copyWith(
        isNavigating: false,
        clearRouteInfo: true,
        polylines: const {},
      ));
    }
  }

  void setMapSelectedLocation({
    required LatLng position,
    required String address,
    required bool isOrigin,
  }) {
    if (!isClosed) {
      emit(state.copyWith(
        mapSelectedLocation: position,
        mapSelectedAddress: address,
        mapSelectedIsOrigin: isOrigin,
      ));
    }
  }

  void clearMapSelectedLocation() {
    if (!isClosed) {
      emit(state.copyWith(
        clearMapSelectedLocation: true,
        clearMapSelectedAddress: true,
      ));
    }
  }

  Future<void> setMyLocation(LatLng location) async {
    if (!isClosed) {
      final address = await getAddressFromCoordinates(location);
      emit(state.copyWith(myLocation: location, myLocationAddress: address));
    }
  }
}
