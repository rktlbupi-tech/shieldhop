import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:presshop_enterprise/core/constants/app_colors.dart';
import 'package:presshop_enterprise/features/map/core/map_constants.dart';

final List<FilterOption> employeeAlertOptions = [
  const FilterOption(label: 'Alerts', value: ''),
  ...alertOptions.map((e) => FilterOption(label: e.label, value: e.value)),
];

class SearchAndFilterBar extends StatelessWidget {
  final VoidCallback? onPressedOnNavigation;
  final Function(String)? onChange;
  final TextEditingController? searchController;
  final FocusNode? searchFocusNode;
  final String? selectedAlertType;
  final String? selectedDistance;
  final String? selectedCategory;
  final Function(String?)? onAlertTypeChanged;
  final Function(String?)? onDistanceChanged;
  final Function(String?)? onCategoryChanged;
  final bool isNewsPage;
  final bool isFromEmployeeMap;

  const SearchAndFilterBar({
    super.key,
    this.onPressedOnNavigation,
    this.onChange,
    this.searchController,
    this.searchFocusNode,
    this.selectedAlertType,
    this.selectedDistance,
    this.selectedCategory,
    this.onAlertTypeChanged,
    this.onDistanceChanged,
    this.onCategoryChanged,
    this.isNewsPage = false,
    this.isFromEmployeeMap = false,
  });

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    final double responsiveWidth = size.width > 600 ? 500 : size.width;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: responsiveWidth * numD04,
            right: responsiveWidth * numD04,
            top: 2,
            bottom: 6,
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 3,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBDBDBD)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: searchController,
                          focusNode: searchFocusNode,
                          onChanged: onChange,
                          decoration: const InputDecoration(
                            hintText: "Search any location",
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 12,
                            ),
                            isDense: true,
                          ),
                        ),
                      ),
                      Container(
                        width: 35,
                        height: 35,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.search,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isNewsPage) ...[
                const SizedBox(width: 10),
                PopupMenuButton<String>(
                  onSelected: onCategoryChanged,
                  offset: const Offset(0, 45),
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    // child: const Icon(
                    //   Icons.filter_list,
                    //   color: Colors.white,
                    //   size: 24,
                    //   weight: 700,
                    // ),
                    child: Center(
                      child: Image.asset(
                        "assets/icons/switch_160258851.png",
                        color: Colors.white,
                        width: 20,
                        height: 20,
                      ),
                    ),
                  ),
                  itemBuilder: (context) {
                    return categoryOptions.map((e) {
                      return PopupMenuItem<String>(
                        value: e.value,
                        child: Text(e.label),
                      );
                    }).toList();
                  },
                ),
              ] else if (onPressedOnNavigation != null) ...[
                const SizedBox(width: 10),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(
                      LucideIcons.corner_up_right,
                      color: Colors.white,
                    ),
                    onPressed: onPressedOnNavigation,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (!isNewsPage && !isFromEmployeeMap)
          Padding(
            padding: EdgeInsets.only(
              left: responsiveWidth * numD04,
              right: responsiveWidth * numD04,
              bottom: 6,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: FilterDropdown(
                          items: alertOptions,
                          selected: selectedAlertType ?? 'Alert',
                          onChanged: onAlertTypeChanged,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: FilterDropdown(
                          items: radiusOptions,
                          selected: selectedDistance ?? '5 miles',
                          onChanged: onDistanceChanged,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: FilterDropdown(
                          items: categoryOptions,
                          selected: selectedCategory ?? 'Category',
                          onChanged: onCategoryChanged,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        // if (isFromEmployeeMap)
        //   Padding(
        //     padding: EdgeInsets.only(
        //       left: responsiveWidth * numD04,
        //       right: responsiveWidth * numD04,
        //       bottom: 6,
        //     ),
        //     child: Row(
        //       children: [
        //         Expanded(
        //           child: Row(
        //             children: [
        //               Expanded(
        //                 child: FilterDropdown(
        //                   items: radiusOptions,
        //                   selected: selectedDistance ?? '5 miles',
        //                   onChanged: onDistanceChanged,
        //                 ),
        //               ),
        //               const SizedBox(width: 6),
        //               Expanded(
        //                 child: FilterDropdown(
        //                   items: employeeAlertOptions,
        //                   selected: selectedAlertType ?? '',
        //                   onChanged: onAlertTypeChanged,
        //                 ),
        //               ),
        //             ],
        //           ),
        //         ),
        //       ],
        //     ),
        //   ),
      ],
    );
  }
}

class FilterDropdown extends StatelessWidget {
  final List<FilterOption> items;
  final String selected;
  final Function(String?)? onChanged;

  const FilterDropdown({
    super.key,
    required this.items,
    required this.selected,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selectedItem = items.firstWhere(
      (element) => element.value == selected || element.label == selected,
      orElse: () => items.first,
    );
    final effectiveSelected = selectedItem.value;

    return Theme(
      data: Theme.of(context).copyWith(
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: PopupMenuButton<String>(
        offset: const Offset(0, 38),
        color: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.grey.shade300, width: 0.5),
        ),
        onSelected: onChanged,
        itemBuilder: (BuildContext context) {
          return items.map((e) {
            final isSelected = e.value == effectiveSelected;
            return PopupMenuItem<String>(
              value: e.value,
              height: 40,
              padding: EdgeInsets.zero,
              child: Container(
                width: double.infinity,
                height: 40,
                color: isSelected
                    ? const Color(0xFFE0E0E0)
                    : Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.centerLeft,
                child: Text(
                  e.label,
                  style: TextStyle(
                    fontSize: 14,
                    color: isSelected ? Colors.black87 : Colors.black87,
                    fontWeight: isSelected
                        ? FontWeight.w500
                        : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList();
        },
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade400, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  selectedItem.label,
                  style: const TextStyle(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const Icon(Icons.arrow_drop_down, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
