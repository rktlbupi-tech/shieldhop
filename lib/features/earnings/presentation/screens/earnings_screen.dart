import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../../../common/widgets/app_app_bar.dart';
import '../../../../common/widgets/empty_state.dart';
import '../../../../common/widgets/loading_widget.dart';
import '../../../../config/di/injection.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/earning_entity.dart';
import '../bloc/earnings_bloc.dart';

const double _numD025 = 0.025;
const double _numD03 = 0.03;
const double _numD032 = 0.032;
const double _numD026 = 0.026;
const double _numD036 = 0.036;
const double _numD04 = 0.04;
const double _numD045 = 0.045;
const double _numD05 = 0.05;

String _money(double v) =>
    '₹ ${v.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<EarningsBloc>()
        ..add(FetchEarnings(year: DateTime.now().year)),
      child: const _EarningsView(),
    );
  }
}

class _EarningsView extends StatefulWidget {
  const _EarningsView();

  @override
  State<_EarningsView> createState() => _EarningsViewState();
}

class _EarningsViewState extends State<_EarningsView> {
  String? _expandedMonth;
  late int _selectedYear = DateTime.now().year;

  List<int> get _years =>
      List.generate(4, (i) => DateTime.now().year - i); // current → -3

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      appBar: AppAppBar(
        title: "Earnings",
        elevation: 0.5,
        centerTitle: false,
        titleSpacing: 0,
        showBack: true,
      ),
      body: SafeArea(
        child: BlocBuilder<EarningsBloc, EarningsState>(
          builder: (context, state) {
            if (state is EarningsLoading || state is EarningsInitial) {
              return const Center(child: LoadingWidget());
            }
            if (state is EarningsError) {
              return EmptyState(
                icon: Icons.error_outline,
                title: state.message,
                buttonLabel: 'Retry',
                onButtonTap: () => context
                    .read<EarningsBloc>()
                    .add(FetchEarnings(year: _selectedYear)),
              );
            }
            final data = state is EarningsLoaded
                ? state.data
                : YearlyEarningsEntity(year: _selectedYear);
            return _buildContent(size, data);
          },
        ),
      ),
    );
  }

  Widget _buildContent(Size size, YearlyEarningsEntity data) {
    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: size.width * _numD04,
        vertical: size.width * _numD03,
      ),
      children: [
        // Total earnings of year
        Container(
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.15), width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: size.width * 0.15,
                  height: size.width * 0.15,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.12),
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  child: Icon(LucideIcons.wallet,
                      color: AppColors.primary, size: size.width * 0.07),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Total Earnings of Year",
                        style: TextStyle(
                          fontFamily: 'AirbnbCereal',
                          fontSize: size.width * _numD032,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _money(data.totalEarningsYear),
                        style: TextStyle(
                          fontFamily: 'AirbnbCereal',
                          fontSize: size.width * 0.07,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            "Year: ",
                            style: TextStyle(
                              fontFamily: 'AirbnbCereal',
                              fontSize: size.width * _numD026,
                              color: AppColors.primary.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(
                            height: size.width * 0.05,
                            child: _CustomDropdown<int>(
                              value: _selectedYear,
                              items: _years,
                              buttonColor: Colors.transparent,
                              padding: const EdgeInsets.only(left: 4),
                              border: Border.all(color: Colors.transparent),
                              icon: Icon(LucideIcons.chevron_down,
                                  size: size.width * _numD03,
                                  color:
                                      AppColors.primary.withValues(alpha: 0.8)),
                              itemBuilder: (value, isSelected) => Text(
                                '$value',
                                style: TextStyle(
                                  fontFamily: 'AirbnbCereal',
                                  fontSize: size.width * _numD026,
                                  color:
                                      AppColors.primary.withValues(alpha: 0.8),
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                ),
                              ),
                              onChanged: (v) {
                                setState(() {
                                  _selectedYear = v;
                                  _expandedMonth = null;
                                });
                                context
                                    .read<EarningsBloc>()
                                    .add(FetchEarnings(year: v));
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: size.width * _numD05),

        Text(
          "Monthly Breakdown",
          style: TextStyle(
            fontFamily: 'AirbnbCereal',
            fontSize: size.width * _numD036,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),

        if (data.months.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32),
            alignment: Alignment.center,
            child: Text(
              "No earnings published for $_selectedYear",
              style: TextStyle(
                fontFamily: 'AirbnbCereal',
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
            ),
          )
        else
          ...data.months.map((m) => _buildMonthCard(size, m)),
        SizedBox(height: size.width * _numD025),
      ],
    );
  }

  Widget _buildMonthCard(Size size, EarningMonthEntity m) {
    final isExpanded = _expandedMonth == m.period;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEFF1F6)),
      ),
      child: InkWell(
        onTap: () => setState(
            () => _expandedMonth = isExpanded ? null : m.period),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(LucideIcons.calendar,
                          color: AppColors.primary, size: size.width * _numD04),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.monthLabel,
                            style: const TextStyle(
                              fontFamily: 'AirbnbCereal',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            m.payDate != null ? "Paid on ${m.payDate}" : "",
                            style: TextStyle(
                              fontFamily: 'AirbnbCereal',
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _money(m.total),
                      style: TextStyle(
                        fontFamily: 'AirbnbCereal',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.grey,
                      size: size.width * _numD045,
                    ),
                  ],
                ),
                if (isExpanded) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                  ),
                  _sectionHeader(LucideIcons.wallet, "Salary Components"),
                  const SizedBox(height: 8),
                  ...m.salaryComponents.map((c) => _line(c.label, c.amount)),
                  _totalLine("Total Salary", m.totalSalary,
                      const Color(0xFF10B981)),
                  const SizedBox(height: 4),
                  _sectionHeader(LucideIcons.receipt, "Reimbursements"),
                  const SizedBox(height: 8),
                  if (m.reimbursements.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(left: 22, bottom: 6),
                      child: Text("None",
                          style: TextStyle(
                              fontFamily: 'AirbnbCereal',
                              fontSize: 12,
                              color: Color(0xFF9CA3AF))),
                    )
                  else
                    ...m.reimbursements.map((c) => _line(c.label, c.amount)),
                  _totalLine("Total Reimbursements", m.totalReimbursements,
                      const Color(0xFF3B82F6)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title) => Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade400),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'AirbnbCereal',
              fontSize: 13,
              color: Color(0xFF374151),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );

  Widget _line(String label, double amount) => Padding(
        padding: const EdgeInsets.only(bottom: 6, left: 22),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                    fontFamily: 'AirbnbCereal',
                    fontSize: 12,
                    color: Color(0xFF4B5563)),
              ),
            ),
            Text(
              _money(amount),
              style: const TextStyle(
                fontFamily: 'AirbnbCereal',
                fontSize: 12,
                color: Color(0xFF1F2937),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );

  Widget _totalLine(String label, double amount, Color color) => Padding(
        padding: const EdgeInsets.only(left: 22, top: 4, bottom: 10),
        child: Column(
          children: [
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label,
                    style: TextStyle(
                        fontFamily: 'AirbnbCereal',
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.bold)),
                Text(_money(amount),
                    style: TextStyle(
                        fontFamily: 'AirbnbCereal',
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      );
}

class _CustomDropdown<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final Widget Function(T, bool) itemBuilder;
  final ValueChanged<T> onChanged;
  final Widget? icon;
  final Color? buttonColor;
  final double? buttonWidth;
  final double? width;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;
  final BoxBorder? border;

  const _CustomDropdown({
    required this.value,
    required this.items,
    required this.itemBuilder,
    required this.onChanged,
    this.icon,
    this.buttonColor,
    this.buttonWidth,
    this.width,
    this.borderRadius,
    this.padding,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: PopupMenuButton<T>(
        initialValue: value,
        onSelected: onChanged,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        color: Colors.white,
        elevation: 8,
        offset: const Offset(0, 38),
        padding: EdgeInsets.zero,
        itemBuilder: (context) => items.map((item) {
          final isSelected = item == value;
          return PopupMenuItem<T>(
            value: item,
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Container(
              width: buttonWidth ?? 110,
              alignment: Alignment.centerLeft,
              padding:
                  const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: isSelected ? Colors.grey.shade200 : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: itemBuilder(item, isSelected),
            ),
          );
        }).toList(),
        child: Container(
          width: width,
          padding: padding ??
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: buttonColor ?? Colors.transparent,
            borderRadius: BorderRadius.circular(borderRadius ?? 8),
            border: border ??
                Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
          ),
          child: Row(
            mainAxisSize: width != null ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (width != null)
                Expanded(child: itemBuilder(value, false))
              else
                itemBuilder(value, false),
              const SizedBox(width: 8),
              icon ??
                  const Icon(Icons.keyboard_arrow_down,
                      color: Color(0xFF64748B), size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
