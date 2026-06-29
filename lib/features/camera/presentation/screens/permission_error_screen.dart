import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/constants/app_colors.dart';

class CameraPermissionErrorScreen extends StatefulWidget {
  final Map<Permission, bool> permissionsStatus;

  /// Called once every requested permission is granted. If null, the screen
  /// simply pops itself.
  final VoidCallback? onPermissionGranted;

  const CameraPermissionErrorScreen({
    super.key,
    required this.permissionsStatus,
    this.onPermissionGranted,
  });

  @override
  State<CameraPermissionErrorScreen> createState() =>
      _CameraPermissionErrorScreenState();
}

class _CameraPermissionErrorScreenState
    extends State<CameraPermissionErrorScreen> with WidgetsBindingObserver {
  late Map<Permission, bool> _status;

  @override
  void initState() {
    super.initState();
    _status = Map.of(widget.permissionsStatus);
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-check when returning from Settings — auto-recover like the old app.
    if (state == AppLifecycleState.resumed) _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final updated = <Permission, bool>{};
    for (final p in _status.keys) {
      updated[p] = await p.isGranted;
    }
    if (!mounted) return;
    setState(() => _status = updated);

    if (_status.values.every((g) => g)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (widget.onPermissionGranted != null) {
          widget.onPermissionGranted!();
        } else {
          Navigator.of(context).maybePop(true);
        }
      });
    }
  }

  Future<void> _requestPermissions() async {
    for (final p in _status.keys) {
      if (_status[p] == true) continue;
      final result = await p.request();
      if (result.isDenied || result.isPermanentlyDenied || result.isRestricted) {
        await openAppSettings();
      }
      break;
    }
    await _checkPermissions();
  }

  String _label(Permission p) {
    if (p == Permission.camera) return 'Camera';
    if (p == Permission.microphone) return 'Microphone';
    if (p == Permission.location) return 'Location';
    if (p == Permission.photos) return 'Photos';
    return p.toString().split('.').last;
  }

  String _desc(Permission p) {
    if (p == Permission.camera) {
      return 'Allow PressHop to use the camera for taking photos and videos for content submissions.';
    }
    if (p == Permission.microphone) {
      return 'Allow PressHop to record audio during video capture or interviews.';
    }
    if (p == Permission.location) {
      return 'Allow PressHop to access your location to tag and submit content.';
    }
    if (p == Permission.photos) {
      return 'Allow PressHop to access your photos and media to attach content.';
    }
    return 'This permission is required to use this feature.';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: size.width * 0.06),
            child: Column(
              children: [
                const Spacer(),
                Icon(Icons.lock, size: size.width * 0.20, color: Colors.red),
                SizedBox(height: size.width * 0.04),
                Text(
                  'Permissions Required',
                  style: TextStyle(
                    fontSize: size.width * 0.05,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'AirbnbCereal',
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: size.width * 0.02),
                Text(
                  'We need the permissions below to continue using the app. '
                  'Please allow them to proceed.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: size.width * 0.034,
                    color: Colors.black,
                    height: 1.4,
                    fontFamily: 'AirbnbCereal',
                  ),
                ),
                SizedBox(height: size.width * 0.07),
                // Per-permission rows with status icons
                ..._status.keys.map((p) {
                  final granted = _status[p] == true;
                  return Padding(
                    padding: EdgeInsets.only(bottom: size.width * 0.035),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _label(p),
                                style: TextStyle(
                                  fontSize: size.width * 0.04,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'AirbnbCereal',
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(height: size.width * 0.005),
                              Text(
                                _desc(p),
                                style: TextStyle(
                                  fontSize: size.width * 0.032,
                                  color: Colors.grey,
                                  fontFamily: 'AirbnbCereal',
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: size.width * 0.03),
                        Icon(
                          granted ? Icons.check_circle : Icons.cancel,
                          color: granted ? Colors.green : Colors.red,
                          size: size.width * 0.07,
                        ),
                      ],
                    ),
                  );
                }),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: size.width * 0.13,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(size.width * 0.03),
                      ),
                    ),
                    onPressed: _requestPermissions,
                    child: Text(
                      'Allow Permissions',
                      style: TextStyle(
                        fontSize: size.width * 0.04,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'AirbnbCereal',
                      ),
                    ),
                  ),
                ),
                SizedBox(height: size.width * 0.03),
                SizedBox(
                  width: double.infinity,
                  height: size.width * 0.13,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(size.width * 0.03),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: Text(
                      'Go Back',
                      style: TextStyle(
                        fontSize: size.width * 0.04,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'AirbnbCereal',
                      ),
                    ),
                  ),
                ),
                SizedBox(height: size.width * 0.04),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
