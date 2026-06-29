import 'package:flutter/material.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../controllers/task_schedule_controller.dart';

class WeekStrip extends StatelessWidget {
  final TaskScheduleController controller;
  final PageController weekPageController;
  final Size size;

  const WeekStrip({
    super.key,
    required this.controller,
    required this.weekPageController,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 84,
      color: Colors.white,
      child: PageView.builder(
        controller: weekPageController,
        onPageChanged: (index) {},
        itemBuilder: (context, index) {
          final weekOffset = index - controller.initialWeekPage;
          final mondayOfThisWeek = DateTime.now()
              .subtract(Duration(days: DateTime.now().weekday - 1))
              .add(Duration(days: weekOffset * 7));

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (i) {
              final day = mondayOfThisWeek.add(Duration(days: i));
              final isSelected = controller.isSameDay(day, controller.selectedDay);
              final isToday = controller.isToday(day);
              final isSatOrSun = i == 5 || i == 6;

              return GestureDetector(
                onTap: () {
                  controller.updateSelectedDay(day);
                },
                child: Container(
                  width: size.width / 8.5,
                  margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF1877F2) : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        TaskScheduleController.weekDays[i],
                        style: AppTextStyles.caption.copyWith(
                          color: isSelected
                              ? Colors.white.withOpacity(0.85)
                              : isSatOrSun
                                  ? Colors.grey.shade300
                                  : Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "${day.day}",
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: isSelected
                              ? Colors.white
                              : isToday
                                  ? const Color(0xFF1877F2)
                                  : Colors.black,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: (isToday && !isSelected)
                              ? const Color(0xFF1877F2)
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
