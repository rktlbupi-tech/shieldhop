import 'dart:async';
import 'dart:io';

import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../common/widgets/app_app_bar.dart';
import '../../../../config/di/injection.dart';
import '../../../../config/routes/app_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../camera/data/models/camera_data.dart';
import '../../domain/entities/chat_conversation_entity.dart';
import '../../domain/entities/colleague_entity.dart';
import '../../domain/entities/team_chat_message_entity.dart';
import '../bloc/colleagues_cubit.dart';
import '../bloc/team_chat_bloc.dart';
import '../bloc/team_chat_list_bloc.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Local tokens / helpers
// ─────────────────────────────────────────────────────────────────────────────
const String _kFont = 'AirbnbCereal';

const List<Color> _kAvatarColors = [
  Color(0xFF267D55),
  Color(0xFF4FAA4B),
  Color(0xFFEC4E54),
  Color(0xFF8B5CF6),
  Color(0xFFF59E0B),
  Color(0xFF0EA5E9),
  Color(0xFFEC4899),
  Color(0xFF14B8A6),
];

Color _colorFor(String seed) =>
    _kAvatarColors[seed.hashCode.abs() % _kAvatarColors.length];

String _initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts.first[0] + parts.last[0]).toUpperCase();
}

String _formatListTime(DateTime? t) {
  if (t == null) return '';
  final now = DateTime.now();
  final local = t.toLocal();
  final diff = now.difference(local);
  if (diff.inMinutes < 1) return 'now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24 && now.day == local.day) {
    final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m ${local.hour >= 12 ? 'PM' : 'AM'}';
  }
  if (diff.inDays < 2) return 'Yesterday';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${local.day} ${months[local.month - 1]}';
}

// ─────────────────────────────────────────────────────────────────────────────
//  HOME SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class TeamChatScreenV2 extends StatelessWidget {
  const TeamChatScreenV2({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TeamChatListBloc>(
      create: (_) =>
          getIt<TeamChatListBloc>()..add(const LoadConversationsEvent()),
      child: const _TeamChatScreenV2View(),
    );
  }
}

class _TeamChatScreenV2View extends StatefulWidget {
  const _TeamChatScreenV2View();

  @override
  State<_TeamChatScreenV2View> createState() => _TeamChatScreenV2ViewState();
}

