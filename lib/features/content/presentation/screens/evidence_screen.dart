import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:presshop_enterprise/common/widgets/app_app_bar.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../common/widgets/employee_app_bar.dart';
import '../../../../common/widgets/loading_widget.dart';
import '../../../../config/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/routes/app_router.dart';
import '../../data/models/enterprise_feed_model.dart';

class EvidenceScreen extends StatefulWidget {
  final bool hideLeading;
  const EvidenceScreen({super.key, this.hideLeading = true});

  @override
  State<EvidenceScreen> createState() => _EvidenceScreenState();
}

class _EvidenceScreenState extends State<EvidenceScreen> {
  final ScrollController _scrollController = ScrollController();
  List<EnterpriseFeedItem> _feedList = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 1;
  static const int _limit = 20;

  String _selectedSort = "Newest First";

  final List<_FeedFilterModel> _priorityFilters = [
    _FeedFilterModel(name: "High Priority", icon: "ic_exclusive.png"),
    _FeedFilterModel(name: "Medium Priority", icon: "ic_live_content.png"),
    _FeedFilterModel(name: "Low Priority", icon: "ic_share.png"),
  ];

  final List<_FeedFilterModel> _statusFilters = [
    _FeedFilterModel(name: "Assigned", icon: "ic_pending.png"),
    _FeedFilterModel(name: "Ongoing", icon: "ic_clock.png"),
    _FeedFilterModel(name: "Completed", icon: "ic_sold.png"),
  ];

