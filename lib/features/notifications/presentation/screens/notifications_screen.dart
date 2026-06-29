import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import '../../../../config/di/injection.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../common/widgets/app_app_bar.dart';
import '../../../../common/widgets/loading_widget.dart';
import '../bloc/notifications_bloc.dart';
import '../../domain/entities/notification_entity.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          getIt<NotificationsBloc>()..add(const FetchNotifications()),
      child: const _NotificationsView(),
    );
  }
}

class _NotificationsView extends StatefulWidget {
  const _NotificationsView();

  @override
  State<_NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<_NotificationsView> {
  Widget _buildNotificationBadge(int unreadCount) {
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 28.w,
            width: 28.w,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade800, width: 1.5.w),
              borderRadius: BorderRadius.circular(6.r),
            ),
          ),
          Positioned(
            right: -5.w,
            top: -5.h,
            child: Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: unreadCount > 0
                    ? AppColors.primary
                    : Colors.grey.shade400,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5.w),
              ),
              child: Text(
                unreadCount > 99 ? "99+" : unreadCount.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMarkAllReadDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          contentPadding: EdgeInsets.zero,
          insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
          content: Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  AppIcons.delete,
                  colorFilter: const ColorFilter.mode(
                    AppColors.primary,
                    BlendMode.srcIn,
                  ),
                  width: 40.w,
                  height: 40.w,
                ),
                SizedBox(height: 16.h),
                Text(
                  "Are you sure you want to mark\nall notifications as read?",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'AirbnbCereal',
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24.h),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => Navigator.pop(dialogContext),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            "Cancel",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
                              fontFamily: 'AirbnbCereal',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          context.read<NotificationsBloc>().add(
                            const MarkAllAsRead(),
                          );
                          Navigator.pop(dialogContext);
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            "Confirm",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
                              fontFamily: 'AirbnbCereal',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64.sp,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: 16.h),
          Text(
            "No notifications yet",
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey.shade400,
              fontWeight: FontWeight.w600,
              fontFamily: 'AirbnbCereal',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(NotificationEntity notification) {
    return InkWell(
      onTap: () {
        // Handle notification tapping: redirect to task or details based on metadata / type
        final taskId =
            notification.taskId ??
            notification.targetId ??
            notification.metadata['task_id'] ??
            notification.metadata['taskId'];
        if (taskId != null && taskId.toString().isNotEmpty) {
          // If task ID is present, navigate to task detail screen or dashboard tasks tab
          // This is aligned with the old app redirection behavior
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Loading details for task: $taskId"),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : Colors.grey.shade50,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade100, width: 1.w),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(6.r),
              decoration: BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Image.asset(
                AppIcons.rabbitLogo,
                color: Colors.white,
                width: 18.w,
                height: 18.w,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: notification.isRead
                                ? FontWeight.w600
                                : FontWeight.bold,
                            color: Colors.black,
                            fontFamily: 'AirbnbCereal',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: EdgeInsets.only(right: 10.w),
                        child: Text(
                          DateFormat(
                            'hh:mm a, dd MMM yyyy',
                          ).format(notification.createdAt),
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w300,
                            fontFamily: 'AirbnbCereal',
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    notification.body,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.black,
                      fontWeight: FontWeight.normal,
                      fontFamily: 'AirbnbCereal',
                    ),
                  ),
                  if (notification.imageUrl != null &&
                      notification.imageUrl!.isNotEmpty) ...[
                    SizedBox(height: 8.h),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: Image.network(
                        notification.imageUrl!,
                        width: double.infinity,
                        height: 150.h,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationsBloc, NotificationsState>(
      builder: (context, state) {
        int unreadCount = 0;
        List<NotificationEntity> notifications = [];
        bool isLoading = state is NotificationsLoading;

        if (state is NotificationsLoaded) {
          notifications = state.notifications;
          unreadCount = state.unreadCount;
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppAppBar(
            title: "Notifications",
            showBack: true,
            elevation: 0,
            titleSpacing: 0,
            actions: [
              _buildNotificationBadge(unreadCount),
              SizedBox(width: 16.w),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Divider(color: Colors.grey.shade200, thickness: 1.5.h),
              ),
              if (notifications.isNotEmpty && unreadCount > 0)
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                  child: InkWell(
                    onTap: () => _showMarkAllReadDialog(context),
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Text(
                        "Mark all read",
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                          fontFamily: 'AirbnbCereal',
                        ),
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: isLoading && notifications.isEmpty
                    ? const LoadingWidget()
                    : notifications.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: () async {
                          context.read<NotificationsBloc>().add(
                            const FetchNotifications(),
                          );
                          await Future.delayed(
                            const Duration(milliseconds: 500),
                          );
                        },
                        child: ListView.separated(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          itemCount: notifications.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 1),
                          itemBuilder: (context, index) {
                            return _buildNotificationItem(notifications[index]);
                          },
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
