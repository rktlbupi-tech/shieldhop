import 'dart:ui';

import 'package:flutter_lucide/flutter_lucide.dart';

class AppConstantData {
  AppConstantData._();

  static const List<String> queryTypes = [
    'Medical Issue',
    'Vehicle Breakdown',
    'Transport Delay',
    'Traffic Delay',
    'Personal Emergency',
    'App / Check-In Issue',
    'Other Reason',
  ];

  static const List<Map<String, dynamic>> queries = [
    {
      'id': 'Q-9843',
      'date': '04 Jun 2026',
      'type': 'Missing Clock Out',
      'status': 'Approved',
      'description': 'Forgot to clock out on Thursday. Left shift at 6:00 PM.',
      'adminComment': 'Log updated successfully to 6:00 PM.',
    },
    {
      'id': 'Q-9850',
      'date': '08 Jun 2026',
      'type': 'Incorrect Hours',
      'status': 'Pending',
      'description':
          'System registered late arrival but I was here at 8:55 AM, had issues with the app scanner.',
      'adminComment': '',
    },
  ];

  static final List<Map<String, dynamic>> claims = [
    {
      'type': 'Fuel Expense',
      'detail': 'Site Visit - Building A',
      'date': '08 May 2026',
      'amount': '£65.50',
      'status': 'In Review',
      'icon': LucideIcons.fuel,
      'iconColor': const Color(0xFF0066FF),
      'iconBg': const Color(0xFFEFF6FF),
    },
    {
      'type': 'Meal Expense',
      'detail': 'Client Meeting',
      'date': '07 May 2026',
      'amount': '£28.00',
      'status': 'Approved',
      'isReimbursed': true,
      'icon': LucideIcons.utensils,
      'iconColor': const Color(0xFF10B981),
      'iconBg': const Color(0xFFE6F9F2),
    },
    {
      'type': 'Parking Charges',
      'detail': 'Site Visit - Building B',
      'date': '06 May 2026',
      'amount': '£12.00',
      'status': 'Approved',
      'isReimbursed': true,
      'icon': LucideIcons.car,
      'iconColor': const Color(0xFF8B5CF6),
      'iconBg': const Color(0xFFF5F3FF),
    },
    {
      'type': 'Toll Charges',
      'detail': 'Site Visit - Building A',
      'date': '05 May 2026',
      'amount': '£15.00',
      'status': 'Rejected',
      'icon': LucideIcons.container,
      'iconColor': const Color(0xFFEF4444),
      'iconBg': const Color(0xFFFEE2E2),
    },
  ];

  static final List<Map<String, String>> alertTypesForEmployee = [
    {
      'type': 'contact-my-family',
      'icon': 'assets/markers/gifs/contact-family.webp',
      'label': 'Contact my family',
    },
    {
      'type': 'need-help',
      'icon': 'assets/markers/gifs/need-help.webp',
      'label': 'Need help',
    },
    {
      'type': 'send-backup',
      'icon': 'assets/markers/gifs/send-backup.webp',
      'label': 'Send backup',
    },
    {
      'type': 'call-police',
      'icon': 'assets/markers/gifs/call police.webp',
      'label': 'Call police',
    },
    {
      'type': 'call-ambulance',
      'icon': 'assets/markers/gifs/medicine.webp',
      'label': 'Call ambulance',
    },
    {
      'type': 'under-threat',
      'icon': 'assets/markers/gifs/vandalism.webp',
      'label': 'Under threat',
    },
    {
      'type': 'being-followed',
      'icon': 'assets/markers/gifs/being-followed.webp',
      'label': 'Being followed',
    },
    {
      'type': 'get-me-out',
      'icon': 'assets/markers/gifs/get-me-out.webp',
      'label': 'Get me out',
    },
    {
      'type': 'im-safe',
      'icon': 'assets/markers/gifs/i-am-safe.webp',
      'label': "I'm safe",
    },
    {
      'type': 'send-support',
      'icon': 'assets/markers/gifs/safe.webp',
      'label': 'Send support',
    },
    {
      'type': 'no-signal',
      'icon': 'assets/markers/gifs/no-signal.webp',
      'label': 'No signal',
    },
    {
      'type': 'low-battery',
      'icon': 'assets/markers/gifs/low-battery.webp',
      'label': 'Low battery',
    },
  ];
}
