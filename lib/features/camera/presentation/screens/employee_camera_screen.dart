import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:camera/camera.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:video_thumbnail/video_thumbnail.dart' as vt;
import 'package:file_picker/file_picker.dart';

import '../../../../main.dart';
import '../../data/models/camera_data.dart';
import '../../utils/camera_constants.dart';
import '../../utils/app_private_gallery_service.dart';
import 'custom_gallery_screen.dart';
import 'employee_preview_screen.dart';
import 'permission_error_screen.dart';

class EmployeeCameraScreen extends StatefulWidget {
  final bool picAgain;
  final bool autoInitialize;
  final bool isScreenActive;
  final String? initialType;
  final bool hideAppBar;

  const EmployeeCameraScreen({
    super.key,
    this.picAgain = false,
    this.autoInitialize = true,
    this.isScreenActive = true,
    this.initialType,
    this.hideAppBar = false,
  });

  @override
  State<EmployeeCameraScreen> createState() => _EmployeeCameraScreenState();
}

class _EmployeeCameraScreenState extends State<EmployeeCameraScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  CameraController? cameraController;
  final AudioRecorder _audioRecorder = AudioRecorder();
  RecorderController recorderController = RecorderController();

  double x = 0, y = 0;
  String selectedType = photoText, recordingTime = '';
  bool frontCamera = false,
      flashOn = false,
      showFocusCircle = false,
      _isRecordingInProgress = false,
      isAudioRecording = false;

  DateTime? startTime;
  Timer? myTimer;
  Future<void>? cameraValue;
  List<File> _mediaList = [];
  List<CameraData> camListData = [];
  int _pointers = 0;
  late double _minAvailableZoom;
  late double _maxAvailableZoom;
  double _currentScale = 1.0;
  double _baseScale = 1.0;
  double _minAvailableExposureOffset = 0.0;
  double _maxAvailableExposureOffset = 0.0;
  double _currentExposureOffset = 0.0;
  bool pageReplaced = false;
  bool _isInitializingCamera = false;
  Timer? _initTimer;

  late AnimationController _exposureAnimController;
  late Animation<double> _exposureAnim;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    pageReplaced = false;
    _initialiseControllers();
    if (widget.autoInitialize && cameras.isNotEmpty) {
      _safeInitCamera(cameras[0]);
    }
    selectedType = widget.initialType ?? photoText;
    _loadRecentGalleryItem();
  }

  @override
  void dispose() {
    pageReplaced = true;
    _initTimer?.cancel();
    myTimer?.cancel();
    if (cameraController != null && cameraController!.value.isInitialized) {
      cameraController!.dispose();
      cameraController = null;
    }
    _exposureAnimController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _safeInitCamera(CameraDescription desc) async {
    if (_isInitializingCamera) return;
    _isInitializingCamera = true;
    _initTimer?.cancel();
    final delay = Platform.isIOS ? 1200 : 300;
    _initTimer = Timer(Duration(milliseconds: delay), () async {
      if (mounted && widget.isScreenActive) {
        try {
          await initCamera(desc);
        } finally {
          _isInitializingCamera = false;
        }
      } else {
        _isInitializingCamera = false;
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (pageReplaced) return;
    if (state == AppLifecycleState.paused) {
      if (cameraController != null && cameraController!.value.isInitialized) {
        cameraController!.dispose();
        cameraController = null;
        if (mounted) setState(() {});
      }
    } else if (state == AppLifecycleState.resumed) {
      if (mounted && cameras.isNotEmpty) {
        _safeInitCamera(
          frontCamera && cameras.length > 1 ? cameras[1] : cameras[0],
        );
      }
    }
  }

  Future<void> initCamera(CameraDescription desc) async {
    if (cameraController != null) {
      final old = cameraController;
      cameraController = null;
      if (mounted) setState(() {});
      await old!.dispose();
    }
    if (Platform.isIOS) {
      await Future.delayed(const Duration(milliseconds: 200));
    }
    cameraController = CameraController(
      desc,
      ResolutionPreset.high,
      imageFormatGroup: Platform.isIOS
          ? ImageFormatGroup.bgra8888
          : ImageFormatGroup.jpeg,
    );
    cameraValue = cameraController!
        .initialize()
        .then((_) async {
          if (!mounted ||
              cameraController == null ||
              !cameraController!.value.isInitialized ||
              WidgetsBinding.instance.lifecycleState !=
                  AppLifecycleState.resumed) {
            return;
          }
          final ctrl = cameraController;
          try {
            _minAvailableExposureOffset = await ctrl!.getMinExposureOffset();
            _maxAvailableExposureOffset = await ctrl.getMaxExposureOffset();
            _maxAvailableZoom = await ctrl.getMaxZoomLevel();
            _minAvailableZoom = await ctrl.getMinZoomLevel();
          } catch (e) {
            if (cameraController != null && cameraController == ctrl) {
              await cameraController!.dispose();
              cameraController = null;
            }
            return;
          }
          if (mounted && cameraController == ctrl) setState(() {});
        })
        .catchError((Object e) {
          if (e is CameraException && e.code == 'CameraAccessDenied') {
            pageReplaced = true;
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => CameraPermissionErrorScreen(
                    permissionsStatus: {
                      Permission.camera: false,
                      Permission.microphone: false,
                    },
                  ),
                ),
              );
            }
          }
        });
  }

  Future<void> _loadRecentGalleryItem() async {
    final files = await AppPrivateGalleryService.instance.getGalleryFiles();
    if (files.isNotEmpty && mounted) {
      setState(() => _mediaList = [files.first]);
    }
  }

  void _initialiseControllers() {
    recorderController = RecorderController()
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.mpeg4
      ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
      ..sampleRate = 44100
      ..bitRate = 48000;
    _exposureAnimController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _exposureAnim = CurvedAnimation(
      parent: _exposureAnimController,
      curve: Curves.easeInCubic,
    );
  }

  // ── Camera actions ────────────────────────────────────────────────────────

  Future<void> takePicture() async {
    if (cameraController == null ||
        !cameraController!.value.isInitialized ||
        cameraController!.value.isTakingPicture) {
      return;
    }
    try {
      await cameraController!.setFlashMode(FlashMode.off);
      final picture = await cameraController!.takePicture();
      cameraController!.pausePreview();
      File finalFile = File(picture.path);
      try {
        finalFile = await AppPrivateGalleryService.instance.saveToGallery(finalFile);
        setState(() {
          _mediaList = [finalFile];
        });
      } catch (e) {
        debugPrint('App gallery save failed: $e');
      }
      camListData.add(
        CameraData(
          path: finalFile.path,
          mimeType: 'image',
          videoImagePath: '',
          latitude: sharedPreferences?.getDouble(currentLat)?.toString() ?? '0',
          longitude:
              sharedPreferences?.getDouble(currentLon)?.toString() ?? '0',
          dateTime: DateFormat('HH:mm, dd MMM yyyy').format(DateTime.now()),
          location: sharedPreferences?.getString(currentAddress) ?? '',
          country: sharedPreferences?.getString(currentCountry) ?? '',
          city: sharedPreferences?.getString(currentCity) ?? '',
          state: sharedPreferences?.getString(currentState) ?? '',
        ),
      );
      if (!mounted) return;
      if (widget.picAgain) {
        Navigator.pop(context, camListData);
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EmployeePreviewScreen(
              cameraData: null,
              pickAgain: widget.picAgain,
              type: 'camera',
              cameraListData: camListData,
              mediaList: const [],
            ),
          ),
        ).then((_) {
          if (cameraController != null) cameraController!.resumePreview();
        });
      }
    } catch (e) {
      debugPrint('Error taking picture: $e');
    }
  }

  Future<void> startVideoRecording() async {
    if (cameraController!.value.isRecordingVideo) return;
    try {
      await cameraController!.startVideoRecording();
      _recordTime();
      if (mounted) setState(() => _isRecordingInProgress = true);
    } catch (e) {
      debugPrint('Error starting video: $e');
    }
  }

  Future<void> stopVideoRecording() async {
    if (!cameraController!.value.isRecordingVideo) return;
    myTimer?.cancel();
    try {
      final file = await cameraController!.stopVideoRecording();
      final dir = await getTemporaryDirectory();
      final newPath =
          '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.mp4';
      final renamed = await File(file.path).rename(newPath);
      final savedPath = await _saveVideoToGallery(renamed.path);
      if (cameraController != null) cameraController!.pausePreview();
      await _generateThumbnail(savedPath);
    } catch (e) {
      debugPrint('Error stopping video: $e');
    }
  }

  Future<String> _saveVideoToGallery(String path) async {
    try {
      final savedFile = await AppPrivateGalleryService.instance.saveToGallery(File(path));
      setState(() {
        _mediaList = [savedFile];
      });
      return savedFile.path;
    } catch (e) {
      debugPrint('App gallery video save failed: $e');
      return path;
    }
  }

  Future<void> _generateThumbnail(String videoPath) async {
    String? thumbnail;
    try {
      thumbnail = await vt.VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: (await getTemporaryDirectory()).path,
        imageFormat: vt.ImageFormat.PNG,
        maxWidth: 128,
        quality: 25,
      ).timeout(const Duration(seconds: 2), onTimeout: () => null);
    } catch (_) {}

    camListData.add(
      CameraData(
        path: videoPath,
        videoImagePath: thumbnail ?? '',
        mimeType: 'video',
        latitude: sharedPreferences?.getDouble(currentLat)?.toString() ?? '0',
        longitude: sharedPreferences?.getDouble(currentLon)?.toString() ?? '0',
        dateTime: DateFormat('HH:mm, dd MMM yyyy').format(DateTime.now()),
        location: sharedPreferences?.getString(currentAddress) ?? '',
        country: sharedPreferences?.getString(currentCountry) ?? '',
        city: sharedPreferences?.getString(currentCity) ?? '',
        state: sharedPreferences?.getString(currentState) ?? '',
      ),
    );

    if (!mounted) return;
    if (widget.picAgain) {
      Navigator.pop(navigatorKey.currentContext!, camListData);
    } else {
      Navigator.push(
        navigatorKey.currentContext!,
        MaterialPageRoute(
          builder: (_) => EmployeePreviewScreen(
            cameraData: null,
            pickAgain: widget.picAgain,
            type: 'camera',
            cameraListData: camListData,
            mediaList: const [],
          ),
        ),
      ).then((_) {
        if (cameraController != null) cameraController!.resumePreview();
        recordingTime = '';
        if (mounted) setState(() {});
      });
    }
  }

  void _recordTime() {
    startTime = DateTime.now();
    myTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (startTime != null && mounted) {
        final d = DateTime.now().difference(startTime!);
        String two(int n) => n.toString().padLeft(2, '0');
        recordingTime =
            '${two(d.inHours)}:${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}';
        setState(() {});
      }
    });
  }

  Future<void> startAudioRecording() async {
    // The `record` plugin's own check matches what gates recording;
    // permission_handler can report denied on iOS even when granted.
    final status = await _audioRecorder.hasPermission()
        ? PermissionStatus.granted
        : PermissionStatus.denied;
    if (status.isGranted) {
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _audioRecorder.start(const RecordConfig(), path: path);
      _recordTime();
      await recorderController.record();
      if (mounted) setState(() => isAudioRecording = true);
    } else if (status.isDenied || status.isPermanentlyDenied) {
      if (!mounted) return;
      pageReplaced = true;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CameraPermissionErrorScreen(
            permissionsStatus: {Permission.microphone: false},
          ),
        ),
      );
    }
  }

  Future<void> pauseAudioRecording() async {
    await _audioRecorder.pause();
    await recorderController.pause();
    myTimer?.cancel();
  }

  Future<void> stopAudioRecording(bool save) async {
    final path = await _audioRecorder.stop();
    myTimer?.cancel();
    await recorderController.stop();
    if (save && path != null) {
      camListData.add(
        CameraData(
          path: path,
          mimeType: 'audio',
          videoImagePath: '',
          latitude: sharedPreferences?.getDouble(currentLat)?.toString() ?? '0',
          longitude:
              sharedPreferences?.getDouble(currentLon)?.toString() ?? '0',
          dateTime: DateFormat('HH:mm, dd MMM yyyy').format(DateTime.now()),
          location: sharedPreferences?.getString(currentAddress) ?? '',
          country: sharedPreferences?.getString(currentCountry) ?? '',
          city: sharedPreferences?.getString(currentCity) ?? '',
          state: sharedPreferences?.getString(currentState) ?? '',
        ),
      );
      if (!mounted) return;
      if (widget.picAgain) {
        Navigator.pop(context, camListData);
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EmployeePreviewScreen(
              cameraData: null,
              pickAgain: widget.picAgain,
              type: 'camera',
              cameraListData: camListData,
              mediaList: const [],
            ),
          ),
        );
      }
    }
    recordingTime = '';
    isAudioRecording = false;
    if (mounted) setState(() {});
  }

  void openImageScanner() async {
    try {
      final images = await CunningDocumentScanner.getPictures();
      if (images != null && images.isNotEmpty) {
        for (final p in images) {
          camListData.add(
            CameraData(
              path: p,
              mimeType: 'image',
              videoImagePath: '',
              latitude:
                  sharedPreferences?.getDouble(currentLat)?.toString() ?? '0',
              longitude:
                  sharedPreferences?.getDouble(currentLon)?.toString() ?? '0',
              dateTime: DateFormat('HH:mm, dd MMM yyyy').format(DateTime.now()),
              location: sharedPreferences?.getString(currentAddress) ?? '',
              country: sharedPreferences?.getString(currentCountry) ?? '',
              city: sharedPreferences?.getString(currentCity) ?? '',
              state: sharedPreferences?.getString(currentState) ?? '',
            ),
          );
        }
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EmployeePreviewScreen(
              cameraData: null,
              pickAgain: widget.picAgain,
              type: 'camera',
              cameraListData: camListData,
              mediaList: const [],
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Scanner error: $e');
    } finally {
      cameraController?.resumePreview();
    }
  }

  void pickFiles() async {
    try {
      if (cameraController != null) cameraController!.pausePreview();
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );
      if (result != null && result.files.isNotEmpty) {
        for (final f in result.files) {
          final filePath = f.path;
          if (filePath == null || filePath.isEmpty) continue;
          final mimeStr = lookupMimeType(filePath) ?? '';
          String mimeType = 'image';
          if (mimeStr.startsWith('video/')) {
            mimeType = 'video';
          } else if (mimeStr.startsWith('audio/')) {
            mimeType = 'audio';
          } else if (mimeStr.contains('pdf')) {
            mimeType = 'pdf';
          } else if (mimeStr.contains('word') ||
              mimeStr.contains('msword') ||
              filePath.endsWith('.doc') ||
              filePath.endsWith('.docx')) {
            mimeType = 'doc';
          }
          camListData.add(
            CameraData(
              path: filePath,
              mimeType: mimeType,
              videoImagePath: '',
              fromGallary: true,
              latitude:
                  sharedPreferences?.getDouble(currentLat)?.toString() ?? '0',
              longitude:
                  sharedPreferences?.getDouble(currentLon)?.toString() ?? '0',
              dateTime: DateFormat('HH:mm, dd MMM yyyy').format(DateTime.now()),
              location: sharedPreferences?.getString(currentAddress) ?? '',
              country: sharedPreferences?.getString(currentCountry) ?? '',
              city: sharedPreferences?.getString(currentCity) ?? '',
              state: sharedPreferences?.getString(currentState) ?? '',
            ),
          );
        }
        if (camListData.isNotEmpty && mounted) {
          if (widget.picAgain) {
            Navigator.pop(context, camListData);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EmployeePreviewScreen(
                  cameraData: null,
                  pickAgain: widget.picAgain,
                  type: 'camera',
                  cameraListData: camListData,
                  mediaList: const [],
                ),
              ),
            ).then((_) => cameraController?.resumePreview());
          }
        }
      }
    } catch (e) {
      debugPrint('Error picking files: $e');
    } finally {
      cameraController?.resumePreview();
    }
  }

  // ── Exposure & Focus ──────────────────────────────────────────────────────

  void onViewFinderTap(TapDownDetails details, BoxConstraints constraints) {
    cameraController?.setExposurePoint(
      Offset(
        details.localPosition.dx / constraints.maxWidth,
        details.localPosition.dy / constraints.maxHeight,
      ),
    );
  }

  Future<void> _onTap(TapUpDetails details) async {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return;
    }
    showFocusCircle = true;
    x = details.localPosition.dx;
    y = details.localPosition.dy;
    final w = MediaQuery.of(context).size.width;
    final h = w * cameraController!.value.aspectRatio;
    await cameraController!.setFocusPoint(Offset(x / w, y / h));
    await cameraController!.setExposurePoint(Offset(x / w, y / h));
    if (mounted) setState(() => showFocusCircle = false);
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _baseScale = _currentScale;
  }

  Future<void> _handleScaleUpdate(ScaleUpdateDetails details) async {
    if (_pointers != 2) return;
    _currentScale = (_baseScale * details.scale).clamp(
      _minAvailableZoom,
      _maxAvailableZoom,
    );
    await cameraController!.setZoomLevel(_currentScale);
  }

  void _onExposureButtonPressed() {
    if (_exposureAnimController.value == 1) {
      _exposureAnimController.reverse();
    } else {
      _exposureAnimController.forward();
    }
  }

  Future<void> _setExposureOffset(double offset) async {
    if (cameraController == null) return;
    setState(() => _currentExposureOffset = offset);
    try {
      await cameraController!.setExposureOffset(offset);
    } catch (_) {}
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final responsiveWidth = size.width > 600 ? 500.0 : size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // ── Mode selector ──────────────────────────────────────────────
                Center(
                  child: SizedBox(
                    width: responsiveWidth,
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: responsiveWidth * numD05,
                        right: responsiveWidth * numD05,
                        top: 50,
                        bottom: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // _modeTab(
                          //   scanText,
                          //   onTap: () {
                          //     recordingTime = '';
                          //     myTimer?.cancel();
                          //     selectedType = scanText;
                          //     cameraController?.pausePreview();
                          //     openImageScanner();
                          //     setState(() {});
                          //   },
                          // ),
                          _modeTab(
                            photoText,
                            onTap: () {
                              recordingTime = '';
                              myTimer?.cancel();
                              selectedType = photoText;
                              frontCamera = false;
                              if (cameras.isNotEmpty) initCamera(cameras[0]);
                              setState(() {});
                            },
                          ),
                          _modeTab(
                            videoText,
                            onTap: () {
                              recordingTime = '';
                              myTimer?.cancel();
                              selectedType = videoText;
                              frontCamera = false;
                              if (cameras.isNotEmpty) initCamera(cameras[0]);
                              setState(() {});
                            },
                          ),
                          _modeTab(
                            audioText,
                            onTap: () {
                              recordingTime = '';
                              myTimer?.cancel();
                              selectedType = audioText;
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // ── Main view ─────────────────────────────────────────────────
                Expanded(
                  child: selectedType == audioText
                      ? _buildAudioView(size)
                      : _buildCameraView(size),
                ),
              ],
            ),
            // ── Floating back button ──────────────────────────────────────
            Positioned(
              top: 0,
              left: responsiveWidth * numD01,
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Image.asset(
                  'assets/icons/ic_arrow_left.png',
                  width: responsiveWidth * 0.06,
                  height: responsiveWidth * 0.06,
                  color: Colors.white,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.arrow_back_ios_new,
                      size: responsiveWidth * 0.05,
                      color: Colors.white,
                    );
                  },
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeTab(String label, {required VoidCallback onTap}) {
    final size = MediaQuery.of(context).size;
    final isSelected = selectedType == label;
    return InkWell(
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? colorEmployeeGreen1 : Colors.white,
          fontSize: size.width * numD035,
          fontWeight: FontWeight.w500,
          fontFamily: 'AirbnbCereal',
        ),
      ),
    );
  }

  Widget _buildCameraView(Size size) {
    return Stack(
      children: [
        // ── Viewfinder ───────────────────────────────────────────────────
        widget.isScreenActive &&
                cameraController != null &&
                cameraController!.value.isInitialized &&
                mounted
            ? Listener(
                onPointerDown: (_) => _pointers++,
                onPointerUp: (_) => _pointers--,
                child: LayoutBuilder(
                  builder: (_, constraints) => Center(
                    child: GestureDetector(
                      onScaleStart: _handleScaleStart,
                      onScaleUpdate: _handleScaleUpdate,
                      onTapDown: (d) => onViewFinderTap(d, constraints),
                      onTapUp: _onTap,
                      child: SizedBox(
                        height: constraints.maxHeight,
                        width: size.width,
                        child: AspectRatio(
                          aspectRatio: cameraController!.value.aspectRatio,
                          child: CameraPreview(cameraController!),
                        ),
                      ),
                    ),
                  ),
                ),
              )
            : Container(color: Colors.black),

        // ── Exposure slider ───────────────────────────────────────────────
        Positioned(
          left: 0,
          right: 0,
          bottom: size.width * numD25,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: _exposureSlider(size),
          ),
        ),

        // ── Top controls ─────────────────────────────────────────────────
        if (selectedType == photoText || selectedType == videoText)
          Positioned(
            top: size.width * numD06,
            left: size.width * numD1,
            right: size.width * numD1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Flash
                if (!frontCamera)
                  _circleIconBtn(
                    icon: flashOn ? Icons.flash_on : Icons.flash_off,
                    onTap: () {
                      cameraController!.setFlashMode(
                        flashOn ? FlashMode.off : FlashMode.torch,
                      );
                      flashOn = !flashOn;
                      setState(() {});
                    },
                  ),
                // Exposure + recording timer
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _circleImgBtn(
                      icon: Icons.exposure,
                      onTap: cameraController != null
                          ? _onExposureButtonPressed
                          : null,
                    ),
                    _exposureLabelAnim(size),
                    SizedBox(height: size.width * numD01),
                    if (selectedType == videoText)
                      Text(
                        recordingTime,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: size.width * numD035,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'AirbnbCereal',
                        ),
                      ),
                  ],
                ),
                // Flip camera
                _circleImgBtn(
                  icon: Icons.flip_camera_ios_outlined,
                  onTap: () {
                    if (cameras.length > 1) {
                      frontCamera = !frontCamera;
                      initCamera(frontCamera ? cameras[1] : cameras[0]);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Front camera not available'),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),

        // ── Bottom: file picker (plus) ────────────────────────────────────
        Align(
          alignment: Alignment.bottomLeft,
          child: InkWell(
            onTap: pickFiles,
            child: Container(
              margin: EdgeInsets.only(
                left: size.width * numD1,
                bottom: size.width * numD05,
              ),
              padding: EdgeInsets.all(size.width * numD02),
              decoration: BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white),
              ),
              child: Container(
                padding: EdgeInsets.all(size.width * numD02),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add,
                  color: Colors.white,
                  size: size.width * numD07,
                ),
              ),
            ),
          ),
        ),

        // ── Bottom: shutter ───────────────────────────────────────────────
        Align(
          alignment: Alignment.bottomCenter,
          child: InkWell(
            onTap: () {
              if (selectedType == videoText) {
                if (_isRecordingInProgress) {
                  stopVideoRecording();
                } else {
                  startVideoRecording();
                }
              } else {
                Future.delayed(const Duration(milliseconds: 500), takePicture);
              }
            },
            child: Container(
              margin: EdgeInsets.only(bottom: size.width * numD05),
              padding: EdgeInsets.all(size.width * numD01),
              decoration: BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: colorEmployeeGreen1),
              ),
              child: Icon(
                selectedType == videoText && _isRecordingInProgress
                    ? Icons.stop_circle_outlined
                    : Icons.circle,
                color: colorEmployeeGreen1,
                size: size.width * numD13,
              ),
            ),
          ),
        ),

        // ── Bottom: gallery thumbnail ─────────────────────────────────────
        if (selectedType == photoText || selectedType == videoText)
          Align(
            alignment: Alignment.bottomRight,
            child: InkWell(
              onTap: () {
                if (cameraController != null) {
                  cameraController!.dispose();
                  cameraController = null;
                  if (mounted) setState(() {});
                }
                Navigator.of(context)
                    .push(
                      MaterialPageRoute(
                        builder: (_) =>
                            CustomGalleryScreen(picAgain: widget.picAgain),
                      ),
                    )
                    .then((value) {
                      if (mounted && cameras.isNotEmpty) {
                        _safeInitCamera(
                          frontCamera && cameras.length > 1
                              ? cameras[1]
                              : cameras[0],
                        );
                      }
                      if (value != null && mounted) {
                        camListData = value as List<CameraData>;
                        if (Navigator.of(context).canPop()) {
                          Navigator.pop(context, camListData);
                        }
                      }
                    });
              },
              child: Container(
                width: size.width * numD15,
                height: size.width * numD15,
                margin: EdgeInsets.only(
                  bottom: size.width * numD05,
                  right: size.width * numD1,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(size.width * numD025),
                  child: _mediaList.isNotEmpty
                      ? (() {
                          final file = _mediaList.first;
                          final isVideo = file.path.toLowerCase().endsWith('.mp4') ||
                              file.path.toLowerCase().endsWith('.mov') ||
                              file.path.toLowerCase().endsWith('.3gp') ||
                              file.path.toLowerCase().endsWith('.avi');
                          if (isVideo) {
                            return FutureBuilder<String?>(
                              future: AppPrivateGalleryService.instance.getOrGenerateThumbnail(file),
                              builder: (_, snap) {
                                if (snap.hasData && snap.data != null) {
                                  return Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.file(File(snap.data!), fit: BoxFit.cover),
                                      const Align(
                                        alignment: Alignment.bottomRight,
                                        child: Padding(
                                          padding: EdgeInsets.all(4),
                                          child: Icon(
                                            Icons.videocam,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }
                                return Container(color: Colors.grey[800]);
                              },
                            );
                          } else {
                            return Image.file(file, fit: BoxFit.cover);
                          }
                        })()
                      : Container(
                          color: Colors.grey[800],
                          child: const Icon(
                            Icons.photo_library_outlined,
                            color: Colors.white54,
                          ),
                        ),
                ),
              ),
            ),
          ),

        // ── Focus circle ──────────────────────────────────────────────────
        if (showFocusCircle)
          Positioned(
            top: y - 20,
            left: x - 20,
            child: Container(
              width: size.width * numD15,
              height: size.width * numD15,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAudioView(Size size) {
    return Column(
      children: [
        const Spacer(),
        if (widget.isScreenActive && isAudioRecording)
          AudioWaveforms(
            size: Size(size.width, 100),
            recorderController: recorderController,
            enableGesture: false,
            backgroundColor: Colors.transparent,
            shouldCalculateScrolledPosition: true,
            waveStyle: WaveStyle(
              waveColor: colorEmployeeGreen1,
              extendWaveform: true,
              showMiddleLine: false,
              showDurationLabel: false,
              gradient: ui.Gradient.linear(
                const Offset(70, 50),
                Offset(size.width / 2, 0),
                [Colors.red, Colors.green],
              ),
            ),
          ),
        Text(
          recordingTime.isEmpty ? '00:00:00' : recordingTime,
          style: TextStyle(
            fontSize: size.width * numD15,
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontFamily: 'AirbnbCereal',
          ),
        ),
        const Spacer(),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: size.width * numD08,
            vertical: size.width * numD04,
          ),
          child: Row(
            children: [
              if (recordingTime.isNotEmpty)
                IconButton(
                  onPressed: () => stopAudioRecording(false),
                  icon: Icon(
                    Icons.close,
                    color: Colors.red,
                    size: size.width * numD08,
                  ),
                ),
              const Spacer(),
              InkWell(
                onTap: () {
                  if (isAudioRecording) {
                    pauseAudioRecording();
                  } else {
                    startAudioRecording();
                  }
                  isAudioRecording = !isAudioRecording;
                  setState(() {});
                },
                child: Container(
                  padding: EdgeInsets.all(size.width * numD01),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(color: colorEmployeeGreen1),
                  ),
                  child: Icon(
                    isAudioRecording
                        ? Icons.stop_circle_outlined
                        : Icons.circle,
                    color: colorEmployeeGreen1,
                    size: size.width * numD13,
                  ),
                ),
              ),
              const Spacer(),
              if (recordingTime.isNotEmpty)
                IconButton(
                  onPressed: () => stopAudioRecording(true),
                  icon: Icon(
                    Icons.check,
                    color: colorOnlineGreen,
                    size: size.width * numD08,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Small helpers ─────────────────────────────────────────────────────────

  Widget _circleIconBtn({required IconData icon, required VoidCallback onTap}) {
    final size = MediaQuery.of(context).size;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(size.width * numD01),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.black, size: size.width * numD04),
      ),
    );
  }

  Widget _circleImgBtn({required IconData icon, VoidCallback? onTap}) {
    final size = MediaQuery.of(context).size;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(size.width * numD01),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.black, size: size.width * numD042),
      ),
    );
  }

  Widget _exposureSlider(Size size) {
    return SizeTransition(
      sizeFactor: _exposureAnim,
      child: ClipRect(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(
              _minAvailableExposureOffset.toString(),
              style: TextStyle(
                color: Colors.white,
                fontSize: size.width * numD03,
              ),
            ),
            SliderTheme(
              data: SliderThemeData(trackHeight: size.width * numD009),
              child: Slider(
                value: _currentExposureOffset,
                min: _minAvailableExposureOffset,
                max: _maxAvailableExposureOffset,
                activeColor: colorEmployeeGreen1,
                onChanged:
                    _minAvailableExposureOffset == _maxAvailableExposureOffset
                    ? null
                    : _setExposureOffset,
              ),
            ),
            Text(
              _maxAvailableExposureOffset.toString(),
              style: TextStyle(
                color: Colors.white,
                fontSize: size.width * numD03,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _exposureLabelAnim(Size size) {
    return SizeTransition(
      sizeFactor: _exposureAnim,
      child: ClipRect(
        child: TextButton(
          onPressed: cameraController != null
              ? () async {
                  try {
                    await cameraController!.setExposureMode(ExposureMode.auto);
                  } catch (_) {}
                }
              : null,
          child: Text(
            selectedType == scanText
                ? 'This scan is automatically enhanced'
                : selectedType == videoText
                ? 'This video is automatically enhanced'
                : 'This pic is automatically enhanced',
            style: TextStyle(
              color: colorEmployeeGreen1,
              fontSize: size.width * numD03,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
