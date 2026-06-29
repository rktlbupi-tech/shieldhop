import 'package:flutter/material.dart';
import 'package:presshop_enterprise/common/widgets/app_app_bar.dart';
import '../../../../common/widgets/employee_app_bar.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';
import '../controllers/task_schedule_controller.dart';
import '../widgets/month_header.dart';
import '../widgets/week_strip.dart';
import '../widgets/calendar_grid.dart';
import '../widgets/day_schedule_timeline.dart';
import '../widgets/timeline_task_card.dart';

class TaskScheduleScreen extends StatefulWidget {
  final bool hideLeading;
  const TaskScheduleScreen({super.key, this.hideLeading = false});

  @override
  State<TaskScheduleScreen> createState() => _TaskScheduleScreenState();
}

class _TaskScheduleScreenState extends State<TaskScheduleScreen> {
  late TaskScheduleController _controller;

  late PageController _monthPageController;
  late PageController _dayPageController;
  late PageController _weekPageController;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _controller = TaskScheduleController();
    _monthPageController = PageController(
      initialPage: _controller.initialMonthPage,
    );
    _dayPageController = PageController(
      initialPage: _controller.initialDayPage,
    );
    _weekPageController = PageController(
      initialPage: _controller.initialWeekPage,
    );
    _scrollController = ScrollController();

    _controller.addListener(_onControllerChange);
  }

  void _onControllerChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChange);
    _monthPageController.dispose();
    _dayPageController.dispose();
    _weekPageController.dispose();
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: widget.hideLeading
          ? EmployeeAppBar(
              onProfileTap: () {
                final dashboardState = context
                    .findAncestorStateOfType<DashboardScreenState>();
                if (dashboardState != null) {
                  dashboardState.changeTab(4);
                }
              },
            )
          : AppAppBar(
              title: "View task",
              elevation: 0,
              centerTitle: false,
              titleSpacing: 0,
              showBack: true,
            ),
      body: Column(
        children: [
          MonthHeader(
            controller: _controller,
            monthPageController: _monthPageController,
            size: size,
          ),
          _buildWeekDayRow(size),
          const Divider(height: 1, thickness: 0.5, color: Color(0xFFE0E0E0)),
          Expanded(
            child: _controller.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1877F2)),
                  )
                : _buildCalendarBody(size),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekDayRow(Size size) {
    if (_controller.calendarFormat != 'Month') return const SizedBox.shrink();
    return Container(
      padding: EdgeInsets.symmetric(vertical: size.width * 0.015),
      child: Row(
        children: TaskScheduleController.weekDays.map((day) {
          final isSat = day == 'Sat';
          final isSun = day == 'Sun';
          return Expanded(
            child: Center(
              child: Text(
                day,
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isSat || isSun
                      ? Colors.grey.shade300
                      : Colors.grey.shade500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCalendarBody(Size size) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _controller.calendarFormat == 'Month'
          ? Column(
              children: [
                SizedBox(
                  height: size.height * 0.32,
                  child: CalendarGrid(
                    key: const ValueKey('MonthView'),
                    controller: _controller,
                    monthPageController: _monthPageController,
                    size: size,
                  ),
                ),
                _buildTaskListHeader(size),
                Expanded(child: _buildIntegratedTaskList()),
              ],
            )
          : KeyedSubtree(
              key: ValueKey(
                'DayView_${_controller.selectedDay.year}_${_controller.selectedDay.month}_${_controller.selectedDay.day}',
              ),
              child: _buildTaskList(_controller.selectedDay),
            ),
    );
  }

  Widget _buildTaskListHeader(Size size) {
    final day = _controller.selectedDay;
    final String dateStr =
        "${_getWeekdayFull(day.weekday)}, ${day.day} ${TaskScheduleController.months[day.month - 1]} ${day.year}";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      color: Colors.white,
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: const Color(0xFF1877F2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            dateStr,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              fontFamily: "AirbnbCereal",
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntegratedTaskList() {
    final tasks = _controller.getTasksFor(_controller.selectedDay);
    if (tasks.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _controller.fetchTasks(showLoading: false),
        color: const Color(0xFF1877F2),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.4,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 48,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  "No tasks scheduled for this day",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                    fontFamily: "AirbnbCereal",
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _controller.fetchTasks(showLoading: false),
      color: const Color(0xFF1877F2),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          return TimelineTaskCard(task: tasks[index]);
        },
      ),
    );
  }

  String _getWeekdayFull(int weekday) {
    switch (weekday) {
      case 1:
        return "Monday";
      case 2:
        return "Tuesday";
      case 3:
        return "Wednesday";
      case 4:
        return "Thursday";
      case 5:
        return "Friday";
      case 6:
        return "Saturday";
      case 7:
        return "Sunday";
      default:
        return "";
    }
  }

  Widget _buildTaskList(DateTime startDay) {
    if (_controller.calendarFormat == 'Day') {
      return PageView.builder(
        controller: _dayPageController,
        onPageChanged: (index) {
          final newDay = startDay.add(
            Duration(days: index - _controller.initialDayPage),
          );
          _controller.updateSelectedDay(newDay);
        },
        itemBuilder: (context, index) {
          final day = startDay.add(
            Duration(days: index - _controller.initialDayPage),
          );
          final tasks = _controller.getTasksFor(day);
          return RefreshIndicator(
            onRefresh: () => _controller.fetchTasks(showLoading: false),
            color: const Color(0xFF1877F2),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: DayScheduleTimeline(
                  day: day,
                  tasks: tasks,
                  controller: _controller,
                ),
              ),
            ),
          );
        },
      );
    } else if (_controller.calendarFormat == 'Week') {
      return Column(
        children: [
          WeekStrip(
            controller: _controller,
            weekPageController: _weekPageController,
            size: MediaQuery.of(context).size,
          ),
          const Divider(height: 1, thickness: 0.5, color: Color(0xFFEEEEEE)),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _controller.fetchTasks(showLoading: false),
              color: const Color(0xFF1877F2),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: DayScheduleTimeline(
                    day: _controller.selectedDay,
                    tasks: _controller.getTasksFor(_controller.selectedDay),
                    controller: _controller,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    final List<DateTime> daysToShow = List.generate(14, (i) {
      return startDay.add(Duration(days: i));
    });

    return Container(
      color: Colors.white,
      child: RefreshIndicator(
        onRefresh: () => _controller.fetchTasks(showLoading: false),
        color: const Color(0xFF1877F2),
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: daysToShow.map((day) {
            final tasks = _controller.getTasksFor(day);
            return SliverToBoxAdapter(
              child: DayScheduleTimeline(
                day: day,
                tasks: tasks,
                controller: _controller,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
