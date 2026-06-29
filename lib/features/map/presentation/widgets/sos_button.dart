import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:presshop_enterprise/features/map/data/models/map_models.dart';
import 'package:presshop_enterprise/features/map/data/services/sos_service.dart';

class SosButton extends StatefulWidget {
  final double size;
  final double fontSize;
  final LatLng? Function() getPosition;
  final void Function(SosSession? session)? onSosStarted;
  final VoidCallback? onSosStopped;
  final bool triggerSosDirectly;

  const SosButton({
    super.key,
    required this.size,
    required this.fontSize,
    required this.getPosition,
    this.onSosStarted,
    this.onSosStopped,
    this.triggerSosDirectly = false,
  });

  @override
  State<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<SosButton> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final SosApiService _sosApi = SosApiService();

  bool _isActive = false;
  bool _isStopping = false;
  bool _isCountingDown = false;
  int _countdown = 5;
  Timer? _countdownTimer;
  SosSession? _activeSession;
  OverlayEntry? _overlayEntry;
  OverlayEntry? _countdownOverlayEntry;
  final ValueNotifier<int> _countdownNotifier = ValueNotifier(5);

  @override
  void initState() {
    super.initState();
    if (widget.triggerSosDirectly) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isActive) _startCountdown();
      });
    }
  }

  @override
  void didUpdateWidget(covariant SosButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.triggerSosDirectly && !oldWidget.triggerSosDirectly) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isActive) _startCountdown();
      });
    }
  }

  void _handleTap() {
    if (_isActive) {
      _stopSosFlow();
    } else if (_isCountingDown) {
      _cancelCountdown();
    } else {
      _startCountdown();
    }
  }

  void _startCountdown() {
    if (mounted)
      setState(() {
        _isCountingDown = true;
        _countdown = 5;
      });
    _countdownNotifier.value = 5;
    _countdownOverlayEntry = OverlayEntry(
      builder: (_) => _SosCountdownOverlay(
        countdownNotifier: _countdownNotifier,
        onCancel: _cancelCountdown,
      ),
    );
    Overlay.of(context).insert(_countdownOverlayEntry!);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdown <= 1) {
        timer.cancel();
        _countdownOverlayEntry?.remove();
        _countdownOverlayEntry = null;
        if (mounted) setState(() => _isCountingDown = false);
        _startSosFlow();
      } else {
        setState(() => _countdown--);
        _countdownNotifier.value = _countdown;
      }
    });
  }

  void _cancelCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _countdownOverlayEntry?.remove();
    _countdownOverlayEntry = null;
    if (mounted) {
      setState(() {
        _isCountingDown = false;
        _countdown = 5;
      });
    }
    widget.onSosStopped?.call();
  }

  void _startSosFlow() {
    _overlayEntry = OverlayEntry(
      builder: (_) => _SosMapOverlay(onStop: _stopSosFlow),
    );
    Overlay.of(context).insert(_overlayEntry!);
    _activateSos();
  }

  Future<void> _stopSosFlow() async {
    if (_isStopping) return;
    if (mounted) setState(() => _isStopping = true);

    if (_activeSession != null) {
      await _sosApi.stopSos(sessionId: _activeSession!.sessionId);
      _activeSession = null;
    }

    _overlayEntry?.remove();
    _overlayEntry = null;
    await _audioPlayer.stop();

    if (mounted) {
      setState(() {
        _isActive = false;
        _isStopping = false;
      });
    }
    widget.onSosStopped?.call();
  }

  Future<void> _activateSos() async {
    if (!mounted) return;
    setState(() => _isActive = true);

    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('audio/sos.mp3'));
    } catch (_) {}

    final pos = widget.getPosition();
    if (pos != null) {
      final session = await _sosApi.startSos(
        type: 'under_attack',
        lat: pos.latitude,
        lng: pos.longitude,
      );
      _activeSession = session;
      widget.onSosStarted?.call(session);
    } else {
      widget.onSosStarted?.call(null);
    }
  }

  void stopSos() => _stopSosFlow();

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _countdownOverlayEntry?.remove();
    _countdownOverlayEntry = null;
    _countdownNotifier.dispose();
    _overlayEntry?.remove();
    _overlayEntry = null;
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Container(
        width: widget.size,
        height: widget.size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _isActive ? const Color(0xFFB71C1C) : Colors.red,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _isActive
                  ? Colors.red.withValues(alpha: 0.6)
                  : Colors.black.withValues(alpha: 0.25),
              blurRadius: _isActive ? 20 : 8,
              spreadRadius: _isActive ? 3 : 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          'SOS',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: widget.fontSize,
            fontFamily: 'AirbnbCereal',
          ),
        ),
      ),
    );
  }
}

