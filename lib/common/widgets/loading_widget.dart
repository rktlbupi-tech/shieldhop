import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LoadingWidget extends StatelessWidget {
  final double? size;
  const LoadingWidget({super.key, this.size});

  @override
  Widget build(BuildContext context) {
    final s = size ?? 100.w;
    return Center(
      child: Lottie.asset(
        'assets/animations/loader_new.json',
        width: s,
        height: s,
        fit: BoxFit.contain,
      ),
    );
  }
}
