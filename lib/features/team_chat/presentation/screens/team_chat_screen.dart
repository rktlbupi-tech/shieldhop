import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../config/di/injection.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../common/widgets/company_logo_widget.dart';
import '../../../tasks/data/models/employee_task_model.dart';
import '../../domain/entities/team_chat_message_entity.dart';
import '../bloc/team_chat_bloc.dart';

class TeamChatScreen extends StatefulWidget {
  final String roomId, roomName;
  final EmployeeTaskModel? task;
  const TeamChatScreen({
    super.key,
    required this.roomId,
    required this.roomName,
    this.task,
  });
  @override
  State<TeamChatScreen> createState() => _TeamChatScreenState();
}

class _TeamChatScreenState extends State<TeamChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  String _myId = '';
  String _myName = '';

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  void _initChat() {
    final prefs = getIt<SharedPreferences>();
    _myId = prefs.getString('user_id') ?? '';
    _myName =
        '${prefs.getString('first_name') ?? ''} ${prefs.getString('last_name') ?? ''}'
            .trim();
  }

  void _sendMessage(BuildContext context) {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    context.read<TeamChatBloc>().add(
      SendTeamChatMessageEvent(text: text, myId: _myId, myName: _myName),
    );
    _controller.clear();
    _scrollToBottom();
  }

  void _onTypingInput(BuildContext context, String _) {
    context.read<TeamChatBloc>().add(
      SendTeamChatTypingInputEvent(myId: _myId, myName: _myName),
    );
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

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildTaskHeader(Size size) {
    if (widget.task == null) return const SizedBox.shrink();
    final task = widget.task!;
    final companyName = widget.roomName;
    final profileImage = task.creatorSummary?.profileImage ?? "";

    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: size.width * 0.04,
        vertical: 12,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 25),
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        companyName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontFamily: "AirbnbCereal",
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFF0F2F5),
                      ),
                      child: ClipOval(
                        child: profileImage.isNotEmpty
                            ? Image.network(
                                profileImage,
                                fit: BoxFit.cover,
                                errorBuilder: (_, e, s) => const Icon(
                                  Icons.person,
                                  color: Colors.grey,
                                ),
                              )
                            : const Icon(Icons.person, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF0F172A),
                    fontFamily: "AirbnbCereal",
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  task.description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF475569),
                    fontFamily: "AirbnbCereal",
                    fontWeight: FontWeight.w400,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            child: Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(Size size, TeamChatState state) {
    if (state.messages.isEmpty) {
      if (widget.task != null) {
        return Column(
          children: [
            _buildTaskHeader(size),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 56.sp,
                      color: const Color(0xFFCBD5E1),
                    ),
                    SizedBox(height: 12.h),
                    const Text(
                      'No messages yet',
                      style: TextStyle(
                        fontFamily: 'AirbnbCereal',
                        fontSize: 16,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    const Text(
                      'Conversation will appear here',
                      style: TextStyle(
                        fontFamily: 'AirbnbCereal',
                        fontSize: 13,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      } else {
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
              const Text(
                'No messages yet',
                style: TextStyle(
                  fontFamily: 'AirbnbCereal',
                  fontSize: 16,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4.h),
              const Text(
                'Say hi to your team!',
                style: TextStyle(
                  fontFamily: 'AirbnbCereal',
                  fontSize: 13,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        );
      }
    }

    final hasHeader = widget.task != null;

    final messages = state.messages.reversed.toList();

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      itemCount: messages.length + (hasHeader ? 1 : 0),
      itemBuilder: (context, i) {
        if (hasHeader && i == 0) {
          return _buildTaskHeader(size);
        }
        final msg = messages[hasHeader ? i - 1 : i];
        return _MessageBubble(msg: msg, myId: _myId);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final prefs = getIt<SharedPreferences>();
    final token = prefs.getString('auth_token') ?? '';

    return BlocProvider<TeamChatBloc>(
      create: (context) => getIt<TeamChatBloc>()
        ..add(InitTeamChatEvent(conversationId: widget.roomId, token: token)),
      child: BlocConsumer<TeamChatBloc, TeamChatState>(
        listener: (context, state) {
          if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          }
          // Scroll to bottom when a new message is received
          _scrollToBottom();
        },
        builder: (context, state) {
          final otherTypers = state.typingMembers.entries
              .where((e) => e.key != _myId)
              .map((e) => e.value)
              .toList();
          final otherTyping = otherTypers.isNotEmpty;
          final typingName = otherTypers.join(', ');

          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
              titleSpacing: 0,
              title: Text(
                widget.task != null ? "Manage Task" : widget.roomName,
                style: const TextStyle(
                  color: Colors.black,
                  fontFamily: 'AirbnbCereal',
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              centerTitle: false,
              actions: const [CompanyLogoAction()],
            ),
            body: state.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : Column(
                    children: [
                      Expanded(child: _buildBody(size, state)),
                      if (otherTyping)
                        Padding(
                          padding: EdgeInsets.only(left: 16.w, bottom: 4.h),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '$typingName ${otherTypers.length > 1 ? 'are' : 'is'} typing...',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ),
                      _InputBar(
                        controller: _controller,
                        onSend: () => _sendMessage(context),
                        onChanged: (val) => _onTypingInput(context, val),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final TeamChatMessageEntity msg;
  final String myId;
  const _MessageBubble({required this.msg, required this.myId});

  @override
  Widget build(BuildContext context) {
    final isMe = msg.isMyMessage(myId);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (!isMe)
            Padding(
              padding: EdgeInsets.only(left: 44.w, bottom: 4.h),
              child: Text(
                msg.senderName,
                style: TextStyle(
                  fontFamily: 'AirbnbCereal',
                  fontSize: 12.sp,
                  color: const Color(0xFF1877F2),
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
                CircleAvatar(
                  radius: 16.r,
                  backgroundColor: const Color(
                    0xFF1877F2,
                  ).withValues(alpha: 0.1),
                  child: Text(
                    msg.senderName.isNotEmpty
                        ? msg.senderName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontFamily: 'AirbnbCereal',
                      fontSize: 13.sp,
                      color: const Color(0xFF1877F2),
                      fontWeight: FontWeight.bold,
                    ),
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
                    color: isMe
                        ? const Color(0xFF1877F2)
                        : const Color(0xFFF1F5F9),
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
                      fontFamily: 'AirbnbCereal',
                      fontSize: 14.sp,
                      height: 1.3,
                      color: isMe ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ),
              if (isMe) ...[
                SizedBox(width: 6.w),
                Icon(
                  Icons.done_all,
                  size: 14.sp,
                  color: const Color(0xFF1877F2),
                ),
              ],
            ],
          ),
          Padding(
            padding: EdgeInsets.only(
              top: 4.h,
              left: isMe ? 0 : 44.w,
              right: isMe ? 20.w : 0,
            ),
            child: Text(
              '${msg.createdAt.hour.toString().padLeft(2, '0')}:${msg.createdAt.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontFamily: 'AirbnbCereal',
                fontSize: 11.sp,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final void Function(String) onChanged;
  const _InputBar({
    required this.controller,
    required this.onSend,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
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
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(24.r),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  minLines: 1,
                  maxLines: 4,
                  style: TextStyle(
                    fontFamily: 'AirbnbCereal',
                    fontSize: 14.sp,
                    color: const Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(
                      fontFamily: 'AirbnbCereal',
                      fontSize: 14.sp,
                      color: const Color(0xFF94A3B8),
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
              onTap: onSend,
              child: Container(
                padding: EdgeInsets.all(12.r),
                decoration: const BoxDecoration(
                  color: Color(0xFF1877F2),
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
