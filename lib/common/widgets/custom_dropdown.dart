import 'package:flutter/material.dart';

class CustomDropdown<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final Widget Function(T, bool) itemBuilder; // Item widget builder, passes item and selected state
  final ValueChanged<T> onChanged;
  final Widget? icon;
  final Color? buttonColor;
  final double? buttonWidth;
  final double? width;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;
  final BoxBorder? border;

  const CustomDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.itemBuilder,
    required this.onChanged,
    this.icon,
    this.buttonColor,
    this.buttonWidth,
    this.width,
    this.borderRadius,
    this.padding,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: PopupMenuButton<T>(
        initialValue: value,
        onSelected: onChanged,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        color: Colors.white,
        elevation: 8,
        offset: const Offset(0, 38),
        padding: EdgeInsets.zero,
        itemBuilder: (BuildContext context) {
          return items.map((T item) {
            final isSelected = item == value;
            return PopupMenuItem<T>(
              value: item,
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Container(
                width: buttonWidth ?? 110,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.grey.shade200 : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: itemBuilder(item, isSelected),
              ),
            );
          }).toList();
        },
        child: Container(
          width: width,
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: buttonColor ?? Colors.white,
            borderRadius: BorderRadius.circular(borderRadius ?? 8),
            border: border ?? Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
          ),
          child: Row(
            mainAxisSize: width != null ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (width != null)
                Expanded(child: itemBuilder(value, false))
              else
                itemBuilder(value, false),
              const SizedBox(width: 8),
              icon ?? const Icon(
                Icons.keyboard_arrow_down,
                color: Color(0xFF64748B),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
