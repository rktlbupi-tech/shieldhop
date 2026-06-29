import 'dart:io';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import '../../utils/camera_constants.dart';

class AudioWaveFormWidget extends StatefulWidget {
  final String mediaPath;
  const AudioWaveFormWidget({super.key, required this.mediaPath});

  @override
  State<AudioWaveFormWidget> createState() => _AudioWaveFormWidgetState();
}

class _AudioWaveFormWidgetState extends State<AudioWaveFormWidget> {
  final PlayerController _controller = PlayerController();
  bool _playing = false;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    try {
      final path = widget.mediaPath;
      if (path.isEmpty) return;
      if (!path.startsWith('http') && !File(path).existsSync()) return;
      await _controller.preparePlayer(
        path: path,
        shouldExtractWaveform: true,
        noOfSamples: 100,
        volume: 1.0,
      );
      _controller.onCompletion.listen((_) {
        if (mounted) setState(() => _playing = false);
      });
      if (mounted) setState(() => _ready = true);
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mic, color: Colors.white, size: 64),
            SizedBox(height: size.width * numD04),
            if (_ready)
              AudioFileWaveforms(
                size: Size(size.width * 0.8, 60),
                playerController: _controller,
                enableSeekGesture: true,
                waveformType: WaveformType.long,
                playerWaveStyle: const PlayerWaveStyle(
                  fixedWaveColor: Colors.white38,
                  liveWaveColor: colorEmployeeGreen1,
                  spacing: 6,
                  seekLineColor: colorEmployeeGreen1,
                  seekLineThickness: 2,
                  showSeekLine: true,
                ),
              ),
            SizedBox(height: size.width * numD04),
            GestureDetector(
              onTap: () async {
                if (_playing) {
                  await _controller.pausePlayer();
                } else {
                  await _controller.startPlayer();
                }
                if (mounted) setState(() => _playing = !_playing);
              },
              child: Container(
                padding: EdgeInsets.all(size.width * numD03),
                decoration: const BoxDecoration(
                  color: colorEmployeeGreen1,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _playing ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: size.width * numD08,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
