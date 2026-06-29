import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:geolocator/geolocator.dart';
import 'package:presshop_enterprise/core/constants/constant_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:presshop_enterprise/common/widgets/loading_widget.dart';
import 'package:presshop_enterprise/core/constants/app_colors.dart';
import 'package:presshop_enterprise/features/map/data/services/emergency_service.dart';

class AlertPanelEmployee extends StatefulWidget {
  final VoidCallback onClose;
  final Function(String alertType)? onAlertSelected;

  const AlertPanelEmployee({
    super.key,
    required this.onClose,
    this.onAlertSelected,
  });

  @override
  State<AlertPanelEmployee> createState() => _AlertPanelEmployeeState();
}

class _AlertPanelEmployeeState extends State<AlertPanelEmployee> {
  bool showEmergencyServices = false;
  bool isLoading = false;

  final EmergencyService _emergencyService = EmergencyService();

  Map<String, List<EmergencyStation>> realEmergencyServices = {
    'Police': [],
    'Ambulance': [],
    'Fire Brigade': [],
  };

  final Set<String> _loadingCategories = {};
  bool _fetchStarted = false;

  String getEmergencyNumber(String category) {
    String countryCode = '';
    try {
      countryCode = _prefs?.getString('country_code') ?? '';
    } catch (_) {}

    countryCode = countryCode.replaceAll(RegExp(r'[^\d]'), '');

    if (countryCode == '44') {
      // UK
      return '999';
    } else if (countryCode == '1') {
      // USA / Canada
      return '911';
    } else if (countryCode == '91') {
      // India
      if (category == 'Police') return '100';
      if (category == 'Ambulance') return '102';
      return '101';
    } else {
      // Default to UK 999 to match prior behaviour; falls through here when no
      // country code is stored.
      return '999';
    }
  }

  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (mounted) _prefs = p;
    });
  }

  Future<void> _fetchRealEmergencyData() async {
    if (!mounted) return;
    setState(() {
      showEmergencyServices = true;
      isLoading = true;
      _fetchStarted = true;
      _loadingCategories.addAll(['Police', 'Ambulance', 'Fire Brigade']);
      realEmergencyServices = {
        'Police': [],
        'Ambulance': [],
        'Fire Brigade': [],
      };
    });

    Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint('Error getting location: $e');
      _loadFallbackData();
      if (mounted) {
        setState(() {
          isLoading = false;
          _loadingCategories.clear();
        });
      }
      return;
    }

    void updateCategory(String key, List<EmergencyStation> stations) {
      if (!mounted) return;
      setState(() {
        realEmergencyServices[key] = stations;
        _loadingCategories.remove(key);
        if (_loadingCategories.isEmpty) {
          isLoading = false;
          // If every category came back empty, show fallback default cards.
          if (realEmergencyServices.values.every((l) => l.isEmpty)) {
            _loadFallbackData();
          }
        }
      });
    }

    // Fire all three independently — UI updates as each one arrives.
    _emergencyService
        .fetchNearbyStations(
          lat: position.latitude,
          lng: position.longitude,
          type: 'police',
        )
        .then((r) => updateCategory('Police', r));
    _emergencyService
        .fetchNearbyStations(
          lat: position.latitude,
          lng: position.longitude,
          type: 'hospital',
        )
        .then((r) => updateCategory('Ambulance', r));
    _emergencyService
        .fetchNearbyStations(
          lat: position.latitude,
          lng: position.longitude,
          type: 'fire_station',
        )
        .then((r) => updateCategory('Fire Brigade', r));
  }

  void _loadFallbackData() {
    EmergencyStation fallback(String category) => EmergencyStation(
      name: category,
      address: 'Default emergency number',
      phoneNumber: getEmergencyNumber(category),
      distance: 0.0,
      lat: 0.0,
      lng: 0.0,
    );

    realEmergencyServices = {
      'Police': [fallback('Police')],
      'Ambulance': [fallback('Ambulance')],
      'Fire Brigade': [fallback('Fire Brigade')],
    };
  }

  Future<void> _makeCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) return;
    final clean = phoneNumber.replaceAll(RegExp(r'[^\d+*#]'), '');
    final uri = Uri(scheme: 'tel', path: clean);
    try {
      debugPrint(
        '[AlertPanel] Launching tel URI: $uri (Original: $phoneNumber)',
      );
      await launchUrl(uri);
    } catch (e) {
      debugPrint('[AlertPanel] Error launching tel URI: $e');
    }
  }

  Future<void> _navigateToLocation(double lat, double lng) async {
    final String googleMapsUrl =
        "https://www.google.com/maps/search/?api=1&query=$lat,$lng";
    final String appleMapsUrl = "https://maps.apple.com/?q=$lat,$lng";

    if (Theme.of(context).platform == TargetPlatform.iOS) {
      if (await canLaunchUrl(Uri.parse(appleMapsUrl))) {
        await launchUrl(
          Uri.parse(appleMapsUrl),
          mode: LaunchMode.externalApplication,
        );
        return;
      }
    }

    if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
      await launchUrl(
        Uri.parse(googleMapsUrl),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width > 600 ? 650.0 : size.width;

    return Stack(
      children: [
        Align(
          alignment: Alignment.bottomLeft,
          child: Container(
            margin: EdgeInsets.only(left: w * 0.04, bottom: w * 0.042),
            width: w * 0.70,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(w * 0.05),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: w * 0.026,
                  offset: Offset(0, w * 0.01),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(w * 0.05),
              child: SizedBox(
                height: w * 1.23,
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: w * 0.026,
                    vertical: w * 0.015,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Row(
                        children: [
                          GestureDetector(
                            onTap: showEmergencyServices
                                ? () => setState(
                                    () => showEmergencyServices = false,
                                  )
                                : null,
                            child: Row(
                              children: [
                                if (showEmergencyServices) ...[
                                  Icon(
                                    Icons.arrow_back_ios,
                                    size: w * 0.04,
                                    color: Colors.black,
                                  ),
                                  SizedBox(width: w * 0.02),
                                ],
                                Text(
                                  showEmergencyServices
                                      ? 'Emergency services'
                                      : 'Share Alerts',
                                  style: TextStyle(
                                    fontSize: w * 0.032,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'AirbnbCereal',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          if (!showEmergencyServices)
                            GestureDetector(
                              onTap: () {
                                if (!_fetchStarted) {
                                  _fetchRealEmergencyData();
                                } else {
                                  setState(() => showEmergencyServices = true);
                                }
                              },
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.phone,
                                    size: w * 0.04,
                                    color: AppColors.primary,
                                  ),
                                  SizedBox(width: w * 0.02),
                                  Text(
                                    'Emergency services',
                                    style: TextStyle(
                                      fontSize: w * 0.032,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.primary,
                                      fontFamily: 'AirbnbCereal',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: w * 0.02),
                      Container(
                        height: w * 0.005,
                        width: double.infinity,
                        margin: EdgeInsets.only(bottom: w * 0.02),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(w * 0.005),
                        ),
                      ),
                      if (!showEmergencyServices) ...[
                        Row(
                          children: [
                            Text(
                              'Tap to instantly alert your team',
                              style: TextStyle(
                                color: const Color(0xFF4F4F4F),
                                fontSize: w * 0.028,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'AirbnbCereal',
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: w * 0.03),
                        GridView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount:
                              AppConstantData.alertTypesForEmployee.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                childAspectRatio: 0.85,
                                crossAxisSpacing: w * 0.012,
                                mainAxisSpacing: w * 0.012,
                              ),
                          itemBuilder: (context, i) {
                            final item =
                                AppConstantData.alertTypesForEmployee[i];
                            return GestureDetector(
                              onTap: () {
                                widget.onAlertSelected?.call(item['type']!);
                                widget.onClose();
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(
                                    w * 0.021,
                                  ),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      item['icon']!,
                                      width: w * 0.09,
                                      height: w * 0.09,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => Icon(
                                        Icons.warning_amber_rounded,
                                        size: w * 0.09,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    SizedBox(height: w * 0.016),
                                    Text(
                                      item['label']!,
                                      style: TextStyle(
                                        fontSize: w * 0.028,
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.w400,
                                        fontFamily: 'AirbnbCereal',
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ] else ...[
                        _buildEmergencyServices(w),
                      ],
                      SizedBox(height: w * 0.02),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        // Arrow pointer
        Positioned(
          left: w * 0.15,
          bottom: w * 0.016,
          child: Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: w * 0.05,
              height: w * 0.05,
              decoration: const BoxDecoration(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmergencyServices(double w) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: realEmergencyServices.entries.map((entry) {
        final category = entry.key;
        final stations = entry.value;
        final isLoadingCategory = _loadingCategories.contains(category);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: w * 0.02),
              child: Text(
                'Contact $category',
                style: TextStyle(
                  fontSize: w * 0.032,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                  fontFamily: 'AirbnbCereal',
                ),
              ),
            ),
            if (isLoadingCategory)
              Padding(
                padding: EdgeInsets.only(bottom: w * 0.02),
                child: Row(
                  children: [
                    SizedBox(
                      width: w * 0.04,
                      height: w * 0.04,
                      child: LoadingWidget(size: w * 0.04),
                    ),
                    SizedBox(width: w * 0.02),
                    Text(
                      'Searching nearby...',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: w * 0.028,
                        fontFamily: 'AirbnbCereal',
                      ),
                    ),
                  ],
                ),
              )
            else if (stations.isEmpty)
              Padding(
                padding: EdgeInsets.only(bottom: w * 0.02),
                child: Text(
                  'No nearby ${category.toLowerCase()} found',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: w * 0.028,
                    fontFamily: 'AirbnbCereal',
                  ),
                ),
              )
            else
              ...stations.map(
                (station) => _buildStationCard(w, category, station),
              ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildStationCard(
    double w,
    String category,
    EmergencyStation station,
  ) {
    final dialNumber = station.phoneNumber.isNotEmpty
        ? station.phoneNumber
        : getEmergencyNumber(category);
    debugPrint(
      '[AlertPanel] Building card for ${station.name}: Phone="${station.phoneNumber}", DialNumber="$dialNumber"',
    );

    return Container(
      margin: EdgeInsets.only(bottom: w * 0.02),
      padding: EdgeInsets.all(w * 0.03),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(w * 0.02),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  station.name,
                  style: TextStyle(
                    fontSize: w * 0.032,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'AirbnbCereal',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: w * 0.008),
                Text(
                  station.address,
                  style: TextStyle(
                    fontSize: w * 0.026,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey.shade600,
                    fontFamily: 'AirbnbCereal',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if ((station.distanceStr ?? '').isNotEmpty) ...[
                  SizedBox(height: w * 0.008),
                  Text(
                    station.distanceStr!,
                    style: TextStyle(
                      fontSize: w * 0.026,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade500,
                      fontFamily: 'AirbnbCereal',
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: w * 0.02),
          if (station.lat != 0.0 && station.lng != 0.0) ...[
            GestureDetector(
              onTap: () => _navigateToLocation(station.lat, station.lng),
              child: Container(
                padding: EdgeInsets.all(w * 0.015),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 1.5),
                ),
                child: Icon(
                  LucideIcons.corner_up_right,
                  size: w * 0.035,
                  color: Colors.black,
                ),
              ),
            ),
            SizedBox(width: w * 0.015),
          ],
          GestureDetector(
            onTap: () => _makeCall(dialNumber),
            child: Container(
              padding: EdgeInsets.all(w * 0.015),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.red, width: 1.5),
              ),
              child: Icon(Icons.phone, size: w * 0.035, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
