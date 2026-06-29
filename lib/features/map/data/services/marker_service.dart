import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image/image.dart' as img;

class MarkerService {
  Future<BitmapDescriptor> bitmapFromIncidentAsset(
    String assetPath,
    int width,
  ) async {
    try {
      final byteData = await rootBundle.load(assetPath);
      final bytes = byteData.buffer.asUint8List();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return BitmapDescriptor.defaultMarker;
      final resized = img.copyResize(decoded, width: width);
      return BitmapDescriptor.fromBytes(
        Uint8List.fromList(img.encodePng(resized)),
      );
    } catch (e) {
      if (assetPath != 'assets/markers/marker-icons/no-marker.webp') {
        return bitmapFromIncidentAsset(
            'assets/markers/marker-icons/no-marker.webp', width);
      }
      return BitmapDescriptor.defaultMarker;
    }
  }
}
