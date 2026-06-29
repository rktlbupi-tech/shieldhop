import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:presshop_enterprise/common/widgets/sliding_tabs.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../../../../config/di/injection.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../common/widgets/app_app_bar.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/routes/app_router.dart';
import '../../domain/entities/form_entity.dart';
import '../bloc/submit_forms_bloc.dart';

class SubmitFormsScreen extends StatefulWidget {
  const SubmitFormsScreen({super.key});

  @override
  State<SubmitFormsScreen> createState() => _SubmitFormsScreenState();
}

class _SubmitFormsScreenState extends State<SubmitFormsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final PageController _pageController = PageController();

  // Tabs navigation
  bool _showSubmissionsTab = false;

  String _searchQuery = "";
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _pageController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  String _getFormNameById(String formId, List<FormEntity> forms) {
    for (final form in forms) {
      if (form.id == formId) {
        return form.name;
      }
    }
    return 'Form';
  }

  FormEntity? _getFormById(String formId, List<FormEntity> forms) {
    for (final form in forms) {
      if (form.id == formId) {
        return form;
      }
    }
    return null;
  }

  Color _getCardIconColor(int index) => AppColors.primary;

  Color _getCardBgColor(int index) => AppColors.primary.withValues(alpha: 0.08);

  void _shareSubmission(
    BuildContext buttonContext,
    FormSubmissionEntity submission,
    String formName,
  ) {
    final formId = submission.formId;
    final submissionId = submission.id;
    final token = getIt<SharedPreferences>().getString('auth_token') ?? '';

    final viewUrl =
        "https://presshop.dev/f/$formId/view/$submissionId?token=$token";

    Rect? shareOrigin;
    final box = buttonContext.findRenderObject() as RenderBox?;
    if (box != null) {
      shareOrigin = box.localToGlobal(Offset.zero) & box.size;
    }
    if (shareOrigin == null ||
        shareOrigin.width == 0 ||
        shareOrigin.height == 0) {
      shareOrigin = const Rect.fromLTWH(0, 0, 100, 100);
    }

    Share.share(
      "Check out my submission for $formName:\n$viewUrl",
      sharePositionOrigin: shareOrigin,
    );
  }

  void _onSubmissionTap(FormSubmissionEntity submission, String formName) {
    final formId = submission.formId;
    final submissionId = submission.id;
    final token = getIt<SharedPreferences>().getString('auth_token') ?? '';

    final viewUrl =
        "https://presshop.dev/f/$formId/view/$submissionId?token=$token";

    context.push(
      AppRoutes.webViewForm,
      extra: {'formId': formId, 'formName': formName, 'customUrl': viewUrl},
    );
  }

  void _openForm(String formId, String formName) {
    context
        .push(
          AppRoutes.webViewForm,
          extra: {'formId': formId, 'formName': formName},
        )
        .then((_) {
          // Reload on return
          if (mounted) {
            context.read<SubmitFormsBloc>().add(
              const FetchAvailableFormsEvent(),
            );
            if (_showSubmissionsTab) {
              context.read<SubmitFormsBloc>().add(
                const FetchSubmissionsEvent(),
              );
            }
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return BlocProvider<SubmitFormsBloc>(
      create: (_) =>
          getIt<SubmitFormsBloc>()..add(const FetchAvailableFormsEvent()),
      child: BlocBuilder<SubmitFormsBloc, SubmitFormsState>(
        builder: (context, state) {
          final query = _searchQuery.toLowerCase();

          // Reactively filter lists locally for fast visual feedback
          final filteredForms = state.availableForms.where((form) {
            if (query.isEmpty) return true;
            final name = form.name.toLowerCase();
            final description = form.description.toLowerCase();
            final tags = form.tags.map((t) => t.toLowerCase()).toList();
            return name.contains(query) ||
                description.contains(query) ||
                tags.any((tag) => tag.contains(query));
          }).toList();

          final filteredSubmissions = state.submissions.where((sub) {
            if (query.isEmpty) return true;
            final formName = _getFormNameById(
              sub.formId,
              state.availableForms,
            ).toLowerCase();
            final code = sub.submissionCode.toLowerCase();
            final status = sub.status.toLowerCase();
            return formName.contains(query) ||
                code.contains(query) ||
                status.contains(query);
          }).toList();

          return Scaffold(
            backgroundColor: const Color(0xFFF5F6FA),
            appBar: AppAppBar(
              title: "Submit form",
              elevation: 0.5,
              centerTitle: false,
              titleSpacing: 0,
              showBack: true,
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Persistent Search Bar
                Container(
                  padding: EdgeInsets.fromLTRB(
                    size.width * 0.03,
                    size.width * 0.03,
                    size.width * 0.03,
                    0,
                  ),
                  color: Colors.white,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: _showSubmissionsTab
                          ? "Search submitted forms..."
                          : "Search available forms...",
                      prefixIcon: const Icon(LucideIcons.search, size: 20),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });

                      if (_debounce?.isActive ?? false) _debounce!.cancel();
                      _debounce = Timer(const Duration(milliseconds: 500), () {
                        if (_showSubmissionsTab) {
                          context.read<SubmitFormsBloc>().add(
                            FetchSubmissionsEvent(query: val),
                          );
                        } else {
                          context.read<SubmitFormsBloc>().add(
                            FetchAvailableFormsEvent(query: val),
                          );
                        }
                      });
                    },
                  ),
                ),

                // Top Segmented Tab Selector
                Container(
                  color: Colors.white,
                  padding: EdgeInsets.all(size.width * 0.03),
                  child: SlidingTabs(
                    selectedIndex: _showSubmissionsTab ? 1 : 0,
                    onTabChanged: (index) {
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    tabs: const ["Available", "Submitted"],
                  ),
                ),

                // Sliding View
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _showSubmissionsTab = (index == 1);
                      });
                      if (index == 1 && state.submissions.isEmpty) {
                        context.read<SubmitFormsBloc>().add(
                          FetchSubmissionsEvent(query: _searchQuery),
                        );
                      }
                    },
                    children: [
                      _buildAvailableFormsList(
                        context,
                        state,
                        filteredForms,
                        size,
                      ),
                      _buildSubmissionsList(
                        context,
                        state,
                        filteredSubmissions,
                        size,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAvailableFormsList(
    BuildContext context,
    SubmitFormsState state,
    List<FormEntity> forms,
    Size size,
  ) {
    if (state.isAvailableFormsLoading && forms.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.availableFormsError != null && forms.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                state.availableFormsError!,
                style: const TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  context.read<SubmitFormsBloc>().add(
                    FetchAvailableFormsEvent(query: _searchQuery),
                  );
                },
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<SubmitFormsBloc>().add(
          FetchAvailableFormsEvent(query: _searchQuery),
        );
      },
      child: forms.isEmpty
          ? SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: size.height * 0.5,
                child: const Center(
                  child: Text(
                    "No forms available",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            )
          : ListView.builder(
              physics: const BouncingScrollPhysics(),
              clipBehavior: Clip.none,
              padding: EdgeInsets.fromLTRB(
                size.width * 0.04,
                size.width * 0.03,
                size.width * 0.04,
                size.width * 0.03,
              ),
              itemCount: forms.length,
              itemBuilder: (context, index) {
                final form = forms[index];
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: 8.0,
                    top: index == 0 ? 8.0 : 0.0,
                  ),
                  child: _buildFormCard(
                    size: size,
                    formId: form.id,
                    formName: form.name,
                    formCode: form.formCode,
                    thumbnailUrl: form.thumbnailUrl,
                    index: index,
                  ),
                );
              },
            ),
    );
  }

  Widget _buildSubmissionsList(
    BuildContext context,
    SubmitFormsState state,
    List<FormSubmissionEntity> submissions,
    Size size,
  ) {
    if (state.isSubmissionsLoading && submissions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.submissionsError != null && submissions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                state.submissionsError!,
                style: const TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  context.read<SubmitFormsBloc>().add(
                    FetchSubmissionsEvent(query: _searchQuery),
                  );
                },
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<SubmitFormsBloc>().add(
          FetchSubmissionsEvent(query: _searchQuery),
        );
      },
      child: submissions.isEmpty
          ? SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: size.height * 0.5,
                child: const Center(
                  child: Text(
                    "No submissions found",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            )
          : ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                size.width * 0.04,
                size.width * 0.03,
                size.width * 0.04,
                size.width * 0.03,
              ),
              itemCount: submissions.length,
              itemBuilder: (context, index) {
                final sub = submissions[index];
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: 8.0,
                    top: index == 0 ? 8.0 : 0.0,
                  ),
                  child: _buildSubmissionCard(context, state, sub, index),
                );
              },
            ),
    );
  }

  Widget _buildSubmissionCard(
    BuildContext context,
    SubmitFormsState state,
    FormSubmissionEntity submission,
    int index,
  ) {
    final formName = _getFormNameById(submission.formId, state.availableForms);
    final code = submission.submissionCode;
    final dateStr = submission.createdAt;
    final formattedDate = DateFormat('MMM d, yyyy').format(dateStr);

    final form = _getFormById(submission.formId, state.availableForms);
    final thumbnailUrl = form != null ? form.thumbnailUrl : '';
    final cardBg = _getCardBgColor(index);
    final cardIconColor = _getCardIconColor(index);

    return InkWell(
      onTap: () => _onSubmissionTap(submission, formName),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEFF1F6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 58,
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: cardIconColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: thumbnailUrl.isNotEmpty
                    ? Image.network(
                        thumbnailUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Icon(
                            Icons.picture_as_pdf,
                            color: cardIconColor,
                            size: 20,
                          ),
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.picture_as_pdf,
                          color: cardIconColor,
                          size: 20,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formName,
                    style: const TextStyle(
                      color: Color(0xFF1F2937),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'AirbnbCereal',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    code,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 11,
                      fontFamily: 'AirbnbCereal',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.calendar,
                        size: 10,
                        color: Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        formattedDate,
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 10,
                          fontFamily: 'AirbnbCereal',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Builder(
              builder: (buttonContext) {
                return IconButton(
                  icon: const Icon(
                    LucideIcons.share_2,
                    color: Color(0xFF9CA3AF),
                    size: 20,
                  ),
                  onPressed: () =>
                      _shareSubmission(buttonContext, submission, formName),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard({
    required Size size,
    required String formId,
    required String formName,
    required String formCode,
    required String thumbnailUrl,
    required int index,
  }) {
    final cardBg = _getCardBgColor(index);
    final cardIconColor = _getCardIconColor(index);

    return InkWell(
      onTap: () => _openForm(formId, formName),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEFF1F6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 58,
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: cardIconColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: thumbnailUrl.isNotEmpty
                    ? Image.network(
                        thumbnailUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Icon(
                            Icons.picture_as_pdf,
                            color: cardIconColor,
                            size: 20,
                          ),
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.picture_as_pdf,
                          color: cardIconColor,
                          size: 20,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formName,
                    style: const TextStyle(
                      color: Color(0xFF1F2937),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'AirbnbCereal',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formCode.isNotEmpty ? formCode : "Honda/123/2026",
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 11,
                      fontFamily: 'AirbnbCereal',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Icon(Icons.chevron_right, color: Color(0xFF9CA3AF), size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
