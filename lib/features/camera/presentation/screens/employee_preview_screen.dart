import 'dart:io';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:location/location.dart';
import 'package:path/path.dart' as path;
import '../../data/models/camera_data.dart';
import '../../utils/camera_constants.dart';
import '../../utils/camera_location_service.dart';
import '../widgets/audio_waveform_widget.dart';
import '../widgets/video_player_widget.dart';
import 'employee_camera_screen.dart';
import 'employee_publish_content_screen.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';
import '../../../../main.dart' show sharedPreferences;

class EmployeePreviewScreen extends StatefulWidget {
  final CameraData? cameraData;
  final List<CameraData> cameraListData;
  final List<MediaData> mediaList;
  final bool pickAgain;
  final String type;

  const EmployeePreviewScreen({
    super.key,
    required this.cameraData,
    required this.pickAgain,
    required this.cameraListData,
    required this.mediaList,
    required this.type,
  });

  @override
  State<EmployeePreviewScreen> createState() => _EmployeePreviewScreenState();
}

class _EmployeePreviewScreenState extends State<EmployeePreviewScreen> {
  late PageController _pageController;
  final CameraLocationService _locationService = CameraLocationService();

  List<MediaData> mediaList = [];
  int currentPage = 0;
  bool isLocationFetching = false;
  String country = '', state = '', city = '', latitude = '', longitude = '';

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _addFromCameraList(widget.cameraListData);
    if (widget.mediaList.isNotEmpty) {
      mediaList = List.from(widget.mediaList);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        _requestLocation(shouldShowSettingPopup: false, showErrorPage: false));
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _addFromCameraList(List<CameraData> list) {
    for (final item in list) {
      mediaList.insert(
        0,
        MediaData(
          mimeType: item.mimeType,
          latitude: item.latitude,
          longitude: item.longitude,
          location: item.location,
          dateTime: item.dateTime,
          mediaPath: item.path,
          thumbnail: item.videoImagePath,
          isLocalMedia: true,
        ),
      );
    }
    currentPage = 0;
    if (_pageController.hasClients) _pageController.jumpToPage(0);
  }

  Future<void> _requestLocation({
    bool shouldShowSettingPopup = true,
    bool showErrorPage = true,
  }) async {
    setState(() => isLocationFetching = true);
    LocationData? loc = await _locationService.getCurrentLocation(
      context,
      shouldShowSettingPopup: shouldShowSettingPopup,
    );
    // The `location` plugin often returns null (or null lat/lon) on the first
    // call before a GPS fix is acquired — retry once after a short delay.
    if ((loc == null || loc.latitude == null || loc.longitude == null) &&
        mounted) {
      await Future.delayed(const Duration(milliseconds: 900));
      loc = await _locationService.getCurrentLocation(
        context,
        shouldShowSettingPopup: false,
      );
    }
    if (!mounted) return;
    setState(() => isLocationFetching = false);
    if (loc != null && loc.latitude != null && loc.longitude != null) {
      await _applyLocation(loc);
    } else {
      // Live fetch failed — fall back to the last cached location in prefs.
      _applyFromPrefs();
    }
  }

  /// Uses the last known location saved in SharedPreferences so the preview
  /// still shows something useful when a live fix isn't available.
  void _applyFromPrefs() {
    final lat = sharedPreferences?.getDouble(currentLat);
    final lon = sharedPreferences?.getDouble(currentLon);
    final address = sharedPreferences?.getString(currentAddress) ?? '';
    final hasCoords = lat != null && lon != null && (lat != 0 || lon != 0);
    if (address.isEmpty && !hasCoords) return;
    if (!mounted) return;
    setState(() {
      for (final m in mediaList) {
        if (m.latitude.isEmpty && lat != null) m.latitude = lat.toString();
        if (m.longitude.isEmpty && lon != null) m.longitude = lon.toString();
        if (m.location.isEmpty) {
          m.location =
              address.isNotEmpty ? address : 'Lat: $lat, Long: $lon';
        }
      }
      country = sharedPreferences?.getString(currentCountry) ?? country;
      state = sharedPreferences?.getString(currentState) ?? state;
      city = sharedPreferences?.getString(currentCity) ?? city;
      if (lat != null) latitude = lat.toString();
      if (lon != null) longitude = lon.toString();
    });
  }

