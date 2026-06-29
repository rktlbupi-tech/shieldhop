// Leave hub — My Requests list + balances strip + entry points to Apply,
// Balances and Calendar. Wired to the real Leave API.

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
import 'leave_apply_screen.dart';
import 'leave_balances_screen.dart';
import 'leave_calendar_screen.dart';
import 'leave_request_detail_screen.dart';

// ── shared status helpers ───────────────────────────────────────────────────
({String label, Color color, Color bg}) leaveStatusVisual(String status) {
  switch (status) {
    case 'approved':
      return (
        label: 'Approved',
        color: const Color(0xFF10B981),
        bg: const Color(0xFFE6F9F2)
      );
    case 'rejected':
      return (
        label: 'Rejected',
        color: const Color(0xFFEF4444),
        bg: const Color(0xFFFEE2E2)
      );
    case 'cancelled':
      return (
        label: 'Cancelled',
        color: const Color(0xFF6B7280),
        bg: const Color(0xFFF1F5F9)
      );
    case 'pending_hr':
      return (
        label: 'Pending · HR',
        color: const Color(0xFFF59E0B),
        bg: const Color(0xFFFFF8EC)
      );
    default:
      return (
        label: 'Pending · Manager',
        color: const Color(0xFFF59E0B),
        bg: const Color(0xFFFFF8EC)
      );
  }
}

String leaveRange(LeaveRequestEntity r) {
  if (r.from == null) return '';
  final fmt = DateFormat('dd MMM');
  final fmtY = DateFormat('dd MMM yyyy');
  final half = r.halfDay != 'none' ? ' (half day)' : '';
  if (r.to == null || r.from == r.to) {
    return '${fmtY.format(r.from!)}$half';
  }
  return '${fmt.format(r.from!)} – ${fmtY.format(r.to!)}';
}

class LeaveScreen extends StatelessWidget {
  const LeaveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<LeaveRequestsCubit>()..fetch()),
        BlocProvider(create: (_) => getIt<LeaveBalancesCubit>()..load()),
      ],
      child: const _LeaveHome(),
    );
  }
}

class _LeaveHome extends StatefulWidget {
  const _LeaveHome();
  @override
  State<_LeaveHome> createState() => _LeaveHomeState();
}

class _LeaveHomeState extends State<_LeaveHome> {
  String _filter = 'all'; // all | pending | approved | rejected | cancelled

  bool _matches(LeaveRequestEntity r) {
    switch (_filter) {
      case 'pending':
        return r.isPending;
      case 'approved':
        return r.status == 'approved';
      case 'rejected':
        return r.status == 'rejected';
      case 'cancelled':
        return r.status == 'cancelled';
      default:
        return true;
    }
  }

  Future<void> _refresh() async {
    context.read<LeaveRequestsCubit>().fetch();
    context.read<LeaveBalancesCubit>().load();
  }

