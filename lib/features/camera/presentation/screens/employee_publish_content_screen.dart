import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/camera_data.dart';
import '../../utils/camera_constants.dart';
import '../../utils/camera_task_service.dart';
import '../../utils/upload_progress_notifier.dart';
import 'audio_recorder_screen.dart';
import 'content_submitted_screen.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';
import '../../../../main.dart' show sharedPreferences;
import '../../../../common/widgets/loading_widget.dart';
import '../../../../config/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/socket/socket_manager.dart';

class EmployeePublishContentScreen extends StatefulWidget {
  final PublishData? publishData;
  final String docType;
  final bool hideDraft;

  const EmployeePublishContentScreen({
    super.key,
    required this.publishData,
    required this.docType,
    this.hideDraft = true,
  });

  @override
  State<EmployeePublishContentScreen> createState() =>
      _EmployeePublishContentScreenState();
}

class _EmployeePublishContentScreenState
    extends State<EmployeePublishContentScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final PlayerController _playerController = PlayerController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _locationCtrl = TextEditingController();
  final TextEditingController _timestampCtrl = TextEditingController();
  final CameraTaskService _taskService = CameraTaskService();

  String _audioPath = '';
  bool _audioPlaying = false;

  List<CameraTaskModel> _todayTasks = [];
  CameraTaskModel? _selectedTask;
  bool _isTasksLoading = false;

  int imageCount = 0, videoCount = 0, audioCount = 0, docCount = 0;

  @override
  void initState() {
    super.initState();
    for (final m in (widget.publishData?.mediaList ?? [])) {
      if (m.mimeType == 'image') imageCount++;
      if (m.mimeType == 'video') videoCount++;
      if (m.mimeType == 'audio') audioCount++;
      if (m.mimeType == 'doc' || m.mimeType == 'pdf') docCount++;
    }
    final address = (widget.publishData?.address ?? '').isNotEmpty
        ? widget.publishData!.address
        : sharedPreferences?.getString(currentAddress) ?? '';
    _locationCtrl.text = address;
    _timestampCtrl.text = DateFormat(
      'dd MMM yyyy, hh:mm a',
    ).format(DateTime.now());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchTodayTasks();
      UploadProgressNotifier.instance.init();
    });
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _timestampCtrl.dispose();
    _playerController.dispose();
    super.dispose();
  }

  Future<void> _fetchTodayTasks() async {
    if (!mounted) return;
    setState(() => _isTasksLoading = true);
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final tasks = await _taskService.fetchTodayTasks(
      startDate: today,
      endDate: today,
    );
    if (mounted) {
      setState(() {
        _todayTasks = tasks;
        _isTasksLoading = false;
      });
    }
  }

  Future<void> _initAudioPlayer(String path) async {
    try {
      await _playerController.preparePlayer(
        path: path,
        shouldExtractWaveform: true,
        noOfSamples: 100,
        volume: 1.0,
      );
      _playerController.onCompletion.listen((_) {
        if (mounted) setState(() => _audioPlaying = false);
      });
    } catch (_) {}
  }

  void _showTaskPicker(Size size) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(size.width * numD07),
          topRight: Radius.circular(size.width * numD07),
        ),
      ),
      builder: (sheetCtx) => Container(
        width: double.infinity,
        height: size.height * 0.75,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(size.width * numD07),
            topRight: Radius.circular(size.width * numD07),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: size.width * numD045),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: size.width * numD035),
              Row(
                children: [
                  Text(
                    'Select Task',
                    style: TextStyle(
                      fontSize: size.width * numD045,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'AirbnbCereal',
                    ),
                  ),
                  SizedBox(width: size.width * numD015),
                  Icon(
                    Icons.assignment_outlined,
                    size: size.width * numD06,
                    color: Colors.black,
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(sheetCtx),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(color: Color(0xFFE0E0E0), thickness: 1.3),
              SizedBox(height: size.width * numD035),
              Expanded(
                child: _isTasksLoading
                    ? const LoadingWidget()
                    : _todayTasks.isEmpty
                    ? Center(
                        child: Text(
                          'No tasks scheduled for today',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: size.width * numD03,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _todayTasks.length,
                        separatorBuilder: (context2, i2) =>
                            SizedBox(height: size.width * numD02),
                        itemBuilder: (_, i) {
                          final task = _todayTasks[i];
                          final isSelected = _selectedTask?.id == task.id;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedTask = isSelected ? null : task;
                              });
                              Navigator.pop(sheetCtx);
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: size.width * numD025,
                                vertical: size.width * numD025,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFEEF2FF)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(
                                  size.width * numD03,
                                ),
                                border: Border.all(
                                  color: isSelected
                                      ? colorEmployeeGreen1
                                      : Colors.grey.shade300,
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: size.width * numD1,
                                    height: size.width * numD1,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8EDFF),
                                      borderRadius: BorderRadius.circular(
                                        size.width * numD02,
                                      ),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.location_on_outlined,
                                        size: size.width * numD045,
                                        color: colorEmployeeGreen1,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: size.width * numD025),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          task.title,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: size.width * numD034,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if ((task.destinationLabel ?? '')
                                            .isNotEmpty) ...[
                                          const SizedBox(height: 3),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.location_on_outlined,
                                                size: size.width * numD03,
                                                color: Colors.grey.shade500,
                                              ),
                                              const SizedBox(width: 2),
                                              Expanded(
                                                child: Text(
                                                  task.destinationLabel!,
                                                  style: TextStyle(
                                                    fontSize:
                                                        size.width * numD026,
                                                    color: Colors.grey.shade500,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: size.width * numD02),
                                  if (isSelected)
                                    Icon(
                                      Icons.check_circle,
                                      color: colorEmployeeGreen1,
                                      size: size.width * numD05,
                                    )
                                  else
                                    SizedBox(width: size.width * numD05),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              SizedBox(height: size.width * numD04),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_selectedTask == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a task to submit with'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    FocusScope.of(context).unfocus();

    final fallbackAddress = (widget.publishData?.address ?? '').isNotEmpty
        ? widget.publishData!.address
        : sharedPreferences?.getString(currentAddress) ?? '';
    final fallbackLat = (widget.publishData?.latitude ?? '').isNotEmpty
        ? widget.publishData!.latitude
        : (sharedPreferences?.getDouble(currentLat) ?? 0.0).toString();
    final fallbackLng = (widget.publishData?.longitude ?? '').isNotEmpty
        ? widget.publishData!.longitude
        : (sharedPreferences?.getDouble(currentLon) ?? 0.0).toString();

    final mediaList = (widget.publishData?.mediaList ?? [])
        .map(
          (e) => CameraTaskMediaData(
            mediaPath: e.mediaPath,
            mimeType: e.mimeType,
            thumbnail: e.thumbnail,
            latitude: e.latitude.isNotEmpty ? e.latitude : fallbackLat,
            longitude: e.longitude.isNotEmpty ? e.longitude : fallbackLng,
            location: e.location.isNotEmpty ? e.location : fallbackAddress,
            dateTime: e.dateTime,
            isLocalMedia: e.isLocalMedia,
          ),
        )
        .toList();

    if (_audioPath.isNotEmpty) {
      mediaList.add(
        CameraTaskMediaData(
          mediaPath: _audioPath,
          mimeType: 'audio',
          thumbnail: '',
          latitude: fallbackLat,
          longitude: fallbackLng,
          location: fallbackAddress,
          dateTime: DateTime.now().toIso8601String(),
          isLocalMedia: true,
        ),
      );
    }

    final taskId = _selectedTask!.id;
    final description = _descCtrl.text.trim();
    final lat = double.tryParse(fallbackLat) ?? 0.0;
    final lng = double.tryParse(fallbackLng) ?? 0.0;

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: LoadingWidget()),
    );

    final title = (description.isNotEmpty)
        ? description
        : 'Uploading task evidence';

    UploadProgressNotifier.instance.startUpload(taskId: taskId, title: title);

    try {
      final success = await _taskService.uploadEvidence(
        taskId: taskId,
        mediaList: mediaList,
        latitude: lat,
        longitude: lng,
        address: fallbackAddress,
        description: description,
        onProgress: UploadProgressNotifier.instance.updateProgress,
      );

      if (success) {
        UploadProgressNotifier.instance.completeUpload();
        sharedPreferences?.remove('ev_notify_10');
        sharedPreferences?.remove('ev_notify_40');
        sharedPreferences?.remove('ev_notify_90');

        await _sendContentNotificationToTaskChat(
          taskId: taskId,
          mediaList: mediaList,
          address: fallbackAddress,
        );

        if (mounted) {
          Navigator.pop(context); // Dismiss loading dialog
        }

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ContentSubmittedScreen(publishData: widget.publishData),
            ),
            (r) => false,
          );
        }
      } else {
        if (mounted) {
          Navigator.pop(context); // Dismiss loading dialog
        }
        UploadProgressNotifier.instance.failUpload();
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Submission Failed'),
              content: const Text(
                'Could not submit evidence. Please try again.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      UploadProgressNotifier.instance.failUpload();
      if (mounted) {
        Navigator.pop(context); // Dismiss loading dialog
      }

      String errorMessage = 'Failed to submit evidence. Please try again.';
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          errorMessage = data['message'].toString();
        } else if (data is Map && data['error'] != null) {
          errorMessage = data['error'].toString();
        } else if (e.message != null) {
          errorMessage = e.message!;
        }
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Submission Error'),
            content: Text(errorMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _sendContentNotificationToTaskChat({
    required String taskId,
    required List<CameraTaskMediaData> mediaList,
    required String address,
  }) async {
    try {
      final localFiles = mediaList
          .where((e) => !e.mediaPath.startsWith('http'))
          .map((e) => File(e.mediaPath))
          .toList();
      if (localFiles.isEmpty) return;

      final apiClient = getIt<ApiClient>();
      final convResp = await apiClient.get(
        'chat-v2/enterprise/tasks/$taskId/conversation',
      );
      if (convResp.statusCode != 200 || convResp.data == null) return;

      final raw = convResp.data;
      final data = (raw is Map && raw['data'] != null) ? raw['data'] : raw;
      final conversation = data['conversation'];
      final conversationId =
          conversation?['_id']?.toString() ?? conversation?['id']?.toString();
      if (conversationId == null || conversationId.isEmpty) return;

      final items = localFiles
          .map(
            (f) => {
              'fileName': f.path.split('/').last,
              'contentType': _getMimeType(f.path),
              'size': f.lengthSync(),
            },
          )
          .toList();

      final resp = await apiClient.post(
        'chat-v2/media/prepare',
        data: {'conversationId': conversationId, 'items': items},
      );
      if (resp.statusCode != 200 && resp.statusCode != 201) return;

      final prepRaw = resp.data;
      final prepData = prepRaw is Map && prepRaw['data'] != null
          ? prepRaw['data']
          : prepRaw;
      final list = prepData is List ? prepData : (prepData['items'] as List);

      final List<String> assetIds = [];
      for (int i = 0; i < list.length; i++) {
        final asset = list[i];
        final uploadUrl = asset['uploadUrl'] as String;
        final assetId = asset['assetId'] as String;
        final file = localFiles[i];
        final contentType = _getMimeType(file.path);

        final uploadDio = Dio();
        final bytes = await file.readAsBytes();
        final putResp = await uploadDio.put(
          uploadUrl,
          data: bytes,
          options: Options(
            headers: {'Content-Type': contentType},
            followRedirects: false,
            validateStatus: (s) => s != null && s < 400,
          ),
        );
        if (putResp.statusCode != null && putResp.statusCode! < 400) {
          // Confirm the media upload
          final confirmResp = await apiClient.post(
            'chat-v2/media/$assetId/confirm',
          );
          if (confirmResp.statusCode == 200 || confirmResp.statusCode == 201) {
            assetIds.add(assetId);
          }
        }
      }

      if (assetIds.isEmpty) return;

      final socket = SocketManager.instance.chatSocket;
      if (!socket.isConnected) {
        final token = sharedPreferences?.getString('auth_token') ?? '';
        if (token.isNotEmpty) {
          socket.connect(token);
        }
      }

      int retries = 0;
      while (!socket.isConnected && retries < 10) {
        await Future.delayed(const Duration(milliseconds: 300));
        retries++;
      }

      if (socket.isConnected) {
        // Subscribe to the task conversation room
        socket.emitWithAck(
          'conversation.subscribe',
          {"conversationId": conversationId, "afterSeq": 0, "limit": 10},
          ack: (ack) {
            debugPrint('Content task conversation subscribe ack: $ack');
          },
        );

        // Wait a short moment for subscription registration
        await Future.delayed(const Duration(milliseconds: 200));

        final clientMessageId = "msg-${DateTime.now().millisecondsSinceEpoch}";
        final Map<String, dynamic> payload = {"text": ""};
        if (address.isNotEmpty) payload["location"] = address;

        socket.emitWithAck(
          'message.send',
          {
            "conversationId": conversationId,
            "clientMessageId": clientMessageId,
            "kind": "media",
            "payload": payload,
            "mediaAssetIds": assetIds,
          },
          ack: (ack) {
            debugPrint('Content task chat notification ack: $ack');
          },
        );
      }
    } catch (e) {
      debugPrint('Error in _sendContentNotificationToTaskChat: $e');
    }
  }

  String _getMimeType(String filePath) {
    final ext = filePath.split('.').last.toLowerCase();
    if (ext == 'jpg' || ext == 'jpeg') return 'image/jpeg';
    if (ext == 'png') return 'image/png';
    if (ext == 'gif') return 'image/gif';
    if (ext == 'mp4') return 'video/mp4';
    if (ext == 'mov') return 'video/quicktime';
    if (ext == 'mp3') return 'audio/mpeg';
    if (ext == 'm4a') return 'audio/mp4';
    if (ext == 'wav') return 'audio/wav';
    if (ext == 'pdf') return 'application/pdf';
    return 'application/octet-stream';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Text(
          'Submit content or evidence',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: size.width * appBarHeadingFontSize,
            fontFamily: 'AirbnbCereal',
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: size.width * numD06),

                // ── Thumbnail + description ─────────────────────────────
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width * numD04,
                  ),
                  child: SizedBox(
                    height: size.width * numD35,
                    child: Row(
                      children: [
                        // Thumbnail
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              size.width * numD06,
                            ),
                            child: Stack(
                              children: [
                                _buildThumbnail(size),
                                Positioned(
                                  top: size.width * numD03,
                                  left: size.width * numD03,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                      horizontal: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.5,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        size.width * numD013,
                                      ),
                                    ),
                                    child: Text(
                                      (imageCount + videoCount + audioCount)
                                          .toString(),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: size.width * numD03,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: size.width * numD03),
                        // Description input
                        Expanded(
                          child: SizedBox(
                            height: size.height,
                            child: TextFormField(
                              controller: _descCtrl,
                              maxLines: 100,
                              keyboardType: TextInputType.multiline,
                              cursorColor: Colors.black,
                              style: TextStyle(
                                fontSize: size.width * numD03,
                                color: Colors.black,
                                fontFamily: 'AirbnbCereal',
                              ),
                              decoration: InputDecoration(
                                hintText:
                                    'Please provide details of the content or evidence captured. Type here or use the voice input below.',
                                hintStyle: TextStyle(
                                  color: colorHint,
                                  fontSize: size.width * numD03,
                                  fontFamily: 'AirbnbCereal',
                                ),
                                disabledBorder: _outlineBorder(size),
                                focusedBorder: _outlineBorder(size),
                                enabledBorder: _outlineBorder(size),
                                errorBorder: _outlineBorder(size),
                                focusedErrorBorder: _outlineBorder(size),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: size.width * numD02),
                const Divider(color: colorLightGrey, thickness: 1),
                SizedBox(height: size.width * numD025),

                // ── Speak (audio narration) ─────────────────────────────
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width * numD04,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: size.width * numD32,
                        child: Text(
                          'SPEAK',
                          style: TextStyle(
                            fontSize: size.width * numD036,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'AirbnbCereal',
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context)
                                .push(
                                  MaterialPageRoute(
                                    builder: (_) => const AudioRecorderScreen(),
                                  ),
                                )
                                .then((value) {
                                  if (value != null) {
                                    _audioPath = value[0].toString();
                                    setState(() {});
                                    _initAudioPlayer(_audioPath);
                                  }
                                });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              vertical: size.width * numD03,
                              horizontal: size.width * numD05,
                            ),
                            decoration: BoxDecoration(
                              color: colorLightGrey,
                              borderRadius: BorderRadius.circular(
                                size.width * numD06,
                              ),
                            ),
                            child: Row(
                              children: [
                                InkWell(
                                  onTap: _audioPath.isNotEmpty
                                      ? () async {
                                          if (_audioPlaying) {
                                            await _playerController
                                                .pausePlayer();
                                          } else {
                                            await _playerController
                                                .startPlayer();
                                          }
                                          if (mounted) {
                                            setState(
                                              () => _audioPlaying =
                                                  !_audioPlaying,
                                            );
                                          }
                                        }
                                      : null,
                                  child: SizedBox(
                                    height: size.width * numD06,
                                    child: _audioPath.isEmpty
                                        ? ImageIcon(
                                            const AssetImage(
                                              'assets/icons/ic_mic.png',
                                            ),
                                            size: size.width * numD04,
                                            color: Colors.black,
                                          )
                                        : Icon(
                                            _audioPlaying
                                                ? Icons.pause_circle
                                                : Icons.play_circle,
                                            color: Colors.black,
                                            size: size.width * numD06,
                                          ),
                                  ),
                                ),
                                _audioPath.isNotEmpty
                                    ? Expanded(
                                        child: AudioFileWaveforms(
                                          size: Size(
                                            size.width,
                                            size.width * numD04,
                                          ),
                                          playerController: _playerController,
                                          enableSeekGesture: false,
                                          animationCurve: Curves.bounceIn,
                                          waveformType: WaveformType.long,
                                          continuousWaveform: true,
                                          playerWaveStyle: PlayerWaveStyle(
                                            fixedWaveColor: Colors.black,
                                            liveWaveColor: colorEmployeeGreen1,
                                            spacing: 6,
                                            liveWaveGradient:
                                                ui.Gradient.linear(
                                                  const Offset(70, 50),
                                                  Offset(size.width / 2, 0),
                                                  [
                                                    Colors.green,
                                                    Colors.white70,
                                                  ],
                                                ),
                                            fixedWaveGradient:
                                                ui.Gradient.linear(
                                                  const Offset(70, 50),
                                                  Offset(size.width / 2, 0),
                                                  [
                                                    Colors.green,
                                                    Colors.white70,
                                                  ],
                                                ),
                                            seekLineColor: colorEmployeeGreen1,
                                            seekLineThickness: 2,
                                            showSeekLine: true,
                                            showBottom: true,
                                          ),
                                        ),
                                      )
                                    : Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: size.width * numD02,
                                        ),
                                        child: Text(
                                          '00:00',
                                          style: TextStyle(
                                            fontSize: size.width * numD03,
                                            fontFamily: 'AirbnbCereal',
                                          ),
                                        ),
                                      ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: size.width * numD025),
                const Divider(color: colorLightGrey, thickness: 1),
                SizedBox(height: size.width * numD022),

                // ── Location ────────────────────────────────────────────
                _labelFieldRow(
                  size: size,
                  label: 'LOCATION',
                  child: TextFormField(
                    controller: _locationCtrl,
                    readOnly: true,
                    style: TextStyle(
                      fontSize: size.width * numD028,
                      color: Colors.black,
                      fontFamily: 'AirbnbCereal',
                    ),
                    decoration: _filledDecoration(
                      size,
                      prefixIcon: const ImageIcon(
                        AssetImage('assets/icons/ic_location.png'),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: size.width * numD02),
                const Divider(color: colorLightGrey, thickness: 1),
                SizedBox(height: size.width * numD025),

                // ── Timestamp ───────────────────────────────────────────
                _labelFieldRow(
                  size: size,
                  label: 'TIMESTAMP',
                  child: TextFormField(
                    controller: _timestampCtrl,
                    readOnly: true,
                    style: TextStyle(
                      fontSize: size.width * numD028,
                      color: Colors.black,
                      fontFamily: 'AirbnbCereal',
                    ),
                    decoration: _filledDecoration(
                      size,
                      prefixIcon: const ImageIcon(
                        AssetImage('assets/icons/ic_clock.png'),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: size.width * numD02),
                const Divider(color: colorLightGrey, thickness: 1),
                SizedBox(height: size.width * numD02),

                // ── Task selector ───────────────────────────────────────
                GestureDetector(
                  onTap: () => _showTaskPicker(size),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: size.width * numD04,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: size.width * numD32,
                          child: Text(
                            'TASK',
                            style: TextStyle(
                              fontSize: size.width * numD035,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'AirbnbCereal',
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: size.width * numD04,
                              vertical: size.width * numD035,
                            ),
                            decoration: BoxDecoration(
                              color: colorLightGrey,
                              borderRadius: BorderRadius.circular(
                                size.width * numD08,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.assignment_outlined,
                                  size: size.width * numD04,
                                  color: Colors.black,
                                ),
                                SizedBox(width: size.width * numD02),
                                Expanded(
                                  child: Text(
                                    _selectedTask?.title ?? 'Select a task',
                                    style: TextStyle(
                                      fontSize: size.width * numD031,
                                      fontFamily: 'AirbnbCereal',
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Icon(
                                  _selectedTask != null
                                      ? Icons.check_circle
                                      : Icons.keyboard_arrow_down_rounded,
                                  size: size.width * numD045,
                                  color: _selectedTask != null
                                      ? colorEmployeeGreen1
                                      : Colors.grey.shade500,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: size.width * numD02),
                const Divider(color: colorLightGrey, thickness: 1),
                SizedBox(height: size.width * numD038),

                // ── Buttons ─────────────────────────────────────────────
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width * numD04,
                  ),
                  child: Row(
                    children: [
                      if (!widget.hideDraft) ...[
                        Expanded(
                          child: SizedBox(
                            height: size.width * numD15,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    size.width * numD03,
                                  ),
                                ),
                              ),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Draft successfully saved'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                final nav = Navigator.of(context);
                                Future.delayed(const Duration(seconds: 2), () {
                                  nav.pushAndRemoveUntil(
                                    MaterialPageRoute(
                                      builder: (_) => const DashboardScreen(),
                                    ),
                                    (r) => false,
                                  );
                                });
                              },
                              child: Text(
                                'Save Draft',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: size.width * numD035,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'AirbnbCereal',
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: size.width * numD04),
                      ],
                      Expanded(
                        child: SizedBox(
                          height: size.width * numD15,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorEmployeeGreen1,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  size.width * numD03,
                                ),
                              ),
                            ),
                            onPressed: _submit,
                            child: Text(
                              'Submit',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: size.width * numD035,
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
                SizedBox(height: size.width * numD04),

                // ── Legal text ──────────────────────────────────────────
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width * numD04,
                  ),
                  child: Text(
                    'Please ensure all submissions comply with your organisation\'s editorial policies, GDPR requirements, and legal guidelines. Content involving privacy breaches, explicit material, minors, or safeguarding concerns is strictly prohibited.',
                    textAlign: TextAlign.justify,
                    style: TextStyle(
                      fontSize: size.width * numD03,
                      color: Colors.black,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'AirbnbCereal',
                    ),
                  ),
                ),
                SizedBox(height: size.width * numD06),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  Widget _buildThumbnail(Size size) {
    final mList = widget.publishData?.mediaList ?? [];
    final mimeType = widget.publishData?.mimeType ?? '';

    if (mList.isNotEmpty &&
        mList.first.mimeType == 'image' &&
        mList.first.isLocalMedia) {
      return Image.file(
        File(mList.first.mediaPath),
        width: size.width * numD30,
        height: size.width * numD35,
        fit: BoxFit.cover,
      );
    }
    if (mList.isNotEmpty && mList.first.mimeType == 'video') {
      final thumb = mList.first.thumbnail;
      if (thumb.isNotEmpty && File(thumb).existsSync()) {
        return Image.file(
          File(thumb),
          width: size.width * numD30,
          height: size.width * numD35,
          fit: BoxFit.cover,
        );
      }
    }
    if (mList.isNotEmpty && mList.first.mimeType == 'audio') {
      return Container(
        width: size.width * numD30,
        height: size.width * numD35,
        color: colorEmployeeGreen1,
        child: Icon(
          Icons.play_arrow_rounded,
          size: size.width * numD18,
          color: Colors.white,
        ),
      );
    }
    if (mimeType.contains('pdf')) {
      return Container(
        width: size.width * numD30,
        height: size.width * numD35,
        color: colorLightGrey,
        child: Icon(
          Icons.picture_as_pdf,
          size: size.width * numD18,
          color: Colors.red,
        ),
      );
    }
    if (mimeType.contains('doc')) {
      return Container(
        width: size.width * numD30,
        height: size.width * numD35,
        color: colorLightGrey,
        child: Icon(
          Icons.description,
          size: size.width * numD18,
          color: Colors.blue,
        ),
      );
    }
    return Container(
      width: size.width * numD30,
      height: size.width * numD35,
      color: colorLightGrey,
      child: Icon(Icons.image, size: size.width * numD18, color: Colors.grey),
    );
  }

  Widget _labelFieldRow({
    required Size size,
    required String label,
    required Widget child,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: size.width * numD04),
      child: Row(
        children: [
          SizedBox(
            width: size.width * numD32,
            child: Text(
              label,
              style: TextStyle(
                fontSize: size.width * numD035,
                fontWeight: FontWeight.bold,
                fontFamily: 'AirbnbCereal',
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }

  InputDecoration _filledDecoration(Size size, {Widget? prefixIcon}) {
    final borderRadius = BorderRadius.circular(size.width * numD08);
    const side = BorderSide(width: 0, style: BorderStyle.none);
    final border = OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: side,
    );
    return InputDecoration(
      filled: true,
      fillColor: colorLightGrey,
      prefixIcon: prefixIcon != null
          ? Padding(
              padding: EdgeInsets.only(
                left: size.width * numD04,
                right: size.width * numD02,
              ),
              child: prefixIcon,
            )
          : null,
      prefixIconConstraints: BoxConstraints(maxHeight: size.width * numD05),
      prefixIconColor: colorTextFieldIcon,
      contentPadding: EdgeInsets.only(left: size.width * numD06),
      disabledBorder: border,
      focusedBorder: border,
      enabledBorder: border,
      errorBorder: border,
      focusedErrorBorder: border,
    );
  }

  OutlineInputBorder _outlineBorder(Size size) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(size.width * numD04),
      borderSide: const BorderSide(width: 1, color: Color(0xFFE0E0E0)),
    );
  }
}
