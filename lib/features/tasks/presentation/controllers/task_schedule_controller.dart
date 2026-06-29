import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../config/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/employee_task_model.dart';

class TaskScheduleController extends ChangeNotifier {
  late DateTime focusedMonth;
  late DateTime selectedDay;
  String calendarFormat = 'Day';
  List<ScheduleTask> allTasks = [];
  bool isLoading = false;

  // PageView indices
  final int initialMonthPage = 1200;
  final int initialDayPage = 5000;
  final int initialWeekPage = 1000;

  static const List<String> weekDays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun'
  ];

  static const List<String> months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  TaskScheduleController() {
    focusedMonth = DateTime.now();
    selectedDay = DateTime.now();
    fetchTasks();
  }

  Future<void> fetchTasks({bool showLoading = true}) async {
    if (showLoading) {
      isLoading = true;
      notifyListeners();
    }

    // Calculate start and end of current focused month
    final firstDay = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final lastDay = DateTime(focusedMonth.year, focusedMonth.month + 1, 0);

    try {
      final client = getIt<ApiClient>();
      final response = await client.get(
        'enterprise/tasks',
        queryParameters: {
          'page': 1,
          'limit': 100,
          'sortBy': 'createdAt',
          'sortOrder': 'desc',
          'scheduledFor_gte': DateFormat('yyyy-MM-dd').format(firstDay),
          'scheduledFor_lte': DateFormat('yyyy-MM-dd').format(lastDay),
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final parsed = GetTasksResponseModel.fromJson(response.data as Map<String, dynamic>);
        allTasks = parsed.data.map((task) => _mapToScheduleTask(task)).toList();
      } else {
        allTasks = [];
      }
    } catch (e) {
      allTasks = [];
    }

    if (showLoading) {
      isLoading = false;
    }
    notifyListeners();
  }

  ScheduleTask _mapToScheduleTask(EmployeeTaskModel task) {
    DateTime taskDate = DateTime.now();
    if (task.scheduledFor != null) {
      taskDate = DateTime.parse(task.scheduledFor!);
    } else if (task.createdAt.isNotEmpty) {
      taskDate = DateTime.parse(task.createdAt);
    }

    bool isExpired = false;
    if (task.dueAt != null) {
      try {
        final dueTime = DateTime.parse(task.dueAt!);
        if (dueTime.isBefore(DateTime.now())) {
          isExpired = true;
        }
      } catch (_) {}
    }

    final bool isCompletedOrClosed =
        ['completed', 'closed', 'rejected'].contains(task.status.toLowerCase());

    return ScheduleTask(
      id: task.id,
      startTime: task.scheduledFor != null
          ? DateFormat('HH:mm').format(DateTime.parse(task.scheduledFor!))
          : "00:00",
      endTime: task.dueAt != null
          ? DateFormat('HH:mm').format(DateTime.parse(task.dueAt!))
          : "23:59",
      title: task.title,
      location: task.taskDestination?.label ??
          task.taskDestination?.address.city ??
          "Location unknown",
      tag: task.status.toUpperCase(),
      date: taskDate,
      color: (isExpired || isCompletedOrClosed)
          ? const Color(0xFF94A3B8)
          : _getPriorityColor(task.priority),
      mediaHouseLogo: (task.creatorSummary?.profileImage != null &&
              task.creatorSummary!.profileImage.isNotEmpty)
          ? task.creatorSummary!.profileImage
          : null,
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical':
        return const Color(0xFF1877F2); // match primary brand blue
      case 'high':
        return const Color(0xFF1877F2);
      case 'medium':
        return const Color(0xFF1877F2);
      default:
        return const Color(0xFF1877F2);
    }
  }

  void updateCalendarFormat(String format) {
    calendarFormat = format;
    notifyListeners();
  }

  void updateSelectedDay(DateTime day) {
    bool monthChanged =
        day.month != selectedDay.month || day.year != selectedDay.year;
    selectedDay = day;
    focusedMonth = DateTime(day.year, day.month, 1);

    if (monthChanged) {
      fetchTasks();
    } else {
      notifyListeners();
    }
  }

  void updateFocusedMonth(DateTime month) {
    if (month.month != focusedMonth.month || month.year != focusedMonth.year) {
      focusedMonth = month;
      fetchTasks();
    }
  }

  List<ScheduleTask> getTasksFor(DateTime day) {
    return allTasks.where((t) => isSameDay(t.date, day)).toList();
  }

  bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool isToday(DateTime d) => isSameDay(d, DateTime.now());

  String get monthLabel =>
      '${months[focusedMonth.month - 1]} ${focusedMonth.year}';

  DateTime getMonthForPage(int page) {
    final int offset = page - initialMonthPage;
    return DateTime(DateTime.now().year, DateTime.now().month + offset, 1);
  }

  void previousMonth(PageController monthPageController) {
    if (calendarFormat == 'Month') {
      monthPageController.previousPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      updateSelectedDay(
          DateTime(selectedDay.year, selectedDay.month - 1, selectedDay.day));
    }
  }

  void nextMonth(PageController monthPageController) {
    if (calendarFormat == 'Month') {
      monthPageController.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      updateSelectedDay(
          DateTime(selectedDay.year, selectedDay.month + 1, selectedDay.day));
    }
  }
}
