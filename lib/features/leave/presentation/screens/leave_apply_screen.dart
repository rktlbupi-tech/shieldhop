import 'dart:io';
import 'package:file_picker/file_picker.dart';
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

class LeaveApplyScreen extends StatelessWidget {
  const LeaveApplyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<LeaveApplyCubit>()..load(),
      child: const _ApplyView(),
    );
  }
}

class _ApplyView extends StatefulWidget {
  const _ApplyView();
  @override
  State<_ApplyView> createState() => _ApplyViewState();
}

class _ApplyViewState extends State<_ApplyView> {
  LeaveTypeEntity? _type;
  DateTime? _from;
  DateTime? _to;
  String _halfDay = 'none';
  final _reasonCtrl = TextEditingController();
  final List<LeaveAttachment> _attachments = [];
  bool _uploading = false;
  String? _error;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  bool get _isSingleDay =>
      _from != null && _to != null && _from == _to;

  double get _days {
    if (_from == null || _to == null) return 0;
    if (_halfDay != 'none' && _isSingleDay) return 0.5;
    return _to!.difference(_from!).inDays + 1;
  }

  Future<void> _pick({required bool isStart}) async {
    final init = isStart ? (_from ?? DateTime.now()) : (_to ?? _from ?? DateTime.now());
    final d = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (c, ch) => Theme(
        data: Theme.of(c).copyWith(
          colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black),
        ),
        child: ch!,
      ),
    );
    if (d == null) return;
    setState(() {
      if (isStart) {
        _from = d;
        if (_to != null && _to!.isBefore(d)) _to = d;
      } else {
        _to = d;
      }
      if (!_isSingleDay) _halfDay = 'none';
    });
  }

  Future<void> _pickAttachment() async {
    try {
      final res = await FilePicker.platform.pickFiles();
      final path = res?.files.single.path;
      if (path == null) return;
      setState(() => _uploading = true);
      final url = await context.read<LeaveApplyCubit>().uploadAttachment(File(path));
      setState(() {
        _uploading = false;
        if (url != null) {
          _attachments.add(LeaveAttachment(
              url: url, fileName: res!.files.single.name));
        } else {
          _error = 'Attachment upload failed.';
        }
      });
    } catch (_) {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (_type == null) {
      setState(() => _error = 'Please select a leave type.');
      return;
    }
    if (_from == null || _to == null) {
      setState(() => _error = 'Please select the leave dates.');
      return;
    }
    if (_to!.isBefore(_from!)) {
      setState(() => _error = 'The start date must be on or before the end date.');
      return;
    }
    if (_halfDay != 'none' && !_isSingleDay) {
      setState(() => _error = 'A half day can only be applied to a single date.');
      return;
    }
    if (_type!.requiresAttachment && _attachments.isEmpty) {
      setState(() => _error = 'This leave type requires an attachment.');
      return;
    }
    final cubit = context.read<LeaveApplyCubit>();
    if (_type!.paid) {
      final available = cubit.state.availableFor(_type!.id);
      if (available != null && available < _days) {
        setState(() => _error = 'Insufficient leave balance for this leave type.');
        return;
      }
    }

    final fmt = DateFormat('yyyy-MM-dd');
    final (req, err) = await cubit.submit(
      leaveTypeId: _type!.id,
      from: fmt.format(_from!),
      to: fmt.format(_to!),
      halfDay: _halfDay,
      reason: _reasonCtrl.text.trim(),
      attachments: _attachments,
    );
    if (!mounted) return;
    if (req != null) {
      Navigator.pop(context, true);
    } else {
      setState(() => _error = err ?? 'Unable to submit leave request.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: const AppAppBar(title: 'Apply for leave', showBack: true),
      body: SafeArea(
        child: BlocBuilder<LeaveApplyCubit, LeaveApplyState>(
          builder: (context, state) {
            if (state.loading) return const Center(child: LoadingWidget());
            if (state.loadError != null && state.types.isEmpty) {
              return EmptyState(
                icon: Icons.error_outline,
                title: state.loadError!,
                buttonLabel: 'Retry',
                onButtonTap: () => context.read<LeaveApplyCubit>().load(),
              );
            }
            return _form(state);
          },
        ),
      ),
    );
  }

  Widget _form(LeaveApplyState state) {
    final available =
        _type != null ? state.availableFor(_type!.id) : null;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _label('Leave type'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: state.types.map((t) {
            final sel = _type?.id == t.id;
            final c = leaveColor(t.color);
            return GestureDetector(
              onTap: () => setState(() => _type = t),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: sel ? c.withValues(alpha: 0.1) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: sel ? c : Colors.grey.shade200,
                      width: sel ? 1.4 : 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(t.label,
                        style: TextStyle(
                            fontFamily: 'AirbnbCereal',
                            fontSize: 12.5,
                            fontWeight: sel ? FontWeight.bold : FontWeight.w500,
                            color: const Color(0xFF374151))),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        if (_type != null && _type!.paid && available != null) ...[
          const SizedBox(height: 8),
          Text('Available balance: ${_fmtNum(available)} day(s)',
              style: const TextStyle(
                  fontFamily: 'AirbnbCereal',
                  fontSize: 12,
                  color: Color(0xFF10B981),
                  fontWeight: FontWeight.w600)),
        ],
        if (_type != null && !_type!.paid) ...[
          const SizedBox(height: 8),
          Text('Unpaid leave — no balance applies',
              style: TextStyle(
                  fontFamily: 'AirbnbCereal',
                  fontSize: 12,
                  color: Colors.grey.shade500)),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _dateField('From', _from, () => _pick(isStart: true))),
            const SizedBox(width: 10),
            Expanded(child: _dateField('To', _to, () => _pick(isStart: false))),
          ],
        ),
        if (_isSingleDay) ...[
          const SizedBox(height: 14),
          _label('Half day'),
          const SizedBox(height: 8),
          Row(
            children: [
              _halfChip('none', 'Full day'),
              _halfChip('first_half', '1st half'),
              _halfChip('second_half', '2nd half'),
            ],
          ),
        ],
        const SizedBox(height: 16),
        _label('Reason'),
        const SizedBox(height: 8),
        TextField(
          controller: _reasonCtrl,
          maxLines: 3,
          style: const TextStyle(fontFamily: 'AirbnbCereal', fontSize: 13),
          decoration: _dec('Reason (optional)'),
        ),
        const SizedBox(height: 16),
        _label(_type?.requiresAttachment == true
            ? 'Attachment (required)'
            : 'Attachment (optional)'),
        const SizedBox(height: 8),
        ..._attachments.map((a) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(LucideIcons.paperclip, size: 14, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(a.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontFamily: 'AirbnbCereal', fontSize: 12)),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _attachments.remove(a)),
                    child: Icon(Icons.close, size: 16, color: Colors.grey.shade500),
                  ),
                ],
              ),
            )),
        OutlinedButton.icon(
          onPressed: _uploading ? null : _pickAttachment,
          icon: _uploading
              ? const SizedBox(
                  width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(LucideIcons.upload, size: 16),
          label: Text(_uploading ? 'Uploading…' : 'Add attachment',
              style: const TextStyle(fontFamily: 'AirbnbCereal', fontSize: 13)),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: Color(0xFFDBEAFE)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!,
              style: const TextStyle(
                  fontFamily: 'AirbnbCereal',
                  fontSize: 12.5,
                  color: Color(0xFFEF4444))),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: state.submitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: state.submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Submit Request',
                    style: TextStyle(
                        fontFamily: 'AirbnbCereal',
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
          ),
        ),
      ],
    );
  }

  Widget _label(String t) => Text(t,
      style: const TextStyle(
          fontFamily: 'AirbnbCereal',
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.black87));

  Widget _dateField(String label, DateTime? value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.calendar, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              value == null ? label : DateFormat('dd MMM yyyy').format(value),
              style: TextStyle(
                  fontFamily: 'AirbnbCereal',
                  fontSize: 13,
                  color: value == null ? Colors.grey : Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _halfChip(String value, String label) {
    final sel = _halfDay == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _halfDay = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: sel ? const Color(0xFFEFF6FF) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: sel ? const Color(0xFFDBEAFE) : Colors.grey.shade200),
          ),
          child: Text(label,
              style: TextStyle(
                  fontFamily: 'AirbnbCereal',
                  fontSize: 12,
                  color: sel ? AppColors.primary : const Color(0xFF6B7280),
                  fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
        ),
      ),
    );
  }

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade50,
        hintStyle: TextStyle(
            fontFamily: 'AirbnbCereal', color: Colors.grey, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      );

  String _fmtNum(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}
