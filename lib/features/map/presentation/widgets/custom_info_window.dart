library custom_info_window;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CustomInfoWindowController {
  Function(Widget, LatLng, [double, double, double])? addInfoWindow;
  VoidCallback? onCameraMove;
  VoidCallback? hideInfoWindow;
  VoidCallback? showInfoWindow;
  GoogleMapController? googleMapController;

  void dispose() {
    addInfoWindow = null;
    onCameraMove = null;
    hideInfoWindow = null;
    showInfoWindow = null;
    googleMapController = null;
  }
}

class CustomInfoWindow extends StatefulWidget {
  final CustomInfoWindowController controller;
  final double height;
  final double width;
  final double offset;
  final Function(double top, double left, double width, double height)?
      onChange;

  const CustomInfoWindow({
    super.key,
    required this.controller,
    this.height = 50,
    this.width = 100,
    this.offset = 0,
    this.onChange,
  });

  @override
  State<CustomInfoWindow> createState() => _CustomInfoWindowState();
}

class _CustomInfoWindowState extends State<CustomInfoWindow> {
  bool _showNow = false;
  double _leftMargin = 0;
  double _topMargin = 0;
  Widget? _child;
  LatLng? _latLng;
  double? _offset;
  double? _height;
  double? _width;

  @override
  void initState() {
    super.initState();
    widget.controller.addInfoWindow = _addInfoWindow;
    widget.controller.onCameraMove = _onCameraMove;
    widget.controller.hideInfoWindow = _hideInfoWindow;
    widget.controller.showInfoWindow = _showInfoWindow;
  }

  Future<void> _updateInfoWindow() async {
    if (_latLng == null ||
        _child == null ||
        _height == null ||
        _width == null ||
        widget.controller.googleMapController == null) return;
    if (!mounted) return;
    try {
      final screenCoordinate = await widget
          .controller.googleMapController!
          .getScreenCoordinate(_latLng!);
      if (!mounted) return;
      final dpr = Theme.of(context).platform == TargetPlatform.android
          ? MediaQuery.of(context).devicePixelRatio
          : 1.0;
      final left =
          (screenCoordinate.x.toDouble() / dpr) - (_width! / 2);
      final top = (screenCoordinate.y.toDouble() / dpr) -
          ((_offset ?? 0) + _height!);
      setState(() {
        _showNow = true;
        _leftMargin = left;
        _topMargin = top;
      });
      widget.onChange?.call(top, left, _width!, _height!);
    } catch (e) {
      debugPrint('CustomInfoWindow error: $e');
    }
  }

  void _addInfoWindow(Widget child, LatLng latLng,
      [double offset = 0, double height = 50, double width = 100]) {
    _child = child;
    _latLng = latLng;
    _offset = offset == 0 && widget.offset != 0 ? widget.offset : offset;
    _height = height == 50 && widget.height != 50 ? widget.height : height;
    _width = width == 100 && widget.width != 100 ? widget.width : width;
    _updateInfoWindow();
  }

  void _onCameraMove() {
    if (!_showNow || !mounted) return;
    _updateInfoWindow();
  }

  void _hideInfoWindow() {
    if (mounted) setState(() => _showNow = false);
  }

  void _showInfoWindow() {
    if (mounted) _updateInfoWindow();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _leftMargin,
      top: _topMargin,
      child: Visibility(
        visible: _showNow &&
            (_leftMargin != 0 || _topMargin != 0) &&
            _child != null &&
            _latLng != null,
        child: SizedBox(
          height: _height,
          width: _width,
          child: _child,
        ),
      ),
    );
  }
}
