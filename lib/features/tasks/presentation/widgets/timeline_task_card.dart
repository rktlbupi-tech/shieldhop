import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/employee_task_model.dart';

class TimelineTaskCard extends StatelessWidget {
  final ScheduleTask task;

  const TimelineTaskCard({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    Color bgColor = task.color.withOpacity(0.05);
    Color accentColor = task.color;
    final size = MediaQuery.sizeOf(context);

    String to12HourFormat(String timeStr) {
      try {
        final parts = timeStr.split(':');
        if (parts.length >= 2) {
          int hour = int.parse(parts[0]);
          int minute = int.parse(parts[1]);
          String ampm = hour >= 12 ? 'PM' : 'AM';
          int displayHour = hour % 12;
          if (displayHour == 0) {
            displayHour = 12;
          }
          String hourStr = displayHour.toString().padLeft(2, '0');
          String minuteStr = minute.toString().padLeft(2, '0');
          return "$hourStr:$minuteStr $ampm";
        }
      } catch (_) {}
      return timeStr;
    }

    return GestureDetector(
      onTap: () {
        context.push('/task-details/${task.id}');
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 4.5,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontFamily: "AirbnbCereal",
                          fontWeight: FontWeight.bold,
                          fontSize: size.width * 0.033,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${to12HourFormat(task.startTime)} - ${to12HourFormat(task.endTime)}",
                        style: TextStyle(
                          fontFamily: "AirbnbCereal",
                          fontWeight: FontWeight.w400,
                          fontSize: size.width * 0.028,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Image.asset(
                            "assets/icons/ic_location.png",
                            height: size.width * 0.028,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              task.location,
                              style: TextStyle(
                                fontFamily: "AirbnbCereal",
                                fontWeight: FontWeight.w400,
                                fontSize: size.width * 0.028,
                                color: Colors.grey.shade500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 18),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child:
                        (task.mediaHouseLogo != null &&
                            task.mediaHouseLogo!.isNotEmpty)
                        ? Image.network(
                            task.mediaHouseLogo!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.business,
                                  size: 20,
                                  color: Colors.grey,
                                ),
                          )
                        : const Icon(
                            Icons.business,
                            size: 20,
                            color: Colors.grey,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
