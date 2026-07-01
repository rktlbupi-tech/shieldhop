import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:presshop_enterprise/core/constants/app_colors.dart';
import 'package:presshop_enterprise/features/map/core/map_constants.dart';
import 'package:presshop_enterprise/features/map/presentation/bloc/map_cubit.dart';
import 'package:presshop_enterprise/common/widgets/loading_widget.dart';

class GetDirectionCard extends StatefulWidget {
  const GetDirectionCard({super.key});

  @override
  State<GetDirectionCard> createState() => _GetDirectionCardState();
}

class _GetDirectionCardState extends State<GetDirectionCard> {
  final TextEditingController _currentLocationController =
      TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final FocusNode _currentLocationFocusNode = FocusNode();
  final FocusNode _destinationFocusNode = FocusNode();
  List<dynamic> _currentLocationPredictions = [];
  List<dynamic> _destinationPredictions = [];
  bool _showCurrentLocationDropdown = false;
  bool _showDestinationDropdown = false;
  bool _isLoading = false;
  LatLng? _selectedOrigin;
  LatLng? _selectedDestination;
  // LatLng? _lastProcessedMapLocation;
  @override
  void initState() {
    super.initState();

    _currentLocationFocusNode.addListener(() {
      if (!_currentLocationFocusNode.hasFocus) {
        setState(() {
          _showCurrentLocationDropdown = false;
        });
      }
    });

    _destinationFocusNode.addListener(() {
      if (!_destinationFocusNode.hasFocus) {
        setState(() {
          _showDestinationDropdown = false;
        });
      }
    });

    // Initialize with current location address if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<MapCubit>().state;
      if (state.myLocationAddress != null &&
          state.myLocationAddress!.isNotEmpty) {
        setState(() {
          _currentLocationController.text = state.myLocationAddress!;
          _selectedOrigin = state.myLocation;
        });
      }
    });
  }

  @override
  void dispose() {
    _currentLocationController.dispose();
    _destinationController.dispose();
    _currentLocationFocusNode.dispose();
    _destinationFocusNode.dispose();
    super.dispose();
  }

  Future<void> _searchPlaces(String input, {bool isOrigin = false}) async {
    if (input.isEmpty) {
      setState(() {
        if (isOrigin) {
          _currentLocationPredictions = [];
          _showCurrentLocationDropdown = false;
        } else {
          _destinationPredictions = [];
          _showDestinationDropdown = false;
        }
      });
      return;
    }
    // const googleMapAPiKey = "AIzaSyClF12i0eHy7Nrig6EYu8Z4U5DA2zC09OI";
    // const appleMapAPiKey = "AIzaSyA0ZDsoYkDf4Dkh_jOCBzWBAIq5w6sk8gw";
    // const googleApiKey = 'AIzaSyClF12i0eHy7Nrig6EYu8Z4U5DA2zC09OI';
    final url =
        "$googleMapURL"
        "?input=$input"
        "&key=$googleMapAPiKey"
        "&types=geocode";

    final response = await http.get(Uri.parse(url));

    if (!mounted) return;

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final preds = data['predictions'] as List<dynamic>? ?? [];

      setState(() {
        if (isOrigin) {
          _currentLocationPredictions = preds;
          _showCurrentLocationDropdown = preds.isNotEmpty;
        } else {
          _destinationPredictions = preds;
          _showDestinationDropdown = preds.isNotEmpty;
        }
      });
    } else {
      setState(() {
        if (isOrigin) {
          _currentLocationPredictions = [];
          _showCurrentLocationDropdown = false;
        } else {
          _destinationPredictions = [];
          _showDestinationDropdown = false;
        }
      });
    }
  }

  Future<void> _selectPlace(
    String placeId,
    String description, {
    bool isOrigin = false,
  }) async {
    // const googleApiKey = 'AIzaSyClF12i0eHy7Nrig6EYu8Z4U5DA2zC09OI';
    final url =
        "$googlePlaceDetailsURL"
        "?place_id=$placeId"
        "&key=$googleMapAPiKey";

    final response = await http.get(Uri.parse(url));

    if (!mounted) return;

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final location = data['result']['geometry']['location'];
      final selectedLocation = LatLng(location['lat'], location['lng']);

      setState(() {
        if (isOrigin) {
          _showCurrentLocationDropdown = false;
          _currentLocationPredictions = [];
          _currentLocationController.text = description;
          _selectedOrigin = selectedLocation;
          _currentLocationFocusNode.unfocus();
        } else {
          _showDestinationDropdown = false;
          _destinationPredictions = [];
          _destinationController.text = description;
          _selectedDestination = selectedLocation;
          _destinationFocusNode.unfocus();
        }
      });

      if (!isOrigin && _selectedDestination != null) {
        await _getRoute(_selectedOrigin, _selectedDestination!);
      } else if (isOrigin &&
          _selectedOrigin != null &&
          _selectedDestination != null) {
        await _getRoute(_selectedOrigin, _selectedDestination!);
      }
    }
  }

  Future<void> _getRoute(LatLng? origin, LatLng destination) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final mapController = context.read<MapCubit>();
      await mapController.addRoute(origin, destination);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  // when content window open then emit socket and recieved to show view on content window

  // Future<void> _useCurrentLocation() async {
  //   final state = context.read<MapCubit>().state;
  //   if (state.myLocation != null) {
  //     setState(() {
  //       _currentLocationController.text =
  //           state.myLocationAddress ?? 'Current Location';
  //       _selectedOrigin = state.myLocation; // Ensure precise lat/lng
  //       _currentLocationFocusNode.unfocus();
  //     });

  //     if (_selectedDestination != null) {
  //       await _getRoute(_selectedOrigin, _selectedDestination!);
  //     }
  //   }
  // }

  // void _handleMapSelectedLocation() {
  //   final state = context.read<MapCubit>().state;

  //   if (state.mapSelectedLocation != null &&
  //       state.mapSelectedAddress != null &&
  //       state.mapSelectedIsOrigin != null &&
  //       state.mapSelectedLocation != _lastProcessedMapLocation) {
  //     final mapController = context.read<MapCubit>();

  //     // Mark as processed
  //     _lastProcessedMapLocation = state.mapSelectedLocation;

  //     if (state.mapSelectedIsOrigin == true) {
  //       setState(() {
  //         _currentLocationController.text = state.mapSelectedAddress!;
  //         _selectedOrigin = state.mapSelectedLocation;
  //       });
  //     } else {
  //       setState(() {
  //         _destinationController.text = state.mapSelectedAddress!;
  //         _selectedDestination = state.mapSelectedLocation;
  //       });
  //     }

  //     mapController.clearMapSelectedLocation();

  //     if (!_isLoading) {
  //       Future.delayed(const Duration(milliseconds: 300), () {
  //         if (mounted && !_isLoading) {
  //           if (_selectedOrigin != null && _selectedDestination != null) {
  //             _getRoute(_selectedOrigin, _selectedDestination!);
  //           } else if (_selectedDestination != null) {
  //             _getRoute(_selectedOrigin, _selectedDestination!);
  //           }
  //         }
  //       });
  //     }
  //   }
  // }

  final LayerLink _originLayerLink = LayerLink();
  final LayerLink _destinationLayerLink = LayerLink();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MapCubit>().state;
    var size = MediaQuery.of(context).size;
    final double responsiveWidth = size.width > 600 ? 650 : size.width;

    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: responsiveWidth * numD65,
            padding: EdgeInsets.all(responsiveWidth * numD03),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(responsiveWidth * numD04),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: responsiveWidth * numD03,
                  spreadRadius: responsiveWidth * numD002,
                  offset: Offset(0.0, 0.0),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// ------- TITLE -------
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Get Direction',
                      style: TextStyle(
                        fontSize: responsiveWidth * numD026,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F1F1F),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        context.read<MapCubit>().clearRoute();
                      },
                      child: Padding(
                        padding: EdgeInsets.all(responsiveWidth * numD01),
                        child: Icon(
                          Icons.close,
                          size: responsiveWidth * numD04,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: responsiveWidth * numD02),
                const Divider(height: size1, color: Colors.black12),
                SizedBox(height: responsiveWidth * numD025),

                /// ------- LOCATION INPUTS -------
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        Icon(
                          Icons.my_location,
                          size: responsiveWidth * numD045,
                          color: AppColors.primary,
                        ),
                        SizedBox(height: responsiveWidth * numD02),
                        dottedLine(responsiveWidth),
                        SizedBox(height: responsiveWidth * numD02),
                        Icon(
                          Icons.location_on_outlined,
                          size: responsiveWidth * numD045,
                          color: Color.fromARGB(255, 121, 121, 121),
                        ),
                      ],
                    ),
                    SizedBox(width: responsiveWidth * numD04),
                    Expanded(
                      child: Column(
                        children: [
                          CompositedTransformTarget(
                            link: _originLayerLink,
                            child: TextField(
                              controller: _currentLocationController,
                              focusNode: _currentLocationFocusNode,
                              onChanged: (value) =>
                                  _searchPlaces(value, isOrigin: true),
                              decoration: InputDecoration(
                                hintText: 'Your Location',
                                filled: true,
                                hintStyle: TextStyle(
                                  fontSize: responsiveWidth * numD03,
                                ),
                                fillColor: Colors.grey.shade100,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: responsiveWidth * numD02,
                                  horizontal: responsiveWidth * numD03,
                                ),
                                isDense: true,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    responsiveWidth * numD02,
                                  ),
                                  borderSide: BorderSide(
                                    color: Color(0xFFBDBDBD),
                                    width: size1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    responsiveWidth * numD02,
                                  ),
                                  borderSide: BorderSide(
                                    color: colorThemePink,
                                    width: size1_2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: responsiveWidth * numD03),
                          CompositedTransformTarget(
                            link: _destinationLayerLink,
                            child: TextField(
                              controller: _destinationController,
                              focusNode: _destinationFocusNode,
                              onChanged: (value) =>
                                  _searchPlaces(value, isOrigin: false),
                              decoration: InputDecoration(
                                hintText: 'Destination',
                                hintStyle: TextStyle(
                                  fontSize: responsiveWidth * numD03,
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade100,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: responsiveWidth * numD02,
                                  horizontal: responsiveWidth * numD03,
                                ),
                                isDense: true,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    responsiveWidth * numD02,
                                  ),
                                  borderSide: BorderSide(
                                    color: Color(0xFFBDBDBD),
                                    width: size1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    responsiveWidth * numD02,
                                  ),
                                  borderSide: BorderSide(
                                    color: colorThemePink,
                                    width: size1_2,
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

                SizedBox(height: responsiveWidth * numD035),

                /// ------- GO BUTTON -------
                SizedBox(
                  width: double.infinity,
                  height: responsiveWidth * numD09,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            if (_destinationController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter a destination'),
                                ),
                              );
                              return;
                            }

                            final origin = _selectedOrigin;

                            // Use selected destination or state destination
                            final destination =
                                _selectedDestination ?? state.destination;
                            if (destination != null) {
                              await _getRoute(origin, destination);
                              // Start navigation
                              context.read<MapCubit>().startNavigation();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please select a destination from the suggestions or map',
                                  ),
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      elevation: 0.0,
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          responsiveWidth * numD02,
                        ),
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: responsiveWidth * numD04,
                            height: responsiveWidth * numD04,
                            child: LoadingWidget(
                              size: responsiveWidth * numD04,
                            ),
                          )
                        : Text(
                            'GO',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: responsiveWidth * numD025,
                              letterSpacing: responsiveWidth * numD003,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),

          /// ------- POINTER TRIANGLE -------
          Positioned(
            right: responsiveWidth * numD04,
            top: -(responsiveWidth * numD02),
            child: Transform.rotate(
              angle: math.pi / 4,
              child: Container(
                width: responsiveWidth * numD055,
                height: responsiveWidth * numD055,
                color: Colors.white,
              ),
            ),
          ),

          /// ------- DROPDOWNS (On Top) -------
          if (_showCurrentLocationDropdown &&
              _currentLocationPredictions.isNotEmpty)
            CompositedTransformFollower(
              link: _originLayerLink,
              showWhenUnlinked: false,
              offset: Offset(size0, responsiveWidth * numD1),
              child: Material(
                elevation: 4.0,
                borderRadius: BorderRadius.circular(responsiveWidth * numD02),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: responsiveWidth * numD40,
                    maxWidth:
                        responsiveWidth *
                        numD50, // Match approx width of text field
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: _currentLocationPredictions.length,
                    itemBuilder: (context, index) {
                      final prediction = _currentLocationPredictions[index];
                      return InkWell(
                        onTap: () {
                          _selectPlace(
                            prediction['place_id'],
                            prediction['description'],
                            isOrigin: true,
                          );
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: responsiveWidth * numD03,
                            vertical: responsiveWidth * numD02,
                          ),
                          child: Text(
                            prediction['description'],
                            style: TextStyle(
                              fontSize: responsiveWidth * numD03,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

          if (_showDestinationDropdown && _destinationPredictions.isNotEmpty)
            CompositedTransformFollower(
              link: _destinationLayerLink,
              showWhenUnlinked: false,
              offset: Offset(size0, responsiveWidth * numD1),
              child: Material(
                elevation: 4.0,
                borderRadius: BorderRadius.circular(responsiveWidth * numD02),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: responsiveWidth * numD40,
                    maxWidth: responsiveWidth * numD50,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: _destinationPredictions.length,
                    itemBuilder: (context, index) {
                      final prediction = _destinationPredictions[index];
                      return InkWell(
                        onTap: () {
                          _selectPlace(
                            prediction['place_id'],
                            prediction['description'],
                            isOrigin: false,
                          );
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: responsiveWidth * numD03,
                            vertical: responsiveWidth * numD02,
                          ),
                          child: Text(
                            prediction['description'],
                            style: TextStyle(
                              fontSize: responsiveWidth * numD03,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

Widget dottedLine(double responsiveWidth) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Container(
        width: responsiveWidth * numD005,
        height: responsiveWidth * numD008,
        decoration: BoxDecoration(
          color: Colors.grey,

          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(responsiveWidth * numD005),
            topRight: Radius.circular(responsiveWidth * numD005),
          ), // color: Colors.grey,
        ),
      ),
      SizedBox(height: responsiveWidth * numD003),
      Container(
        width: responsiveWidth * numD005,
        height: responsiveWidth * numD015,
        color: Colors.grey,
      ),
      SizedBox(height: responsiveWidth * numD003),
      Container(
        width: responsiveWidth * numD005,
        height: responsiveWidth * numD008,
        decoration: BoxDecoration(
          color: Colors.grey,

          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(responsiveWidth * numD005),
            bottomRight: Radius.circular(responsiveWidth * numD005),
          ), // color: Colors.grey,
        ),
      ),
    ],
  );
}