  Future<void> _applyLocation(LocationData loc) async {
    final lat = loc.latitude;
    final lon = loc.longitude;
    if (lat == null || lon == null) return;
    try {
      final placemarks = await placemarkFromCoordinates(lat, lon);
      final place = placemarks.first;
      final address =
          '${place.street ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}, ${place.country ?? ''}';
      if (!mounted) return;
      setState(() {
        for (final m in mediaList) {
          if (m.latitude.isEmpty) m.latitude = lat.toString();
          if (m.longitude.isEmpty) m.longitude = lon.toString();
          if (m.location.isEmpty) m.location = address;
        }
        country = place.country ?? '';
        state = place.administrativeArea ?? '';
        city = place.locality ?? '';
        latitude = lat.toString();
        longitude = lon.toString();
      });
      // Cache for later captures (parity with the old app).
      sharedPreferences?.setDouble(currentLat, lat);
      sharedPreferences?.setDouble(currentLon, lon);
      sharedPreferences?.setString(currentAddress, address);
      sharedPreferences?.setString(currentCountry, place.country ?? '');
      sharedPreferences?.setString(currentState, place.administrativeArea ?? '');
      sharedPreferences?.setString(currentCity, place.locality ?? '');
    } catch (_) {
      if (!mounted) return;
      setState(() {
        for (final m in mediaList) {
          if (m.latitude.isEmpty) m.latitude = lat.toString();
          if (m.longitude.isEmpty) m.longitude = lon.toString();
          if (m.location.isEmpty) m.location = 'Lat: $lat, Long: $lon';
        }
        latitude = lat.toString();
        longitude = lon.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          if (widget.type == 'draft') {
            Navigator.pop(context);
          } else {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const DashboardScreen()),
              (r) => false,
            );
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Column(
          children: [
            // ── PageView ────────────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (v) => setState(() => currentPage = v),
                itemCount: mediaList.length,
                itemBuilder: (context, index) {
                  final media = mediaList[index];
                  return InteractiveViewer(
                    scaleEnabled: media.mimeType == 'image',
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        // ── Media content ──────────────────────────────
                        _buildMediaContent(size, media),

                        // ── Close/delete button ────────────────────────
                        Positioned(
                          top: size.width * numD09 + MediaQuery.of(context).padding.top,
                          right: size.width * numD02,
                          child: IconButton(
                            onPressed: () {
                              if (mediaList.length == 1) {
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                      builder: (_) => const DashboardScreen()),
                                  (r) => false,
                                );
                              } else {
                                setState(() {
                                  mediaList.removeAt(index);
                                  if (currentPage >= mediaList.length) {
                                    currentPage = mediaList.length - 1;
                                  }
                                });
                              }
                            },
                            icon: Container(
                              decoration: const BoxDecoration(
                                  color: Colors.white, shape: BoxShape.circle),
                              child: Icon(Icons.close,
                                  color: Colors.black,
                                  size: size.width * numD06),
                            ),
                          ),
                        ),

                        // ── Dots indicator ─────────────────────────────
                        if (mediaList.length > 1)
                          Positioned(
                            bottom: media.mimeType == 'video'
                                ? size.width * numD08
                                : 0,
                            child: DotsIndicator(
                              dotsCount: mediaList.length,
                              position: currentPage,
                              decorator: const DotsDecorator(
                                color: Colors.grey,
                                activeColor: colorEmployeeGreen1,
                              ),
                            ),
                          ),

                        // ── Date & location row ────────────────────────
                        Container(
                          margin: EdgeInsets.only(
                            bottom: media.mimeType == 'video'
                                ? size.width * numD11
                                : size.width * numD03,
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: size.width * numD04,
                            vertical: size.width * numD04,
                          ),
                          child: Row(
                            children: [
                              // Date-time card
                              Expanded(
                                child: Container(
                                  height: size.width * numD11,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(
                                        size.width * numD04),
                                    border: Border.all(
                                        color: Colors.black
                                            .withValues(alpha: 0.06)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.08),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.access_time,
                                          size: size.width * numD04,
                                          color: const Color(0xFF64748B)),
                                      const SizedBox(width: 8),
                                      Text(
                                        media.dateTime,
                                        style: TextStyle(
                                          fontSize: size.width * numD028,
                                          color: const Color(0xFF1E293B),
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'AirbnbCereal',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Location card — tap to (re)fetch location.
                              Expanded(
                                child: GestureDetector(
                                  onTap: isLocationFetching
                                      ? null
                                      : () => _requestLocation(
                                            shouldShowSettingPopup: true,
                                            showErrorPage: false,
                                          ),
                                  child: Container(
                                  height: size.width * numD11,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(
                                        size.width * numD04),
                                    border: Border.all(
                                        color: Colors.black
                                            .withValues(alpha: 0.06)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.08),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        size: size.width * numD04,
                                        color: media.location.isEmpty
                                            ? Colors.red
                                            : const Color(0xFF64748B),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          media.location.isEmpty
                                              ? 'No Location'
                                              : media.location,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: size.width * numD028,
                                            color: const Color(0xFF1E293B),
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'AirbnbCereal',
                                          ),
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
                      ],
                    ),
                  );
                },
              ),
            ),

            // ── Bottom action bar ────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: EdgeInsets.fromLTRB(
                size.width * numD03,
                size.width * numD02,
                size.width * numD03,
                size.width * numD08,
              ),
              child: Row(
                children: [
                  // Add More
                  Expanded(
                    child: SizedBox(
                      height: size.width * numD13,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(size.width * numD03),
                          ),
                        ),
                        onPressed: () {
                          if (mediaList.length >= 10) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Limit 10 contents'),
                                  backgroundColor: colorEmployeeGreen1),
                            );
                            return;
                          }
                          Navigator.of(context)
                              .push(MaterialPageRoute(
                            builder: (_) => const EmployeeCameraScreen(
                                picAgain: true),
                          ))
                              .then((value) {
                            if (value != null && mounted) {
                              setState(() => _addFromCameraList(
                                  value as List<CameraData>));
                            }
                          });
                        },
                        child: Text(
                          'Add More',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: size.width * numD035,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'AirbnbCereal',
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Next
                  Expanded(
                    child: SizedBox(
                      height: size.width * numD13,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorEmployeeGreen1,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(size.width * numD03),
                          ),
                        ),
                        onPressed: () async {
                          // Try to attach a location, but never block
                          // publishing on it — otherwise Next silently does
                          // nothing when location is unavailable.
                          if (mediaList.first.location.isEmpty) {
                            await _requestLocation(
                              shouldShowSettingPopup: true,
                              showErrorPage: false,
                            );
                          }
                          if (!mounted) return;
                          final pubData = PublishData(
                            imagePath: mediaList.first.mediaPath,
                            address: mediaList[currentPage].location,
                            date: mediaList[currentPage].dateTime,
                            city: city,
                            state: state,
                            country: country,
                            latitude: latitude,
                            longitude: longitude,
                            mimeType: mediaList.first.mimeType,
                            videoImagePath: mediaList.first.thumbnail,
                            mediaList: mediaList,
                          );
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => EmployeePublishContentScreen(
                              publishData: pubData,
                              docType: widget.type,
                            ),
                          ));
                        },
                        child: Text(
                          'Next',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: size.width * numD035,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'AirbnbCereal',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaContent(Size size, MediaData media) {
    if (media.mimeType.contains('video')) {
      return Align(
        alignment: Alignment.center,
        child: VideoWidget(mediaData: media),
      );
    }
    if (media.mimeType.contains('audio')) {
      return AudioWaveFormWidget(mediaPath: media.mediaPath);
    }
    if (media.mimeType.contains('doc') || media.mimeType.contains('pdf')) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              media.mimeType.contains('pdf')
                  ? Icons.picture_as_pdf
                  : Icons.description,
              color: Colors.white,
              size: size.width * numD45,
            ),
            SizedBox(height: size.width * numD03),
            Text(
              path.basename(media.mediaPath),
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    // Image
    return SizedBox(
      height: size.height,
      width: size.width,
      child: media.isLocalMedia
          ? Image.file(File(media.mediaPath), fit: BoxFit.contain)
          : Image.network(media.mediaPath, fit: BoxFit.contain),
    );
  }
}
