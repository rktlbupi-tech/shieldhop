import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:presshop_enterprise/features/map/data/models/marker_model.dart';

import 'package:presshop_enterprise/features/map/data/services/map_service.dart';

class MapState {
  final LatLng? myLocation;
  final CameraPosition? initialCamera;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final Set<Polygon> polygons;
  final Set<Circle> circles;
  final bool showAlertPanel;
  final bool showGetDirectionCard;
  final LatLng? destination;
  final RouteInfo? routeInfo;
  final Incident? selectedIncident;
  final LatLng? selectedPosition;
  final bool isDragging;
  final String? selectedPolygonId;
  final LatLng? selectedPolygonPosition;
  final String? selectedAlertType;
  final String? selectedDistance;
  final String? selectedCategory;
  final bool isDestinationSelectionMode;
  final bool isSelectingOrigin;
  final bool isNavigating;
  final LatLng? currentNavigationPosition;
  final LatLng? mapSelectedLocation;
  final String? mapSelectedAddress;
  final bool? mapSelectedIsOrigin;
  final LatLng? routeMidpoint;

  final String? previewAlertMarkerId;
  final String? previewAlertType;
  final LatLng? previewAlertPosition;
  final bool isLoadingNews;
  final bool isLoadingMapData;
  final LatLng? searchedLocation;
  final String? myLocationAddress;
  final bool isLocationDenied;

  MapState({
    this.myLocation,
    this.initialCamera,
    this.markers = const {},
    this.polylines = const {},
    this.polygons = const {},
    this.circles = const {},
    this.showAlertPanel = false,
    this.showGetDirectionCard = false,
    this.destination,
    this.routeInfo,
    this.selectedIncident,
    this.selectedPosition,
    this.isDragging = false,
    this.selectedPolygonId,
    this.selectedPolygonPosition,
    this.selectedAlertType,
    this.selectedDistance,
    this.selectedCategory,
    this.isDestinationSelectionMode = false,
    this.isSelectingOrigin = false,
    this.isNavigating = false,
    this.currentNavigationPosition,
    this.mapSelectedLocation,
    this.mapSelectedAddress,
    this.mapSelectedIsOrigin,
    this.routeMidpoint,
    this.previewAlertMarkerId,
    this.previewAlertType,
    this.previewAlertPosition,
    this.newsList = const [],
    this.isLoadingNews = false,
    this.isLoadingMapData = false,
    this.searchedLocation,
    this.myLocationAddress,
    this.newlyCreatedIncident,
    this.isLocationDenied = false,
    this.hasUnreadAlert = false,
    this.lastAlertIncident,
  });

  final List<Incident> newsList;
  final bool hasUnreadAlert;
  final Incident? lastAlertIncident;

