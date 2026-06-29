// Team Chat V2 — self-contained UI mockup driven entirely by dummy data.
//
// Shows two sections on the home list:
//   • Groups                – multi-member group conversations
//   • Individual Team Chat   – one-to-one conversations with teammates
//
// Users can create a new group (pick members + name) and open any chat into a
// dummy conversation view where sending appends messages locally.
//
// No bloc / DI / network — everything here is in-memory dummy data so the
// screen can be dropped in and previewed on its own.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../common/widgets/app_app_bar.dart';
import '../../../../common/widgets/custom_dropdown.dart';
import '../../../../config/di/injection.dart';
import '../../../../core/constants/app_text_styles.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Brand tokens (kept local so this file is standalone)
// ─────────────────────────────────────────────────────────────────────────────
const Color _kPrimary = Color(0xFF1877F2);
const Color _kInk = Color(0xFF0F172A);
const Color _kInkSoft = Color(0xFF475569);
const Color _kMuted = Color(0xFF94A3B8);
const Color _kSurface = Color(0xFFF1F5F9);
const Color _kBorder = Color(0xFFE2E8F0);
const String _kFont = 'AirbnbCereal';

// A small palette to give each member a stable avatar colour.
const List<Color> _kAvatarColors = [
  Color(0xFF1877F2),
  Color(0xFF4FAA4B),
  Color(0xFFEC4E54),
  Color(0xFF8B5CF6),
  Color(0xFFF59E0B),
  Color(0xFF0EA5E9),
  Color(0xFFEC4899),
  Color(0xFF14B8A6),
];

// ─────────────────────────────────────────────────────────────────────────────
//  Dummy data models
// ─────────────────────────────────────────────────────────────────────────────
class _ChatUser {
  final String id;
  final String name;
  final String role;
  final bool online;

  const _ChatUser({
    required this.id,
    required this.name,
    required this.role,
    this.online = false,
  });

  Color get color => _kAvatarColors[id.hashCode.abs() % _kAvatarColors.length];

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '?';
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

class _ChatMessage {
  final String senderId;
  final String text;
  final DateTime time;
  final bool isMe;

  _ChatMessage({
    required this.senderId,
    required this.text,
    required this.time,
    this.isMe = false,
  });
}

class _Conversation {
  final String id;
  String title;
  final bool isGroup;
  final List<_ChatUser> members; // excludes "me"
  final List<_ChatMessage> messages;
  int unread;

  _Conversation({
    required this.id,
    required this.title,
    required this.isGroup,
    required this.members,
    required this.messages,
    this.unread = 0,
  });

