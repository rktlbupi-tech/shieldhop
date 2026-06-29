import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import '../../../../common/widgets/app_app_bar.dart';
import '../../../../common/widgets/empty_state.dart';
import '../../../../common/widgets/loading_widget.dart';
import '../../../../config/di/injection.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/leave_entities.dart';
import '../bloc/leave_cubits.dart';

String _ym(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';

class LeaveCalendarScreen extends StatelessWidget {
  const LeaveCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<LeaveCalendarCubit>()..load(_ym(DateTime.now())),
      child: const _CalendarView(),
    );
  }
}

class _CalendarView extends StatelessWidget {
  const _CalendarView();

  DateTime _parse(String ym) {
    final p = ym.split('-');
    return DateTime(int.parse(p[0]), int.parse(p[1]));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: const AppAppBar(title: 'Leave calendar', showBack: true),
      body: SafeArea(
        child: BlocBuilder<LeaveCalendarCubit, LeaveCalendarState>(
          builder: (context, state) {
            final cubit = context.read<LeaveCalendarCubit>();
            final month = _parse(state.month);
            return Column(
              children: [
                // Month switcher
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => cubit.load(_ym(
                            DateTime(month.year, month.month - 1))),
                      ),
                      Text(
                        DateFormat('MMMM yyyy').format(month),
                        style: const TextStyle(
                            fontFamily: 'AirbnbCereal',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () => cubit.load(_ym(
                            DateTime(month.year, month.month + 1))),
                      ),
                    ],
                  ),
                ),
                Expanded(child: _body(context, state)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _body(BuildContext context, LeaveCalendarState state) {
    if (state.loading) return const Center(child: LoadingWidget());
    if (state.error != null && state.calendar == null) {
      return EmptyState(
        icon: Icons.error_outline,
        title: state.error!,
        buttonLabel: 'Retry',
        onButtonTap: () => context.read<LeaveCalendarCubit>().load(state.month),
      );
    }
    final cal = state.calendar;
    final holidays = cal?.holidays ?? const <LeaveHoliday>[];
    final onLeave = cal?.onLeave ?? const <LeaveOnLeave>[];

    if (holidays.isEmpty && onLeave.isEmpty) {
      return const EmptyState(
          icon: Icons.event_available,
          title: 'No holidays or leave this month');
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        if (holidays.isNotEmpty) ...[
          _header(LucideIcons.party_popper, 'Holidays'),
          const SizedBox(height: 8),
          ...holidays.map(_holidayTile),
          const SizedBox(height: 18),
        ],
        _header(LucideIcons.users, 'On leave this month'),
        const SizedBox(height: 8),
        if (onLeave.isEmpty)
          Text('Nobody on leave',
              style: TextStyle(
                  fontFamily: 'AirbnbCereal',
                  fontSize: 13,
                  color: Colors.grey.shade500))
        else
          ...onLeave.map(_onLeaveTile),
      ],
    );
  }

  Widget _header(IconData icon, String title) => Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  fontFamily: 'AirbnbCereal',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
        ],
      );

  Widget _holidayTile(LeaveHoliday h) {
    final d = h.date;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.calendar_heart,
              size: 18, color: Color(0xFFEC4899)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(h.name,
                style: const TextStyle(
                    fontFamily: 'AirbnbCereal',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87)),
          ),
          Text(d != null ? DateFormat('EEE, dd MMM').format(d) : '',
              style: TextStyle(
                  fontFamily: 'AirbnbCereal',
                  fontSize: 12,
                  color: Colors.grey.shade600)),
          if (h.optional)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text('(optional)',
                  style: TextStyle(
                      fontFamily: 'AirbnbCereal',
                      fontSize: 10,
                      color: Colors.grey.shade400)),
            ),
        ],
      ),
    );
  }

  Widget _onLeaveTile(LeaveOnLeave o) {
    final c = leaveColor(o.color);
    final range = (o.from != null && o.to != null)
        ? '${DateFormat('dd MMM').format(o.from!)} – ${DateFormat('dd MMM').format(o.to!)}'
        : '';
    final initials = o.workerName.isEmpty
        ? '?'
        : o.workerName.trim().split(RegExp(r'\s+')).map((p) => p[0]).take(2).join().toUpperCase();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: c.withValues(alpha: 0.15),
            backgroundImage: (o.workerAvatarUrl != null &&
                    o.workerAvatarUrl!.isNotEmpty)
                ? NetworkImage(o.workerAvatarUrl!)
                : null,
            child: (o.workerAvatarUrl == null || o.workerAvatarUrl!.isEmpty)
                ? Text(initials,
                    style: TextStyle(
                        fontFamily: 'AirbnbCereal',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: c))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(o.workerName,
                    style: const TextStyle(
                        fontFamily: 'AirbnbCereal',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(width: 7, height: 7, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(
                      '${o.leaveTypeCode}${o.halfDay != 'none' ? ' · half day' : ''}',
                      style: TextStyle(
                          fontFamily: 'AirbnbCereal',
                          fontSize: 11.5,
                          color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(range,
              style: TextStyle(
                  fontFamily: 'AirbnbCereal',
                  fontSize: 11.5,
                  color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}
