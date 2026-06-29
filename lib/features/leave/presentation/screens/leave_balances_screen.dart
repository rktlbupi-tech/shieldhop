import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../common/widgets/app_app_bar.dart';
import '../../../../common/widgets/empty_state.dart';
import '../../../../common/widgets/loading_widget.dart';
import '../../../../config/di/injection.dart';
import '../../domain/entities/leave_entities.dart';
import '../bloc/leave_cubits.dart';

class LeaveBalancesScreen extends StatelessWidget {
  const LeaveBalancesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<LeaveBalancesCubit>()..load(),
      child: const _BalancesView(),
    );
  }
}

class _BalancesView extends StatelessWidget {
  const _BalancesView();

  String _n(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: const AppAppBar(title: 'Leave balances', showBack: true),
      body: SafeArea(
        child: BlocBuilder<LeaveBalancesCubit, LeaveBalancesState>(
          builder: (context, state) {
            if (state.loading) return const Center(child: LoadingWidget());
            if (state.error != null && state.balances.isEmpty) {
              return EmptyState(
                icon: Icons.error_outline,
                title: state.error!,
                buttonLabel: 'Retry',
                onButtonTap: () => context.read<LeaveBalancesCubit>().load(),
              );
            }
            if (state.balances.isEmpty) {
              return const EmptyState(
                  icon: Icons.event_available, title: 'No leave balances');
            }
            return RefreshIndicator(
              onRefresh: () async => context.read<LeaveBalancesCubit>().load(),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: state.balances.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _card(state.balances[i]),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _card(LeaveBalanceEntity b) {
    final c = leaveColor(b.color);
    final entitlement = b.opening + b.accrued + b.carriedForward;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(b.label,
                    style: const TextStyle(
                        fontFamily: 'AirbnbCereal',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87)),
              ),
              if (!b.paid)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6)),
                  child: const Text('Unpaid',
                      style: TextStyle(
                          fontFamily: 'AirbnbCereal',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280))),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(b.paid ? _n(b.available) : '—',
                  style: TextStyle(
                      fontFamily: 'AirbnbCereal',
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: c)),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('days available',
                    style: TextStyle(
                        fontFamily: 'AirbnbCereal',
                        fontSize: 12,
                        color: Colors.grey.shade500)),
              ),
            ],
          ),
          const Divider(height: 22, color: Color(0xFFF1F5F9)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _mini('Entitlement', _n(entitlement)),
              _mini('Used', _n(b.used)),
              _mini('Pending', _n(b.pending)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mini(String label, String value) => Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontFamily: 'AirbnbCereal',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937))),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontFamily: 'AirbnbCereal',
                  fontSize: 10.5,
                  color: Colors.grey.shade500)),
        ],
      );
}
