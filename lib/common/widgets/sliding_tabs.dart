import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class SlidingTabs extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;
  final List<String> tabs;
  final double height;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color? indicatorColor;
  final Color? activeTextColor;
  final Color? inactiveTextColor;
  final double fontSize;

  const SlidingTabs({
    super.key,
    required this.selectedIndex,
    required this.onTabChanged,
    required this.tabs,
    this.height = 52.0,
    this.margin,
    this.backgroundColor,
    this.indicatorColor,
    this.activeTextColor,
    this.inactiveTextColor,
    this.fontSize = 14.0,
  }) : assert(
         tabs.length == 2,
         'SlidingTabs currently supports exactly 2 tabs.',
       );

  @override
  Widget build(BuildContext context) {
    final themeIndicatorColor = indicatorColor ?? AppColors.primary;
    final themeBackgroundColor = backgroundColor ?? Colors.grey[100];

    return Container(
      margin: margin,
      height: height,
      decoration: BoxDecoration(
        color: themeBackgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          // Sliding indicator
          AnimatedAlign(
            alignment: selectedIndex == 1
                ? Alignment.centerRight
                : Alignment.centerLeft,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: themeIndicatorColor,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          // Tab options
          Row(
            children: List.generate(tabs.length, (index) {
              final isSelected = selectedIndex == index;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTabChanged(index),
                  child: Container(
                    color: Colors.transparent,
                    alignment: Alignment.center,
                    child: Text(
                      tabs[index],
                      style: TextStyle(
                        color: isSelected
                            ? (activeTextColor ?? Colors.white)
                            : (inactiveTextColor ?? Colors.grey.shade600),
                        fontWeight: FontWeight.bold,
                        fontSize: fontSize,
                        fontFamily: 'AirbnbCereal',
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
