import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:presshop_enterprise/core/constants/app_colors.dart';
import 'package:presshop_enterprise/features/map/core/map_constants.dart';

class AlertButtonMapForEmployee extends StatelessWidget {
  const AlertButtonMapForEmployee({super.key});

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    final double responsiveWidth = size.width > 600 ? 650 : size.width;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(size200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: responsiveWidth * numD01,
            offset: Offset(size0, responsiveWidth * numD005),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(size100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              LucideIcons.triangle_alert,
              color: Colors.white,
              size: 18,
            ),
          ),
          Expanded(
            child: Text(
              "Share Alerts",
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.black87,
                fontSize: responsiveWidth * numD032,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
