import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:presshop_enterprise/config/routes/app_router.dart';
import 'package:presshop_enterprise/core/constants/constant_data.dart';
import 'package:presshop_enterprise/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:presshop_enterprise/features/map/presentation/screens/location_error_screen_map_news.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:presshop_enterprise/features/map/presentation/widgets/message_button.dart';
import 'package:presshop_enterprise/main.dart';
import 'package:presshop_enterprise/features/map/core/map_constants.dart';
import 'package:presshop_enterprise/common/widgets/employee_app_bar.dart';
import 'package:presshop_enterprise/common/widgets/loading_widget.dart';

import 'package:presshop_enterprise/features/map/presentation/widgets/alert_button_map.dart';
import 'package:presshop_enterprise/features/map/data/models/map_models.dart'
    hide EmployeeMapState;

import 'package:presshop_enterprise/features/map/presentation/widgets/alert_panel.dart';
import 'package:presshop_enterprise/features/map/presentation/widgets/sos_button.dart';
import 'package:presshop_enterprise/features/map/core/map_socket_constants.dart';
import 'package:presshop_enterprise/features/map/presentation/bloc/map_cubit.dart';
import 'package:presshop_enterprise/features/map/presentation/bloc/employee_map_cubit.dart';

import 'package:presshop_enterprise/features/map/presentation/widgets/custom_info_window.dart'
    as ciw;
import 'package:presshop_enterprise/features/map/presentation/widgets/get_direction_card.dart';
import 'package:presshop_enterprise/features/map/presentation/widgets/search_filter_widget.dart';
import 'package:presshop_enterprise/features/map/presentation/widgets/side_action_panel.dart';
import 'package:presshop_enterprise/features/map/presentation/widgets/burst_animation.dart';
import 'package:presshop_enterprise/features/map/data/services/marker_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';

class TeamMapScreen extends StatefulWidget {
  final bool isScreenActive;
  final bool openSosDirectly;
  final bool openShareAlertDirectly;

  const TeamMapScreen({
    super.key,
    this.isScreenActive = false,
    this.openSosDirectly = false,
    this.openShareAlertDirectly = false,
  });

  @override
  State<TeamMapScreen> createState() => _TeamMapScreenState();
}