class _TeamChatScreenV2ViewState extends State<_TeamChatScreenV2View> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String? _companyLogo;
  String _companyName = 'Team';

  @override
  void initState() {
    super.initState();
    final prefs = getIt<SharedPreferences>();
    _companyName = prefs.getString('company_name') ?? 'Team';
    _companyLogo = prefs.getString('company_logo');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matches(ChatConversationEntity c) =>
      _query.isEmpty || c.title.toLowerCase().contains(_query.toLowerCase());

  Future<void> _openConversation(
    BuildContext context,
    ChatConversationEntity c,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConversationScreenV2(
          conversationId: c.id,
          title: c.title.isNotEmpty ? c.title : _companyName,
          avatarImage: c.avatarImage,
          isGroup: c.isGroup,
        ),
      ),
    );
    if (context.mounted) {
      context.read<TeamChatListBloc>().add(const RefreshConversationsEvent());
    }
  }

  Future<void> _startDirectChat(BuildContext context) async {
    final picked = await Navigator.push<List<ColleagueEntity>>(
      context,
      MaterialPageRoute(
        builder: (_) => const _ColleaguePickerScreen(isGroup: false),
      ),
    );
    if (picked == null || picked.isEmpty || !context.mounted) return;
    final colleague = picked.first;
    context.read<TeamChatListBloc>().add(
      CreateConversationEvent(
        channelType: 'direct',
        memberIds: [colleague.id],
        fallbackTitle: colleague.name,
        fallbackAvatar: colleague.avatarUrl,
      ),
    );
  }

  Future<void> _startGroupChat(BuildContext context) async {
    final result = await Navigator.push<_GroupPickResult>(
      context,
      MaterialPageRoute(
        builder: (_) => const _ColleaguePickerScreen(isGroup: true),
      ),
    );
    if (result == null || !context.mounted) return;
    context.read<TeamChatListBloc>().add(
      CreateConversationEvent(
        channelType: 'group',
        title: result.title,
        memberIds: result.members.map((m) => m.id).toList(),
        fallbackTitle: result.title,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppAppBar(
        title: 'Team Chat',
        showBack: true,
        centerTitle: false,
        titleSpacing: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
            onSelected: (v) {
              if (v == 'chat') _startDirectChat(context);
              if (v == 'group') _startGroupChat(context);
            },
            itemBuilder: (_) => [
              _menuItem('chat', LucideIcons.message_circle_plus, 'New chat'),
              _menuItem('group', LucideIcons.users, 'New group'),
            ],
          ),
          SizedBox(width: 4.w),
        ],
      ),
      body: BlocConsumer<TeamChatListBloc, TeamChatListState>(
        listenWhen: (prev, curr) =>
            curr.createdConversation != null ||
            (curr.errorMessage != null &&
                curr.errorMessage != prev.errorMessage),
        listener: (context, state) {
          if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          }
          final created = state.createdConversation;
          if (created != null) {
            _openConversation(context, created);
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              _buildSearchBar(),
              if (state.isCreating)
                const LinearProgressIndicator(
                  minHeight: 2,
                  color: AppColors.primary,
                  backgroundColor: Colors.transparent,
                ),
              Expanded(child: _buildList(context, state)),
            ],
          );
        },
      ),
    );
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18.sp, color: AppColors.primary),
          SizedBox(width: 10.w),
          Text(
            label,
            style: TextStyle(
              fontFamily: _kFont,
              fontSize: 14.sp,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, TeamChatListState state) {
    if (state.isLoading && state.conversations.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final org = state.orgTeamChats.where(_matches).toList();
    final groups = state.groupChats.where(_matches).toList();
    final directs = state.directChats.where(_matches).toList();

    if (org.isEmpty && groups.isEmpty && directs.isEmpty) {
      return _buildEmpty();
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        context.read<TeamChatListBloc>().add(const RefreshConversationsEvent());
      },
      child: ListView(
        padding: EdgeInsets.only(bottom: 16.h),
        children: [
          if (org.isNotEmpty) ...[
            const _SectionHeader(title: 'Default team chat'),
            ...org.map((c) => _buildCompanyCard(context, c)),
          ],
          if (groups.isNotEmpty) ...[
            _SectionHeader(title: 'Groups', count: groups.length),
            ...groups.map(
              (c) => _ChatTile(
                convo: c,
                onTap: () => _openConversation(context, c),
              ),
            ),
          ],
          if (directs.isNotEmpty) ...[
            _SectionHeader(
              title: 'Individual Team Chat',
              count: directs.length,
            ),
            ...directs.map(
              (c) => _ChatTile(
                convo: c,
                onTap: () => _openConversation(context, c),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 8.h),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: AppColors.border),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _query = v.trim()),
          style: TextStyle(
            fontFamily: _kFont,
            fontSize: 14.sp,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Search chats...',
            hintStyle: TextStyle(
              fontFamily: _kFont,
              fontSize: 14.sp,
              color: AppColors.textHint,
            ),
            prefixIcon: const Icon(Icons.search, color: AppColors.textHint),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 12.h),
          ),
        ),
      ),
    );
  }

  Widget _buildCompanyCard(BuildContext context, ChatConversationEntity c) {
    final hasLogo =
        c.avatarImage.isNotEmpty ||
        (_companyLogo != null && _companyLogo!.isNotEmpty);
    final logo = c.avatarImage.isNotEmpty
        ? c.avatarImage
        : (_companyLogo ?? '');
    final last = c.lastMessagePreview.isNotEmpty
        ? c.lastMessagePreview
        : 'Company channel · Everyone can chat here';

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 6.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14.r),
          onTap: () => _openConversation(context, c),
          child: Container(
            padding: EdgeInsets.all(11.w),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
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
                            image: NetworkImage(logo),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: hasLogo
                      ? null
                      : Icon(
                          Icons.business_rounded,
                          color: AppColors.primary,
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
                              c.title.isNotEmpty
                                  ? c.title
                                  : '$_companyName Team chat',
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
                        last,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                if (c.unreadCount > 0) ...[
                  SizedBox(width: 8.w),
                  _UnreadBadge(count: c.unreadCount, onDark: true),
                ] else
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

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _query.isEmpty ? Icons.forum_outlined : Icons.search_off,
            size: 48.sp,
            color: const Color(0xFFCBD5E1),
          ),
          SizedBox(height: 12.h),
          Text(
            _query.isEmpty ? 'No chats yet' : 'No chats found',
            style: TextStyle(
              fontFamily: _kFont,
              fontSize: 15.sp,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (_query.isEmpty) ...[
            SizedBox(height: 6.h),
            Text(
              'Use the menu to start a new chat.',
              style: TextStyle(
                fontFamily: _kFont,
                fontSize: 12.sp,
                color: AppColors.textHint,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Section header + list tile + badge
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
              color: AppColors.textSecondary,
            ),
          ),
          if (count != null) ...[
            SizedBox(width: 8.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Text(
                '$count',
                style: AppTextStyles.labelSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final ChatConversationEntity convo;
  final VoidCallback onTap;
  const _ChatTile({required this.convo, required this.onTap});

  String get _preview => convo.lastMessagePreview.isNotEmpty
      ? convo.lastMessagePreview
      : (convo.subtitle.isNotEmpty ? convo.subtitle : 'No messages yet');

  @override
  Widget build(BuildContext context) {
    final unread = convo.unreadCount > 0;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 7.h),
        child: Row(
          children: [
            _ChatAvatar(
              title: convo.title,
              avatarImage: convo.avatarImage,
              isGroup: convo.isGroup,
              size: 46,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          convo.title.isNotEmpty ? convo.title : 'Chat',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: _kFont,
                            fontSize: 14.5.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (convo.lastMessageAt != null)
                        Text(
                          _formatListTime(convo.lastMessageAt),
                          style: AppTextStyles.caption.copyWith(
                            color: unread
                                ? AppColors.primary
                                : AppColors.textHint,
                            fontWeight: unread
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
                          _preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: unread
                                ? AppColors.textSecondary
                                : AppColors.textHint,
                            fontWeight: unread
                                ? FontWeight.w400
                                : FontWeight.w300,
                          ),
                        ),
                      ),
                      if (unread) ...[
                        SizedBox(width: 8.w),
                        _UnreadBadge(count: convo.unreadCount),
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

class _UnreadBadge extends StatelessWidget {
  final int count;
  final bool onDark;
  const _UnreadBadge({required this.count, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minWidth: 20.w),
      padding: EdgeInsets.all(5.r),
      decoration: BoxDecoration(
        color: onDark ? Colors.white : AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$count',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: _kFont,
          fontSize: 10.sp,
          color: onDark ? AppColors.primary : Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Avatar (network image, group icon, or initials circle)
// ─────────────────────────────────────────────────────────────────────────────
class _ChatAvatar extends StatelessWidget {
  final String title;
  final String avatarImage;
  final bool isGroup;
  final double size;
  const _ChatAvatar({
    required this.title,
    required this.avatarImage,
    required this.isGroup,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final dim = size.r;
    if (avatarImage.isNotEmpty) {
      return Container(
        width: dim,
        height: dim,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.shade100,
        ),
        child: ClipOval(
          child: Image.network(
            avatarImage,
            fit: BoxFit.cover,
            errorBuilder: (_, e, s) => _fallback(dim),
          ),
        ),
      );
    }
    return _fallback(dim);
  }

  Widget _fallback(double dim) {
    if (isGroup) {
      return Container(
        width: dim,
        height: dim,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary.withValues(alpha: 0.12),
        ),
        child: Icon(Icons.groups, color: AppColors.primary, size: dim * 0.5),
      );
    }
    final color = _colorFor(title);
    return Container(
      width: dim,
      height: dim,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.14),
      ),
      child: Text(
        _initialsOf(title),
        style: TextStyle(
          fontFamily: _kFont,
          fontSize: dim * 0.36,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  COLLEAGUE PICKER (new direct chat / new group)
// ─────────────────────────────────────────────────────────────────────────────
class _GroupPickResult {
  final String title;
  final List<ColleagueEntity> members;
  const _GroupPickResult({required this.title, required this.members});
}

class _ColleaguePickerScreen extends StatelessWidget {
  final bool isGroup;
  const _ColleaguePickerScreen({required this.isGroup});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ColleaguesCubit>(
      create: (_) => getIt<ColleaguesCubit>()..load(),
      child: _ColleaguePickerView(isGroup: isGroup),
    );
  }
}

class _ColleaguePickerView extends StatefulWidget {
  final bool isGroup;
  const _ColleaguePickerView({required this.isGroup});

  @override
  State<_ColleaguePickerView> createState() => _ColleaguePickerViewState();
}

class _ColleaguePickerViewState extends State<_ColleaguePickerView> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Map<String, ColleagueEntity> _selected = {};
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        context.read<ColleaguesCubit>().loadMore();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _nameController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearch(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      context.read<ColleaguesCubit>().load(search: v.trim());
    });
  }

  void _toggle(ColleagueEntity c) {
    setState(() {
      if (_selected.containsKey(c.id)) {
        _selected.remove(c.id);
      } else {
        _selected[c.id] = c;
      }
    });
  }

  bool get _canCreateGroup =>
      _nameController.text.trim().isNotEmpty && _selected.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppAppBar(
        title: widget.isGroup ? 'New group' : 'New chat',
        showBack: true,
        centerTitle: false,
        titleSpacing: 0,
      ),
      body: Column(
        children: [
          if (widget.isGroup) _buildGroupNameField(),
          _buildSearchField(),
          if (widget.isGroup && _selected.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.fromLTRB(18.w, 6.h, 16.w, 2.h),
                child: Text(
                  '${_selected.length} selected',
                  style: TextStyle(
                    fontFamily: _kFont,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          Expanded(
            child: BlocConsumer<ColleaguesCubit, ColleaguesState>(
              listenWhen: (p, c) =>
                  c.errorMessage != null && c.errorMessage != p.errorMessage,
              listener: (context, state) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.errorMessage ?? 'Something went wrong'),
                  ),
                );
              },
              builder: (context, state) {
                if (state.isLoading && state.colleagues.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }
                if (state.colleagues.isEmpty) {
                  return Center(
                    child: Text(
                      'No teammates found',
                      style: TextStyle(
                        fontFamily: _kFont,
                        fontSize: 14.sp,
                        color: AppColors.textHint,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  itemCount:
                      state.colleagues.length + (state.isLoadingMore ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (i >= state.colleagues.length) {
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        child: const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      );
                    }
                    return _buildColleagueTile(state.colleagues[i]);
                  },
                );
              },
            ),
          ),
          if (widget.isGroup) _buildCreateGroupButton(),
        ],
      ),
    );
  }

  Widget _buildGroupNameField() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 4.h),
      child: TextField(
        controller: _nameController,
        onChanged: (_) => setState(() {}),
        style: TextStyle(
          fontFamily: _kFont,
          fontSize: 15.sp,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: 'Group name',
          hintStyle: TextStyle(
            fontFamily: _kFont,
            fontSize: 15.sp,
            color: AppColors.textHint,
          ),
          prefixIcon: const Icon(
            Icons.groups_2_rounded,
            color: AppColors.primary,
          ),
          filled: true,
          fillColor: const Color(0xFFF1F5F9),
          contentPadding: EdgeInsets.symmetric(vertical: 14.h),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 4.h),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearch,
        style: TextStyle(
          fontFamily: _kFont,
          fontSize: 14.sp,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'Search teammates...',
          hintStyle: TextStyle(
            fontFamily: _kFont,
            fontSize: 14.sp,
            color: AppColors.textHint,
          ),
          prefixIcon: const Icon(Icons.search, color: AppColors.textHint),
          filled: true,
          fillColor: const Color(0xFFF1F5F9),
          contentPadding: EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24.r),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildColleagueTile(ColleagueEntity c) {
    final checked = _selected.containsKey(c.id);
    return InkWell(
      onTap: () {
        if (widget.isGroup) {
          _toggle(c);
        } else {
          Navigator.pop(context, <ColleagueEntity>[c]);
        }
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        child: Row(
          children: [
            _ChatAvatar(
              title: c.name,
              avatarImage: c.avatarUrl,
              isGroup: false,
              size: 46,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: _kFont,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (c.subtitle.isNotEmpty) ...[
                    SizedBox(height: 2.h),
                    Text(
                      c.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: _kFont,
                        fontSize: 12.5.sp,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (widget.isGroup)
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 24.r,
                height: 24.r,
                decoration: BoxDecoration(
                  color: checked ? AppColors.primary : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: checked ? AppColors.primary : AppColors.border,
                    width: 1.6,
                  ),
                ),
                child: checked
                    ? Icon(Icons.check, size: 16.sp, color: Colors.white)
                    : null,
              )
            else
              Icon(Icons.chevron_right, color: AppColors.textHint, size: 20.sp),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateGroupButton() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
        child: SizedBox(
          width: double.infinity,
          height: 52.h,
          child: ElevatedButton(
            onPressed: _canCreateGroup
                ? () => Navigator.pop(
                    context,
                    _GroupPickResult(
                      title: _nameController.text.trim(),
                      members: _selected.values.toList(),
                    ),
                  )
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.border,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r),
              ),
            ),
            child: Text(
              'Create group',
              style: TextStyle(
                fontFamily: _kFont,
                fontSize: 15.sp,
                fontWeight: FontWeight.w800,
                color: _canCreateGroup ? Colors.white : AppColors.textHint,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  CONVERSATION SCREEN — real, wired to TeamChatBloc
// ─────────────────────────────────────────────────────────────────────────────
class ConversationScreenV2 extends StatelessWidget {
  final String conversationId;
  final String title;
  final String avatarImage;
  final bool isGroup;

  const ConversationScreenV2({
    super.key,
    required this.conversationId,
    required this.title,
    this.avatarImage = '',
    this.isGroup = false,
  });

  @override
  Widget build(BuildContext context) {
    final prefs = getIt<SharedPreferences>();
    return BlocProvider<TeamChatBloc>(
      create: (_) => getIt<TeamChatBloc>()
        ..add(
          InitTeamChatEvent(
            conversationId: conversationId,
            token: prefs.getString('auth_token') ?? '',
          ),
        ),
      child: _ConversationView(
        title: title,
        avatarImage: avatarImage,
        isGroup: isGroup,
      ),
    );
  }
}

class _ConversationView extends StatefulWidget {
  final String title;
  final String avatarImage;
  final bool isGroup;
  const _ConversationView({
    required this.title,
    required this.avatarImage,
    required this.isGroup,
  });

  @override
  State<_ConversationView> createState() => _ConversationViewState();
}

class _ConversationViewState extends State<_ConversationView> {
  final TextEditingController _controller = TextEditingController();
  late final SharedPreferences _prefs;
  String _myId = '';
  String _myName = '';

  bool _isRecording = false;
  int _recordDuration = 0;
  Timer? _recordTimer;
  final AudioRecorder _audioRecorder = AudioRecorder();

  @override
  void initState() {
    super.initState();
    _prefs = getIt<SharedPreferences>();
    _myId = _prefs.getString('user_id') ?? '';
    _myName =
        '${_prefs.getString('first_name') ?? ''} ${_prefs.getString('last_name') ?? ''}'
            .trim();
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _audioRecorder.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _send(BuildContext context) {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    context.read<TeamChatBloc>().add(
      SendTeamChatMessageEvent(text: text, myId: _myId, myName: _myName),
    );
    _controller.clear();
  }

  void _onTyping(BuildContext context) {
    context.read<TeamChatBloc>().add(
      SendTeamChatTypingInputEvent(myId: _myId, myName: _myName),
    );
  }

  // ── Media ────────────────────────────────────────────────────────────────
  Future<void> _launchCamera(BuildContext context) async {
    final result = await context.push(
      AppRoutes.employeeCamera,
      extra: {'picAgain': true},
    );
    if (result == null || result is! List) return;
    final captured = <CameraData>[];
    for (final e in result) {
      if (e is CameraData && e.path.isNotEmpty) captured.add(e);
    }
    if (captured.isEmpty || !context.mounted) return;

    final previewResult = await Navigator.push<List<CameraData>>(
      context,
      MaterialPageRoute(
        builder: (_) => _MediaPreviewScreen(initialItems: captured),
      ),
    );
    if (previewResult == null || previewResult.isEmpty || !context.mounted)
      return;
    final files = previewResult
        .where((e) => e.path.isNotEmpty)
        .map((e) => File(e.path))
        .toList();
    if (files.isNotEmpty) {
      context.read<TeamChatBloc>().add(SendTeamChatMediaEvent(files: files));
    }
  }

  Future<void> _startRecording() async {
    try {
      if (!await _audioRecorder.hasPermission()) {
        _showMicPermissionDialog();
        return;
      }
      final dir = await getApplicationCacheDirectory();
      final path =
          '${dir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _audioRecorder.start(const RecordConfig(), path: path);
      if (mounted) {
        setState(() {
          _isRecording = true;
          _recordDuration = 0;
        });
      }
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _recordDuration++);
      });
    } catch (_) {
      _snack('Microphone is currently busy or in use by another app.');
    }
  }

  Future<void> _stopAndSend(BuildContext context) async {
    _recordTimer?.cancel();
    try {
      final path = await _audioRecorder.stop();
      if (mounted) setState(() => _isRecording = false);
      if (path == null) return;
      if (context.mounted) {
        context.read<TeamChatBloc>().add(
          SendTeamChatMediaEvent(files: [File(path)]),
        );
      }
    } catch (_) {}
  }

  void _showMicPermissionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Microphone permission',
          style: TextStyle(fontFamily: _kFont, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Microphone access is needed to record voice notes. Please enable it in Settings.',
          style: TextStyle(fontFamily: _kFont),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: _buildAppBar(),
      body: BlocConsumer<TeamChatBloc, TeamChatState>(
        listener: (context, state) {
          if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
            _snack(state.errorMessage!);
          }
        },
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          final otherTypers = state.typingMembers.entries
              .where((e) => e.key != _myId)
              .map((e) => e.value)
              .toList();
          return Column(
            children: [
              Expanded(
                child: state.messages.isEmpty
                    ? _buildEmpty()
                    : ListView.builder(
                        reverse: true,
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 12.h,
                        ),
                        itemCount: state.messages.length,
                        itemBuilder: (context, i) => _MessageBubbleV2(
                          msg: state.messages[i],
                          myId: _myId,
                          isGroup: widget.isGroup,
                        ),
                      ),
              ),
              if (otherTypers.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(left: 16.w, bottom: 4.h),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${otherTypers.join(', ')} ${otherTypers.length > 1 ? 'are' : 'is'} typing...',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
              _buildInputBar(context, state),
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0.5,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back,
          color: AppColors.textPrimary,
          size: 22,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          _ChatAvatar(
            title: widget.title,
            avatarImage: widget.avatarImage,
            isGroup: widget.isGroup,
            size: 38,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
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
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Say hi to ${widget.title}!',
            style: TextStyle(
              fontFamily: _kFont,
              fontSize: 13.sp,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(BuildContext context, TeamChatState state) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: 12.w,
        vertical: 8.h,
      ).copyWith(bottom: MediaQuery.of(context).viewInsets.bottom + 8.h),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            state.isUploading
                ? SizedBox(
                    width: 40.w,
                    height: 40.w,
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  )
                : _circleIcon(
                    icon: Icons.add,
                    onTap: () => _launchCamera(context),
                  ),
            SizedBox(width: 8.w),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(24.r),
                  border: Border.all(color: AppColors.border),
                ),
                child: _isRecording
                    ? Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 12.h,
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.mic, color: Colors.red, size: 18),
                            SizedBox(width: 8.w),
                            Text(
                              Duration(
                                seconds: _recordDuration,
                              ).toString().split('.').first,
                              style: TextStyle(
                                fontFamily: _kFont,
                                fontSize: 14.sp,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 4,
                        onChanged: (_) => _onTyping(context),
                        style: TextStyle(
                          fontFamily: _kFont,
                          fontSize: 14.sp,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(
                            fontFamily: _kFont,
                            fontSize: 14.sp,
                            color: AppColors.textHint,
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
            _sendOrMicButton(context),
          ],
        ),
      ),
    );
  }

  Widget _sendOrMicButton(BuildContext context) {
    final hasText = _controller.text.trim().isNotEmpty;
    if (_isRecording) {
      return _circleIcon(
        icon: Icons.send_rounded,
        onTap: () => _stopAndSend(context),
      );
    }
    if (hasText) {
      return _circleIcon(icon: Icons.send_rounded, onTap: () => _send(context));
    }
    return _circleIcon(icon: Icons.mic_none_sharp, onTap: _startRecording);
  }

  Widget _circleIcon({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(11.r),
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20.sp),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Message bubble (entity-backed, v2 styling, media attachments)
// ─────────────────────────────────────────────────────────────────────────────
class _MessageBubbleV2 extends StatelessWidget {
  final TeamChatMessageEntity msg;
  final String myId;
  final bool isGroup;
  const _MessageBubbleV2({
    required this.msg,
    required this.myId,
    required this.isGroup,
  });

  String _time(DateTime t) {
    final local = t.toLocal();
    final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m ${local.hour >= 12 ? 'PM' : 'AM'}';
  }

  @override
  Widget build(BuildContext context) {
    final isMe = msg.isMyMessage(myId);
    final text = msg.text;
    final attachments = msg.attachments;
    final onlyMedia = text.trim().isEmpty && attachments.isNotEmpty;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (!isMe && isGroup && msg.senderName.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(left: 44.w, bottom: 4.h),
              child: Text(
                msg.senderName,
                style: TextStyle(
                  fontFamily: _kFont,
                  fontSize: 12.sp,
                  color: _colorFor(msg.senderName),
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
                _ChatAvatar(
                  title: msg.senderName.isNotEmpty ? msg.senderName : 'Member',
                  avatarImage: msg.senderProfileImage,
                  isGroup: false,
                  size: 32,
                ),
                SizedBox(width: 8.w),
              ],
              Flexible(
                child: onlyMedia
                    ? Column(
                        crossAxisAlignment: isMe
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: attachments
                            .map((a) => _AttachmentView(att: a, isMe: isMe))
                            .toList(),
                      )
                    : Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 10.h,
                        ),
                        decoration: BoxDecoration(
                          color: isMe
                              ? AppColors.primary
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16.r),
                            topRight: Radius.circular(16.r),
                            bottomLeft: Radius.circular(isMe ? 16.r : 4.r),
                            bottomRight: Radius.circular(isMe ? 4.r : 16.r),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (attachments.isNotEmpty) ...[
                              ...attachments.map(
                                (a) => _AttachmentView(att: a, isMe: isMe),
                              ),
                              if (text.isNotEmpty) SizedBox(height: 6.h),
                            ],
                            if (text.isNotEmpty)
                              Text(
                                text,
                                style: TextStyle(
                                  fontFamily: _kFont,
                                  fontSize: 14.sp,
                                  height: 1.3,
                                  color: isMe
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                ),
                              ),
                          ],
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
                  _time(msg.createdAt),
                  style: TextStyle(
                    fontFamily: _kFont,
                    fontSize: 11.sp,
                    color: AppColors.textHint,
                  ),
                ),
                if (isMe) ...[
                  SizedBox(width: 4.w),
                  Icon(Icons.done_all, size: 14.sp, color: AppColors.primary),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachmentView extends StatelessWidget {
  final TeamChatAttachmentEntity att;
  final bool isMe;
  const _AttachmentView({required this.att, required this.isMe});

  Future<void> _open(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final url = att.url;
    switch (att.mediaType) {
      case 'image':
        return Padding(
          padding: EdgeInsets.only(bottom: 6.h),
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => _FullImageScreen(url: url)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14.r),
              child: Image.network(
                url,
                width: 200.w,
                fit: BoxFit.cover,
                errorBuilder: (_, e, s) => const Icon(
                  Icons.broken_image,
                  size: 40,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
        );
      case 'video':
        return GestureDetector(
          onTap: () => _open(url),
          child: Padding(
            padding: EdgeInsets.only(bottom: 6.h),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10.r),
              child: Container(
                width: 200.w,
                height: 118.w,
                color: const Color(0xFF1A1A2E),
                child: const Center(
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
              ),
            ),
          ),
        );
      case 'audio':
        return _AudioBubble(
          audioUrl: url,
          fileName: att.fileName.isNotEmpty ? att.fileName : 'Voice note',
        );
      default:
        return GestureDetector(
          onTap: () => _open(url),
          child: Padding(
            padding: EdgeInsets.only(bottom: 6.h),
            child: Container(
              width: 200.w,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: isMe ? Colors.white : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.insert_drive_file,
                    color: AppColors.textPrimary,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      att.fileName.isNotEmpty ? att.fileName : 'Document',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
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
}

class _AudioBubble extends StatelessWidget {
  final String audioUrl;
  final String fileName;
  const _AudioBubble({required this.audioUrl, required this.fileName});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        try {
          final uri = Uri.parse(audioUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        } catch (_) {}
      },
      child: Container(
        width: 200.w,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        margin: EdgeInsets.only(bottom: 6.h),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F3F5),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.play_circle_outline,
              color: AppColors.primary,
              size: 28,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: _kFont,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Voice note',
                    style: TextStyle(
                      fontFamily: _kFont,
                      fontSize: 10.sp,
                      color: Colors.grey,
                    ),
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

class _FullImageScreen extends StatelessWidget {
  final String url;
  const _FullImageScreen({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(
            url,
            fit: BoxFit.contain,
            errorBuilder: (_, e, s) =>
                const Icon(Icons.broken_image, color: Colors.white, size: 60),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Media preview (after capturing photos/videos) — before sending
// ─────────────────────────────────────────────────────────────────────────────
class _MediaPreviewScreen extends StatefulWidget {
  final List<CameraData> initialItems;
  const _MediaPreviewScreen({required this.initialItems});

  @override
  State<_MediaPreviewScreen> createState() => _MediaPreviewScreenState();
}

class _MediaPreviewScreenState extends State<_MediaPreviewScreen> {
  late List<CameraData> items;
  int _currentPage = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    items = List.from(widget.initialItems);
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _addMore() async {
    final result = await context.push(
      AppRoutes.employeeCamera,
      extra: {'picAgain': true},
    );
    if (result is List) {
      for (final e in result) {
        if (e is CameraData && e.path.isNotEmpty) {
          setState(() => items.insert(0, e));
        }
      }
      if (mounted && items.isNotEmpty) {
        setState(() => _currentPage = 0);
        _pageController.jumpToPage(0);
      }
    }
  }

  void _removeCurrent() {
    if (items.isEmpty) return;
    setState(() => items.removeAt(_currentPage));
    if (items.isEmpty) {
      Navigator.pop(context);
      return;
    }
    final next = _currentPage >= items.length ? items.length - 1 : _currentPage;
    setState(() => _currentPage = next);
    _pageController.jumpToPage(next);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final item = items[i];
                final isImage =
                    item.mimeType.startsWith('image') ||
                    item.mimeType.isEmpty ||
                    item.path.toLowerCase().endsWith('.jpg') ||
                    item.path.toLowerCase().endsWith('.jpeg') ||
                    item.path.toLowerCase().endsWith('.png');
                return InteractiveViewer(
                  scaleEnabled: isImage,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      if (isImage)
                        SizedBox(
                          height: size.height,
                          width: size.width,
                          child: Image.file(
                            File(item.path),
                            fit: BoxFit.contain,
                            errorBuilder: (_, e, s) => const Icon(
                              Icons.broken_image,
                              color: Colors.white,
                              size: 60,
                            ),
                          ),
                        )
                      else
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.videocam,
                                color: Colors.white,
                                size: 64,
                              ),
                              SizedBox(height: 12.h),
                              Text(
                                item.path.split('/').last,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      Positioned(
                        top: topPad + 12,
                        right: 8,
                        child: IconButton(
                          onPressed: _removeCurrent,
                          icon: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.black,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                      if (items.length > 1)
                        Positioned(
                          bottom: 90,
                          child: DotsIndicator(
                            dotsCount: items.length,
                            position: _currentPage,
                            decorator: const DotsDecorator(
                              color: Colors.grey,
                              activeColor: AppColors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 28.h),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48.h,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      onPressed: _addMore,
                      child: Text(
                        'Add More',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          fontFamily: _kFont,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: SizedBox(
                    height: 48.h,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context, items),
                      child: Text(
                        'Send',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          fontFamily: _kFont,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