  final _FeedFilterModel _dateFilter = _FeedFilterModel(
    name: "Custom Date Range",
    icon: "ic_yearly_calendar.png",
  );

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _loadFeed(refresh: true);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _loadFeed();
      }
    }
  }

  Future<void> _loadFeed({bool refresh = false}) async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      if (refresh) {
        _page = 1;
        _hasMore = true;
      }
    });

    try {
      final apiClient = getIt<ApiClient>();

      // Build query parameters
      final Map<String, dynamic> queryParams = {
        'page': _page,
        'limit': _limit,
        'sortBy': 'createdAt',
        'sortOrder': _selectedSort == "Newest First" ? 'desc' : 'asc',
      };

      // Priority Filter
      final selectedPriorities = _priorityFilters
          .where((f) => f.isSelected)
          .map((f) => f.name.toLowerCase().replaceAll(' priority', ''))
          .toList();
      if (selectedPriorities.isNotEmpty) {
        queryParams['priority'] = selectedPriorities.join(',');
      }

      // Status Filter
      final selectedStatuses = _statusFilters
          .where((f) => f.isSelected)
          .map((f) => f.name.toLowerCase())
          .toList();
      if (selectedStatuses.isNotEmpty) {
        queryParams['status'] = selectedStatuses.join(',');
      }

      // Date Range Filter
      if (_dateFilter.fromDate != null) {
        queryParams['startDate'] = _dateFilter.fromDate;
      }
      if (_dateFilter.toDate != null) {
        queryParams['endDate'] = _dateFilter.toDate;
      }

      final response = await apiClient.get(
        ApiEndpoints.feed,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final feedResponse = EnterpriseFeedResponse.fromJson(response.data);
        setState(() {
          if (refresh) {
            _feedList = feedResponse.data;
          } else {
            _feedList.addAll(feedResponse.data);
          }
          _page++;
          if (feedResponse.data.length < _limit) {
            _hasMore = false;
          }
        });
      }
    } catch (e) {
      debugPrint("Error loading feed: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setBottomSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              padding: EdgeInsets.only(
                top: 24,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 48.w,
                        height: 5.h,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Sort & Filter",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 20.sp,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setBottomSheetState(() {
                              _selectedSort = "Newest First";
                              for (var item in _priorityFilters) {
                                item.isSelected = false;
                              }
                              for (var item in _statusFilters) {
                                item.isSelected = false;
                              }
                              _dateFilter.isSelected = false;
                              _dateFilter.fromDate = null;
                              _dateFilter.toDate = null;
                            });
                          },
                          child: Text(
                            "Clear All",
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Color(0xFFE2E8F0)),
                    SizedBox(height: 12.h),
                    Text(
                      "Sort By",
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        _buildSortChip(
                          context,
                          setBottomSheetState,
                          "Newest First",
                        ),
                        SizedBox(width: 12.w),
                        _buildSortChip(
                          context,
                          setBottomSheetState,
                          "Oldest First",
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      "Custom Date Range",
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setBottomSheetState(() {
                                  _dateFilter.fromDate = picked
                                      .toIso8601String();
                                  _dateFilter.isSelected = true;
                                });
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                vertical: 10.h,
                                horizontal: 12.w,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _dateFilter.fromDate != null
                                        ? DateFormat('dd MMM yyyy').format(
                                            DateTime.parse(
                                              _dateFilter.fromDate!,
                                            ),
                                          )
                                        : "From Date",
                                    style: TextStyle(
                                      color: _dateFilter.fromDate != null
                                          ? Colors.black87
                                          : Colors.grey[500],
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                  Icon(
                                    Icons.calendar_month,
                                    size: 16.sp,
                                    color: Colors.grey[600],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              if (_dateFilter.fromDate == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please select a From Date first',
                                    ),
                                  ),
                                );
                                return;
                              }
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.parse(
                                  _dateFilter.fromDate!,
                                ),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setBottomSheetState(() {
                                  _dateFilter.toDate = picked.toIso8601String();
                                  _dateFilter.isSelected = true;
                                });
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                vertical: 10.h,
                                horizontal: 12.w,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _dateFilter.toDate != null
                                        ? DateFormat('dd MMM yyyy').format(
                                            DateTime.parse(_dateFilter.toDate!),
                                          )
                                        : "To Date",
                                    style: TextStyle(
                                      color: _dateFilter.toDate != null
                                          ? Colors.black87
                                          : Colors.grey[500],
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                  Icon(
                                    Icons.calendar_month,
                                    size: 16.sp,
                                    color: Colors.grey[600],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 32.h),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.black87,
                              side: BorderSide(color: Colors.grey[400]!),
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text(
                              "Cancel",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15.sp,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              _loadFeed(refresh: true);
                            },
                            child: Text(
                              "Apply Filters",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15.sp,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSortChip(
    BuildContext context,
    StateSetter setBottomSheetState,
    String label,
  ) {
    final bool isSelected = _selectedSort == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primary.withValues(alpha: 0.15),
      backgroundColor: Colors.grey[100],
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12.sp,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.transparent,
          width: 1,
        ),
      ),
      showCheckmark: false,
      onSelected: (bool selected) {
        if (selected) {
          setBottomSheetState(() {
            _selectedSort = label;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: widget.hideLeading
          ? EmployeeAppBar(onFilterTap: _showFilterBottomSheet)
          : AppAppBar(
              showBack: true,
              title: "Content & evidence",
              elevation: 0,
              titleSpacing: 0,
            ),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 8.h),
            const Divider(height: 1, thickness: 0.5, color: Color(0xFFE0E0E0)),
            Expanded(
              child: _isLoading && _feedList.isEmpty
                  ? const LoadingWidget()
                  : RefreshIndicator(
                      onRefresh: () => _loadFeed(refresh: true),
                      child: _feedList.isNotEmpty
                          ? GridView.builder(
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              controller: _scrollController,
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 16.h,
                              ),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 0.69,
                                    mainAxisSpacing: 16.w,
                                    crossAxisSpacing: 16.w,
                                  ),
                              itemCount: _feedList.length,
                              itemBuilder: (context, index) {
                                return InkWell(
                                  onTap: () {
                                    context.push(
                                      AppRoutes.evidenceDetails,
                                      extra: _feedList[index],
                                    );
                                  },
                                  child: _feedCard(_feedList[index]),
                                );
                              },
                            )
                          : SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              child: Container(
                                height: 400.h,
                                alignment: Alignment.center,
                                child: const Text("No Content Found"),
                              ),
                            ),
                    ),
            ),
            if (_isLoading && _feedList.isNotEmpty)
              Padding(
                padding: EdgeInsets.all(8.r),
                child: LoadingWidget(size: 40.w),
              ),
          ],
        ),
      ),
    );
  }

  Widget _feedCard(EnterpriseFeedItem item) {
    final firstContent = item.content.isNotEmpty ? item.content.first : null;
    final imageUrl = firstContent?.previewUrl ?? '';
    final location =
        (firstContent?.captureAddressLine1 != null &&
            firstContent!.captureAddressLine1.isNotEmpty)
        ? firstContent.captureAddressLine1
        : 'Location Not Captured';
    final capturedAt =
        (firstContent?.capturedAt != null &&
            firstContent!.capturedAt.isNotEmpty)
        ? firstContent.capturedAt
        : (firstContent?.createdAt ?? item.task.createdAt);
    final description = item.task.description.isNotEmpty
        ? item.task.description
        : (firstContent?.description ?? '');

    return Container(
      padding: EdgeInsets.only(left: 12.w, right: 12.w, top: 12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            spreadRadius: 2,
            blurRadius: 1,
          ),
        ],
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _feedThumbnail(imageUrl, item.content),
          SizedBox(height: 8.h),
          Text(
            item.task.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (description.isNotEmpty) ...[
            SizedBox(height: 4.h),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
          const Spacer(),
          if (capturedAt.isNotEmpty)
            Wrap(
              spacing: 6.w,
              runSpacing: 4.h,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      "assets/icons/ic_clock.png",
                      height: 11.w,
                      color: Colors.grey[600],
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      _formatTime(capturedAt),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      "assets/icons/ic_yearly_calendar.png",
                      height: 11.w,
                      color: Colors.grey[600],
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      _formatDate(capturedAt),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          SizedBox(height: 4.h),
          if (location.isNotEmpty)
            Row(
              children: [
                Image.asset(
                  "assets/icons/ic_location.png",
                  height: 12.w,
                  color: Colors.grey[600],
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: Text(
                    location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          SizedBox(height: 8.h),
        ],
      ),
    );
  }

  Widget _feedThumbnail(
    String imageUrl,
    List<EnterpriseFeedContent> contentList,
  ) {
    final firstContent = contentList.isNotEmpty ? contentList.first : null;
    final showImage = _isDisplayableImage(firstContent);
    final placeholderType = firstContent?.evidenceType ?? "image";
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.r),
      child: Stack(
        children: [
          showImage
              ? Image.network(
                  imageUrl,
                  height: 110.w,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _imagePlaceholder(placeholderType),
                )
              : _imagePlaceholder(placeholderType),
          if (showImage)
            Image.asset(
              "assets/images/watermark1.png",
              height: 110.w,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          Positioned(
            right: 8.w,
            top: 8.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Center(
                child: Text(
                  "${contentList.length}",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder(String type) {
    return Container(
      height: 110.w,
      width: double.infinity,
      color: Colors.grey[300],
      child: Center(
        child: Icon(_evidenceTypeIcon(type), size: 40.w, color: Colors.grey),
      ),
    );
  }

  String _formatTime(String iso) {
    try {
      final parsed = DateTime.parse(iso);
      return DateFormat('hh:mm a').format(parsed.toLocal());
    } catch (_) {
      return '';
    }
  }

  String _formatDate(String iso) {
    try {
      final parsed = DateTime.parse(iso);
      return DateFormat('dd MMM yyyy').format(parsed.toLocal());
    } catch (_) {
      return '';
    }
  }
}

bool _isDisplayableImage(EnterpriseFeedContent? content) {
  if (content == null) return false;
  final url = content.previewUrl.toLowerCase();
  if (url.isEmpty) return false;

  final type = content.evidenceType.toLowerCase();
  if (type == 'video' ||
      type == 'audio' ||
      type == 'doc' ||
      type == 'document' ||
      type == 'pdf') {
    return false;
  }

  const nonImageExtensions = [
    '.m4a',
    '.mp3',
    '.wav',
    '.aac',
    '.ogg',
    '.flac',
    '.mp4',
    '.mov',
    '.webm',
    '.m4v',
    '.avi',
    '.mkv',
    '.pdf',
    '.doc',
    '.docx',
  ];
  if (nonImageExtensions.any((ext) => url.contains(ext))) return false;

  return true;
}

IconData _evidenceTypeIcon(String type) {
  switch (type.toLowerCase()) {
    case 'video':
      return Icons.videocam_outlined;
    case 'audio':
      return Icons.audiotrack_outlined;
    case 'doc':
    case 'document':
    case 'pdf':
      return Icons.description_outlined;
    default:
      return Icons.image_outlined;
  }
}

class _FeedFilterModel {
  String name;
  String icon;
  bool isSelected;
  String? fromDate;
  String? toDate;

  _FeedFilterModel({
    required this.name,
    required this.icon,
    this.isSelected = false,
    this.fromDate,
    this.toDate,
  });
}
