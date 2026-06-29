import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:presshop_enterprise/features/map/data/models/map_models.dart';
import 'package:presshop_enterprise/features/map/data/services/heatmap_service.dart';

// ─── State ───────────────────────────────────────────────────────────────────

class EmployeeMapState {
  final List<HeatmapWorker> workers;
  final List<EmployeeAlertMarker> alertMarkers;
  final EmployeeAlertMarker? newlyCreatedAlert;
  final bool isAlertPanelOpen;
  final bool isGetDirectionOpen;
  final bool isLoading;

  const EmployeeMapState({
    this.workers = const [],
    this.alertMarkers = const [],
    this.newlyCreatedAlert,
    this.isAlertPanelOpen = false,
    this.isGetDirectionOpen = false,
    this.isLoading = false,
  });

  EmployeeMapState copyWith({
    List<HeatmapWorker>? workers,
    List<EmployeeAlertMarker>? alertMarkers,
    EmployeeAlertMarker? newlyCreatedAlert,
    bool clearNewlyCreatedAlert = false,
    bool? isAlertPanelOpen,
    bool? isGetDirectionOpen,
    bool? isLoading,
  }) {
    return EmployeeMapState(
      workers: workers ?? this.workers,
      alertMarkers: alertMarkers ?? this.alertMarkers,
      newlyCreatedAlert: clearNewlyCreatedAlert
          ? null
          : (newlyCreatedAlert ?? this.newlyCreatedAlert),
      isAlertPanelOpen: isAlertPanelOpen ?? this.isAlertPanelOpen,
      isGetDirectionOpen: isGetDirectionOpen ?? this.isGetDirectionOpen,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// ─── Cubit ───────────────────────────────────────────────────────────────────

class EmployeeMapCubit extends Cubit<EmployeeMapState> {
  final HeatmapApiService _api = HeatmapApiService();
  final HeatmapSocketService _socket = HeatmapSocketService();

  static const Map<String, String> _alertTypeLabels = {
    'contact-my-family': 'Contact my family',
    'need-help': 'Need help',
    'send-backup': 'Send backup',
    'call-police': 'Call police',
    'call-ambulance': 'Call ambulance',
    'under_threat': 'Under threat',
    'being-followed': 'Being followed',
    'get_me_out': 'Get me out',
    'im_safe': "I'm safe",
    'send-support': 'Send support',
    'no-signal': 'No signal',
    'low-battery': 'Low battery',
    'medical': 'Medical Emergency',
    'security': 'Security Threat',
    'fire': 'Fire Hazard',
  };

  EmployeeMapCubit() : super(const EmployeeMapState());

  EmployeeAlertMarker _alertFromHeatmap(HeatmapAlert a) => EmployeeAlertMarker(
        id: a.id,
        type: a.type,
        typeLabel: a.typeLabel.isNotEmpty
            ? a.typeLabel
            : (_alertTypeLabels[a.type] ?? a.type),
        position: LatLng(a.lat, a.lng),
        imageUrl: a.imageUrl,
        timestamp: DateTime.now(),
        description: a.description,
        formattedAddress: a.formattedAddress,
        creatorName: a.creatorName,
        creatorImage: a.creatorImage,
      );

  Future<void> loadInitialData(
    double lat,
    double lng, {
    double radiusMiles = 5.0,
    String? alertType,
  }) async {
    if (isClosed) return;
    emit(state.copyWith(isLoading: true));
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      if (token.isNotEmpty) {
        _socket.connect(token);
        _socket.clearListeners();
        _socket.onSnapshot(handleSnapshot);
        _socket.onWorkerUpdated(handleWorkerUpdated);
        _socket.onAlertCreated(handleNewAlert);
      }

      final workers = await _api.getWorkers(
        lat: lat,
        lng: lng,
        radiusMiles: radiusMiles,
        includeSelf: true,
        includeStale: true,
      );
      final alerts = await _api.getAlerts(
        lat: lat,
        lng: lng,
        radiusMiles: radiusMiles,
        type: alertType,
      );
      final alertMarkers = alerts.map(_alertFromHeatmap).toList();
      if (!isClosed) {
        emit(state.copyWith(
            workers: workers, alertMarkers: alertMarkers, isLoading: false));
      }
      _socket.subscribe(lat: lat, lng: lng, radiusMiles: radiusMiles);
    } catch (e) {
      debugPrint('EmployeeMapCubit.loadInitialData error: $e');
      if (!isClosed) emit(state.copyWith(isLoading: false));
    }
  }

  @override
  Future<void> close() {
    _socket.clearListeners();
    _socket.unsubscribe();
    return super.close();
  }

  void handleSnapshot(Map<String, dynamic> snapshot) {
    if (isClosed) return;
    try {
      final workers = ((snapshot['workers'] ?? []) as List)
          .map((e) => HeatmapWorker.fromJson(e))
          .toList();
      final alerts = ((snapshot['alerts'] ?? []) as List)
          .map((e) => _alertFromHeatmap(HeatmapAlert.fromJson(e)))
          .toList();
      emit(state.copyWith(workers: workers, alertMarkers: alerts));
    } catch (e) {
      debugPrint('handleSnapshot error: $e');
    }
  }

  void handleWorkerUpdated(Map<String, dynamic> data) {
    if (isClosed) return;
    try {
      final worker = HeatmapWorker.fromJson(data);
      final list = [...state.workers];
      final idx = list.indexWhere((w) => w.id == worker.id);
      if (idx >= 0) {
        list[idx] = worker;
      } else {
        list.add(worker);
      }
      emit(state.copyWith(workers: list));
    } catch (e) {
      debugPrint('handleWorkerUpdated error: $e');
    }
  }

  void handleNewAlert(Map<String, dynamic> data) {
    if (isClosed) return;
    try {
      final newAlert = _alertFromHeatmap(HeatmapAlert.fromJson(data));
      if (state.alertMarkers.any((m) => m.id == newAlert.id)) return;
      emit(state.copyWith(
        alertMarkers: [...state.alertMarkers, newAlert],
        newlyCreatedAlert: newAlert,
      ));
    } catch (e) {
      debugPrint('handleNewAlert error: $e');
    }
  }

  void toggleAlertPanel() {
    if (isClosed) return;
    final open = !state.isAlertPanelOpen;
    emit(state.copyWith(
      isAlertPanelOpen: open,
      isGetDirectionOpen: open ? false : state.isGetDirectionOpen,
    ));
  }

  void closeAlertPanel() {
    if (isClosed) return;
    if (state.isAlertPanelOpen) emit(state.copyWith(isAlertPanelOpen: false));
  }

  void toggleGetDirection() {
    if (isClosed) return;
    final open = !state.isGetDirectionOpen;
    emit(state.copyWith(
      isGetDirectionOpen: open,
      isAlertPanelOpen: open ? false : state.isAlertPanelOpen,
    ));
  }

  void closeDirectionCard() {
    if (!isClosed) emit(state.copyWith(isGetDirectionOpen: false));
  }

  Future<void> addAlertMarker(String type, LatLng position) async {
    print('[EmployeeMapCubit] addAlertMarker event triggered: type=$type, lat=${position.latitude}, lng=${position.longitude}');
    if (isClosed) return;
    try {
      Map<String, dynamic> addressData = {};
      String resolvedAddress = '';
      const description = 'I need immediate assistance here';

      try {
        final placemarks = await placemarkFromCoordinates(
            position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          resolvedAddress =
              '${p.street}, ${p.subLocality}, ${p.locality}, ${p.administrativeArea}, ${p.country}';
          addressData = {
            'line1': '${p.street}, ${p.subLocality}',
            'city': p.locality ?? p.subAdministrativeArea,
            'state': p.administrativeArea,
            'country': p.country,
            'postalCode': p.postalCode,
            'formattedAddress': resolvedAddress,
          };
        }
      } catch (e) {
        debugPrint('Geocoding error: $e');
      }

      _socket.shareAlert(
        type: type,
        severity: 'high',
        lat: position.latitude,
        lng: position.longitude,
        description: description,
        address: addressData,
        metadata: {'source': 'app', 'tile': type},
      );

      final newAlert = EmployeeAlertMarker(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        type: type,
        typeLabel: _alertTypeLabels[type] ?? type,
        position: position,
        imageUrl: '',
        timestamp: DateTime.now(),
        description: description,
        formattedAddress: resolvedAddress,
        creatorName: '',
        creatorImage: '',
      );

      if (!isClosed) {
        emit(state.copyWith(
          alertMarkers: [...state.alertMarkers, newAlert],
          newlyCreatedAlert: newAlert,
          isAlertPanelOpen: false,
        ));
      }
    } catch (e, stack) {
      debugPrint('addAlertMarker error: $e\n$stack');
      if (!isClosed) emit(state.copyWith(isAlertPanelOpen: false));
    }
  }
}
