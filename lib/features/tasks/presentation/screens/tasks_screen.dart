// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:go_router/go_router.dart';
// import '../../../../common/widgets/app_app_bar.dart';

// class TasksScreen extends StatefulWidget {
//   const TasksScreen({super.key});

//   @override
//   State<TasksScreen> createState() => _TasksScreenState();
// }

// class _TasksScreenState extends State<TasksScreen> {
//   final List<_DummyScheduleTask> _tasks = [
//     _DummyScheduleTask(
//       id: "1",
//       title: "Cover local protest",
//       startTime: "10:00",
//       endTime: "14:00",
//       location: "City Centre",
//       color: Colors.red,
//       mediaHouseLogo: "https://picsum.photos/100",
//     ),
//     _DummyScheduleTask(
//       id: "2",
//       title: "Interview Mayor",
//       startTime: "15:00",
//       endTime: "16:30",
//       location: "City Hall",
//       color: Colors.orange,
//       mediaHouseLogo: "https://picsum.photos/101",
//     ),
//     _DummyScheduleTask(
//       id: "3",
//       title: "Weather report footage",
//       startTime: "17:00",
//       endTime: "18:00",
//       location: "River Side",
//       color: Colors.blue,
//       mediaHouseLogo: "https://picsum.photos/102",
//     ),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppAppBar(title: 'My Tasks'),
//       body: Column(
//         children: [
//           // Header (similar to integrated list header)
//           Container(
//             width: double.infinity,
//             padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 12.h),
//             color: Colors.white,
//             child: Row(
//               children: [
//                 Container(
//                   width: 4.w,
//                   height: 20.h,
//                   decoration: BoxDecoration(
//                     color: const Color(0xFF007AFF),
//                     borderRadius: BorderRadius.circular(2.r),
//                   ),
//                 ),
//                 SizedBox(width: 12.w),
//                 Text(
//                   "Today's Tasks", // Dummy title
//                   style: TextStyle(
//                     fontSize: 16.sp,
//                     fontWeight: FontWeight.w800,
//                     color: Colors.black,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Expanded(
//             child: ListView.builder(
//               physics: const AlwaysScrollableScrollPhysics(
//                 parent: BouncingScrollPhysics(),
//               ),
//               padding: EdgeInsets.symmetric(horizontal: 20.w),
//               itemCount: _tasks.length,
//               itemBuilder: (context, index) {
//                 return _TimelineTaskCard(task: _tasks[index]);
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _TimelineTaskCard extends StatelessWidget {
//   final _DummyScheduleTask task;

//   const _TimelineTaskCard({required this.task});

//   String _to12HourFormat(String timeStr) {
//     try {
//       final parts = timeStr.split(':');
//       if (parts.length >= 2) {
//         int hour = int.parse(parts[0]);
//         int minute = int.parse(parts[1]);
//         String ampm = hour >= 12 ? 'PM' : 'AM';
//         int displayHour = hour % 12;
//         if (displayHour == 0) displayHour = 12;
//         String hourStr = displayHour.toString().padLeft(2, '0');
//         String minuteStr = minute.toString().padLeft(2, '0');
//         return "$hourStr:$minuteStr $ampm";
//       }
//     } catch (_) {}
//     return timeStr;
//   }

//   @override
//   Widget build(BuildContext context) {
//     Color bgColor = task.color.withValues(alpha: 0.05);
//     Color accentColor = task.color;

//     return GestureDetector(
//       onTap: () {
//         context.push('/task-details/${task.id}');
//       },
//       child: Container(
//         width: double.infinity,
//         margin: EdgeInsets.only(bottom: 10.h),
//         decoration: BoxDecoration(
//           color: bgColor,
//           borderRadius: BorderRadius.circular(16.r),
//         ),
//         child: IntrinsicHeight(
//           child: Row(
//             children: [
//               Container(
//                 width: 4.5.w,
//                 decoration: BoxDecoration(
//                   color: accentColor,
//                   borderRadius: BorderRadius.only(
//                     topLeft: Radius.circular(16.r),
//                     bottomLeft: Radius.circular(16.r),
//                   ),
//                 ),
//               ),
//               Expanded(
//                 child: Padding(
//                   padding: EdgeInsets.symmetric(
//                     horizontal: 16.w,
//                     vertical: 10.h,
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         task.title,
//                         style: TextStyle(
//                           fontWeight: FontWeight.w700,
//                           fontSize: 14.sp,
//                           color: Colors.black,
//                         ),
//                       ),
//                       SizedBox(height: 4.h),
//                       Text(
//                         "${_to12HourFormat(task.startTime)} - ${_to12HourFormat(task.endTime)}",
//                         style: TextStyle(
//                           fontWeight: FontWeight.w400,
//                           fontSize: 12.sp,
//                           color: Colors.grey.shade600,
//                         ),
//                       ),
//                       SizedBox(height: 5.h),
//                       Row(
//                         children: [
//                           Icon(
//                             Icons.location_on,
//                             size: 12.sp,
//                             color: Colors.grey.shade500,
//                           ),
//                           SizedBox(width: 4.w),
//                           Expanded(
//                             child: Text(
//                               task.location,
//                               style: TextStyle(
//                                 fontWeight: FontWeight.w400,
//                                 fontSize: 12.sp,
//                                 color: Colors.grey.shade500,
//                               ),
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               Padding(
//                 padding: EdgeInsets.only(right: 18.w),
//                 child: Container(
//                   width: 42.w,
//                   height: 42.w,
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     shape: BoxShape.circle,
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withValues(alpha: 0.04),
//                         blurRadius: 10,
//                         offset: const Offset(0, 4),
//                       ),
//                     ],
//                   ),
//                   child: ClipOval(
//                     child: task.mediaHouseLogo.isNotEmpty
//                         ? Image.network(
//                             task.mediaHouseLogo,
//                             fit: BoxFit.cover,
//                             errorBuilder: (_, __, ___) => const Icon(
//                               Icons.business,
//                               size: 20,
//                               color: Colors.grey,
//                             ),
//                           )
//                         : const Icon(
//                             Icons.business,
//                             size: 20,
//                             color: Colors.grey,
//                           ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _DummyScheduleTask {
//   final String id;
//   final String title;
//   final String startTime;
//   final String endTime;
//   final String location;
//   final Color color;
//   final String mediaHouseLogo;

//   _DummyScheduleTask({
//     required this.id,
//     required this.title,
//     required this.startTime,
//     required this.endTime,
//     required this.location,
//     required this.color,
//     required this.mediaHouseLogo,
//   });
// }