  _ChatMessage? get lastMessage => messages.isEmpty ? null : messages.last;
}

// "Me" — the signed-in user for this mockup.
const _ChatUser _me = _ChatUser(
  id: 'me',
  name: 'You',
  role: 'Reporter',
  online: true,
);

// Roster of teammates available for individual chats and group creation.
const List<_ChatUser> _kRoster = [
  _ChatUser(
    id: 'u1',
    name: 'Aarav Sharma',
    role: 'Field Reporter',
    online: true,
  ),
  _ChatUser(id: 'u2', name: 'Meera Patel', role: 'Photo Editor', online: true),
  _ChatUser(id: 'u3', name: 'Rohan Gupta', role: 'Desk Editor'),
  _ChatUser(id: 'u4', name: 'Sara Khan', role: 'Producer', online: true),
  _ChatUser(id: 'u5', name: 'Vikram Rao', role: 'Camera Op'),
  _ChatUser(id: 'u6', name: 'Priya Nair', role: 'Sub-Editor'),
  _ChatUser(id: 'u7', name: 'Daniel Cruz', role: 'Correspondent'),
  _ChatUser(id: 'u8', name: 'Lena Fischer', role: 'Bureau Chief', online: true),
];

_ChatUser _userById(String id) =>
    _kRoster.firstWhere((u) => u.id == id, orElse: () => _me);

// ─────────────────────────────────────────────────────────────────────────────
//  Seed conversations
// ─────────────────────────────────────────────────────────────────────────────
List<_Conversation> _seedGroups() {
  final now = DateTime.now();
  return [
    _Conversation(
      id: 'g1',
      title: 'Breaking News Desk',
      isGroup: true,
      members: [
        _userById('u1'),
        _userById('u3'),
        _userById('u8'),
        _userById('u4'),
      ],
      unread: 3,
      messages: [
        _ChatMessage(
          senderId: 'u8',
          text: 'Team, the press conference moved to 4 PM.',
          time: now.subtract(const Duration(minutes: 48)),
        ),
        _ChatMessage(
          senderId: 'u1',
          text: 'On my way to the venue now.',
          time: now.subtract(const Duration(minutes: 40)),
        ),
        _ChatMessage(
          senderId: 'u3',
          text: 'I\'ll prep the live blog template.',
          time: now.subtract(const Duration(minutes: 12)),
        ),
      ],
    ),
    _Conversation(
      id: 'g2',
      title: 'Photo & Video',
      isGroup: true,
      members: [_userById('u2'), _userById('u5')],
      unread: 0,
      messages: [
        _ChatMessage(
          senderId: 'u2',
          text: 'Uploaded the edited gallery to the shared drive.',
          time: now.subtract(const Duration(hours: 2)),
        ),
        _ChatMessage(
          senderId: 'me',
          text: 'Perfect, thanks Meera!',
          time: now.subtract(const Duration(hours: 2)),
          isMe: true,
        ),
      ],
    ),
    _Conversation(
      id: 'g3',
      title: 'Weekend Edition',
      isGroup: true,
      members: [_userById('u6'), _userById('u7'), _userById('u4')],
      unread: 1,
      messages: [
        _ChatMessage(
          senderId: 'u7',
          text: 'Pitch list for Saturday is ready for review.',
          time: now.subtract(const Duration(hours: 5)),
        ),
      ],
    ),
  ];
}

List<_Conversation> _seedIndividuals() {
  final now = DateTime.now();
  return [
    _Conversation(
      id: 'd1',
      title: 'Aarav Sharma',
      isGroup: false,
      members: [_userById('u1')],
      unread: 2,
      messages: [
        _ChatMessage(
          senderId: 'u1',
          text: 'Did you get the quotes from the mayor?',
          time: now.subtract(const Duration(minutes: 22)),
        ),
        _ChatMessage(
          senderId: 'u1',
          text: 'Need them for the 3 o\'clock filing.',
          time: now.subtract(const Duration(minutes: 21)),
        ),
      ],
    ),
    _Conversation(
      id: 'd2',
      title: 'Meera Patel',
      isGroup: false,
      members: [_userById('u2')],
      unread: 0,
      messages: [
        _ChatMessage(
          senderId: 'me',
          text: 'Can you send the hi-res version?',
          time: now.subtract(const Duration(hours: 1)),
          isMe: true,
        ),
        _ChatMessage(
          senderId: 'u2',
          text: 'Sent! Check your inbox.',
          time: now.subtract(const Duration(minutes: 58)),
        ),
      ],
    ),
    _Conversation(
      id: 'd3',
      title: 'Sara Khan',
      isGroup: false,
      members: [_userById('u4')],
      unread: 0,
      messages: [
        _ChatMessage(
          senderId: 'u4',
          text: 'Studio is booked for 6 PM 👍',
          time: now.subtract(const Duration(hours: 3)),
        ),
      ],
    ),
    _Conversation(
      id: 'd4',
      title: 'Lena Fischer',
      isGroup: false,
      members: [_userById('u8')],
      unread: 0,
      messages: [
        _ChatMessage(
          senderId: 'u8',
          text: 'Great work on the exclusive today.',
          time: now.subtract(const Duration(days: 1)),
        ),
      ],
    ),
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
//  Time helper
// ─────────────────────────────────────────────────────────────────────────────
String _formatListTime(DateTime t) {
  final now = DateTime.now();
  final diff = now.difference(t);
  if (diff.inMinutes < 1) return 'now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24 && now.day == t.day) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m ${t.hour >= 12 ? 'PM' : 'AM'}';
  }
  if (diff.inDays < 2) return 'Yesterday';
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return days[t.weekday - 1];
}

String _formatBubbleTime(DateTime t) {
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final m = t.minute.toString().padLeft(2, '0');
  return '$h:$m ${t.hour >= 12 ? 'PM' : 'AM'}';
}

// ─────────────────────────────────────────────────────────────────────────────
//  HOME SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class TeamChatScreenV2 extends StatefulWidget {
  const TeamChatScreenV2({super.key});

  @override
  State<TeamChatScreenV2> createState() => _TeamChatScreenV2State();
}

class _TeamChatScreenV2State extends State<TeamChatScreenV2> {
  final List<_Conversation> _groups = _seedGroups();
  final List<_Conversation> _individuals = _seedIndividuals();
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  // The company-wide default channel — everyone on the team is in it.
  late final _Conversation _company;
  String? _companyLogo;

