import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../data/models/camera_data.dart';
class VideoWidget extends StatefulWidget {
  final MediaData mediaData;
  const VideoWidget({super.key, required this.mediaData});

  @override
  State<VideoWidget> createState() => _VideoWidgetState();
}

class _VideoWidgetState extends State<VideoWidget> {
  VideoPlayerController? _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  Future<void> _initController() async {
    final path = widget.mediaData.mediaPath;
    VideoPlayerController ctrl;
    if (widget.mediaData.isLocalMedia || !path.startsWith('http')) {
      ctrl = VideoPlayerController.file(File(path));
    } else {
      ctrl = VideoPlayerController.networkUrl(Uri.parse(path));
    }
    _controller = ctrl;
    await ctrl.initialize();
    ctrl.addListener(() {
      if (mounted) setState(() {});
    });
    if (mounted) setState(() => _initialized = true);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized || _controller == null) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    return Stack(
      alignment: Alignment.center,
      children: [
        AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: VideoPlayer(_controller!),
        ),
        GestureDetector(
          onTap: () {
            if (_controller!.value.isPlaying) {
              _controller!.pause();
            } else {
              _controller!.play();
            }
            setState(() {});
          },
          child: Container(
            color: Colors.transparent,
            child: !_controller!.value.isPlaying
                ? Container(
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(16),
                    child: const Icon(Icons.play_arrow,
                        color: Colors.white, size: 48),
                  )
                : null,
          ),
        ),
        Positioned(
          bottom: 8,
          left: 8,
          right: 8,
          child: VideoProgressIndicator(
            _controller!,
            allowScrubbing: true,
            colors: const VideoProgressColors(
              playedColor: Color(0xFF1877F2),
              bufferedColor: Colors.white38,
              backgroundColor: Colors.white12,
            ),
          ),
        ),
      ],
    );
  }
}
