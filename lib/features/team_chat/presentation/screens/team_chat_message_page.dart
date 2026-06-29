import 'dart:async';
import 'dart:io';

import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../config/di/injection.dart';
import '../../../../core/constants/app_colors.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/routes/app_router.dart';
import '../../../camera/data/models/camera_data.dart';
import '../../domain/entities/team_chat_message_entity.dart';
import '../bloc/team_chat_bloc.dart';

class TeamChatMessagePage extends StatefulWidget {
  final String conversationId;
  final String title;
  final String? image;

  const TeamChatMessagePage({
    super.key,
    required this.conversationId,
    required this.title,
    this.image,
  });

  @override
  State<TeamChatMessagePage> createState() => _TeamChatMessagePageState();
}

class _TeamChatMessagePageState extends State<TeamChatMessagePage> {
  late final SharedPreferences _prefs;

  final ScrollController _chatScrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();

  bool _isRecording = false;
  int _recordDuration = 0;
  Timer? _recordTimer;
  final AudioRecorder _audioRecorder = AudioRecorder();

  @override
  void initState() {
    super.initState();
    _prefs = getIt<SharedPreferences>();
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _audioRecorder.dispose();
    _chatScrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage(BuildContext context) {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final myId = _prefs.getString('user_id') ?? '';
    final myName = '${_prefs.getString('first_name') ?? ''} ${_prefs.getString('last_name') ?? ''}'.trim();

    context.read<TeamChatBloc>().add(
          SendTeamChatMessageEvent(
            text: text,
            myId: myId,
            myName: myName,
          ),
        );
    _messageController.clear();
  }

  Future<void> _startAudioRecording() async {
    try {
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
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
    } catch (e) {
      _showSnack("Microphone is currently busy or in use by another app.");
    }
  }

  void _showMicPermissionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Microphone permission',
          style: TextStyle(
            fontFamily: 'AirbnbCereal',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Microphone access is needed to record voice notes. Please enable it for PressHop in Settings.',
          style: TextStyle(fontFamily: 'AirbnbCereal'),
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

  Future<void> _stopAndSendAudio(BuildContext context) async {
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

  Future<void> _uploadAndSendFiles(BuildContext context, List<File> files) async {
    if (files.isEmpty) return;
    context.read<TeamChatBloc>().add(SendTeamChatMediaEvent(files: files));
  }

  Future<void> _launchCameraScreen(BuildContext context) async {
    final result = await context.push(
      AppRoutes.employeeCamera,
      extra: {'picAgain': true},
    );
    if (result == null || result is! List) return;

    final List<CameraData> captured = [];
    for (final e in result) {
      if (e is CameraData && e.path.isNotEmpty) captured.add(e);
    }
    if (captured.isEmpty) return;

    if (!context.mounted) return;
    final previewResult = await Navigator.push<List<CameraData>>(
      context,
      MaterialPageRoute(
        builder: (_) => _TeamMediaPreviewScreen(initialItems: captured),
      ),
    );
    if (previewResult != null && previewResult.isNotEmpty) {
      final files = previewResult
          .where((e) => e.path.isNotEmpty)
          .map((e) => File(e.path))
          .toList();
      if (files.isNotEmpty && context.mounted) {
        await _uploadAndSendFiles(context, files);
      }
    }
  }

  Future<void> _openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _formatMsgTime(DateTime createdAt) {
    final local = createdAt.toLocal();
    final h = local.hour > 12
        ? local.hour - 12
        : (local.hour == 0 ? 12 : local.hour);
    final m = local.minute.toString().padLeft(2, '0');
    final ampm = local.hour >= 12 ? 'PM' : 'AM';
    final months = [
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
    return '$h:$m $ampm, ${local.day} ${months[local.month - 1]} ${local.year}';
  }

  Widget _buildNoMessagesPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.chat_bubble_outline, size: 52, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        const Text(
          'Start to chat',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.w600,
            fontFamily: 'AirbnbCereal',
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'Say hello to ${widget.title}! Send a message to start the conversation.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
              fontFamily: 'AirbnbCereal',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChatBubble(TeamChatMessageEntity msg, Size size) {
    final myId = _prefs.getString('user_id') ?? '';
    const Color primaryColor = AppColors.primary;
    final bool isMe = msg.isMyMessage(myId);

    final String text = msg.text;
    final String time = _formatMsgTime(msg.createdAt);
    final attachments = msg.attachments;

    final avatar = Container(
      height: size.width * 0.11,
      width: size.width * 0.11,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: msg.senderProfileImage.isNotEmpty
            ? Image.network(
                msg.senderProfileImage,
                fit: BoxFit.cover,
                errorBuilder: (_, e, s) =>
                    const Icon(Icons.person, color: Colors.grey),
              )
            : const Icon(Icons.person, color: Colors.grey),
      ),
    );

    final bubble = Column(
      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (!isMe)
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 3),
            child: Text(
              msg.senderName.isNotEmpty ? msg.senderName : 'Member',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: primaryColor,
                letterSpacing: 0.1,
              ),
            ),
          ),
        text.trim().isEmpty && attachments.isNotEmpty
            ? Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: attachments
                    .map<Widget>(
                      (att) => _buildAttachment(att, msg, isMe, size),
                    )
                    .toList(),
              )
            : Container(
                constraints: BoxConstraints(maxWidth: size.width * 0.68),
                padding: text.trim().isEmpty
                    ? EdgeInsets.zero
                    : EdgeInsets.symmetric(
                        horizontal: size.width * 0.05,
                        vertical: size.width * 0.025,
                      ),
                decoration: BoxDecoration(
                  color: text.trim().isEmpty
                      ? Colors.transparent
                      : (isMe ? primaryColor : const Color(0xFFF1F3F5)),
                  borderRadius: isMe
                      ? BorderRadius.only(
                          topLeft: Radius.circular(size.width * 0.04),
                          topRight: Radius.circular(size.width * 0.04),
                          bottomLeft: Radius.circular(size.width * 0.04),
                        )
                      : BorderRadius.only(
                          topRight: Radius.circular(size.width * 0.04),
                          bottomLeft: Radius.circular(size.width * 0.04),
                          bottomRight: Radius.circular(size.width * 0.04),
                        ),
                  boxShadow: text.trim().isEmpty
                      ? []
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (attachments.isNotEmpty) ...[
                      ...attachments.map<Widget>(
                        (att) => _buildAttachment(att, msg, isMe, size),
                      ),
                      if (text.isNotEmpty) const SizedBox(height: 6),
                    ],
                    if (text.isNotEmpty)
                      Text(
                        text,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.45,
                          color: isMe ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.1,
                        ),
                      ),
                  ],
                ),
              ),
        if (time.isNotEmpty &&
            !attachments.any((a) => a.mediaType == 'image')) ...[
          const SizedBox(height: 3),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Text(
                time,
                style: TextStyle(
                  fontSize: size.width * 0.028,
                  color: const Color(0xFFADB5BD),
                ),
              ),
              if (isMe) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.done_all,
                  size: size.width * 0.04,
                  color: Colors.green.shade400,
                ),
              ],
            ],
          ),
        ],
        const SizedBox(height: 8),
      ],
    );

    if (isMe) {
      return Align(
        alignment: Alignment.centerRight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [bubble, const SizedBox(width: 6), avatar],
        ),
      );
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [avatar, const SizedBox(width: 6), bubble],
      ),
    );
  }

  Widget _buildAttachment(
    TeamChatAttachmentEntity att,
    TeamChatMessageEntity msg,
    bool isMe,
    Size size,
  ) {
    final mediaType = att.mediaType;
    final url = att.url;

    if (mediaType == 'image') {
      return Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => _FullImageScreen(url: url)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(size.width * 0.04),
              child: Image.network(
                url,
                width: size.width * 0.64,
                fit: BoxFit.cover,
                errorBuilder: (_, e, s) => const Icon(
                  Icons.broken_image,
                  size: 40,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: size.width * 0.64,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.access_time,
                  size: size.width * 0.028,
                  color: Colors.grey,
                ),
                SizedBox(width: size.width * 0.012),
                Text(
                  _formatMsgTime(msg.createdAt),
                  style: TextStyle(
                    fontSize: size.width * 0.028,
                    color: Colors.grey,
                  ),
                ),
                if (isMe) ...[
                  SizedBox(width: size.width * 0.012),
                  Icon(
                    Icons.done_all,
                    size: size.width * 0.04,
                    color: Colors.green.shade400,
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: size.width * 0.018),
        ],
      );
    }

    if (mediaType == 'video') {
      return GestureDetector(
        onTap: () => _openUrl(url),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 200,
              height: 118,
              color: const Color(0xFF1A1A2E),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 10,
                    child: Text(
                      att.fileName.isNotEmpty ? att.fileName : 'Video',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (mediaType == 'audio') {
      return _AudioBubble(
        audioUrl: url,
        fileName: att.fileName.isNotEmpty ? att.fileName : 'Voice note',
      );
    }

    return GestureDetector(
      onTap: () => _openUrl(url),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Container(
          width: 200,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isMe ? Colors.white : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.insert_drive_file, color: Colors.black87),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  att.fileName.isNotEmpty ? att.fileName : 'Document',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput(BuildContext context, TeamChatState state) {
    const Color primaryColor = AppColors.primary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(height: 1, thickness: 1, color: Color(0xFFF1F3F5)),
        Container(
          padding: EdgeInsets.fromLTRB(
            12,
            10,
            12,
            12 + MediaQuery.of(context).padding.bottom,
          ),
          color: Colors.white,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              state.isUploading
                  ? const SizedBox(
                      width: 44,
                      height: 44,
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    )
                  : _inputIconButton(
                      icon: LucideIcons.plus,
                      onTap: () => _launchCameraScreen(context),
                    ),
              const SizedBox(width: 8),
              Expanded(
                child: Stack(
                  alignment: Alignment.centerRight,
                  children: [
                    Container(
                      constraints: const BoxConstraints(
                        minHeight: 44,
                        maxHeight: 120,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F6F8),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 1.0,
                        ),
                      ),
                      child: TextField(
                        controller: _messageController,
                        maxLines: null,
                        textAlignVertical: TextAlignVertical.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1A1A2E),
                          fontFamily: 'AirbnbCereal',
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Type or speak here ...',
                          hintStyle: TextStyle(
                            color: Color(0xFFADB5BD),
                            fontFamily: 'AirbnbCereal',
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.only(
                            left: 14,
                            right: 44,
                            top: 12,
                            bottom: 12,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 6,
                      child: GestureDetector(
                        onTap: () => _sendMessage(context),
                        child: const SizedBox(
                          width: 36,
                          height: 36,
                          child: Center(
                            child: Icon(
                              Icons.arrow_forward,
                              color: Colors.black87,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_isRecording)
                      Positioned.fill(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F6F8),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.mic_none_outlined,
                                color: Colors.red,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                Duration(
                                  seconds: _recordDuration,
                                ).toString().split('.').first,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'AirbnbCereal',
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _isRecording
                    ? () => _stopAndSendAudio(context)
                    : _startAudioRecording,
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: Icon(
                      _isRecording ? Icons.send_rounded : Icons.mic_none_sharp,
                      color: _isRecording ? primaryColor : Colors.black87,
                      size: 26,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _inputIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
          border: Border.all(
            color: const Color(0xFF1677FF).withValues(alpha: 0.45),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1677FF),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
                width: 1,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final String image = widget.image ?? '';
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A2E), size: 22),
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade50,
              border: Border.all(color: Colors.grey.shade200, width: 1),
            ),
            child: ClipOval(
              child: image.isNotEmpty
                  ? Image.network(
                      image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, e, s) =>
                          const Icon(Icons.person, color: Colors.grey),
                    )
                  : const Icon(Icons.person, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.title,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E),
                fontFamily: 'AirbnbCereal',
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: const Color(0xFFECECEC), height: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return BlocProvider<TeamChatBloc>(
      create: (_) => getIt<TeamChatBloc>()
        ..add(
          InitTeamChatEvent(
            conversationId: widget.conversationId,
            token: _prefs.getString('auth_token') ?? '',
          ),
        ),
      child: BlocConsumer<TeamChatBloc, TeamChatState>(
        listener: (context, state) {
          if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
            _showSnack(state.errorMessage!);
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: Colors.white,
            resizeToAvoidBottomInset: true,
            appBar: _buildAppBar(),
            body: state.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: state.messages.isEmpty
                            ? _buildNoMessagesPlaceholder()
                            : Align(
                                alignment: Alignment.topCenter,
                                child: ListView.builder(
                                  controller: _chatScrollController,
                                  reverse: true,
                                  shrinkWrap: true,
                                  padding: EdgeInsets.only(
                                    left: size.width * 0.04,
                                    right: size.width * 0.04,
                                    bottom: size.width * 0.03,
                                    top: 16,
                                  ),
                                  itemCount: state.messages.length,
                                  itemBuilder: (context, index) {
                                    return _buildChatBubble(
                                      state.messages[index],
                                      size,
                                    );
                                  },
                                ),
                              ),
                      ),
                      _buildMessageInput(context, state),
                    ],
                  ),
          );
        },
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

class _AudioBubble extends StatefulWidget {
  final String audioUrl;
  final String fileName;
  const _AudioBubble({required this.audioUrl, required this.fileName});

  @override
  State<_AudioBubble> createState() => _AudioBubbleState();
}

class _AudioBubbleState extends State<_AudioBubble> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        try {
          final uri = Uri.parse(widget.audioUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        } catch (_) {}
      },
      child: Container(
        width: 200,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F3F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.play_circle_outline,
              color: AppColors.primary,
              size: 28,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.fileName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'AirbnbCereal',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    'Voice note',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                      fontFamily: 'AirbnbCereal',
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

// ── Media preview screen shown after capturing photos/videos ─────────────────
class _TeamMediaPreviewScreen extends StatefulWidget {
  final List<CameraData> initialItems;
  const _TeamMediaPreviewScreen({required this.initialItems});

  @override
  State<_TeamMediaPreviewScreen> createState() =>
      _TeamMediaPreviewScreenState();
}

class _TeamMediaPreviewScreenState extends State<_TeamMediaPreviewScreen> {
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
    if (result != null && result is List) {
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

  void _removeCurrentPage() {
    if (items.isEmpty) return;
    setState(() {
      items.removeAt(_currentPage);
    });
    if (items.isEmpty) {
      Navigator.pop(context);
      return;
    }
    final nextPage = _currentPage >= items.length
        ? items.length - 1
        : _currentPage;
    setState(() => _currentPage = nextPage);
    _pageController.jumpToPage(nextPage);
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
                              const SizedBox(height: 12),
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
                        top: topPad + size.width * 0.04,
                        right: size.width * 0.02,
                        child: IconButton(
                          onPressed: _removeCurrentPage,
                          icon: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              color: Colors.black,
                              size: size.width * 0.06,
                            ),
                          ),
                        ),
                      ),
                      if (items.length > 1)
                        Positioned(
                          bottom: 0,
                          child: DotsIndicator(
                            dotsCount: items.length,
                            position: _currentPage,
                            decorator: DotsDecorator(
                              color: Colors.grey,
                              activeColor: AppColors.primary,
                            ),
                          ),
                        ),
                      Container(
                        margin: EdgeInsets.only(bottom: size.width * 0.03),
                        padding: EdgeInsets.symmetric(
                          horizontal: size.width * 0.04,
                          vertical: size.width * 0.04,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _infoPill(
                                size,
                                icon: Icons.access_time,
                                text: item.dateTime,
                                isAlert: false,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _infoPill(
                                size,
                                icon: Icons.location_on,
                                text: item.location.isEmpty
                                    ? 'No Location'
                                    : item.location,
                                isAlert: item.location.isEmpty,
                              ),
                            ),
                          ],
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
            padding: EdgeInsets.fromLTRB(
              size.width * 0.03,
              size.width * 0.02,
              size.width * 0.03,
              size.width * 0.08,
            ),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: size.width * 0.13,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            size.width * 0.03,
                          ),
                        ),
                      ),
                      onPressed: _addMore,
                      child: Text(
                        'Add More',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: size.width * 0.035,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'AirbnbCereal',
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: size.width * 0.13,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            size.width * 0.03,
                          ),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context, items),
                      child: Text(
                        'Submit',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: size.width * 0.035,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'AirbnbCereal',
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

  Widget _infoPill(
    Size size, {
    required IconData icon,
    required String text,
    required bool isAlert,
  }) {
    return Container(
      height: size.width * 0.11,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size.width * 0.04),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: size.width * 0.04,
            color: isAlert ? Colors.red : const Color(0xFF64748B),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: size.width * 0.028,
                color: const Color(0xFF1E293B),
                fontWeight: FontWeight.w600,
                fontFamily: 'AirbnbCereal',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
