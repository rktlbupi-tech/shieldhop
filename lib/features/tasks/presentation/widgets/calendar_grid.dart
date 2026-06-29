import 'package:flutter/material.dart';
import '../controllers/task_schedule_controller.dart';
import '../../data/models/employee_task_model.dart';

class CalendarGrid extends StatelessWidget {
  final TaskScheduleController controller;
  final PageController monthPageController;
  final Size size;

  const CalendarGrid({
    super.key,
    required this.controller,
    required this.monthPageController,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: monthPageController,
      onPageChanged: (page) {
        controller.updateFocusedMonth(controller.getMonthForPage(page));
      },
      itemBuilder: (context, page) {
        final month = controller.getMonthForPage(page);
        final cells = _buildCalendarGrid(month);
        const int rows = 6;
        const int cols = 7;

        return Column(
          children: List.generate(rows, (row) {
            return Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(cols, (col) {
                  final idx = row * cols + col;
                  final day = cells[idx];
                  return _buildDayCell(context, day, size, col);
                }),
              ),
            );
          }),
        );
      },
    );
  }

  List<DateTime> _buildCalendarGrid(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    int startOffset = firstDay.weekday - 1;
    final int daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    List<DateTime> cells = [];
    final prevMonth = DateTime(month.year, month.month - 1, 1);
    final prevDays = DateUtils.getDaysInMonth(prevMonth.year, prevMonth.month);
    for (int i = startOffset - 1; i >= 0; i--) {
      cells.add(DateTime(prevMonth.year, prevMonth.month, prevDays - i));
    }
    for (int d = 1; d <= daysInMonth; d++) {
      cells.add(DateTime(month.year, month.month, d));
    }
    final nextMonth = DateTime(month.year, month.month + 1, 1);
    int nextDay = 1;
    while (cells.length < 42) {
      cells.add(DateTime(nextMonth.year, nextMonth.month, nextDay++));
    }
    return cells;
  }

  Widget _buildDayCell(BuildContext context, DateTime day, Size size, int colIndex) {
    final bool isCurrentMonth = day.month == controller.focusedMonth.month;
    final bool isSelected = controller.isSameDay(day, controller.selectedDay);
    final bool isWeekend = colIndex == 5 || colIndex == 6;
    final List<ScheduleTask> tasks = controller.getTasksFor(day);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          controller.updateSelectedDay(day);
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.grey.shade100, width: 0.5),
            ),
            color: isSelected ? const Color(0xFF1877F2).withOpacity(0.05) : Colors.transparent,
          ),
          child: Column(
            children: [
              const SizedBox(height: 4),
              isSelected
                  ? Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1877F2), // Brand primary blue
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${day.day}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            fontFamily: "AirbnbCereal",
                          ),
                        ),
                      ),
                    )
                  : Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: day.day == 1 ? FontWeight.bold : FontWeight.w500,
                        fontFamily: "AirbnbCereal",
                        color: !isCurrentMonth
                            ? Colors.grey.shade300
                            : isWeekend
                                ? Colors.grey.shade400
                                : Colors.black87,
                      ),
                    ),
              const SizedBox(height: 4),
              if (tasks.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: tasks.take(4).map((t) {
                    return Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: t.color,
                        shape: BoxShape.circle,
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
