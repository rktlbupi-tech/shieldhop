import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import '../../../../common/widgets/app_app_bar.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/leave_entities.dart';
import '../bloc/leave_cubits.dart';
import 'leave_screen.dart' show leaveStatusVisual, leaveRange;

class LeaveRequestDetailScreen extends StatefulWidget {
  final LeaveRequestEntity request;
  const LeaveRequestDetailScreen({super.key, required this.request});

  @override
  State<LeaveRequestDetailScreen> createState() =>
      _LeaveRequestDetailScreenState();
}

class _LeaveRequestDetailScreenState extends State<LeaveRequestDetailScreen> {
  late LeaveRequestEntity _r = widget.request;
  bool _cancelling = false;

  void _toast(String m) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(m, style: const TextStyle(fontFamily: 'AirbnbCereal')),
            behavior: SnackBarBehavior.floating),
      );

  Future<void> _cancel() async {
    setState(() => _cancelling = true);
    final err = await context.read<LeaveRequestsCubit>().cancel(_r.id);
    if (!mounted) return;
    setState(() => _cancelling = false);
    if (err == null) {
      _toast('Leave request cancelled.');
      Navigator.pop(context, true);
    } else {
      _toast(err);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = leaveStatusVisual(_r.status);
    final fmt = DateFormat('dd MMM yyyy, hh:mm a');
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: const AppAppBar(title: 'Leave details', showBack: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Summary
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _r.leaveTypeCode.isEmpty
                            ? 'Leave'
                            : _r.leaveTypeCode[0].toUpperCase() +
                                _r.leaveTypeCode.substring(1),
                        style: const TextStyle(
                            fontFamily: 'AirbnbCereal',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: s.bg,
                            borderRadius: BorderRadius.circular(6)),
                        child: Text(s.label,
                            style: TextStyle(
                                fontFamily: 'AirbnbCereal',
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: s.color)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _row(LucideIcons.calendar, leaveRange(_r)),
                  const SizedBox(height: 8),
                  _row(LucideIcons.hourglass,
                      '${_num(_r.applicableWorkdays)} working day(s)'),
                  if (_r.submittedAt != null) ...[
                    const SizedBox(height: 8),
                    _row(LucideIcons.send, 'Submitted ${fmt.format(_r.submittedAt!.toLocal())}'),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (_r.reason.isNotEmpty) ...[
              _sectionTitle('Reason'),
              const SizedBox(height: 8),
              _card(Text(_r.reason,
                  style: TextStyle(
                      fontFamily: 'AirbnbCereal',
                      fontSize: 13,
                      color: Colors.grey.shade700))),
              const SizedBox(height: 16),
            ],

            if (_r.attachments.isNotEmpty) ...[
              _sectionTitle('Attachments'),
              const SizedBox(height: 8),
              _card(Column(
                children: _r.attachments
                    .map((a) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.paperclip,
                                  size: 14, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(a.fileName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontFamily: 'AirbnbCereal',
                                        fontSize: 12)),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              )),
              const SizedBox(height: 16),
            ],

            _sectionTitle('Approval'),
            const SizedBox(height: 8),
            _card(_buildTimeline()),
            const SizedBox(height: 20),

            if (_r.canCancel)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _cancelling ? null : _cancel,
                  icon: _cancelling
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(LucideIcons.x, size: 16),
                  label: Text(_r.isPending ? 'Withdraw request' : 'Cancel leave',
                      style: const TextStyle(
                          fontFamily: 'AirbnbCereal',
                          fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    side: const BorderSide(color: Color(0xFFFECACA)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline() {
    final stages = _r.approvalChain.isNotEmpty
        ? _r.approvalChain
        : const [
            LeaveApprovalStage(stage: 'manager', status: 'pending'),
            LeaveApprovalStage(stage: 'hr', status: 'pending'),
          ];
    return Column(
      children: List.generate(stages.length, (i) {
        final st = stages[i];
        final isLast = i == stages.length - 1;
        final done = st.status == 'approved';
        final rejected = st.status == 'rejected';
        final color = rejected
            ? const Color(0xFFEF4444)
            : done
                ? const Color(0xFF10B981)
                : Colors.grey.shade400;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Icon(
                    rejected
                        ? Icons.cancel
                        : done
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                    color: color,
                    size: 20,
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                          width: 2, color: Colors.grey.shade200, margin: const EdgeInsets.symmetric(vertical: 2)),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(st.stage == 'hr' ? 'HR' : 'Manager',
                          style: const TextStyle(
                              fontFamily: 'AirbnbCereal',
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87)),
                      const SizedBox(height: 2),
                      Text(
                        '${st.status[0].toUpperCase()}${st.status.substring(1)}'
                        '${st.approverName != null ? ' · ${st.approverName}' : ''}',
                        style: TextStyle(
                            fontFamily: 'AirbnbCereal',
                            fontSize: 11.5,
                            color: color),
                      ),
                      if ((st.note ?? '').isNotEmpty)
                        Text(st.note!,
                            style: TextStyle(
                                fontFamily: 'AirbnbCereal',
                                fontSize: 11,
                                color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _row(IconData icon, String text) => Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontFamily: 'AirbnbCereal',
                    fontSize: 12.5,
                    color: Colors.grey.shade700)),
          ),
        ],
      );

  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(
          fontFamily: 'AirbnbCereal',
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.black87));

  Widget _card(Widget child) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: child,
      );

  String _num(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}
