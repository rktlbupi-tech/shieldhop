import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../common/widgets/app_app_bar.dart';
import '../../../../common/widgets/empty_state.dart';
import '../../../../common/widgets/loading_widget.dart';
import '../../../../config/di/injection.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../claims/domain/entities/claim_entities.dart';
import '../../../claims/presentation/bloc/claims_bloc.dart';
import '../widgets/custom_dropdown.dart';

class ClaimExpensesScreen extends StatelessWidget {
  const ClaimExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ClaimsBloc>()..add(const FetchClaimsOverview()),
      child: const _ClaimExpensesView(),
    );
  }
}

class _ClaimExpensesView extends StatelessWidget {
  const _ClaimExpensesView();

  void _showToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'AirbnbCereal',
            fontSize: 12,
            color: Colors.white,
          ),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── formatting / visual helpers ───────────────────────────────────────────

  String _money(double amount, String currency) {
    const symbols = {'GBP': '£', 'USD': '\$', 'EUR': '€', 'INR': '₹'};
    final sym = symbols[currency] ?? '$currency ';
    return '$sym${amount.toStringAsFixed(2)}';
  }

  ({IconData icon, Color color, Color bg}) _categoryVisual(ClaimCategory c) {
    switch (c) {
      case ClaimCategory.fuel:
        return (
          icon: LucideIcons.fuel,
          color: const Color(0xFF0066FF),
          bg: const Color(0xFFEFF6FF)
        );
      case ClaimCategory.meal:
        return (
          icon: LucideIcons.utensils,
          color: const Color(0xFF10B981),
          bg: const Color(0xFFE6F9F2)
        );
      case ClaimCategory.parkingToll:
        return (
          icon: LucideIcons.car,
          color: const Color(0xFF8B5CF6),
          bg: const Color(0xFFF5F3FF)
        );
      case ClaimCategory.travel:
        return (
          icon: LucideIcons.plane,
          color: const Color(0xFF0EA5E9),
          bg: const Color(0xFFE0F2FE)
        );
      case ClaimCategory.accommodation:
        return (
          icon: LucideIcons.house,
          color: const Color(0xFFF59E0B),
          bg: const Color(0xFFFFF8EC)
        );
      case ClaimCategory.officeSupplies:
        return (
          icon: LucideIcons.briefcase,
          color: const Color(0xFF6366F1),
          bg: const Color(0xFFEEF2FF)
        );
      case ClaimCategory.other:
        return (
          icon: LucideIcons.receipt,
          color: const Color(0xFF8B5CF6),
          bg: const Color(0xFFF5F3FF)
        );
    }
  }

  ({String label, Color color, Color bg}) _statusVisual(String status) {
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
      case 'in_review':
      default:
        return (
          label: 'In Review',
          color: const Color(0xFFF59E0B),
          bg: const Color(0xFFFFF8EC)
        );
    }
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      appBar: AppAppBar(
        title: "Claim expenses",
        elevation: 0.5,
        centerTitle: false,
        titleSpacing: 0,
        showBack: true,
      ),
      body: SafeArea(
        child: BlocConsumer<ClaimsBloc, ClaimsState>(
          listenWhen: (prev, curr) =>
              curr is AddClaimSuccess || curr is AddClaimFailure,
          listener: (context, state) {
            if (state is AddClaimSuccess) {
              _showToast(context, "Expense claim submitted.");
            } else if (state is AddClaimFailure) {
              _showToast(context, state.errorMessage);
            }
          },
          builder: (context, state) {
            if (state is ClaimsLoading || state is ClaimsInitial) {
              return const Center(child: LoadingWidget());
            }
            if (state is ClaimsError) {
              return EmptyState(
                icon: Icons.error_outline,
                title: state.message,
                buttonLabel: 'Retry',
                onButtonTap: () => context
                    .read<ClaimsBloc>()
                    .add(const FetchClaimsOverview()),
              );
            }

            final loaded = state is ClaimsLoaded ? state : null;
            if (loaded == null) {
              return const Center(child: LoadingWidget());
            }
            return _buildContent(context, size, loaded);
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Size size, ClaimsLoaded loaded) {
    final summary = loaded.summary;
    final claims = loaded.claims;
    final currency = claims.isNotEmpty ? claims.first.currency : 'GBP';

    String sub(int count) => count == 1 ? "1 Claim" : "$count Claims";

    return ListView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16),
      children: [
        // My Expense Summary Header + period filter
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "My Expense Summary",
              style: TextStyle(
                fontFamily: 'AirbnbCereal',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            CustomDropdown<ClaimPeriod>(
              value: loaded.period,
              items: ClaimPeriod.values,
              buttonWidth: 125,
              buttonColor: Colors.white,
              itemBuilder: (period, isSelected) {
                return Text(
                  period.label,
                  style: TextStyle(
                    fontFamily: 'AirbnbCereal',
                    fontSize: 12,
                    color: isSelected
                        ? const Color(0xFF1F2937)
                        : const Color(0xFF6B7280),
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              },
              onChanged: (ClaimPeriod val) {
                context.read<ClaimsBloc>().add(ChangeClaimsPeriod(val));
              },
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Expense metrics status grid
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildExpenseStatusItem(
                context,
                "Submitted",
                _money(summary?.submitted.amount ?? 0, currency),
                sub(summary?.submitted.count ?? 0),
                LucideIcons.folder,
                const Color(0xFF0066FF),
                const Color(0xFFEFF6FF),
              ),
              const SizedBox(width: 8),
              _buildExpenseStatusItem(
                context,
                "In Review",
                _money(summary?.inReview.amount ?? 0, currency),
                sub(summary?.inReview.count ?? 0),
                LucideIcons.clock,
                const Color(0xFFF59E0B),
                const Color(0xFFFFF8EC),
              ),
              const SizedBox(width: 8),
              _buildExpenseStatusItem(
                context,
                "Approved",
                _money(summary?.approved.amount ?? 0, currency),
                sub(summary?.approved.count ?? 0),
                Icons.check_circle_outline,
                const Color(0xFF10B981),
                const Color(0xFFE6F9F2),
              ),
              const SizedBox(width: 8),
              _buildExpenseStatusItem(
                context,
                "Rejected",
                _money(summary?.rejected.amount ?? 0, currency),
                sub(summary?.rejected.count ?? 0),
                Icons.cancel_outlined,
                const Color(0xFFEF4444),
                const Color(0xFFFEE2E2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _PresshopCommonButton(
          text: "Add Expense",
          backgroundColor: AppColors.primary,
          isLoading: loaded.isSubmitting,
          onPressed:
              loaded.isSubmitting ? null : () => _addNewExpense(context),
        ),
        const SizedBox(height: 18),

        const Text(
          "Recent Claims",
          style: TextStyle(
            fontFamily: 'AirbnbCereal',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 10),

        if (claims.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28),
            alignment: Alignment.center,
            child: Text(
              "No claims yet",
              style: TextStyle(
                fontFamily: 'AirbnbCereal',
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
            ),
          )
        else
          ...claims
              .map((claim) => _buildClaimItem(context, size, claim, currency)),
        const SizedBox(height: 12),

        // Footnote
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Icon(LucideIcons.info, size: 16, color: Color(0xFF0066FF)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Claim expenses and get reimbursed. Ensure receipts are clear and all details are accurate for faster approval.",
                  style: TextStyle(
                    fontFamily: 'AirbnbCereal',
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildClaimItem(
    BuildContext context,
    Size size,
    ClaimEntity claim,
    String currency,
  ) {
    final cat = _categoryVisual(claim.categoryEnum);
    final status = _statusVisual(claim.status);
    final dateStr =
        claim.date != null ? DateFormat('dd MMM yyyy').format(claim.date!) : '';
    final hasReceipt = (claim.receiptUrl ?? '').isNotEmpty;

    return GestureDetector(
      onTap: () => _showReceiptPreview(context, claim),
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: cat.bg, shape: BoxShape.circle),
                child: Icon(cat.icon, color: cat.color, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      claim.categoryEnum.label,
                      style: const TextStyle(
                        fontFamily: 'AirbnbCereal',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    if (claim.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        claim.description,
                        style: const TextStyle(
                          fontFamily: 'AirbnbCereal',
                          fontSize: 10,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                    if (dateStr.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        dateStr,
                        style: const TextStyle(
                          fontFamily: 'AirbnbCereal',
                          fontSize: 11,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                    if (hasReceipt) ...[
                      const SizedBox(height: 5),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            LucideIcons.paperclip,
                            size: 12,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 4),
                          Text(
                            "View receipt",
                            style: TextStyle(
                              fontFamily: 'AirbnbCereal',
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: status.bg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      status.label,
                      style: TextStyle(
                        fontFamily: 'AirbnbCereal',
                        fontWeight: FontWeight.bold,
                        fontSize: size.width * 0.023,
                        color: status.color,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _money(claim.amount, claim.currency),
                    style: const TextStyle(
                      fontFamily: 'AirbnbCereal',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  if (claim.reimbursed) ...[
                    const SizedBox(height: 2),
                    Text(
                      "Reimbursed",
                      style: TextStyle(
                        fontFamily: 'AirbnbCereal',
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF10B981),
                        fontSize: size.width * 0.023,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          if ((claim.decisionNote ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                claim.decisionNote!,
                style: const TextStyle(
                  fontFamily: 'AirbnbCereal',
                  fontSize: 11,
                  color: Color(0xFF6B7280),
                  height: 1.3,
                ),
              ),
            ),
          ],
        ],
      ),
      ),
    );
  }

  void _showReceiptPreview(BuildContext context, ClaimEntity claim) {
    final url = claim.receiptUrl;
    if (url == null || url.isEmpty) {
      _showToast(context, "No receipt attached for this claim");
      return;
    }

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header: title + close
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "${claim.categoryEnum.label} · ${_money(claim.amount, claim.currency)}",
                      style: const TextStyle(
                        fontFamily: 'AirbnbCereal',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Zoomable receipt image
              Flexible(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.contain,
                      placeholder: (c, _) => Container(
                        height: 320,
                        color: Colors.white10,
                        alignment: Alignment.center,
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      errorWidget: (c, _, __) => Container(
                        height: 320,
                        color: Colors.white10,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(LucideIcons.image_off,
                                color: Colors.white54, size: 36),
                            SizedBox(height: 8),
                            Text(
                              "Couldn't load receipt",
                              style: TextStyle(
                                fontFamily: 'AirbnbCereal',
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExpenseStatusItem(
    BuildContext context,
    String label,
    String value,
    String subText,
    IconData icon,
    Color color,
    Color bgColor,
  ) {
    final size = MediaQuery.of(context).size;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.15), width: 1.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'AirbnbCereal',
                fontSize: size.width * 0.028,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'AirbnbCereal',
                fontSize: size.width * 0.034,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subText,
              style: TextStyle(
                fontFamily: 'AirbnbCereal',
                fontSize: size.width * 0.024,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Add expense modal ───────────────────────────────────────────────────────

  void _addNewExpense(BuildContext screenContext) {
    final bloc = screenContext.read<ClaimsBloc>();
    const placeholder = 'Select Category';
    String selectedCategory = placeholder;
    DateTime? pickedDate;
    final dateCtrl = TextEditingController();
    final detailCtrl = TextEditingController();
    final amtCtrl = TextEditingController();

    showModalBottomSheet(
      context: screenContext,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final size = MediaQuery.of(context).size;
        File? receiptFile;
        String? attachmentName;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Add New Expense",
                    style: TextStyle(
                      fontFamily: 'AirbnbCereal',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 14),
                  CustomDropdown<String>(
                    value: selectedCategory,
                    items: [
                      placeholder,
                      ...ClaimCategory.values.map((c) => c.label),
                    ],
                    width: double.infinity,
                    buttonWidth: size.width - 64,
                    buttonColor: Colors.grey.shade50,
                    borderRadius: 10,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9.5,
                    ),
                    border: Border.all(color: Colors.grey.shade200, width: 1.0),
                    itemBuilder: (category, isSelected) {
                      return Text(
                        category,
                        style: TextStyle(
                          fontFamily: 'AirbnbCereal',
                          fontSize: 13.5,
                          color: category == placeholder
                              ? Colors.grey
                              : Colors.black87,
                        ),
                      );
                    },
                    onChanged: (String val) {
                      setModalState(() => selectedCategory = val);
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: dateCtrl,
                    readOnly: true,
                    style: const TextStyle(
                      fontFamily: 'AirbnbCereal',
                      fontSize: 13.5,
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2101),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: AppColors.primary,
                                onPrimary: Colors.white,
                                onSurface: Colors.black,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setModalState(() {
                          pickedDate = picked;
                          dateCtrl.text =
                              DateFormat('dd MMM yyyy').format(picked);
                        });
                      }
                    },
                    decoration: _inputDecoration(
                      hintText: "Date",
                      prefixIcon: LucideIcons.calendar,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: detailCtrl,
                    style: const TextStyle(
                      fontFamily: 'AirbnbCereal',
                      fontSize: 13.5,
                    ),
                    decoration: _inputDecoration(hintText: "Add description"),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: amtCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: const TextStyle(
                      fontFamily: 'AirbnbCereal',
                      fontSize: 13.5,
                    ),
                    decoration: _inputDecoration(hintText: "Amount (£)"),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    "Attach Receipt (optional)",
                    style: TextStyle(
                      fontFamily: 'AirbnbCereal',
                      fontSize: size.width * 0.03,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () => _pickReceipt(
                      context,
                      onPicked: (file) => setModalState(() {
                        receiptFile = file;
                        attachmentName = file.path.split('/').last;
                      }),
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 9.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 16),
                          const Icon(
                            LucideIcons.paperclip,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              attachmentName ?? "Upload Receipt / Camera",
                              style: const TextStyle(
                                fontFamily: 'AirbnbCereal',
                                fontSize: 12.0,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 40),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _PresshopCommonButton(
                    text: "Submit Claim",
                    backgroundColor: AppColors.primary,
                    height: 44,
                    fontSize: 14,
                    onPressed: () {
                      if (selectedCategory == placeholder) {
                        _showToast(context, "Please select a category");
                        return;
                      }
                      final amount = double.tryParse(amtCtrl.text.trim());
                      if (amount == null || amount <= 0) {
                        _showToast(context, "Please enter a valid amount");
                        return;
                      }
                      final category = ClaimCategory.values
                          .firstWhere((c) => c.label == selectedCategory)
                          .value;

                      bloc.add(AddClaim(
                        category: category,
                        date: pickedDate,
                        description: detailCtrl.text.trim(),
                        amount: amount,
                        receiptFile: receiptFile,
                      ));
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _pickReceipt(
    BuildContext context, {
    required void Function(File file) onPicked,
  }) {
    final picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.camera, color: AppColors.primary),
              title: const Text("Take Photo",
                  style: TextStyle(fontFamily: 'AirbnbCereal')),
              onTap: () async {
                Navigator.pop(sheetCtx);
                try {
                  final img = await picker.pickImage(source: ImageSource.camera);
                  if (img != null) onPicked(File(img.path));
                } catch (e) {
                  if (context.mounted) {
                    _showToast(context, "Camera access denied");
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.image, color: AppColors.primary),
              title: const Text("Choose from Gallery",
                  style: TextStyle(fontFamily: 'AirbnbCereal')),
              onTap: () async {
                Navigator.pop(sheetCtx);
                try {
                  final img =
                      await picker.pickImage(source: ImageSource.gallery);
                  if (img != null) onPicked(File(img.path));
                } catch (e) {
                  if (context.mounted) {
                    _showToast(context, "Gallery access denied");
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    IconData? prefixIcon,
    double fontSize = 13.5,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, size: 18, color: Colors.grey)
          : null,
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      hintStyle: TextStyle(
        fontFamily: 'AirbnbCereal',
        color: Colors.grey,
        fontSize: fontSize,
      ),
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
  }
}

class _PresshopCommonButton extends StatelessWidget {
  final String? text;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isLoading;
  final Color? backgroundColor;
  final Color textColor;
  final double height;
  final double? width;
  final double borderRadius;
  final double fontSize;
  final FontWeight fontWeight;
  final BorderSide? borderSide;

  const _PresshopCommonButton({
    this.text,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor = Colors.white,
    this.height = 48,
    this.width,
    this.borderRadius = 12,
    this.fontSize = 15,
    this.fontWeight = FontWeight.bold,
    this.borderSide,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onPressed != null && !isLoading;

    final Widget content = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(textColor),
              strokeWidth: 2.5,
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                icon!,
                if (text != null) const SizedBox(width: 8),
              ],
              if (text != null)
                Text(
                  text!,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: fontWeight,
                    color: textColor,
                    fontFamily: "AirbnbCereal",
                  ),
                ),
            ],
          );

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.primary,
          disabledBackgroundColor:
              (backgroundColor ?? AppColors.primary).withOpacity(0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            side: borderSide ?? BorderSide.none,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: content,
      ),
    );
  }
}