// ─── Countdown overlay ────────────────────────────────────────────────────────

class _SosCountdownOverlay extends StatefulWidget {
  final ValueListenable<int> countdownNotifier;
  final VoidCallback onCancel;

  const _SosCountdownOverlay({
    required this.countdownNotifier,
    required this.onCancel,
  });

  @override
  State<_SosCountdownOverlay> createState() => _SosCountdownOverlayState();
}

class _SosCountdownOverlayState extends State<_SosCountdownOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnim = TweenSequence<double>(
      [
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 35),
        TweenSequenceItem(tween: Tween(begin: 1.35, end: 0.92), weight: 35),
        TweenSequenceItem(tween: Tween(begin: 0.92, end: 1.0), weight: 30),
      ],
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeOut));
    widget.countdownNotifier.addListener(_onTick);
    _pulseController.forward(from: 0.0);
  }

  void _onTick() {
    if (mounted) _pulseController.forward(from: 0.0);
  }

  @override
  void dispose() {
    widget.countdownNotifier.removeListener(_onTick);
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Material(
      color: Colors.transparent,
      child: Container(
        color: Colors.black.withValues(alpha: 0.72),
        width: size.width,
        height: size.height,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: ValueListenableBuilder<int>(
                valueListenable: widget.countdownNotifier,
                builder: (context, count, _) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ScaleTransition(
                      scale: _scaleAnim,
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontFamily: 'AirbnbCereal',
                          fontSize: size.width * 0.50,
                          fontWeight: FontWeight.w900,
                          color: Colors.white.withValues(alpha: 0.88),
                          height: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: size.width * 0.08,
                      ),
                      child: Text(
                        'Your SOS alert will be sent in 5 seconds. Nearby team members and emergency contacts will be notified. Tap Cancel to stop this alert.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'AirbnbCereal',
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: size.width * 0.038,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: bottomPad + 40,
              child: GestureDetector(
                onTap: widget.onCancel,
                child: Container(
                  width: size.width * 0.65,
                  height: 58,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.50),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFD32F2F),
                      width: 1.5,
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontFamily: 'AirbnbCereal',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Active SOS overlay (strobe) ─────────────────────────────────────────────

class _SosMapOverlay extends StatefulWidget {
  final VoidCallback onStop;
  const _SosMapOverlay({required this.onStop});

  @override
  State<_SosMapOverlay> createState() => _SosMapOverlayState();
}

class _SosMapOverlayState extends State<_SosMapOverlay> {
  bool _isRedState = true;
  Timer? _strobeTimer;

  @override
  void initState() {
    super.initState();
    _strobeTimer = Timer.periodic(const Duration(milliseconds: 350), (_) {
      if (mounted) setState(() => _isRedState = !_isRedState);
    });
  }

  @override
  void dispose() {
    _strobeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    final bgColor = _isRedState
        ? const Color(0xFFD32F2F)
        : const Color.fromARGB(255, 255, 182, 182);
    final sosColor = _isRedState ? Colors.white : const Color(0xFFD32F2F);
    final alertColor = _isRedState
        ? Colors.white.withValues(alpha: 0.8)
        : const Color(0xFFB71C1C);
    final btnBg = _isRedState
        ? const Color(0xFF8B0000).withValues(alpha: 0.9)
        : const Color(0xFF1E1E1E).withValues(alpha: 0.9);
    final btnText = _isRedState ? Colors.white : const Color(0xFFD32F2F);

    return Material(
      color: Colors.transparent,
      child: Container(
        color: bgColor,
        width: size.width,
        height: size.height,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'SOS',
                    style: TextStyle(
                      fontFamily: 'AirbnbCereal',
                      fontSize: size.width * 0.28,
                      fontWeight: FontWeight.w900,
                      color: sosColor,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ALERT ACTIVE',
                    style: TextStyle(
                      fontFamily: 'AirbnbCereal',
                      fontSize: size.width * 0.045,
                      fontWeight: FontWeight.w800,
                      color: alertColor,
                      letterSpacing: 4,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: bottomPad + 40,
              child: GestureDetector(
                onTap: widget.onStop,
                child: Container(
                  width: size.width * 0.65,
                  height: 58,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: btnBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFD32F2F),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontFamily: 'AirbnbCereal',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: btnText,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
