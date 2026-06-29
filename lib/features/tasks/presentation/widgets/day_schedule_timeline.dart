import 'package:flutter/material.dart';
import '../../data/models/employee_task_model.dart';
import '../controllers/task_schedule_controller.dart';
import 'timeline_task_card.dart';

class DayScheduleTimeline extends StatelessWidget {
  final DateTime day;
  final List<ScheduleTask> tasks;
  final TaskScheduleController controller;

  const DayScheduleTimeline({
    super.key,
    required this.day,
    required this.tasks,
    required this.controller,
  });

  int _parseSlotHour(String hourStr) {
    try {
      final cleanHourStr = hourStr.split(' ')[0]; // E.g. "08:00"
      final parts = cleanHourStr.split(':');
      int hr = int.parse(parts[0]);
      if (hourStr.contains('PM') && hr != 12) {
        hr += 12;
      } else if (hourStr.contains('AM') && hr == 12) {
        hr = 0;
      }
      return hr;
    } catch (_) {}
    return 8;
  }

  int? _parseTaskStartHour(String startTime) {
    try {
      final parts = startTime.split(':');
      if (parts.isNotEmpty) {
        return int.parse(parts[0]);
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final List<String> hours = [
      "08:00 AM",
      "09:00 AM",
      "10:00 AM",
      "11:00 AM",
      "12:00 PM",
      "01:00 PM",
      "02:00 PM",
      "03:00 PM",
      "04:00 PM",
      "05:00 PM",
      "06:00 PM",
      "07:00 PM",
      "08:00 PM"
    ];

    return Column(
      children: List.generate(hours.length, (index) {
        final hour = hours[index];
        final slotHour = _parseSlotHour(hour);

        final hourTasks = tasks.where((t) {
          final startHour = _parseTaskStartHour(t.startTime);
          if (startHour == null) return false;
          if (slotHour == 8) {
            // First slot: capture everything from midnight up to 8 AM
            return startHour <= 8;
          } else if (slotHour == 20) {
            // Last slot: capture everything from 8 PM onwards
            return startHour >= 20;
          } else {
            return startHour == slotHour;
          }
        }).toList();

        final isCurrentHour = controller.isToday(day) && DateTime.now().hour == slotHour;

        return Padding(
          padding: const EdgeInsets.only(left: 2, right: 16),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 55,
                    padding: const EdgeInsets.only(right: 10, top: 4),
                    alignment: Alignment.topRight,
                    child: Text(
                      hour.split(' ')[0],
                      style: TextStyle(
                        color: isCurrentHour ? Colors.red : Colors.black,
                        fontSize: 12,
                        fontWeight: isCurrentHour ? FontWeight.bold : FontWeight.w400,
                        fontFamily: "AirbnbCereal",
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: isCurrentHour ? Colors.red.withOpacity(0.5) : const Color(0xFFF5F5F5),
                        ),
                        if (hourTasks.isNotEmpty)
                          ...hourTasks.map((task) => TimelineTaskCard(task: task))
                        else
                          const SizedBox(height: 50),
                      ],
                    ),
                  ),
                ],
              ),
              if (isCurrentHour)
                Positioned(
                  top: 0,
                  left: 45,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      "NOW",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        fontFamily: "AirbnbCereal",
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}
