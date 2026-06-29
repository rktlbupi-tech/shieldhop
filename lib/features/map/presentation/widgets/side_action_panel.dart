import 'package:flutter/material.dart';
import 'package:presshop_enterprise/core/constants/app_colors.dart';

class SideActionPanel extends StatelessWidget {
  final VoidCallback? onCurrentLocation;
  final VoidCallback? onZoomIn;
  final VoidCallback? onZoomOut;

  const SideActionPanel({
    super.key,
    this.onCurrentLocation,
    this.onZoomIn,
    this.onZoomOut,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(w * 0.025),
            border: Border.all(color: const Color(0xFFBDBDBD)),
          ),
          child: _buildButton(Icons.my_location_sharp, onCurrentLocation, w),
        ),
        SizedBox(height: w * 0.025),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(w * 0.025),
            border: Border.all(color: const Color(0xFFBDBDBD)),
          ),
          child: Column(
            children: [
              _buildButton(Icons.add, onZoomIn, w),
              Divider(height: 0.5, thickness: 0.5, color: Color(0xFFBDBDBD)),
              _buildButton(Icons.remove, onZoomOut, w),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildButton(IconData icon, VoidCallback? onPressed, double w) {
    return SizedBox(
      width: w * 0.1,
      height: w * 0.1,
      child: IconButton(
        icon: Icon(icon, size: w * 0.05, color: AppColors.primary),
        onPressed: onPressed,
      ),
    );
  }
}
