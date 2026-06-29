import 'package:flutter/material.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../controllers/task_schedule_controller.dart';

class MonthHeader extends StatelessWidget {
  final TaskScheduleController controller;
  final PageController monthPageController;
  final Size size;

  const MonthHeader({
    super.key,
    required this.controller,
    required this.monthPageController,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        size.width * 0.045,
        size.width * 0.02,
        size.width * 0.045,
        size.width * 0.015,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (controller.calendarFormat == 'Month') ...[
            Text(
              controller.monthLabel,
              style: AppTextStyles.h4.copyWith(
                color: const Color(0xFF1877F2), // Brand primary blue
                fontWeight: FontWeight.w800,
              ),
            ),
          ] else ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "${controller.selectedDay.day} ${TaskScheduleController.months[controller.selectedDay.month - 1]} ${controller.selectedDay.year}",
                  style: AppTextStyles.h4.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  "${controller.getTasksFor(controller.selectedDay).length} tasks scheduled",
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ],
          const Spacer(),
          PopupMenuButton<String>(
            onSelected: (String newValue) {
              controller.updateCalendarFormat(newValue);
            },
            offset: const Offset(0, 40),
            elevation: 4,
            shadowColor: Colors.black12,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F4F7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    controller.calendarFormat,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      fontFamily: "AirbnbCereal",
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                    color: Colors.black45,
                  ),
                ],
              ),
            ),
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              _buildPopupItem("Day", Icons.calendar_view_day),
              _buildPopupItem("Week", Icons.calendar_view_week),
              _buildPopupItem("Month", Icons.calendar_month),
            ],
          ),
          const SizedBox(width: 14),
          _chevron(
            Icons.chevron_left,
            () => controller.previousMonth(monthPageController),
          ),
          const SizedBox(width: 6),
          _chevron(
            Icons.chevron_right,
            () => controller.nextMonth(monthPageController),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildPopupItem(String value, IconData icon) {
    bool isSelected = controller.calendarFormat == value;
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected ? const Color(0xFF1877F2) : Colors.grey,
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontFamily: "AirbnbCereal",
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? const Color(0xFF1877F2) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chevron(IconData icon, VoidCallback onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Padding(
      padding: const EdgeInsets.all(4),
      child: Icon(icon, color: Colors.grey.shade400, size: 24),
    ),
  );
}
