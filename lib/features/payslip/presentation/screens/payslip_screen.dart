import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:presshop_enterprise/features/map/core/map_constants.dart';
import 'package:presshop_enterprise/common/widgets/app_app_bar.dart';
import '../../../../common/widgets/empty_state.dart';
import '../../../../common/widgets/loading_widget.dart';
import '../../../../config/di/injection.dart';
import '../../domain/entities/payslip_entities.dart';
import '../bloc/payslip_bloc.dart';

String _money(double v) =>
    '₹ ${v.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

class PayslipScreen extends StatelessWidget {
  const PayslipScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PayslipBloc>()..add(const FetchPayslips()),
      child: const _PayslipView(),
    );
  }
}

class _PayslipView extends StatefulWidget {
  const _PayslipView();

  @override
  State<_PayslipView> createState() => _PayslipViewState();
}

class _PayslipViewState extends State<_PayslipView> {
  bool _earningsExpanded = true;
  bool _deductionsExpanded = true;

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: const TextStyle(fontFamily: 'AirbnbCereal')),
        backgroundColor: colorEmployeeGreen1,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      appBar: AppAppBar(
        title: "Payslip",
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        showBack: true,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.download, color: Colors.black),
            onPressed: () => _toast("PDF export is not available yet."),
          ),
        ],
      ),
      body: SafeArea(
        child: BlocBuilder<PayslipBloc, PayslipState>(
          builder: (context, state) {
            if (state is PayslipLoading || state is PayslipInitial) {
              return const Center(child: LoadingWidget());
            }
            if (state is PayslipError) {
              return EmptyState(
                icon: Icons.error_outline,
                title: state.message,
                buttonLabel: 'Retry',
                onButtonTap: () =>
                    context.read<PayslipBloc>().add(const FetchPayslips()),
              );
            }
            final loaded = state as PayslipLoaded;
            if (loaded.list.isEmpty) {
              return const EmptyState(
                icon: Icons.receipt_long,
                title: 'No payslip published yet',
              );
            }
            return _buildContent(loaded);
          },
        ),
      ),
    );
  }

  Widget _buildContent(PayslipLoaded loaded) {
    final selected = loaded.list.firstWhere(
      (p) => p.id == loaded.selectedId,
      orElse: () => loaded.list.first,
    );
    final detail = loaded.detail;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // Month picker + Net Pay card
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Select Month",
                    style: TextStyle(
                      fontFamily: 'AirbnbCereal',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selected.id,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down,
                            color: Colors.grey),
                        items: loaded.list
                            .map((p) => DropdownMenuItem<String>(
                                  value: p.id,
                                  child: Row(
                                    children: [
                                      const Icon(LucideIcons.calendar,
                                          size: 16, color: Colors.grey),
                                      const SizedBox(width: 8),
                                      Text(
                                        p.monthLabel,
                                        style: const TextStyle(
                                          fontFamily: 'AirbnbCereal',
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ))
                            .toList(),
                        onChanged: (id) {
                          if (id != null) {
                            context.read<PayslipBloc>().add(SelectPayslip(id));
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFDCFCE7)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Net Pay",
                      style: TextStyle(
                        fontFamily: 'AirbnbCereal',
                        fontSize: 11,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _money(selected.netPay),
                      style: const TextStyle(
                        fontFamily: 'AirbnbCereal',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    if (selected.payDate != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            "Paid on ${selected.payDate}",
                            style: const TextStyle(
                              fontFamily: 'AirbnbCereal',
                              fontSize: 9,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.check_circle,
                              size: 12, color: Color(0xFF10B981)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (loaded.isLoadingDetail || detail == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 60),
            child: Center(child: LoadingWidget()),
          )
        else
          ..._buildDetail(detail),
      ],
    );
  }

  List<Widget> _buildDetail(PayslipDetail d) {
    final emp = d.employee;
    return [
      // Employee details
      Container(
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
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorEmployeeGreen1.withValues(alpha: 0.12),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(LucideIcons.user,
                      color: colorEmployeeGreen1),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        emp.name,
                        style: const TextStyle(
                          fontFamily: 'AirbnbCereal',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      if (emp.code.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          emp.code,
                          style: const TextStyle(
                            fontFamily: 'AirbnbCereal',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colorEmployeeGreen1,
                          ),
                        ),
                      ],
                      if (emp.designation != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          emp.designation!,
                          style: const TextStyle(
                            fontFamily: 'AirbnbCereal',
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (emp.department != null ||
                emp.location != null ||
                emp.joinedDate != null) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: Color(0xFFF1F5F9)),
              ),
              if (emp.department != null)
                _meta(LucideIcons.briefcase, emp.department!),
              if (emp.location != null) ...[
                const SizedBox(height: 8),
                _meta(LucideIcons.map_pin, emp.location!),
              ],
              if (emp.joinedDate != null) ...[
                const SizedBox(height: 8),
                _meta(LucideIcons.calendar, "Joined on ${emp.joinedDate}"),
              ],
            ],
          ],
        ),
      ),
      const SizedBox(height: 16),

      _buildSectionCard(
        title: "Earnings",
        icon: LucideIcons.wallet,
        iconColor: const Color(0xFF10B981),
        iconBgColor: const Color(0xFFE6F9F2),
        isExpanded: _earningsExpanded,
        onToggle: () => setState(() => _earningsExpanded = !_earningsExpanded),
        items: d.earnings,
        totalLabel: "Total Earnings",
        totalValue: d.totalEarnings,
        accentColor: const Color(0xFF10B981),
      ),
      const SizedBox(height: 16),

      _buildSectionCard(
        title: "Deductions",
        icon: LucideIcons.shield_alert,
        iconColor: const Color(0xFFEF4444),
        iconBgColor: const Color(0xFFFEE2E2),
        isExpanded: _deductionsExpanded,
        onToggle: () =>
            setState(() => _deductionsExpanded = !_deductionsExpanded),
        items: d.deductions,
        totalLabel: "Total Deductions",
        totalValue: d.totalDeductions,
        accentColor: const Color(0xFFEF4444),
      ),
      const SizedBox(height: 16),

      // Net Pay highlight
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFDBEAFE)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Net Pay",
                  style: TextStyle(
                    fontFamily: 'AirbnbCereal',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  "(Total Earnings - Total Deductions)",
                  style: TextStyle(
                    fontFamily: 'AirbnbCereal',
                    fontSize: 10,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
              ],
            ),
            Text(
              _money(d.netPay),
              style: const TextStyle(
                fontFamily: 'AirbnbCereal',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A8A),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),

      // Period / payment details
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Table(
          children: [
            TableRow(
              children: [
                _grid(
                  "Pay Period",
                  (d.payPeriodStart != null && d.payPeriodEnd != null)
                      ? "${d.payPeriodStart} – ${d.payPeriodEnd}"
                      : "—",
                ),
                _grid("Pay Date", d.payDate ?? "—"),
                _grid("Payment Mode",
                    d.paymentMode.isEmpty ? "—" : d.paymentMode),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),

      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.info, size: 14, color: Colors.grey.shade400),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "This is a system generated payslip and does not require signature.",
              style: TextStyle(
                fontFamily: 'AirbnbCereal',
                fontSize: 10.5,
                color: Colors.grey.shade500,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
    ];
  }

  Widget _meta(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 13, color: Colors.grey.shade500),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontFamily: 'AirbnbCereal',
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required bool isExpanded,
    required VoidCallback onToggle,
    required List<PayLineItem> items,
    required String totalLabel,
    required double totalValue,
    required Color accentColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration:
                        BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
                    child: Icon(icon, color: iconColor, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'AirbnbCereal',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    "Amount (₹)",
                    style: TextStyle(
                      fontFamily: 'AirbnbCereal',
                      fontSize: 11,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Divider(height: 1, color: Color(0xFFF1F5F9)),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ...items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item.label,
                                style: TextStyle(
                                  fontFamily: 'AirbnbCereal',
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Text(
                              _money(item.amount),
                              style: const TextStyle(
                                fontFamily: 'AirbnbCereal',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 4),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        totalLabel,
                        style: TextStyle(
                          fontFamily: 'AirbnbCereal',
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                      Text(
                        _money(totalValue),
                        style: TextStyle(
                          fontFamily: 'AirbnbCereal',
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _grid(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'AirbnbCereal',
            fontSize: 10,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'AirbnbCereal',
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
