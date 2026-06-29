import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:presshop_enterprise/features/map/core/map_constants.dart';


class MessageButtonForMap extends StatelessWidget {
  const MessageButtonForMap({super.key});

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
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Team Chat",
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
          Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: true
                  ? colorEmployeeGreen1
                  : colorThemePink,
              borderRadius: BorderRadius.circular(size100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Image.asset(
              "assets/icons/ic_chat6.png",
              color: Colors.white,
              height: 18,
              width: 18,
            ),
          ),
        ],
      ),
    );
  }
}