  MapState copyWith({
    LatLng? myLocation,
    CameraPosition? initialCamera,
    Set<Marker>? markers,
    Set<Polyline>? polylines,
    Set<Polygon>? polygons,
    Set<Circle>? circles,
    bool? showAlertPanel,
    bool? showGetDirectionCard,
    LatLng? destination,
    RouteInfo? routeInfo,
    Incident? selectedIncident,
    LatLng? selectedPosition,
    bool? isDragging,
    String? selectedPolygonId,
    LatLng? selectedPolygonPosition,
    String? selectedAlertType,
    String? selectedDistance,
    String? selectedCategory,
    bool? isDestinationSelectionMode,
    bool? isSelectingOrigin,
    bool? isNavigating,
    LatLng? currentNavigationPosition,
    bool? hasUnreadAlert,
    LatLng? mapSelectedLocation,
    String? mapSelectedAddress,
    bool? mapSelectedIsOrigin,
    LatLng? routeMidpoint,
    String? previewAlertMarkerId,
    String? previewAlertType,
    LatLng? previewAlertPosition,
    List<Incident>? newsList,
    bool? isLoadingNews,
    bool? isLoadingMapData,
    LatLng? searchedLocation,
    String? myLocationAddress,
    bool clearDestination = false,
    bool clearRouteInfo = false,
    bool clearSelectedIncident = false,
    bool clearSelectedPosition = false,
    bool clearSelectedPolygonId = false,
    bool clearSelectedPolygonPosition = false,
    bool clearCurrentNavigationPosition = false,
    bool clearMapSelectedLocation = false,
    bool clearMapSelectedAddress = false,
    bool clearMapSelectedIsOrigin = false,
    bool clearPreviewAlert = false,
    bool clearSearchedLocation = false,
    bool clearNewlyCreatedIncident = false,
    Incident? newlyCreatedIncident,
    bool? isLocationDenied,
    Incident? lastAlertIncident,
  }) {
    return MapState(
      lastAlertIncident: lastAlertIncident ?? this.lastAlertIncident,
      hasUnreadAlert: hasUnreadAlert ?? this.hasUnreadAlert,
      newlyCreatedIncident: clearNewlyCreatedIncident
          ? null
          : (newlyCreatedIncident ?? this.newlyCreatedIncident),
      myLocation: myLocation ?? this.myLocation,
      initialCamera: initialCamera ?? this.initialCamera,
      markers: markers ?? this.markers,
      polylines: polylines ?? this.polylines,
      polygons: polygons ?? this.polygons,
      circles: circles ?? this.circles,
      showAlertPanel: showAlertPanel ?? this.showAlertPanel,
      showGetDirectionCard: showGetDirectionCard ?? this.showGetDirectionCard,
      destination: clearDestination ? null : (destination ?? this.destination),
      routeInfo: clearRouteInfo ? null : (routeInfo ?? this.routeInfo),
      selectedIncident: clearSelectedIncident
          ? null
          : (selectedIncident ?? this.selectedIncident),
      selectedPosition: clearSelectedPosition
          ? null
          : (selectedPosition ?? this.selectedPosition),
      isDragging: isDragging ?? this.isDragging,
      selectedPolygonId: clearSelectedPolygonId
          ? null
          : (selectedPolygonId ?? this.selectedPolygonId),
      selectedPolygonPosition: clearSelectedPolygonPosition
          ? null
          : (selectedPolygonPosition ?? this.selectedPolygonPosition),
      selectedAlertType: selectedAlertType ?? this.selectedAlertType,
      selectedDistance: selectedDistance ?? this.selectedDistance,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      isDestinationSelectionMode:
          isDestinationSelectionMode ?? this.isDestinationSelectionMode,
      isSelectingOrigin: isSelectingOrigin ?? this.isSelectingOrigin,
      isNavigating: isNavigating ?? this.isNavigating,
      currentNavigationPosition: clearCurrentNavigationPosition
          ? null
          : (currentNavigationPosition ?? this.currentNavigationPosition),
      mapSelectedLocation: clearMapSelectedLocation
          ? null
          : (mapSelectedLocation ?? this.mapSelectedLocation),
      mapSelectedAddress: clearMapSelectedAddress
          ? null
          : (mapSelectedAddress ?? this.mapSelectedAddress),
      mapSelectedIsOrigin: clearMapSelectedIsOrigin
          ? null
          : (mapSelectedIsOrigin ?? this.mapSelectedIsOrigin),
      routeMidpoint: clearRouteInfo
          ? null
          : (routeMidpoint ?? this.routeMidpoint),
      previewAlertMarkerId: clearPreviewAlert
          ? null
          : (previewAlertMarkerId ?? this.previewAlertMarkerId),
      previewAlertType: clearPreviewAlert
          ? null
          : (previewAlertType ?? this.previewAlertType),
      previewAlertPosition: clearPreviewAlert
          ? null
          : (previewAlertPosition ?? this.previewAlertPosition),
      newsList: newsList ?? this.newsList,
      isLoadingNews: isLoadingNews ?? this.isLoadingNews,
      isLoadingMapData: isLoadingMapData ?? this.isLoadingMapData,
      searchedLocation: clearSearchedLocation
          ? null
          : (searchedLocation ?? this.searchedLocation),
      myLocationAddress: myLocationAddress ?? this.myLocationAddress,
      isLocationDenied: isLocationDenied ?? this.isLocationDenied,
    );
  }

  // Added field
  final Incident? newlyCreatedIncident;
}
