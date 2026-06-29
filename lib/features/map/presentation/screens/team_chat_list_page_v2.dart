import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../common/widgets/app_app_bar.dart';
import '../../../../core/constants/app_colors.dart';

/// Team chat — version 2.
///
/// A cleaner, more formal take on the team chat list, split into three clear
/// sections:
///   1. Default team chat  — the org-wide chat with all employees + company.
///   2. Direct messages    — one-to-one conversations.
///   3. Groups             — groups the user has created with their team, plus
///                           an entry point to create a new one.
///
/// This screen runs entirely on in-memory dummy data so the layout can be
/// previewed without the backend. Wire the marked TODOs to the real API when
/// ready.
class TeamChatListPageV2 extends StatefulWidget {
  const TeamChatListPageV2({super.key});

  @override
  State<TeamChatListPageV2> createState() => _TeamChatListPageV2State();
}

class _TeamChatListPageV2State extends State<TeamChatListPageV2> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  // ── Dummy data ────────────────────────────────────────────────────────
  final _ChatItem _defaultTeamChat = _ChatItem(
    title: 'Bajaj Team chat',
    subtitle: 'Important: please upload your field evidence.',
    time: '12 Jun',
    unread: 2,
    kind: _ChatKind.org,
  );

  final List<_ChatItem> _directChats = [
    _ChatItem(
      title: 'Rahul Mehta',
      subtitle: 'Sounds good, I will head there now.',
      time: '12 Jun',
      unread: 1,
      kind: _ChatKind.direct,
    ),
    _ChatItem(
      title: 'Priya Sharma',
      subtitle: 'Shared the location pin with you.',
      time: '11 Jun',
      unread: 0,
      kind: _ChatKind.direct,
    ),
    _ChatItem(
      title: 'Aman Verma',
      subtitle: 'Thanks for the update 👍',
      time: '09 Jun',
      unread: 0,
      kind: _ChatKind.direct,
    ),
  ];

  final List<_ChatItem> _groups = [
    _ChatItem(
      title: 'Lucknow Field Team',
      subtitle: '4 members · Collecting pics today',
      time: '12 Jun',
      unread: 3,
      kind: _ChatKind.group,
    ),
    _ChatItem(
      title: 'Safety Crew',
      subtitle: '6 members · Chemical spill cleanup',
      time: '10 Jun',
      unread: 0,
      kind: _ChatKind.group,
    ),
  ];

  final List<_Teammate> _teammates = const [
    _Teammate('Rahul Mehta', 'Worker'),
    _Teammate('Priya Sharma', 'Organizer'),
    _Teammate('Aman Verma', 'Worker'),
    _Teammate('Sneha Iyer', 'Worker'),
    _Teammate('Karan Singh', 'Organizer'),
    _Teammate('Neha Gupta', 'Worker'),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_ChatItem> _filter(List<_ChatItem> items) {
    if (_query.isEmpty) return items;
    final q = _query.toLowerCase();
    return items
        .where((c) => c.title.toLowerCase().contains(q))
        .toList(growable: false);
  }

  Future<void> _onCreateGroup() async {
    final group = await showModalBottomSheet<_ChatItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateGroupSheet(teammates: _teammates),
    );
    if (group != null) {
      setState(() => _groups.insert(0, group));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.primary,
            content: Text('Group "${group.title}" created'),
          ),
        );
      }
      // TODO: call create-group API and refresh from server.
    }
  }

  @override
  Widget build(BuildContext context) {
    final directChats = _filter(_directChats);
    final groups = _filter(_groups);
    final showDefault = _query.isEmpty ||
        _defaultTeamChat.title.toLowerCase().contains(_query.toLowerCase());

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppAppBar(
        title: 'Team chat',
        showBack: true,
        centerTitle: false,
        titleSpacing: 0,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 24.h),
              children: [
                if (showDefault) ...[
                  _sectionHeader('Default team chat'),
                  _buildChatRow(_defaultTeamChat),
                ],

                SizedBox(height: 18.h),
                _sectionHeader('Direct messages'),
                if (directChats.isEmpty)
                  _emptyHint('No direct messages')
                else
                  ...directChats.map(_buildChatRow),

                SizedBox(height: 18.h),
                _sectionHeader(
                  'Groups',
                  action: _buildNewGroupButton(),
                ),
                if (groups.isEmpty)
                  _buildGroupsEmptyState()
                else
                  ...groups.map(_buildChatRow),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Search ────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _query = v.trim()),
        style: TextStyle(fontFamily: 'Poppins', fontSize: 14.sp),
        decoration: InputDecoration(
          hintText: 'Search teammates...',
          hintStyle: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14.sp,
            color: AppColors.textHint,
          ),
          prefixIcon: Icon(Icons.search, size: 20.sp, color: AppColors.textSecondary),
          filled: true,
          fillColor: const Color(0xFFF4F6F9),
          contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 12.w),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // ── Section header ────────────────────────────────────────────────────
  Widget _sectionHeader(String label, {Widget? action}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h, top: 2.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: TextStyle(
                fontFamily: 'AirbnbCereal',
                fontSize: 10.5.sp,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w700,
                color: AppColors.textHint,
              ),
            ),
          ),
          if (action != null) action,
        ],
      ),
    );
  }

  Widget _buildNewGroupButton() {
    return InkWell(
      onTap: _onCreateGroup,
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 15.sp, color: AppColors.primary),
            SizedBox(width: 4.w),
            Text(
              'New group',
              style: TextStyle(
                fontFamily: 'AirbnbCereal',
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Chat row ──────────────────────────────────────────────────────────
  Widget _buildChatRow(_ChatItem item) {
    return Column(
      children: [
        InkWell(
          onTap: () {
            // TODO: navigate to the conversation screen.
          },
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 11.h),
            child: Row(
              children: [
                _buildAvatar(item),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'AirbnbCereal',
                          fontSize: 14.5.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        item.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.time,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11.sp,
                        color: AppColors.textHint,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    if (item.unread > 0)
                      Container(
                        constraints: BoxConstraints(minWidth: 20.w),
                        height: 20.w,
                        padding: EdgeInsets.symmetric(horizontal: 6.w),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Center(
                          child: Text(
                            '${item.unread}',
                            style: TextStyle(
                              fontFamily: 'AirbnbCereal',
                              fontSize: 10.5.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                    else
                      Icon(
                        Icons.chevron_right,
                        size: 18.sp,
                        color: AppColors.textHint,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(left: 60.w),
          child: const Divider(height: 1, thickness: 1, color: AppColors.divider),
        ),
      ],
    );
  }

  Widget _buildAvatar(_ChatItem item) {
    final size = 46.w;
    switch (item.kind) {
      case _ChatKind.org:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withValues(alpha: 0.10),
          ),
          child: Icon(Icons.apartment, color: AppColors.primary, size: 22.sp),
        );
      case _ChatKind.group:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withValues(alpha: 0.10),
          ),
          child: Icon(Icons.groups, color: AppColors.primary, size: 24.sp),
        );
      case _ChatKind.direct:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _initialsColor(item.title),
          ),
          child: Center(
            child: Text(
              _initials(item.title),
              style: TextStyle(
                fontFamily: 'AirbnbCereal',
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        );
    }
  }

  // ── Empty states ──────────────────────────────────────────────────────
  Widget _buildGroupsEmptyState() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: 4.h),
      padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Icon(Icons.groups_2, size: 34.sp, color: AppColors.textHint),
          SizedBox(height: 8.h),
          Text(
            'No groups yet',
            style: TextStyle(
              fontFamily: 'AirbnbCereal',
              fontSize: 13.5.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Create a group to coordinate with your team.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11.5.sp,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 14.h),
          ElevatedButton.icon(
            onPressed: _onCreateGroup,
            icon: Icon(Icons.add, size: 17.sp),
            label: Text(
              'Create group',
              style: TextStyle(
                fontFamily: 'AirbnbCereal',
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyHint(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 14.h),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12.sp,
          color: AppColors.textHint,
        ),
      ),
    );
  }
}

// ── Create-group bottom sheet ───────────────────────────────────────────
class _CreateGroupSheet extends StatefulWidget {
  final List<_Teammate> teammates;
  const _CreateGroupSheet({required this.teammates});

  @override
  State<_CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends State<_CreateGroupSheet> {
  final TextEditingController _nameController = TextEditingController();
  final Set<String> _selected = {};

  bool get _canCreate =>
      _nameController.text.trim().isNotEmpty && _selected.isNotEmpty;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _create() {
    final name = _nameController.text.trim();
    final group = _ChatItem(
      title: name,
      subtitle: '${_selected.length + 1} members · New group',
      time: 'now',
      unread: 0,
      kind: _ChatKind.group,
    );
    Navigator.pop(context, group);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 16.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'New group',
                style: TextStyle(
                  fontFamily: 'AirbnbCereal',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'GROUP NAME',
                style: TextStyle(
                  fontFamily: 'AirbnbCereal',
                  fontSize: 10.sp,
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textHint,
                ),
              ),
              SizedBox(height: 6.h),
              TextField(
                controller: _nameController,
                onChanged: (_) => setState(() {}),
                style: TextStyle(fontFamily: 'Poppins', fontSize: 14.sp),
                decoration: InputDecoration(
                  hintText: 'e.g. Lucknow Field Team',
                  hintStyle: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13.sp,
                    color: AppColors.textHint,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF4F6F9),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 14.h, horizontal: 14.w),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              SizedBox(height: 18.h),
              Row(
                children: [
                  Text(
                    'ADD MEMBERS',
                    style: TextStyle(
                      fontFamily: 'AirbnbCereal',
                      fontSize: 10.sp,
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textHint,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_selected.length} selected',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11.sp,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 280.h),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: widget.teammates.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.divider,
                    indent: 52.w,
                  ),
                  itemBuilder: (context, i) {
                    final t = widget.teammates[i];
                    final checked = _selected.contains(t.name);
                    return InkWell(
                      onTap: () => setState(() {
                        if (checked) {
                          _selected.remove(t.name);
                        } else {
                          _selected.add(t.name);
                        }
                      }),
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 9.h),
                        child: Row(
                          children: [
                            Container(
                              width: 38.w,
                              height: 38.w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _initialsColor(t.name),
                              ),
                              child: Center(
                                child: Text(
                                  _initials(t.name),
                                  style: TextStyle(
                                    fontFamily: 'AirbnbCereal',
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.name,
                                    style: TextStyle(
                                      fontFamily: 'AirbnbCereal',
                                      fontSize: 13.5.sp,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    t.role,
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 11.sp,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 22.w,
                              height: 22.w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: checked
                                    ? AppColors.primary
                                    : Colors.transparent,
                                border: Border.all(
                                  color: checked
                                      ? AppColors.primary
                                      : AppColors.border,
                                  width: 1.5,
                                ),
                              ),
                              child: checked
                                  ? Icon(Icons.check,
                                      size: 14.sp, color: Colors.white)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 16.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canCreate ? _create : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor:
                        AppColors.primary.withValues(alpha: 0.4),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    'Create group',
                    style: TextStyle(
                      fontFamily: 'AirbnbCereal',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Models & helpers ────────────────────────────────────────────────────
enum _ChatKind { org, direct, group }

class _ChatItem {
  final String title;
  final String subtitle;
  final String time;
  final int unread;
  final _ChatKind kind;

  _ChatItem({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.unread,
    required this.kind,
  });
}

class _Teammate {
  final String name;
  final String role;
  const _Teammate(this.name, this.role);
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts.first[0] + parts.last[0]).toUpperCase();
}

Color _initialsColor(String seed) {
  const palette = [
    Color(0xFF1877F2),
    Color(0xFF6D3BD4),
    Color(0xFF0EA5E9),
    Color(0xFF4FAA4B),
    Color(0xFFE6A23C),
    Color(0xFFEC4E54),
  ];
  return palette[seed.hashCode.abs() % palette.length];
}