  @override
  void initState() {
    super.initState();
    final prefs = getIt<SharedPreferences>();
    final companyName =
        prefs.getString('company_name') ?? 'ShieldHop';
    _companyLogo = prefs.getString('company_logo');
    _company = _Conversation(
      id: 'company',
      title: companyName,
      isGroup: true,
      members: _kRoster, // everyone
      unread: 0,
      messages: [
        _ChatMessage(
          senderId: 'u8',
          text:
              'Welcome to the $companyName channel — everyone on the team is here. 👋',
          time: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
      ],
    );
  }

  bool get _showCompany =>
      _query.isEmpty ||
      _company.title.toLowerCase().contains(_query.toLowerCase());

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_Conversation> get _filteredGroups => _groups
      .where((c) => c.title.toLowerCase().contains(_query.toLowerCase()))
      .toList();

  List<_Conversation> get _filteredIndividuals => _individuals
      .where((c) => c.title.toLowerCase().contains(_query.toLowerCase()))
      .toList();

  Future<void> _openConversation(_Conversation convo) async {
    setState(() => convo.unread = 0);
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ConversationScreenV2(convo: convo)),
    );
    if (mounted) setState(() {});
  }

  Future<void> _createGroup() async {
    final newGroup = await Navigator.push<_Conversation>(
      context,
      MaterialPageRoute(builder: (_) => const _CreateGroupScreen()),
    );
    if (newGroup != null) {
      setState(() => _groups.insert(0, newGroup));
      _openConversation(newGroup);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppAppBar(
        title: 'Team Chat',
        showBack: true,
        actions: [
          CustomDropdown<String>(
            value: '_menu',
            items: const ['Create group'],
            buttonWidth: 150.w,
            buttonColor: Colors.transparent,
            border: const Border.fromBorderSide(BorderSide.none),
            icon: const SizedBox.shrink(),
            itemBuilder: (val, isSelected) {
              if (val == '_menu') {
                return const Icon(Icons.more_vert, color: _kInk, size: 22);
              }
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.group_add_rounded,
                    color: _kPrimary,
                    size: 20,
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    val,
                    style: TextStyle(
                      fontFamily: _kFont,
                      fontSize: 14.sp,
                      color: _kInk,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            },
            onChanged: (val) {
              if (val == 'Create group') _createGroup();
            },
          ),
          SizedBox(width: 6.w),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: ListView(
              padding: EdgeInsets.only(bottom: 16.h),
              children: [
                if (_showCompany) ...[
                  const _SectionHeader(title: 'Default team chat'),
                  _buildCompanyCard(),
                ],
                if (_filteredGroups.isNotEmpty) ...[
                  _SectionHeader(
                    title: 'Groups',
                    count: _filteredGroups.length,
                  ),
                  ..._filteredGroups.map(
                    (c) =>
                        _ChatTile(convo: c, onTap: () => _openConversation(c)),
                  ),
                ],
                if (_filteredIndividuals.isNotEmpty) ...[
                  _SectionHeader(
                    title: 'Individual Team Chat',
                    count: _filteredIndividuals.length,
                  ),
                  ..._filteredIndividuals.map(
                    (c) =>
                        _ChatTile(convo: c, onTap: () => _openConversation(c)),
                  ),
                ],
                if (_filteredGroups.isEmpty &&
                    _filteredIndividuals.isEmpty &&
                    !_showCompany)
                  _buildEmptySearch(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 8.h),
      child: Container(
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: _kBorder),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _query = v),
          style: TextStyle(fontFamily: _kFont, fontSize: 14.sp, color: _kInk),
          decoration: InputDecoration(
            hintText: 'Search chats...',
            hintStyle: TextStyle(
              fontFamily: _kFont,
              fontSize: 14.sp,
              color: _kMuted,
            ),
            prefixIcon: const Icon(Icons.search, color: _kMuted),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 12.h),
          ),
        ),
      ),
    );
  }

  // Pinned company-wide default channel at the top of the list.
  Widget _buildCompanyCard() {
    final last = _company.lastMessage;
    final hasLogo = (_companyLogo != null && _companyLogo!.isNotEmpty);

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 6.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14.r),
          onTap: () => _openConversation(_company),
          child: Container(
            padding: EdgeInsets.all(11.w),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2979FF), Color(0xFF0D47A1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Row(
              children: [
                Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    image: hasLogo
                        ? DecorationImage(
                            image: NetworkImage(_companyLogo!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: hasLogo
                      ? null
                      : Icon(
                          Icons.business_rounded,
                          color: _kPrimary,
                          size: 20.sp,
                        ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _company.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.h4.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Text(
                              'Company',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: _kFont,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        last?.text ??
                            'Company channel · Everyone can chat here',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.white.withValues(alpha: 0.85),
                  size: 20.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySearch() {
    return Padding(
      padding: EdgeInsets.only(top: 80.h),
      child: Column(
        children: [
          Icon(Icons.search_off, size: 48.sp, color: const Color(0xFFCBD5E1)),
          SizedBox(height: 12.h),
          Text(
            'No chats found',
            style: TextStyle(
              fontFamily: _kFont,
              fontSize: 15.sp,
              color: _kInkSoft,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Section header
// ─────────────────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final int? count;
  const _SectionHeader({required this.title, this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 4.h),
      child: Row(
        children: [
          Text(
            title,
            style: AppTextStyles.labelLarge.copyWith(
              fontWeight: FontWeight.w400,
              letterSpacing: 0.4,
              color: _kInkSoft,
            ),
          ),
          if (count != null) ...[
            SizedBox(width: 8.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Text(
                '$count',
                style: AppTextStyles.labelSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: _kPrimary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Chat list tile
// ─────────────────────────────────────────────────────────────────────────────
class _ChatTile extends StatelessWidget {
  final _Conversation convo;
  final VoidCallback onTap;
  const _ChatTile({required this.convo, required this.onTap});

  String _previewText() {
    final last = convo.lastMessage;
    if (last == null) return 'No messages yet';
    final prefix = last.isMe
        ? 'You: '
        : (convo.isGroup
              ? '${_userById(last.senderId).name.split(' ').first}: '
              : '');
    return '$prefix${last.text}';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final last = convo.lastMessage;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 7.h),
        child: Row(
          children: [
            _ConversationAvatar(convo: convo, size: 46),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          convo.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyMediumW400numD036,
                        ),
                      ),
                      if (last != null)
                        Text(
                          _formatListTime(last.time),
                          style: AppTextStyles.caption.copyWith(
                            color: convo.unread > 0 ? _kPrimary : _kMuted,
                            fontWeight: convo.unread > 0
                                ? FontWeight.w600
                                : FontWeight.w300,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _previewText(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: convo.unread > 0 ? _kInkSoft : _kMuted,
                            fontWeight: convo.unread > 0
                                ? FontWeight.w400
                                : FontWeight.w300,
                          ),
                        ),
                      ),
                      if (convo.unread > 0) ...[
                        SizedBox(width: 8.w),
                        Container(
                          constraints: BoxConstraints(minWidth: 20.w),
                          padding: EdgeInsets.all(5.r),
                          decoration: const BoxDecoration(
                            color: _kPrimary,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${convo.unread}',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.labelSmall.copyWith(
                              fontSize: size.width * 0.026,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Avatar (single initials circle, or stacked for groups)
// ─────────────────────────────────────────────────────────────────────────────
class _ConversationAvatar extends StatelessWidget {
  final _Conversation convo;
  final double size;
  const _ConversationAvatar({required this.convo, required this.size});

  @override
  Widget build(BuildContext context) {
    final dim = size.r;
    if (!convo.isGroup) {
      final user = convo.members.isNotEmpty ? convo.members.first : _me;
      return _InitialsCircle(
        text: user.initials,
        color: user.color,
        diameter: dim,
        online: user.online,
      );
    }

    // Group: two equal member avatars stacked as a clean overlapping pair.
    final m = convo.members;
    final back = m.isNotEmpty ? m[0] : _me;
    final front = m.length > 1 ? m[1] : null;

    // Single-member group → just one full-size circle.
    if (front == null) {
      return _InitialsCircle(
        text: back.initials,
        color: back.color,
        diameter: dim,
      );
    }

    final circle = dim * 0.68;
    return SizedBox(
      width: dim,
      height: dim,
      child: Stack(
        children: [
          // Back avatar, top-left.
          Positioned(
            top: 0,
            left: 0,
            child: _InitialsCircle(
              text: back.initials,
              color: back.color,
              diameter: circle,
            ),
          ),
          // Front avatar, bottom-right, with a white ring to separate it.
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(2),
              child: _InitialsCircle(
                text: front.initials,
                color: front.color,
                diameter: circle - 4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InitialsCircle extends StatelessWidget {
  final String text;
  final Color color;
  final double diameter;
  final bool online;
  const _InitialsCircle({
    required this.text,
    required this.color,
    required this.diameter,
    this.online = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: diameter,
      height: diameter,
      child: Stack(
        children: [
          Container(
            width: diameter,
            height: diameter,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Text(
              text,
              style: TextStyle(
                fontFamily: _kFont,
                fontSize: diameter * 0.36,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
          if (online)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: diameter * 0.26,
                height: diameter * 0.26,
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  CREATE GROUP SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class _CreateGroupScreen extends StatefulWidget {
  const _CreateGroupScreen();

  @override
  State<_CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<_CreateGroupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final Set<String> _selected = {};

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _canCreate =>
      _nameController.text.trim().isNotEmpty && _selected.isNotEmpty;

  void _toggle(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  void _create() {
    final members = _kRoster.where((u) => _selected.contains(u.id)).toList();
    final group = _Conversation(
      id: 'g_${DateTime.now().millisecondsSinceEpoch}',
      title: _nameController.text.trim(),
      isGroup: true,
      members: members,
      unread: 0,
      messages: [
        _ChatMessage(
          senderId: 'me',
          text: 'Created the group "${_nameController.text.trim()}" 🎉',
          time: DateTime.now(),
          isMe: true,
        ),
      ],
    );
    Navigator.pop(context, group);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close, color: _kInk),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: const Text(
          'New Group',
          style: TextStyle(
            color: _kInk,
            fontFamily: _kFont,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          // Group name field
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 4.h),
            child: TextField(
              controller: _nameController,
              onChanged: (_) => setState(() {}),
              style: TextStyle(
                fontFamily: _kFont,
                fontSize: 15.sp,
                color: _kInk,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: 'Group name',
                hintStyle: TextStyle(
                  fontFamily: _kFont,
                  fontSize: 15.sp,
                  color: _kMuted,
                ),
                prefixIcon: const Icon(
                  Icons.groups_2_rounded,
                  color: _kPrimary,
                ),
                filled: true,
                fillColor: _kSurface,
                contentPadding: EdgeInsets.symmetric(vertical: 14.h),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: const BorderSide(color: _kBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: const BorderSide(color: _kBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: const BorderSide(color: _kPrimary, width: 1.4),
                ),
              ),
            ),
          ),
          // Selected count
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.fromLTRB(18.w, 10.h, 16.w, 4.h),
              child: Text(
                _selected.isEmpty
                    ? 'Select members'
                    : '${_selected.length} selected',
                style: TextStyle(
                  fontFamily: _kFont,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                  color: _kInkSoft,
                ),
              ),
            ),
          ),
          // Member list
          Expanded(
            child: ListView.builder(
              itemCount: _kRoster.length,
              itemBuilder: (context, i) {
                final user = _kRoster[i];
                final checked = _selected.contains(user.id);
                return InkWell(
                  onTap: () => _toggle(user.id),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    child: Row(
                      children: [
                        _InitialsCircle(
                          text: user.initials,
                          color: user.color,
                          diameter: 46.r,
                          online: user.online,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                style: TextStyle(
                                  fontFamily: _kFont,
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w600,
                                  color: _kInk,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                user.role,
                                style: TextStyle(
                                  fontFamily: _kFont,
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w400,
                                  color: _kMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 24.r,
                          height: 24.r,
                          decoration: BoxDecoration(
                            color: checked ? _kPrimary : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: checked ? _kPrimary : _kBorder,
                              width: 1.6,
                            ),
                          ),
                          child: checked
                              ? Icon(
                                  Icons.check,
                                  size: 16.sp,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Create button
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
              child: SizedBox(
                width: double.infinity,
                height: 52.h,
                child: ElevatedButton(
                  onPressed: _canCreate ? _create : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    disabledBackgroundColor: _kBorder,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  child: Text(
                    'Create Group',
                    style: TextStyle(
                      fontFamily: _kFont,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                      color: _canCreate ? Colors.white : _kMuted,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  CONVERSATION SCREEN (dummy)
// ─────────────────────────────────────────────────────────────────────────────
class ConversationScreenV2 extends StatefulWidget {
  final _Conversation convo;
  const ConversationScreenV2({required this.convo});

  @override
  State<ConversationScreenV2> createState() => ConversationScreenV2State();
}

class ConversationScreenV2State extends State<ConversationScreenV2> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      widget.convo.messages.add(
        _ChatMessage(
          senderId: 'me',
          text: text,
          time: DateTime.now(),
          isMe: true,
        ),
      );
    });
    _controller.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String get _subtitle {
    if (widget.convo.isGroup) {
      final names = widget.convo.members
          .map((m) => m.name.split(' ').first)
          .toList();
      return '${names.length + 1} members · ${names.take(3).join(', ')}'
          '${names.length > 3 ? '…' : ''}';
    }
    final u = widget.convo.members.first;
    return u.online ? 'Online' : u.role;
  }

  @override
  Widget build(BuildContext context) {
    final messages = widget.convo.messages;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppAppBar(
        showBack: true,
        titleWidget: Row(
          children: [
            _ConversationAvatar(convo: widget.convo, size: 38),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.convo.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.h4.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(color: _kMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? _buildEmpty()
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 12.h,
                    ),
                    itemCount: messages.length,
                    itemBuilder: (context, i) {
                      final msg = messages[i];
                      final showName =
                          widget.convo.isGroup &&
                          !msg.isMe &&
                          (i == 0 || messages[i - 1].senderId != msg.senderId);
                      return _MessageBubbleV2(
                        msg: msg,
                        sender: _userById(msg.senderId),
                        showName: showName,
                        showAvatar: !msg.isMe,
                      );
                    },
                  ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 56.sp,
            color: const Color(0xFFCBD5E1),
          ),
          SizedBox(height: 12.h),
          Text(
            'No messages yet',
            style: TextStyle(
              fontFamily: _kFont,
              fontSize: 16.sp,
              color: _kInkSoft,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Say hi to start the conversation!',
            style: TextStyle(
              fontFamily: _kFont,
              fontSize: 13.sp,
              color: _kMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: 12.w,
        vertical: 8.h,
      ).copyWith(bottom: MediaQuery.of(context).viewInsets.bottom + 8.h),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: _kSurface,
                  borderRadius: BorderRadius.circular(24.r),
                  border: Border.all(color: _kBorder),
                ),
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 4,
                  onSubmitted: (_) => _send(),
                  style: TextStyle(
                    fontFamily: _kFont,
                    fontSize: 14.sp,
                    color: _kInk,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(
                      fontFamily: _kFont,
                      fontSize: 14.sp,
                      color: _kMuted,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 10.h,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            GestureDetector(
              onTap: _send,
              child: Container(
                padding: EdgeInsets.all(12.r),
                decoration: const BoxDecoration(
                  color: _kPrimary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubbleV2 extends StatelessWidget {
  final _ChatMessage msg;
  final _ChatUser sender;
  final bool showName;
  final bool showAvatar;
  const _MessageBubbleV2({
    required this.msg,
    required this.sender,
    required this.showName,
    required this.showAvatar,
  });

  @override
  Widget build(BuildContext context) {
    final isMe = msg.isMe;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (showName)
            Padding(
              padding: EdgeInsets.only(left: 44.w, bottom: 4.h),
              child: Text(
                sender.name,
                style: TextStyle(
                  fontFamily: _kFont,
                  fontSize: 12.sp,
                  color: sender.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Row(
            mainAxisAlignment: isMe
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe) ...[
                Opacity(
                  opacity: showAvatar ? 1 : 0,
                  child: _InitialsCircle(
                    text: sender.initials,
                    color: sender.color,
                    diameter: 32.r,
                  ),
                ),
                SizedBox(width: 8.w),
              ],
              Flexible(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 10.h,
                  ),
                  decoration: BoxDecoration(
                    color: isMe ? _kPrimary : _kSurface,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16.r),
                      topRight: Radius.circular(16.r),
                      bottomLeft: Radius.circular(isMe ? 16.r : 4.r),
                      bottomRight: Radius.circular(isMe ? 4.r : 16.r),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    msg.text,
                    style: TextStyle(
                      fontFamily: _kFont,
                      fontSize: 14.sp,
                      height: 1.3,
                      color: isMe ? Colors.white : _kInk,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(
              top: 4.h,
              left: isMe ? 0 : 44.w,
              right: isMe ? 6.w : 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatBubbleTime(msg.time),
                  style: TextStyle(
                    fontFamily: _kFont,
                    fontSize: 11.sp,
                    color: _kMuted,
                  ),
                ),
                if (isMe) ...[
                  SizedBox(width: 4.w),
                  Icon(Icons.done_all, size: 14.sp, color: _kPrimary),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