  Future<void> _openApply() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const LeaveApplyScreen()),
    );
    if (changed == true && mounted) _refresh();
  }

  Future<void> _openDetail(LeaveRequestEntity r) async {
    final cubit = context.read<LeaveRequestsCubit>();
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: LeaveRequestDetailScreen(request: r),
        ),
      ),
    );
    if (changed == true && mounted) {
      context.read<LeaveBalancesCubit>().load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppAppBar(
        title: 'Leave',
        showBack: true,
        actions: [
          IconButton(
            tooltip: 'Leave calendar',
            icon: const Icon(LucideIcons.calendar_days, color: AppColors.primary),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LeaveCalendarScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openApply,
        backgroundColor: AppColors.primary,
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: const Text('Apply Leave',
            style: TextStyle(
                color: Colors.white,
                fontFamily: 'AirbnbCereal',
                fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _refresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              _buildBalancesStrip(),
              const SizedBox(height: 18),
              _buildFilters(),
              const SizedBox(height: 12),
              _buildRequests(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalancesStrip() {
    return BlocBuilder<LeaveBalancesCubit, LeaveBalancesState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('My Balances',
                    style: TextStyle(
                        fontFamily: 'AirbnbCereal',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87)),
                if (state.balances.isNotEmpty)
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LeaveBalancesScreen()),
                    ),
                    child: const Text('View all',
                        style: TextStyle(
                            fontFamily: 'AirbnbCereal',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary)),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (state.loading)
              const SizedBox(
                  height: 92, child: Center(child: LoadingWidget()))
            else if (state.balances.isEmpty)
              Text('No leave balances',
                  style: TextStyle(
                      fontFamily: 'AirbnbCereal',
                      fontSize: 13,
                      color: Colors.grey.shade500))
            else
              SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: state.balances.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) => _balanceCard(state.balances[i]),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _balanceCard(LeaveBalanceEntity b) {
    final c = leaveColor(b.color);
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(b.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontFamily: 'AirbnbCereal',
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF374151))),
              ),
            ],
          ),
          const Spacer(),
          Text(
            b.paid ? _num(b.available) : '—',
            style: TextStyle(
                fontFamily: 'AirbnbCereal',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: c),
          ),
          Text(b.paid ? 'available · ${_num(b.used)} used' : 'unpaid',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontFamily: 'AirbnbCereal',
                  fontSize: 10,
                  color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    const filters = {
      'all': 'All',
      'pending': 'Pending',
      'approved': 'Approved',
      'rejected': 'Rejected',
      'cancelled': 'Cancelled',
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.entries.map((e) {
          final sel = _filter == e.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(e.value,
                  style: TextStyle(
                      fontFamily: 'AirbnbCereal',
                      fontSize: 12,
                      color: sel ? AppColors.primary : const Color(0xFF6B7280),
                      fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
              selected: sel,
              selectedColor: const Color(0xFFEFF6FF),
              backgroundColor: Colors.white,
              showCheckmark: false,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                    color: sel
                        ? const Color(0xFFDBEAFE)
                        : Colors.grey.shade200),
              ),
              onSelected: (_) => setState(() => _filter = e.key),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRequests() {
    return BlocBuilder<LeaveRequestsCubit, LeaveRequestsState>(
      builder: (context, state) {
        if (state.loading) {
          return const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: LoadingWidget()));
        }
        if (state.error != null) {
          return EmptyState(
            icon: Icons.error_outline,
            title: state.error!,
            buttonLabel: 'Retry',
            onButtonTap: () => context.read<LeaveRequestsCubit>().fetch(),
          );
        }
        final all = state.page?.items ?? const <LeaveRequestEntity>[];
        final items = all.where(_matches).toList();
        if (items.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 36),
            child: Center(
              child: Text('No leave requests',
                  style: TextStyle(
                      fontFamily: 'AirbnbCereal',
                      fontSize: 13,
                      color: Colors.grey.shade500)),
            ),
          );
        }
        return Column(children: items.map(_requestCard).toList());
      },
    );
  }

  Widget _requestCard(LeaveRequestEntity r) {
    final s = leaveStatusVisual(r.status);
    return GestureDetector(
      onTap: () => _openDetail(r),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _typeLabel(r.leaveTypeCode),
                    style: const TextStyle(
                        fontFamily: 'AirbnbCereal',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: s.bg, borderRadius: BorderRadius.circular(6)),
                  child: Text(s.label,
                      style: TextStyle(
                          fontFamily: 'AirbnbCereal',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: s.color)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(LucideIcons.calendar, size: 13, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(leaveRange(r),
                      style: TextStyle(
                          fontFamily: 'AirbnbCereal',
                          fontSize: 12,
                          color: Colors.grey.shade600)),
                ),
                Text('${_num(r.applicableWorkdays)} day(s)',
                    style: const TextStyle(
                        fontFamily: 'AirbnbCereal',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _typeLabel(String code) =>
      code.isEmpty ? 'Leave' : (code[0].toUpperCase() + code.substring(1));

  String _num(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}