class _TeamMapScreenState extends State<TeamMapScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  Completer<GoogleMapController> _controller = Completer();
  GoogleMapController? _googleMapController;
  bool _isDisposed = false;
  int _myLocationMarkerGeneration = 0;

  LatLng? _currentPosition;
  bool _locationDenied = false;
  Set<Marker> _markers = {};
  Marker? _myLocationMarker;
  Marker? _destinationMarker;
  Marker? _searchedPlaceMarker;
  BitmapDescriptor? _destinationIcon;
  StreamSubscription? _bgServiceSubscription;

  final ciw.CustomInfoWindowController _customInfoWindowController =
      ciw.CustomInfoWindowController();
  final Map<String, ciw.CustomInfoWindowController> _markerAlertControllers =
      {};
  final Set<String> _animatedAlertIds = {};

  late AnimationController _pulseController;
  late AnimationController _burstController;
  final List<BurstParticle> _particles = [];
  ui.Image? _burstImage;
  final Map<String, ui.Image> _burstImageCache = {};
  double _currentZoom = 12.0;

  // SOS
  // final SosSocketService _sosSocketService = SosSocketService();

  // Search
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final String _googleApiKey = googleMapAPiKey;
  List<_SearchResult> _searchResults = [];
  bool _showSearchDropdown = false;
  Timer? _searchDebounceTimer;
  String _selectedDistance = '5 miles';
  String _selectedAlertType = '';

  bool _triggerSosDirectly = false;
  bool _triggerShareAlertDirectly = false;
  bool _sosFromMenu = false;

  @override
  void initState() {
    super.initState();
    _triggerSosDirectly = widget.openSosDirectly;
    _triggerShareAlertDirectly = widget.openShareAlertDirectly;
    _sosFromMenu = widget.openSosDirectly;

    if (_triggerShareAlertDirectly) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          BlocProvider.of<EmployeeMapCubit>(context).toggleAlertPanel();
        }
      });
    }
    _pulseController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..addListener(() {
            if (mounted) setState(() {});
          })
          ..repeat();

    _burstController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..addListener(_updateParticles);

    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadBurstImages();
      _loadDestinationIcon();
    });

    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus && mounted && !_isDisposed) {
        setState(() => _showSearchDropdown = false);
      }
    });

    _bgServiceSubscription = FlutterBackgroundService().on('update').listen((
      event,
    ) {
      if (!mounted || _isDisposed) return;
      if (event != null && event['latitude'] != null) {
        final position = LatLng(
          (event['latitude'] as num).toDouble(),
          (event['longitude'] as num).toDouble(),
        );
        double finalHeading = (event['heading'] is num)
            ? (event['heading'] as num).toDouble()
            : 0.0;
        final navState = context.read<MapCubit>().state;
        if (finalHeading == 0.0 || finalHeading == 360.0) {
          LatLng? targetPoint;
          if (navState.routeInfo != null &&
              navState.routeInfo!.points.isNotEmpty) {
            for (var p in navState.routeInfo!.points) {
              if (p.latitude != position.latitude ||
                  p.longitude != position.longitude) {
                targetPoint = p;
                break;
              }
            }
          }
          targetPoint ??= navState.destination;
          if (targetPoint != null) {
            finalHeading = _calculateBearing(position, targetPoint);
          }
        }
        // BlocProvider.of<EmployeeMapCubit>(context).updateNavigationPosition(position, heading: finalHeading);
        if (navState.isNavigating && widget.isScreenActive) {
          _controller.future.then((ctrl) {
            if (!mounted || _isDisposed) return;
            ctrl.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(
                  target: position,
                  zoom: 19,
                  tilt: 60,
                  bearing: finalHeading,
                ),
              ),
            );
          });
        }
      }
    });

    _setupSosSocketListeners();
    // Only request location once the Team tab is actually shown — otherwise the
    // map (built in the dashboard's IndexedStack) prompts for location while the
    // user is still on Home.
    if (widget.isScreenActive) _initLocation();
  }

  void _setupSosSocketListeners() {
    final dynamic socket = null; // Mocked EmployeeSocketClient.heatmapSocket
    if (socket == null) return;

    socket.on(MapSocketConstants.eventSosSessionStarted, (data) {
      if (!mounted || _isDisposed) return;
      final payload = data is Map
          ? Map<String, dynamic>.from(data)
          : <String, dynamic>{};
      final workerName = payload['workerName']?.toString() ?? 'A team member';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🚨 SOS alert from $workerName'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    });

    socket.on(MapSocketConstants.eventSosSessionResolved, (data) {
      if (!mounted || _isDisposed) return;
      // final payload =
      //     data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
      // final workerName = payload['workerName']?.toString() ?? 'A team member';
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      //   content: Text('✅ $workerName is safe — SOS resolved'),
      //   backgroundColor: Colors.green,
      //   duration: const Duration(seconds: 4),
      // ));
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _locationDenied) {
      _initLocation();
    }
  }

  @override
  void didUpdateWidget(covariant TeamMapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Initialize location the first time the Team tab becomes active.
    if (!oldWidget.isScreenActive &&
        widget.isScreenActive &&
        _currentPosition == null) {
      _initLocation();
    }

    if (widget.isScreenActive && !oldWidget.isScreenActive) {
      _pulseController.repeat();
      _loadEmployeeMapData();
      _filterAndRenderMapData();
      _updateMyLocationMarker();
    } else if (!widget.isScreenActive && oldWidget.isScreenActive) {
      _pulseController.stop();
    }

    if (widget.openSosDirectly && !oldWidget.openSosDirectly) {
      setState(() {
        _triggerSosDirectly = true;
        _sosFromMenu = true;
      });
    }
    if (widget.openShareAlertDirectly && !oldWidget.openShareAlertDirectly) {
      setState(() => _triggerShareAlertDirectly = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          BlocProvider.of<EmployeeMapCubit>(context).toggleAlertPanel();
        }
      });
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _burstController.dispose();
    _pulseController.dispose();
    _customInfoWindowController.dispose();
    for (var ctrl in _markerAlertControllers.values) {
      ctrl.googleMapController = null;
      try {
        ctrl.dispose();
      } catch (_) {}
    }
    _markerAlertControllers.clear();
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _bgServiceSubscription?.cancel();
    // _sosSocketService.clearListeners();
    super.dispose();
  }

  Future<void> _loadDestinationIcon() async {
    try {
      final icon = await MarkerService().bitmapFromIncidentAsset(
        'assets/markers/destination-marker.webp',
        70,
      );
      if (mounted && !_isDisposed) setState(() => _destinationIcon = icon);
    } catch (_) {}
  }

  Future<void> _initLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // if (mounted) {
      //   final accepted = await LocationPermissionHelper.showDisclosureDialog(context);
      //   if (accepted) {
      permission = await Geolocator.requestPermission();
      //   }
      // }
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (mounted) setState(() => _locationDenied = true);
      return;
    }

    if (mounted) setState(() => _locationDenied = false);

    final mapState = context.read<MapCubit>().state;
    if (mapState.myLocation != null) {
      if (mounted) {
        setState(() {
          _currentPosition = mapState.myLocation;
        });
        _loadEmployeeMapData();
      }
      return;
    }

    try {
      await context.read<MapCubit>().initLocationAndData();
      final newState = context.read<MapCubit>().state;

      if (mounted) {
        setState(() {
          _currentPosition =
              newState.myLocation ?? const LatLng(51.5074, -0.1278);
        });
        _loadEmployeeMapData();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentPosition = const LatLng(51.5074, -0.1278);
        });
        _updateMyLocationMarker();
      }
    }
  }

  void _loadEmployeeMapData() {
    if (_currentPosition == null) return;
    final clean = _selectedDistance.replaceAll(RegExp(r'[^0-9.]'), '');
    final radius = double.tryParse(clean) ?? 5.0;
    BlocProvider.of<EmployeeMapCubit>(context).loadInitialData(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      radiusMiles: radius,
      alertType: _selectedAlertType,
    );
  }

  double _getZoomForDistance(String distance) {
    if (distance.contains('1 mile')) return 14.0;
    if (distance.contains('2 miles')) return 13.0;
    if (distance.contains('5 miles')) return 12.0;
    if (distance.contains('10 miles')) return 11.0;
    if (distance.contains('15 miles')) return 10.5;
    if (distance.contains('20 miles')) return 10.0;
    if (distance.contains('30 miles')) return 9.0;
    if (distance.contains('50 miles')) return 8.0;
    return 12.0;
  }

  double _calculateBearing(LatLng start, LatLng end) {
    double startLat = start.latitude * pi / 180;
    double startLng = start.longitude * pi / 180;
    double endLat = end.latitude * pi / 180;
    double endLng = end.longitude * pi / 180;

    double dLng = endLng - startLng;

    double y = sin(dLng) * cos(endLat);
    double x =
        cos(startLat) * sin(endLat) - sin(startLat) * cos(endLat) * cos(dLng);

    double bearing = atan2(y, x) * 180 / pi;
    return (bearing + 360) % 360;
  }

  double _getMetersForDistance(String distanceStr) {
    if (distanceStr.contains('1 mile') || distanceStr.contains('1 miles'))
      return 1609.34;
    if (distanceStr.contains('2 miles')) return 3218.68;
    if (distanceStr.contains('5 miles')) return 8046.72;
    if (distanceStr.contains('10 miles')) return 16093.4;
    if (distanceStr.contains('15 miles')) return 24140.1;
    if (distanceStr.contains('20 miles')) return 32186.8;
    if (distanceStr.contains('25 miles')) return 40233.5;
    if (distanceStr.contains('30 miles')) return 48280.2;
    if (distanceStr.contains('50 miles')) return 80467.0;
    return 8046.72; // Default to 5 miles
  }

  bool _alertTypeMatches(String alertType, String selectedType) {
    if (selectedType.isEmpty) return true;
    final normalizedAlert = alertType
        .replaceAll('_', '-')
        .replaceAll(' ', '-')
        .toLowerCase();
    final normalizedSelected = selectedType
        .replaceAll('_', '-')
        .replaceAll(' ', '-')
        .toLowerCase();
    if (normalizedSelected == normalizedAlert) return true;

    // Check aliases/known variations
    // 1. call-police / police-call
    if ((normalizedSelected == 'call-police' ||
            normalizedSelected == 'police-call' ||
            normalizedSelected == 'police') &&
        (normalizedAlert == 'call-police' ||
            normalizedAlert == 'police-call' ||
            normalizedAlert == 'police')) {
      return true;
    }
    // 2. call-ambulance / ambulance-call / ambulance / medicine
    if ((normalizedSelected == 'call-ambulance' ||
            normalizedSelected == 'ambulance-call' ||
            normalizedSelected == 'ambulance' ||
            normalizedSelected == 'medicine') &&
        (normalizedAlert == 'call-ambulance' ||
            normalizedAlert == 'ambulance-call' ||
            normalizedAlert == 'ambulance' ||
            normalizedAlert == 'medicine')) {
      return true;
    }
    // 3. contact-my-family / contact-family
    if ((normalizedSelected == 'contact-my-family' ||
            normalizedSelected == 'contact-family') &&
        (normalizedAlert == 'contact-my-family' ||
            normalizedAlert == 'contact-family')) {
      return true;
    }
    // 4. under-threat / vandalism / threat
    if ((normalizedSelected == 'under-threat' ||
            normalizedSelected == 'vandalism' ||
            normalizedSelected == 'threat') &&
        (normalizedAlert == 'under-threat' ||
            normalizedAlert == 'vandalism' ||
            normalizedAlert == 'threat')) {
      return true;
    }
    // 5. im-safe / i-am-safe / safe
    if ((normalizedSelected == 'im-safe' ||
            normalizedSelected == 'i-am-safe' ||
            normalizedSelected == 'safe') &&
        (normalizedAlert == 'im-safe' ||
            normalizedAlert == 'i-am-safe' ||
            normalizedAlert == 'safe')) {
      return true;
    }
    return false;
  }

  void _filterAndRenderMapData() {
    if (!mounted || _isDisposed) return;
    final mapState = BlocProvider.of<EmployeeMapCubit>(context).state;

    // 1. Render all workers returned by the API
    _generateMarkersFromWorkers(mapState.workers);

    // 2. Render all alerts returned by the API
    _syncAnimatedAlertMarkers(mapState.alertMarkers);
  }

  Future<void> _updateMyLocationMarker() async {
    if (!mounted || _isDisposed) return;
    if (!widget.isScreenActive) return;
    if (_currentPosition == null) return;

    final generation = ++_myLocationMarkerGeneration;

    String userImage = sharedPreferences?.getString('user_avatar') ?? '';
    if (userImage.isEmpty) {
      userImage = sharedPreferences?.getString('user_profile_image') ?? '';
    }

    final icon = await _getMarkerIcon(userImage, showDot: false);
    if (!mounted || _isDisposed || _myLocationMarkerGeneration != generation)
      return;
    setState(() {
      _myLocationMarker = Marker(
        markerId: const MarkerId('my_location'),
        position: _currentPosition!,
        icon: icon,
        anchor: const Offset(0.5, 0.5),
        zIndex: 2,
        onTap: () async {
          _customInfoWindowController.hideInfoWindow?.call();
          final controller = await _controller.future;
          controller.animateCamera(CameraUpdate.newLatLng(_currentPosition!));
        },
      );
    });
  }

  Future<void> _generateMarkersFromWorkers(List<HeatmapWorker> workers) async {
    if (!mounted || _isDisposed) return;
    if (!widget.isScreenActive) return;
    Set<Marker> newMarkers = {};
    final myUserId = sharedPreferences?.getString('user_id') ?? '';

    for (final worker in workers) {
      // Skip yourself since _myLocationMarker already represents you at your current position
      if (worker.isSelf || (myUserId.isNotEmpty && worker.id == myUserId)) {
        continue;
      }

      final imageUrl = worker.profileImage.isNotEmpty
          ? worker.profileImage
          : "https://i.pravatar.cc/150?u=${worker.id}";
      final position = LatLng(worker.lat, worker.lng);
      final icon = await _getMarkerIcon(imageUrl, isOnline: worker.isOnline);

      if (_isDisposed) return;

      newMarkers.add(
        Marker(
          markerId: MarkerId('worker_${worker.id}'),
          position: position,
          icon: icon,
          anchor: const Offset(0.5, 0.5),
          zIndex: 1,
          onTap: () async {
            if (!mounted || _isDisposed) return;

            final empState = BlocProvider.of<EmployeeMapCubit>(context).state;
            if (empState.isGetDirectionOpen) {
              // Fill destination from worker location
              final mapCtrl = context.read<MapCubit>();
              final address = worker.formattedAddress.isNotEmpty
                  ? worker.formattedAddress
                  : await mapCtrl.getAddressFromCoordinates(position);
              if (!mounted || _isDisposed) return;
              mapCtrl.setMapSelectedLocation(
                position: position,
                address: address,
                isOrigin: false,
              );
              setState(() {
                _destinationMarker = Marker(
                  markerId: const MarkerId('destination'),
                  position: position,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueRed,
                  ),
                );
              });
              return;
            }

            if (!mounted || _isDisposed) return;
            _customInfoWindowController.addInfoWindow?.call(
              _buildInfoWindow(
                id: worker.id,
                name: worker.name,
                location: worker.formattedAddress.isNotEmpty
                    ? worker.formattedAddress
                    : 'Unknown location',
                imageUrl: imageUrl,
                designation: worker.role,
                distance: worker.distanceLabel.isNotEmpty
                    ? worker.distanceLabel
                    : 'Nearby',
                phone: worker.phone,
              ),
              position,
              1.0,
              142.0,
              240.0,
            );
            if (!mounted || _isDisposed) return;
            final ctrl = await _controller.future;
            ctrl.animateCamera(CameraUpdate.newLatLng(position));
          },
        ),
      );
    }

    if (mounted && !_isDisposed) {
      setState(() {
        _markers = newMarkers;
      });
    }
  }

  // ─── Animated alert floating icons (hopper-style) ───────────────────────────

  void _syncAnimatedAlertMarkers(List<EmployeeAlertMarker> alerts) {
    if (_isDisposed || !mounted) return;

    final currentIds = alerts.map((a) => a.id).toSet();

    _markerAlertControllers.removeWhere((id, controller) {
      if (!currentIds.contains(id)) {
        controller.onCameraMove = null;
        controller.addInfoWindow = null;
        controller.hideInfoWindow = null;
        controller.googleMapController = null;
        try {
          controller.dispose();
        } catch (_) {}
        _animatedAlertIds.remove(id);
        return true;
      }
      return false;
    });

    for (final alert in alerts) {
      if (!_markerAlertControllers.containsKey(alert.id)) {
        final controller = ciw.CustomInfoWindowController();
        if (_googleMapController != null) {
          controller.googleMapController = _googleMapController;
        }
        _markerAlertControllers[alert.id] = controller;
      }

      if (!_animatedAlertIds.contains(alert.id)) {
        _tryAddAlertInfoWindow(alert, 0);
      }
    }

    if (mounted) setState(() {});
  }

  void _tryAddAlertInfoWindow(EmployeeAlertMarker alert, int retryCount) {
    if (!mounted || _isDisposed || _animatedAlertIds.contains(alert.id)) return;

    final controller = _markerAlertControllers[alert.id];
    if (controller == null) return;

    if (controller.addInfoWindow != null) {
      _doAddAlertInfoWindow(alert, controller);
      return;
    }

    if (retryCount < 10) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _tryAddAlertInfoWindow(alert, retryCount + 1);
      });
    }
  }

  void _doAddAlertInfoWindow(
    EmployeeAlertMarker alert,
    ciw.CustomInfoWindowController controller,
  ) {
    if (controller.addInfoWindow == null ||
        _animatedAlertIds.contains(alert.id))
      return;

    final alertData = AppConstantData.alertTypesForEmployee.firstWhere(
      (e) => _alertTypeMatches(alert.type, e['type'] ?? ''),
      orElse: () => AppConstantData.alertTypesForEmployee.first,
    );

    try {
      controller.addInfoWindow?.call(
        GestureDetector(
          onTap: () {
            _controller.future.then((ctrl) {
              ctrl.animateCamera(CameraUpdate.newLatLng(alert.position));
            });
            _customInfoWindowController.addInfoWindow?.call(
              _buildAlertInfoWindow(alert: alert, alertData: alertData),
              alert.position,
              0, // offset — close to marker
              185, // height
              240, // width
            );
          },
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: const Color(0xFFD9D9D9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.all(2),
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                alertData['icon']!,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.warning, color: Colors.red, size: 16),
              ),
            ),
          ),
        ),
        alert.position,
      );

      _animatedAlertIds.add(alert.id);
      controller.onCameraMove?.call();
    } catch (e) {
      debugPrint("Error adding alert info window for ${alert.id}: $e");
    }
  }

  Widget _buildAlertInfoWindow({
    required EmployeeAlertMarker alert,
    required Map<String, String> alertData,
  }) {
    final hasCreatorImage = alert.creatorImage.isNotEmpty;
    final label = alert.typeLabel.isNotEmpty ? alert.typeLabel : alert.type;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          alignment: Alignment.bottomCenter,
          child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 240,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.13),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: icon + alert type label
                Container(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.07),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(14),
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: Image.asset(
                          alertData['icon']!,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.warning,
                            color: Colors.red,
                            size: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          label,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Colors.red,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                // Creator + description
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 15,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: hasCreatorImage
                            ? NetworkImage(alert.creatorImage)
                            : null,
                        child: !hasCreatorImage
                            ? const Icon(
                                Icons.person,
                                size: 15,
                                color: Colors.grey,
                              )
                            : null,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (alert.creatorName.isNotEmpty)
                              Text(
                                alert.creatorName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            if (alert.description.isNotEmpty)
                              Text(
                                alert.description,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[500],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Address
                if (alert.formattedAddress.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 2, 10, 9),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          LucideIcons.map_pin,
                          size: 10,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            alert.formattedAddress,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          CustomPaint(
            size: const Size(16, 8),
            painter: _TrianglePainter(color: Colors.white),
          ),
        ],
      ),
    );
  }

  // ─── Burst animation ────────────────────────────────────────────────────────

  Future<void> _preloadBurstImages() async {
    for (final entry in burstIcons.entries) {
      if (_isDisposed) return;
      final img = await _loadImage(entry.value);
      if (img != null && !_isDisposed && mounted) {
        _burstImageCache[entry.key] = img;
      }
    }
  }

  Future<ui.Image?> _loadImage(String assetPath) async {
    try {
      final data = await rootBundle.load(assetPath);
      final list = Uint8List.view(data.buffer);
      final completer = Completer<ui.Image>();
      ui.decodeImageFromList(list, (img) {
        completer.complete(img);
      });
      return completer.future;
    } catch (e) {
      debugPrint("Error loading burst image: $e");
      return null;
    }
  }

  void _updateParticles() {
    if (_isDisposed || !mounted) return;
    final t = _burstController.value;
    final size = MediaQuery.of(context).size;

    for (var p in _particles) {
      p.scale = 0.6 + t * 0.5;
      p.opacity = (1 - t).clamp(0.0, 1.0);
      p.position = p.position.translate(
        (p.position.dx - size.width / 2) * 0.02 * t,
        -size.height * 0.01 * p.speed,
      );
    }

    if (t == 1) _particles.clear();
  }

  String _getBurstIconAssetPath(String type) {
    final normType = type
        .replaceAll('_', '-')
        .replaceAll(' ', '-')
        .toLowerCase();
    if (burstIcons.containsKey(type)) {
      return burstIcons[type]!;
    }
    for (final entry in burstIcons.entries) {
      final keyNorm = entry.key
          .replaceAll('_', '-')
          .replaceAll(' ', '-')
          .toLowerCase();
      if (keyNorm == normType) {
        return entry.value;
      }
    }
    if (normType == 'call-police' ||
        normType == 'police-call' ||
        normType == 'police') {
      return burstIcons['police_call'] ?? burstIcons['no_signal']!;
    }
    if (normType == 'call-ambulance' ||
        normType == 'ambulance-call' ||
        normType == 'ambulance' ||
        normType == 'medicine') {
      return burstIcons['ambulance_call'] ?? burstIcons['no_signal']!;
    }
    if (normType == 'contact-my-family' || normType == 'contact-family') {
      return burstIcons['contact_family'] ?? burstIcons['no_signal']!;
    }
    if (normType == 'under-threat' ||
        normType == 'vandalism' ||
        normType == 'threat') {
      return burstIcons['under_threat'] ?? burstIcons['no_signal']!;
    }
    if (normType == 'im-safe' ||
        normType == 'i-am-safe' ||
        normType == 'safe') {
      return burstIcons['im_safe'] ?? burstIcons['no_signal']!;
    }
    if (normType == 'send-support') {
      return burstIcons['send_support'] ?? burstIcons['no_signal']!;
    }
    if (normType == 'no-signal') {
      return burstIcons['no_signal'] ?? burstIcons['no_signal']!;
    }
    if (normType == 'low-battery') {
      return burstIcons['low_battery'] ?? burstIcons['no_signal']!;
    }
    return burstIcons['no_signal']!;
  }

  Future<void> _addBurst(LatLng position, String type) async {
    if (_isDisposed || !mounted) return;
    final size = MediaQuery.of(context).size;

    _particles.clear();
    final normType = type
        .replaceAll('_', '-')
        .replaceAll(' ', '-')
        .toLowerCase();
    ui.Image? foundImg;
    if (_burstImageCache.containsKey(type)) {
      foundImg = _burstImageCache[type];
    } else {
      for (final entry in _burstImageCache.entries) {
        final keyNorm = entry.key
            .replaceAll('_', '-')
            .replaceAll(' ', '-')
            .toLowerCase();
        if (keyNorm == normType) {
          foundImg = entry.value;
          break;
        }
      }
    }
    if (foundImg == null) {
      if (normType == 'call-police' ||
          normType == 'police-call' ||
          normType == 'police') {
        foundImg = _burstImageCache['police_call'];
      } else if (normType == 'call-ambulance' ||
          normType == 'ambulance-call' ||
          normType == 'ambulance' ||
          normType == 'medicine') {
        foundImg = _burstImageCache['ambulance_call'];
      } else if (normType == 'contact-my-family' ||
          normType == 'contact-family') {
        foundImg = _burstImageCache['contact_family'];
      } else if (normType == 'under-threat' ||
          normType == 'vandalism' ||
          normType == 'threat') {
        foundImg = _burstImageCache['under_threat'];
      } else if (normType == 'im-safe' ||
          normType == 'i-am-safe' ||
          normType == 'safe') {
        foundImg = _burstImageCache['im_safe'];
      }
    }

    if (foundImg != null) {
      _burstImage = foundImg;
    } else {
      final assetPath = _getBurstIconAssetPath(type);
      _burstImage = await _loadImage(assetPath);
    }

    if (!mounted || _isDisposed) return;

    for (int i = 0; i < 40; i++) {
      double randomX = Random().nextDouble() * size.width;
      double randomY = size.height + Random().nextDouble() * 300;

      _particles.add(
        BurstParticle(
          position: Offset(randomX, randomY),
          scale: 0.4 + Random().nextDouble() * 0.8,
          opacity: 1.0,
          speed: 1.0 + Random().nextDouble() * 1.5,
        ),
      );
    }

    _burstController.forward(from: 0);
  }

  ImageProvider _getImageProvider(String imageUrl) {
    if (imageUrl.isEmpty) {
      return const NetworkImage("https://i.pravatar.cc/150?u=empty");
    }
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return NetworkImage(imageUrl);
    }
    if (imageUrl.startsWith('file://')) {
      try {
        final uri = Uri.parse(imageUrl);
        return FileImage(File(uri.toFilePath()));
      } catch (_) {
        return FileImage(File(imageUrl.replaceAll('file://', '')));
      }
    }
    if (imageUrl.startsWith('/') || imageUrl.startsWith('content://')) {
      return FileImage(File(imageUrl));
    }
    return NetworkImage(imageUrl);
  }

  // ─── Marker icon builder ─────────────────────────────────────────────────────

  Future<BitmapDescriptor> _getMarkerIcon(
    String imageUrl, {
    bool isOnline = false,
    bool showDot = true,
  }) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double size = 120.0;
    const double radius = size / 2;

    final Paint pinPaint = Paint()
      ..color = colorThemePink
      ..style = PaintingStyle.fill;

    final Path pinPath = Path();
    pinPath.addOval(Rect.fromLTWH(0, 0, size, size));
    canvas.drawPath(pinPath, pinPaint);

    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;
    canvas.drawCircle(const Offset(radius, radius), radius, borderPaint);

    if (imageUrl.isEmpty) {
      TextPainter(
          text: const TextSpan(text: '👤', style: TextStyle(fontSize: 60)),
          textDirection: ui.TextDirection.ltr,
        )
        ..layout()
        ..paint(canvas, const Offset(radius - 30, radius - 40));
    } else {
      try {
        final Completer<ui.Image> completer = Completer();
        final ImageStream stream = _getImageProvider(
          imageUrl,
        ).resolve(ImageConfiguration.empty);
        stream.addListener(
          ImageStreamListener(
            (ImageInfo info, bool _) {
              if (!completer.isCompleted) completer.complete(info.image);
            },
            onError: (exception, stackTrace) {
              if (!completer.isCompleted) completer.completeError(exception);
            },
          ),
        );

        final ui.Image image = await completer.future.timeout(
          const Duration(seconds: 3),
        );

        canvas.save();
        final Path clipPath = Path()
          ..addOval(
            Rect.fromCircle(
              center: const Offset(radius, radius),
              radius: radius - 4,
            ),
          );
        canvas.clipPath(clipPath);

        final double imgWidth = image.width.toDouble();
        final double imgHeight = image.height.toDouble();
        final double scale = size / min(imgWidth, imgHeight);
        final double dw = imgWidth * scale;
        final double dh = imgHeight * scale;
        final double dx = (size - dw) / 2;
        final double dy = (size - dh) / 2;

        canvas.drawImageRect(
          image,
          Rect.fromLTWH(0, 0, imgWidth, imgHeight),
          Rect.fromLTWH(dx, dy, dw, dh),
          Paint(),
        );
        canvas.restore();
      } catch (e) {
        TextPainter(
            text: const TextSpan(text: '👤', style: TextStyle(fontSize: 60)),
            textDirection: ui.TextDirection.ltr,
          )
          ..layout()
          ..paint(canvas, const Offset(radius - 30, radius - 40));
      }
    }

    if (showDot) {
      const double dotRadius = 12.0;
      const Offset dotCenter = Offset(size - 18, size - 18);
      canvas.drawCircle(
        dotCenter,
        dotRadius,
        Paint()
          ..color = isOnline
              ? const Color(0xFF22C55E)
              : const Color(0xFF9E9E9E),
      );
      canvas.drawCircle(
        dotCenter,
        dotRadius,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0,
      );
    }

    final ui.Image markerImage = await pictureRecorder.endRecording().toImage(
      size.toInt(),
      size.toInt(),
    );
    final ByteData? byteData = await markerImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  // ─── Info window builder ─────────────────────────────────────────────────────

  Widget _buildInfoWindow({
    required String id,
    required String name,
    required String designation,
    required String location,
    required String imageUrl,
    required String distance,
    required String phone,
  }) {
    var size = MediaQuery.of(context).size;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 260,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundImage: _getImageProvider(imageUrl),
                      backgroundColor: Colors.grey[100],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle().copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          // Text(
                          //   designation,
                          //   maxLines: 1,
                          //   overflow: TextOverflow.ellipsis,
                          //   style:
                          //       AppTextStyles.subHeading(size: size).copyWith(
                          //     color: colorThemePink,
                          //     fontSize: 11,
                          //     fontWeight: FontWeight.w600,
                          //   ),
                          // ),
                          const SizedBox(height: 2),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 1.0),
                                child: Icon(
                                  LucideIcons.map_pin,
                                  size: 10,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  location,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                LucideIcons.navigation,
                                size: 10,
                                color: colorThemePink,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                distance,
                                style: const TextStyle(
                                  color: colorThemePink,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildActionBtn(
                        icon: LucideIcons.message_circle,
                        label: "Chat",
                        color: colorThemePink,
                        onTap: () {
                          context.push(AppRoutes.teamChatList);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildActionBtn(
                        icon: LucideIcons.phone,
                        label: "Call",
                        color: const Color(0xFF3178D1),
                        onTap: () {
                          debugPrint(
                            "CALL BUTTON CLICKED - First Phone Number: $phone",
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        CustomPaint(
          size: const Size(20, 10),
          painter: _TrianglePainter(color: Colors.grey[50]!),
        ),
      ],
    );
  }

  Widget _buildActionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Camera controls ─────────────────────────────────────────────────────────

  void _onZoomIn() async {
    final controller = await _controller.future;
    controller.animateCamera(CameraUpdate.zoomIn());
  }

  void _onZoomOut() async {
    final controller = await _controller.future;
    controller.animateCamera(CameraUpdate.zoomOut());
  }

  void _onCurrentLocation() async {
    if (_currentPosition != null) {
      final controller = await _controller.future;
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition!, 15),
      );
    }
  }

  Future<void> _fitBoundsToRoute(List<LatLng> points) async {
    if (points.isEmpty || _isDisposed) return;
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
    final ctrl = await _controller.future;
    if (!mounted || _isDisposed) return;
    ctrl.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
  }

  // ─── Navigation overlay ──────────────────────────────────────────────────────

  Widget _buildNavigationBar(Size size) {
    final mapNavState = context.watch<MapCubit>().state;
    if (!mapNavState.isNavigating || mapNavState.routeInfo == null) {
      return const SizedBox.shrink();
    }
    final info = mapNavState.routeInfo!;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.navigation,
                  color: Colors.blue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Navigating',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.compare_arrows,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          info.formattedDistance,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          info.formattedDuration,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  context.read<MapCubit>().clearRoute();
                  if (mounted && !_isDisposed) {
                    setState(() => _destinationMarker = null);
                  }
                },
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Stop'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Search ──────────────────────────────────────────────────────────────────

  void _searchAll(String input) {
    _searchDebounceTimer?.cancel();
    if (input.trim().isEmpty) {
      if (mounted && !_isDisposed) {
        setState(() {
          _searchResults = [];
          _showSearchDropdown = false;
        });
      }
      return;
    }

    final query = input.toLowerCase().trim();
    final mapState = BlocProvider.of<EmployeeMapCubit>(context).state;
    final localResults = <_SearchResult>[];

    for (final worker in mapState.workers) {
      if (worker.name.toLowerCase().contains(query) ||
          worker.role.toLowerCase().contains(query)) {
        localResults.add(
          _SearchResult(
            type: _SearchResultType.worker,
            title: worker.name,
            subtitle: worker.role.isNotEmpty ? worker.role : 'Team member',
            worker: worker,
          ),
        );
      }
    }

    for (final alert in mapState.alertMarkers) {
      if (alert.typeLabel.toLowerCase().contains(query) ||
          alert.description.toLowerCase().contains(query) ||
          alert.formattedAddress.toLowerCase().contains(query)) {
        localResults.add(
          _SearchResult(
            type: _SearchResultType.alert,
            title: alert.typeLabel,
            subtitle: alert.formattedAddress.isNotEmpty
                ? alert.formattedAddress
                : alert.description,
            alert: alert,
          ),
        );
      }
    }

    if (mounted && !_isDisposed) {
      setState(() {
        _searchResults = localResults;
        _showSearchDropdown = localResults.isNotEmpty;
      });
    }

    _searchDebounceTimer = Timer(const Duration(milliseconds: 400), () {
      _doSearchPlaces(query, localResults);
    });
  }

  Future<void> _doSearchPlaces(
    String input,
    List<_SearchResult> existing,
  ) async {
    if (!mounted || _isDisposed) return;
    final url =
        "https://maps.googleapis.com/maps/api/place/autocomplete/json"
        "?input=$input"
        "&key=$_googleApiKey"
        "&types=geocode";

    try {
      final response = await http.get(Uri.parse(url));
      if (!mounted || _isDisposed) return;
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final preds = data['predictions'] as List<dynamic>? ?? [];
        final placeResults = preds
            .take(3)
            .map(
              (p) => _SearchResult(
                type: _SearchResultType.place,
                title: p['description'] as String,
                subtitle: 'Location',
                placeId: p['place_id'] as String,
              ),
            );
        if (mounted && !_isDisposed) {
          setState(() {
            _searchResults = [...existing, ...placeResults];
            _showSearchDropdown = _searchResults.isNotEmpty;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _selectPlace(String placeId, String description) async {
    final url =
        "https://maps.googleapis.com/maps/api/place/details/json"
        "?place_id=$placeId"
        "&key=$_googleApiKey";
    try {
      final response = await http.get(Uri.parse(url));
      if (!mounted || _isDisposed) return;
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final loc = data['result']['geometry']['location'];
        final latLng = LatLng(
          (loc['lat'] as num).toDouble(),
          (loc['lng'] as num).toDouble(),
        );
        final ctrl = await _controller.future;
        ctrl.animateCamera(CameraUpdate.newLatLngZoom(latLng, 13.0));
        if (mounted && !_isDisposed) {
          setState(() {
            _showSearchDropdown = false;
            _searchResults = [];
            _searchController.text = description;
            _searchedPlaceMarker = Marker(
              markerId: MarkerId(placeId),
              position: latLng,
              infoWindow: InfoWindow(title: description),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed,
              ),
            );
          });
        }
        _searchFocusNode.unfocus();
      }
    } catch (_) {}
  }

  Future<void> _navigateToWorker(HeatmapWorker worker) async {
    final position = LatLng(worker.lat, worker.lng);
    final ctrl = await _controller.future;
    ctrl.animateCamera(CameraUpdate.newLatLngZoom(position, 16.0));
    final imageUrl = worker.profileImage.isNotEmpty
        ? worker.profileImage
        : "https://i.pravatar.cc/150?u=${worker.id}";
    _customInfoWindowController.addInfoWindow?.call(
      _buildInfoWindow(
        id: worker.id,
        name: worker.name,
        designation: worker.role,
        location: worker.formattedAddress.isNotEmpty
            ? worker.formattedAddress
            : 'Unknown location',
        imageUrl: imageUrl,
        distance: worker.distanceLabel.isNotEmpty
            ? worker.distanceLabel
            : 'Nearby',
        phone: worker.phone,
      ),
      position,
      1.0,
      142.0,
      240.0,
    );
    if (mounted && !_isDisposed) {
      setState(() {
        _showSearchDropdown = false;
        _searchResults = [];
        _searchController.text = worker.name;
        _searchedPlaceMarker = null;
      });
    }
    _searchFocusNode.unfocus();
  }

  Future<void> _navigateToAlert(EmployeeAlertMarker alert) async {
    final ctrl = await _controller.future;
    ctrl.animateCamera(CameraUpdate.newLatLngZoom(alert.position, 16.0));
    if (mounted && !_isDisposed) {
      setState(() {
        _showSearchDropdown = false;
        _searchResults = [];
        _searchController.text = alert.typeLabel;
        _searchedPlaceMarker = null;
      });
    }
    _searchFocusNode.unfocus();
  }

  Widget _buildSearchResultItem(_SearchResult result) {
    IconData icon;
    Color color;
    switch (result.type) {
      case _SearchResultType.worker:
        icon = Icons.person_rounded;
        color = colorEmployeeGreen1;
        break;
      case _SearchResultType.alert:
        icon = LucideIcons.triangle_alert;
        color = Colors.orange;
        break;
      case _SearchResultType.place:
        icon = Icons.location_on_outlined;
        color = Colors.grey.shade600;
        break;
    }

    return InkWell(
      onTap: () {
        switch (result.type) {
          case _SearchResultType.worker:
            _navigateToWorker(result.worker!);
            break;
          case _SearchResultType.alert:
            _navigateToAlert(result.alert!);
            break;
          case _SearchResultType.place:
            _selectPlace(result.placeId!, result.title);
            break;
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    result.title,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    result.subtitle,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double responsiveWidth = size.width > 600 ? 650 : size.width;
    final appBarHeight = (sharedPreferences?.getBool('isIpad') ?? false)
        ? 80.0
        : kToolbarHeight;
    final searchBarTop = MediaQuery.of(context).padding.top + appBarHeight + 10;
    final double bottomBarHeight =
        responsiveWidth * 0.122 + (responsiveWidth * numD01 * 2).toDouble() + 8;
    final bool isNavigating = context.watch<MapCubit>().state.isNavigating;
    final double bottomOffset =
        kBottomNavigationBarHeight + MediaQuery.of(context).viewPadding.bottom;
    final double zoomPanelBottom = isNavigating
        ? 110.0 + bottomOffset
        : bottomOffset + 20;
    final mapState = context.watch<EmployeeMapCubit>().state;
    final employeeMapNotifier = BlocProvider.of<EmployeeMapCubit>(context);
    return BlocListener<EmployeeMapCubit, EmployeeMapState>(
      listenWhen: (previous, current) {
        return previous.workers != current.workers ||
            previous.alertMarkers != current.alertMarkers ||
            previous.newlyCreatedAlert != current.newlyCreatedAlert;
      },
      listener: (context, state) {
        if (!mounted || _isDisposed) return;
        if (!widget.isScreenActive) return;
        _filterAndRenderMapData();
        _updateMyLocationMarker();
        if (state.newlyCreatedAlert != null) {
          _addBurst(
            state.newlyCreatedAlert!.position,
            state.newlyCreatedAlert!.type,
          );
        }
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: EmployeeAppBar(
          onBackTap: _triggerShareAlertDirectly
              ? () {
                  final dashboardState = context
                      .findAncestorStateOfType<DashboardScreenState>();
                  if (dashboardState != null) {
                    setState(() {
                      _triggerShareAlertDirectly = false;
                    });
                    dashboardState.changeTab(4);
                  }
                }
              : null,
          onProfileTap: () {
            context.push('/menu');
          },
          onFilterTap: null,
          isOnline: true,
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.translucent,
          child: _locationDenied
              ? LocationErrorScreenMapNews(
                  onTapSettings: () {
                    setState(() => _locationDenied = false);
                    _initLocation();
                  },
                )
              : _currentPosition == null
              ? const LoadingWidget()
              : AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final double pulseVal = _pulseController.value;
                    final double opacity = 1.0 - pulseVal;
                    final double baseRadius = 150.0;
                    final double scaleFactor = pow(
                      2,
                      15 - _currentZoom.roundToDouble(),
                    ).toDouble();
                    final double radius = baseRadius * scaleFactor * pulseVal;

                    Set<Circle> pulseCircles = {};

                    if (_currentPosition != null) {
                      pulseCircles.add(
                        Circle(
                          circleId: const CircleId("my_location_pulse"),
                          center: _currentPosition!,
                          radius: radius,
                          fillColor: colorThemePink.withValues(
                            alpha: opacity * 0.3,
                          ),
                          strokeColor: colorThemePink.withValues(
                            alpha: opacity,
                          ),
                          strokeWidth: 1,
                        ),
                      );
                    }

                    return Stack(
                      children: [
                        Positioned.fill(
                          child: GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: _currentPosition!,
                              zoom: _currentZoom,
                            ),
                            padding: const EdgeInsets.only(
                              top: 220,
                              bottom: 120,
                            ),
                            onMapCreated: (controller) {
                              _googleMapController = controller;
                              _customInfoWindowController.googleMapController =
                                  controller;
                              if (!_controller.isCompleted) {
                                _controller.complete(controller);
                              }
                              for (var ctrl in _markerAlertControllers.values) {
                                ctrl.googleMapController = controller;
                                ctrl.onCameraMove?.call();
                              }
                              final state = context
                                  .read<EmployeeMapCubit>()
                                  .state;
                              _syncAnimatedAlertMarkers(state.alertMarkers);
                            },
                            onCameraMove: (position) {
                              _currentZoom = position.zoom;
                              _customInfoWindowController.onCameraMove?.call();
                              for (var ctrl in _markerAlertControllers.values) {
                                if (ctrl.googleMapController != null) {
                                  ctrl.onCameraMove?.call();
                                }
                              }
                            },
                            onCameraIdle: () {
                              _customInfoWindowController.onCameraMove?.call();
                            },
                            markers: {
                              if (_myLocationMarker != null) _myLocationMarker!,
                              ..._markers,
                              if (_destinationMarker != null)
                                _destinationMarker!,
                              if (_searchedPlaceMarker != null)
                                _searchedPlaceMarker!,
                            },
                            polylines: context
                                .watch<MapCubit>()
                                .state
                                .polylines,
                            circles: pulseCircles,
                            myLocationEnabled: false,
                            myLocationButtonEnabled: false,
                            zoomControlsEnabled: false,
                            onTap: (position) async {
                              FocusScope.of(context).unfocus();
                              if (!mounted || _isDisposed) return;
                              _customInfoWindowController.hideInfoWindow
                                  ?.call();

                              final empState = context
                                  .read<EmployeeMapCubit>()
                                  .state;
                              if (empState.isAlertPanelOpen) {
                                context
                                    .read<EmployeeMapCubit>()
                                    .closeAlertPanel();
                              }
                              if (empState.isGetDirectionOpen) {
                                final mapCtrl = context.read<MapCubit>();
                                final address = await mapCtrl
                                    .getAddressFromCoordinates(position);
                                if (!mounted || _isDisposed) return;
                                mapCtrl.setMapSelectedLocation(
                                  position: position,
                                  address: address,
                                  isOrigin: false,
                                );
                                setState(() {
                                  _destinationMarker = Marker(
                                    markerId: const MarkerId('destination'),
                                    position: position,
                                    icon: BitmapDescriptor.defaultMarkerWithHue(
                                      BitmapDescriptor.hueRed,
                                    ),
                                  );
                                });
                                return;
                              }
                            },
                          ),
                        ),

                        // Per-alert floating animated GIF icons (hopper-style)
                        if (mounted)
                          ..._markerAlertControllers.entries.map((entry) {
                            return KeyedSubtree(
                              key: ValueKey('alert_ciw_${entry.key}'),
                              child: ciw.CustomInfoWindow(
                                controller: entry.value,
                                height: responsiveWidth * 0.095,
                                width: responsiveWidth * 0.095,
                                offset: 4,
                              ),
                            );
                          }),

                        // Main info window for worker / alert taps
                        ciw.CustomInfoWindow(
                          controller: _customInfoWindowController,
                          height: 185,
                          width: 240,
                          offset: 1,
                        ),

                        // Burst animation overlay
                        IgnorePointer(
                          child: AnimatedBuilder(
                            animation: _burstController,
                            builder: (context, _) => CustomPaint(
                              painter: BurstPainter(_particles, _burstImage),
                              size: MediaQuery.of(context).size,
                            ),
                          ),
                        ),

                        // Search bar + dropdown
                        Positioned(
                          top: searchBarTop,
                          left: 0,
                          right: 0,
                          child: SizedBox(
                            height: 320,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                SearchAndFilterBar(
                                  isFromEmployeeMap: true,
                                  searchController: _searchController,
                                  searchFocusNode: _searchFocusNode,
                                  onPressedOnNavigation: () {
                                    employeeMapNotifier.toggleGetDirection();
                                  },
                                  onChange: _searchAll,
                                  selectedDistance: _selectedDistance,
                                  selectedAlertType: _selectedAlertType,
                                  onDistanceChanged: (value) async {
                                    if (value != null) {
                                      setState(() {
                                        _selectedDistance = value;
                                      });
                                      _filterAndRenderMapData();

                                      final newZoom = _getZoomForDistance(
                                        value,
                                      );
                                      final ctrl = await _controller.future;
                                      ctrl.animateCamera(
                                        CameraUpdate.zoomTo(newZoom),
                                      );

                                      _loadEmployeeMapData();
                                    }
                                  },
                                  onAlertTypeChanged: (value) {
                                    setState(() {
                                      _selectedAlertType = value ?? '';
                                    });
                                    _filterAndRenderMapData();
                                    _loadEmployeeMapData();
                                  },
                                ),
                                if (_showSearchDropdown &&
                                    _searchResults.isNotEmpty)
                                  Positioned(
                                    left: 16,
                                    right: 56,
                                    top: 50,
                                    child: Material(
                                      elevation: 6,
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.white,
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxHeight: 240,
                                        ),
                                        child: ListView.separated(
                                          shrinkWrap: true,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 4,
                                          ),
                                          itemCount: _searchResults.length,
                                          separatorBuilder: (_, __) => Divider(
                                            height: 1,
                                            color: Colors.grey.shade200,
                                          ),
                                          itemBuilder: (context, index) =>
                                              _buildSearchResultItem(
                                                _searchResults[index],
                                              ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        // Get direction card
                        Positioned(
                          top: 180,
                          right: responsiveWidth * numD05,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 300),
                            opacity: mapState.isGetDirectionOpen ? 1 : 0,
                            child: AnimatedScale(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeOutBack,
                              alignment: Alignment.topRight,
                              scale: mapState.isGetDirectionOpen ? 1 : 0.0,
                              child: IgnorePointer(
                                ignoring: !mapState.isGetDirectionOpen,
                                child: const GetDirectionCard(),
                              ),
                            ),
                          ),
                        ),

                        // Side zoom / location panel
                        Positioned(
                          right: responsiveWidth * numD05,
                          bottom: zoomPanelBottom,
                          child: SideActionPanel(
                            onCurrentLocation: _onCurrentLocation,
                            onZoomIn: _onZoomIn,
                            onZoomOut: _onZoomOut,
                          ),
                        ),

                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: bottomOffset,
                          child: _buildNavigationBar(size),
                        ),

                        // Bottom action bar — hidden during navigation
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 12.h,
                          child: IgnorePointer(
                            ignoring: context
                                .watch<MapCubit>()
                                .state
                                .isNavigating,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 300),
                              opacity:
                                  context.watch<MapCubit>().state.isNavigating
                                  ? 0.0
                                  : 1.0,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AnimatedOpacity(
                                    duration: const Duration(milliseconds: 300),
                                    opacity: mapState.isAlertPanelOpen ? 1 : 0,
                                    child: AnimatedScale(
                                      duration: const Duration(
                                        milliseconds: 400,
                                      ),
                                      curve: Curves.easeOutBack,
                                      alignment: Alignment.bottomLeft,
                                      scale: mapState.isAlertPanelOpen
                                          ? 1
                                          : 0.0,
                                      child: IgnorePointer(
                                        ignoring: !mapState.isAlertPanelOpen,
                                        child: RepaintBoundary(
                                          child: AlertPanelEmployee(
                                            onClose: employeeMapNotifier
                                                .closeAlertPanel,
                                            onAlertSelected: (type) async {
                                              if (_currentPosition != null) {
                                                await employeeMapNotifier
                                                    .addAlertMarker(
                                                      type,
                                                      _currentPosition!,
                                                    );
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Center(
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth: responsiveWidth,
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: responsiveWidth * numD04,
                                        ),
                                        child: Row(
                                          spacing: 8,
                                          children: [
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: employeeMapNotifier
                                                    .toggleAlertPanel,
                                                child:
                                                    const AlertButtonMapForEmployee(),
                                              ),
                                            ),
                                            SosButton(
                                              size: responsiveWidth * 0.122,
                                              fontSize:
                                                  responsiveWidth * numD035,
                                              getPosition: () =>
                                                  _currentPosition,
                                              triggerSosDirectly:
                                                  _triggerSosDirectly,
                                              onSosStarted: (session) {
                                                if (mounted) {
                                                  setState(
                                                    () => _triggerSosDirectly =
                                                        false,
                                                  );
                                                }
                                              },
                                              onSosStopped: () {
                                                if (mounted) {
                                                  if (_sosFromMenu) {
                                                    setState(() {
                                                      _sosFromMenu = false;
                                                      _triggerSosDirectly =
                                                          false;
                                                    });
                                                    final dashboardState = context
                                                        .findAncestorStateOfType<
                                                          DashboardScreenState
                                                        >();
                                                    if (dashboardState !=
                                                        null) {
                                                      dashboardState.changeTab(
                                                        4,
                                                      );
                                                    }
                                                  }
                                                }
                                              },
                                            ),
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: () {
                                                  context.push(
                                                    AppRoutes.teamChatList,
                                                  );
                                                },
                                                child:
                                                    const MessageButtonForMap(),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ),
    );
  }
}

enum _SearchResultType { worker, alert, place }

class _SearchResult {
  final _SearchResultType type;
  final String title;
  final String subtitle;
  final String? placeId;
  final HeatmapWorker? worker;
  final EmployeeAlertMarker? alert;

  const _SearchResult({
    required this.type,
    required this.title,
    required this.subtitle,
    this.placeId,
    this.worker,
    this.alert,
  });
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()..color = color;
    Path path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width / 2, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
